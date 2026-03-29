#!/bin/bash
set -e

# ---------------- CONFIG ----------------
SERVER_VM="server-node"
BASE_CLIENT_IMAGE="/var/lib/libvirt/images/client-base.qcow2"

LOG_FILE="$PWD/host_logs/access.log"

NUM_CLIENTS=3        # number of clients to deploy per itteration
CYCLES=1	     # number of client deployment itterations
CLIENT_DELAY=10      # time to wait for server logs to populate
#SHUTDOWN_DELAY=30    # time between client shutdowns
TRAFFIC_DELAY=5     # time to wait for clients to generate traffic


# ---------------- HELPERS ----------------

get_server_ip() {
    virsh domifaddr "$SERVER_VM" | \
    grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | head -n 1
}

wait_for_clients_in_log() {
    echo "Waiting for clients to appear in logs..."

    SEEN_IPS=""

    while true; do
        # Get unique client IPs from log, excluding server
        CURRENT_IPS=$(grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' "$LOG_FILE" \
            | grep -v "$SERVER_IP" \
            | sort -u)

        # Check if any new IPs have appeared
        NEW_IPS=$(comm -13 <(echo "$SEEN_IPS" | tr ' ' '\n' | sort) <(echo "$CURRENT_IPS" | tr ' ' '\n'))

        if [ -n "$NEW_IPS" ]; then
            # Add new IPs to seen list
            SEEN_IPS="$SEEN_IPS $NEW_IPS"
            # Print only the updated count
            echo "Detected $(echo "$SEEN_IPS" | wc -w) / $NUM_CLIENTS clients"
        fi

        # Break if all clients seen
        if [ $(echo "$SEEN_IPS" | wc -w) -ge "$NUM_CLIENTS" ]; then
            echo "All clients detected! Letting traffic continue for 5 seconds..."
            sleep $TRAFFIC_DELAY
            break
        fi

        sleep 1
    done
}

create_clients() {
    for i in $(seq 1 $NUM_CLIENTS); do
        NAME="client-node-$i"
        DISK="/var/lib/libvirt/images/$NAME.qcow2"

        echo -e "\n[+] Creating $NAME"

        virsh destroy "$NAME" 2>/dev/null || true
        virsh undefine "$NAME" --remove-all-storage 2>/dev/null || true

        sudo qemu-img create -f qcow2 -b "$BASE_CLIENT_IMAGE" -F qcow2 "$DISK"

        # Inject correct server IP into cloud-init
        sed "s/SERVER_IP_PLACEHOLDER/$SERVER_IP/g" configs/client-cloud-init.yaml > /tmp/client-$i.yaml
        
        #echo "------ /tmp/client-$i.yaml ------"
        #cat /tmp/client-$i.yaml
        #echo "--------------------------------"
        
        virt-install \
            --name "$NAME" \
            --memory 512 \
            --vcpus 1 \
            --disk path="$DISK",format=qcow2 \
            --import \
            --os-variant ubuntu20.04 \
            --network network=default \
            --cloud-init user-data=/tmp/client-$i.yaml \
            --noautoconsole --wait 0
    done
    
    wait # wait for all virt-install commands to finish
}


shutdown_clients_gradually() {
    echo "Shutting down clients gradually..."

    for i in $(seq 1 $NUM_CLIENTS); do
        NAME="client-node-$i"

        echo "[-] Stopping $NAME"
        virsh destroy "$NAME" || true
        virsh undefine "$NAME" --remove-all-storage || true
    done   
    wait
}

# ---------------- MAIN ----------------

echo "--- Discovering Server ---"

if ! virsh domstate "$SERVER_VM" | grep -q running; then
    echo "[INFO] Starting server..."
    virsh start "$SERVER_VM"
    sleep 5
fi
SERVER_IP=$(get_server_ip)

if [ -z "$SERVER_IP" ]; then
    echo "[ERROR] Could not determine server IP"
    exit 1
fi

echo "[INFO] Server IP: $SERVER_IP"

# Clear logs from previous orchestration
>"$LOG_FILE"
echo "[INFO] access.log cleared"

for cycle in $(seq 1 $CYCLES); do
    echo "======================================"
    echo "           CYCLE $cycle / $CYCLES"
    echo "======================================"
    
    echo "--- Creating clients ---"
    create_clients

    echo -e "\n--- Waiting for traffic ---"
    #sleep $TRAFFIC_DELAY

    wait_for_clients_in_log

    shutdown_clients_gradually

    echo "--- Cycle $cycle complete ---"

done

echo "======================================"
echo " All cycles complete!"
echo "======================================"


echo "--- Analyzing traffic logs ---"

# Extract IP addresses from access.log
ip_addresses=$(grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' "$LOG_FILE")

# Count total number of IP addresses
total_ip_count=$(echo "$ip_addresses" | wc -l)

# Count unique IP addresses
unique_ip_count=$(echo "$ip_addresses" | sort | uniq | wc -l)

# Count occurrences of each unique IP address and sort them
echo "$ip_addresses" | sort | uniq -c | sort -nr > "$PWD/host_logs/final_sorted.txt"

echo "---------------------------------"
echo "Total number of requests: $total_ip_count"
echo "Number of unique client IPs: $unique_ip_count"
echo "Top clients:"
cat "$PWD/host_logs/final_sorted.txt"
echo "Detailed counts saved in final_sorted.txt"
echo "---------------------------------"


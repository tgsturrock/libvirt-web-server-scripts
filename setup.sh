#!/bin/bash
set -e

# ---------------- CONFIG ----------------
IMAGE_URL="https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img"
IMAGE_NAME="focal-server-cloudimg-amd64.img"
BASE_IMAGE="/var/lib/libvirt/images/$IMAGE_NAME"

SERVER_DISK="/var/lib/libvirt/images/server-node.qcow2"
CLIENT_DISK="/var/lib/libvirt/images/client-base.qcow2"

BASE_DIR=$(pwd)
LOG_DIR="$BASE_DIR/host_logs"

# ---------------- HELPERS ----------------

install_dependencies() {
    echo "--- Installing dependencies ---"
    sudo apt update
    sudo apt install -y \
        qemu-kvm libvirt-daemon-system libvirt-clients \
        libguestfs-tools virtinst wget qemu-utils openssh-client
}

prepare_logs() {
    echo "--- Preparing shared log directory ---"
    mkdir -p "$LOG_DIR"
    sudo chown -R "$USER:$USER" "$LOG_DIR"
    chmod 755 "$LOG_DIR"
    touch "$LOG_DIR/access.log"
    chmod 666 "$LOG_DIR/access.log"
}

download_image(){
    echo "--- 3. Downloading base image ---"
    if [ ! -f "$BASE_IMAGE" ]; then
        wget -nc "$IMAGE_URL"
        sudo mv "$IMAGE_NAME" "$BASE_IMAGE"
    else
        echo "[SKIP] Base image already exists"
    fi
}

vm_exists() {
    virsh list --all | grep -q "$1"
}

get_vm_ip() {
    local vm_name=$1

    # Get MAC address of VM
    local mac=$(virsh domiflist "$vm_name" | awk '/network/ {print $5}')

    # Match MAC in DHCP leases
    virsh net-dhcp-leases default | awk -v mac="$mac" '$0 ~ mac {print $5}' | cut -d/ -f1
}

# ---------------- SETUP ----------------

install_dependencies
prepare_logs
download_image

# ---------------- SERVER SETUP ----------------

# Check if server base exists, if not - create it
if vm_exists "server-node"; then
    STATE=$(virsh domstate server-node)

    echo "[INFO] server-node already exists"

    # Check if virtiofs is attached
    if ! virsh dumpxml server-node | grep -q "<target dir='shared_logs'"; then
        echo "[WARN] shared_logs filesystem NOT attached!"
        echo "[ACTION] You must recreate the VM to apply --filesystem changes"
    else
        echo "[OK] shared_logs filesystem is attached"
    fi

    STATE=$(virsh domstate server-node)

    if [[ "$STATE" != "running" ]]; then
        echo "[INFO] Starting server-node..."
        virsh start server-node
    else
        echo "[SKIP] server-node already running"
    fi
else
    
    echo "--- 4. Creating server VM ---"

    sudo qemu-img create -f qcow2 -F qcow2 -b "$BASE_IMAGE" "$SERVER_DISK" 5G

    virt-install \
        --name server-node \
        --memory 1024 \
        --vcpus 1 \
        --disk path="$SERVER_DISK",format=qcow2 \
        --import \
        --os-variant ubuntu20.04 \
        --network network=default \
        --cloud-init user-data=configs/server-cloud-init.yaml \
        --noautoconsole --wait 0 \
        --filesystem source="$LOG_DIR",target=shared_logs,driver.type=virtiofs \
        --memorybacking source.type=memfd,access.mode=shared
fi

echo -e "\nWaiting for server IP..."

# Wait 30s for server to get IP assigned
for i in {1..30}; do
     SERVER_IP=$(get_vm_ip server-node)

     if [ -n "$SERVER_IP" ]; then
        break
     fi

    sleep 2
done

# Case server doesnt get IP
if [ -z "$SERVER_IP" ]; then
   echo "[ERROR] Failed to get server IP"
   exit 1
fi

# Try to ping server until nginx is up
echo -n "Waiting for Nginx on $SERVER_IP..."

MAX_RETRIES=30
COUNT=0

until curl -s -o /dev/null -w "%{http_code}" http://$SERVER_IP | grep -q 200; do
    echo -n "."
    sleep 3
    COUNT=$((COUNT+1))

    if [ $COUNT -ge $MAX_RETRIES ]; then
        echo "[ERROR] Nginx did not become ready"
        exit 1
    fi
done
echo " OK"
echo "[OK] Server Setup is done!"

# ---------------- CLIENT BASE SETUP ----------------

# Check if client base exists, if not - create it
if vm_exists "client-base"; then
    echo "[SKIP] client-base already exists"
else
    echo "--- 5. Creating client base VM ---"

    sudo qemu-img create -f qcow2 -F qcow2 -b "$BASE_IMAGE" "$CLIENT_DISK" 3G

    virt-install \
        --name client-base \
        --memory 512 \
        --vcpus 1 \
        --disk path="$CLIENT_DISK",format=qcow2 \
        --import \
        --os-variant ubuntu20.04 \
        --network network=default \
        --cloud-init user-data=configs/client-cloud-init.yaml \
        --noautoconsole --wait 0

    echo "Waiting for client-base cloud-init to finish..."
    
    until virsh domifaddr client-base | grep -q ipv4; do
        sleep 2
    done

    echo "[OK] assuming client-base fully provisioned"
    
    echo "Shutting down client-base..."
    virsh shutdown client-base

    echo "Waiting for shutdown..."
    
    # Give time for client base to shutdown (20s)
    for i in {1..20}; do
        STATE=$(virsh domstate client-base)

        if [ "$STATE" = "shut off" ]; then
            echo "[OK] client-base shut down cleanly"
            break
        fi

        sleep 2
    done

    # If still running after 20s, force it off
    if [ "$(virsh domstate client-base)" != "shut off" ]; then
        echo "[WARN] Forcing shutdown..."
        virsh destroy client-base
    fi
   
    # Wait till client base is shut off
    while [ "$(virsh domstate client-base)" != "shut off" ]; do
        sleep 2
    done
    
    echo "Cleaning cloud-init (making template reusable)..."

    sudo virt-customize -a "$CLIENT_DISK" \
      --run-command 'cloud-init clean' \
      --run-command 'rm -rf /var/lib/cloud/*' \
      --run-command 'truncate -s 0 /etc/machine-id' \
      --run-command 'rm -f /var/lib/dbus/machine-id'

    echo "[OK] client-base ready for cloning"
fi


echo "------------------------------------------"
echo " Setup complete!"
echo " Run ./orchestrate.sh to start the program"
echo "------------------------------------------"

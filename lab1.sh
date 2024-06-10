#ssh information
USER="tgs"
SERVER="192.168.122.203"
PASSWORD="1234"
server_vm="ubuntu20.04"

# Set the original VM name
original_vm="client2"

# Function to clone VM
clone_vm() {
    new_vm=$1
    virt-clone --original "$original_vm" --name "$new_vm" --file "/var/lib/libvirt/images/$new_vm.qcow2"
}

# Function to start VM
start_vm() {
    vm_name=$1
    virsh start "$vm_name"
}

# Function to wait for specified duration
wait_for() {
    duration=$1
    echo "Waiting for $duration seconds for clients to be up.."
    sleep "$duration"
}

# Function to check if VM exists
vm_exists() {
    vm_name=$1
    virsh list --all | grep -q "$vm_name"
}

# Function to check if VM is running
vm_is_running() {
    vm_name=$1
    virsh list --state-running | grep -q "$vm_name"
}

# Function to shut down VM
shutdown_vm() {
    vm_name=$1
    virsh shutdown "$vm_name"
    # Wait for VM to shut down
    while vm_is_running "$vm_name"; do
        echo "Waiting for $vm_name to shut down..."
        sleep 5
    done
}

# Function to erase VM
erase_vm() {
    vm_name=$1
    virsh undefine "$vm_name" --remove-all-storage
    sleep 2
}

server_is_running() {
    vm_name=$1
    if ! virsh list --state-running | grep -q "$vm_name"; then
        echo "Server $vm_name is not running. Starting it now..."
        virsh start "$vm_name"
        sleep 10
    else
        echo "Server $vm_name is already running."
    fi
}


# Main script
echo "Laboratoire 1- ELE796 Été 2022"

#Start server if not already running
server_is_running $server_vm

# Clear logs on server side
sshpass -p "$PASSWORD" ssh "$USER"@"$SERVER" "truncate -s 0 /home/tgs/logs/access.log"

#Main loop
for run in {1..3}; do


    
     echo "Run $run: Creating clients and checking server connection."
    # Clone VM three times
    for i in {1..3}; do
        clone_vm "cloned_vm_$i"
    done

    wait 1
    
    # Start cloned VMs
    for i in {1..3}; do
        start_vm "cloned_vm_$i"
    done

    # Wait for clients to be up
    wait_for 40

    # Shut down cloned VMs
    for i in {1..3}; do
        shutdown_vm "cloned_vm_$i"
    done

    # Erase cloned VMs
    for i in {1..3}; do
        erase_vm "cloned_vm_$i"
    done

    echo "Client management is complete."


    # Copy access and copy logs through ssh from server to host
    #sshpass -p "$PASSWORD" ssh "$USER"@"$SERVER" "cat /home/tgs/logs/access.log"> access.log

    # Mount server log folder to host folder
    sshpass -p "$PASSWORD" ssh "$USER"@"$SERVER" "sudo mount -t virtiofs server_logs /home/tgs/shared"

    # Copy logs into mounted folder
    sshpass -p "$PASSWORD" ssh "$USER"@"$SERVER" "cp /home/tgs/logs/access.log /home/tgs/shared/"

    # Extract IP addresses from access.log
    ip_addresses=$(grep -o "[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+" access.log)

    # Count total number of IP addresses
    total_ip_count=$(echo "$ip_addresses" | wc -l)

    # Count unique IP addresses
    unique_ip_count=$(echo "$ip_addresses" | sort | uniq | wc -l)

    # Count occurrences of each unique IP address and sort them
    echo "$ip_addresses" | sort | uniq -c | sort -nr > sorted.txt

    # Output the counts
    echo "---------------------------------"
    echo "Total number of IP addresses: $total_ip_count"
    echo "Number of unique IP addresses: $unique_ip_count"
    echo "IP addresses have been extracted and sorted. Results are in sorted.txt."
    echo "---------------------------------"
    echo "Run $run: Client/Server management is complete."
    sleep 2
done





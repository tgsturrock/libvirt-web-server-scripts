#!/bin/bash

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
    echo "Waiting for $duration seconds..."
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
}

# Main script

# Clone VM three times
for i in {1..3}; do
    clone_vm "cloned_vm_$i"
done

# Verify if VMs have been cloned
for i in {1..3}; do
    if vm_exists "cloned_vm_$i"; then
        echo "VM cloned_vm_$i has been successfully cloned."
    else
        echo "Error: VM cloned_vm_$i cloning failed."
    fi
done

# Start cloned VMs
for i in {1..3}; do
    start_vm "cloned_vm_$i"
done

# Wait for 60 seconds (adjust as needed)
wait_for 35

# Shut down cloned VMs
for i in {1..3}; do
    shutdown_vm "cloned_vm_$i"
done

# Erase cloned VMs
for i in {1..3}; do
    erase_vm "cloned_vm_$i"
done

echo "All operations completed."


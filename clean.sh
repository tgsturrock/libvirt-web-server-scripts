#!/bin/bash
# clean.sh - The "Nuclear Option" Reset

echo "--- 1. Stopping and Removing all VMs ---"
# This catches the server, the base template, and any numbered clones
VMS=$(virsh list --all --name | grep -E "server-node|client-")

for vm in $VMS; do
    echo "Destroying $vm..."
    virsh destroy "$vm" 2>/dev/null || true
    echo "Undefining $vm and removing its storage..."
    virsh undefine "$vm" --remove-all-storage 2>/dev/null || true
done

echo "--- 2. Cleaning Residual Disk Images ---"
# Manually ensures no stray .qcow2 files are hanging out in the default pool
sudo rm -f /var/lib/libvirt/images/server-node.qcow2
sudo rm -f /var/lib/libvirt/images/client-base.qcow2
sudo rm -f /var/lib/libvirt/images/client-node-*.qcow2

echo "--- 3. Resetting Virtual Network (Flushing DHCP) ---"
# This is the most important step for fixing IP assignment bugs
sudo virsh net-destroy default 2>/dev/null || true
sudo virsh net-start default

echo "--- 4. Cleaning Local Logs ---"
# Clears your project log directory so your next run starts at 0 hits
rm -rf ./host_logs/*
touch ./host_logs/access.log
chmod 666 ./host_logs/access.log

echo "-------------------------------------------------------"
echo "SYSTEM RESET COMPLETE."
echo "Your Libvirt environment is now at 'Square One'."
echo "You can now run: ./setup.sh"
echo "-------------------------------------------------------"

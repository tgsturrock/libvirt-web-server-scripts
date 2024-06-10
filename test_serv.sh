#ssh information
USER="tgs"
SERVER="192.168.122.203"
PASSWORD="1234"
server_vm="ubuntu20.04"

echo "Laboratoire 1- ELE796 Été 2022"

#Cette command vérifie s'il a des VMs existantes dans l"hôte
virsh list --all

#Start server
vm_is_running() {
    vm_name=$1
    if ! virsh list --state-running | grep -q "$vm_name"; then
        echo "$vm_name is not running. Starting it now..."
        virsh start "$vm_name"
        sleep 8
    else
        echo "$vm_name is already running."
    fi
}
vm_is_running $server_vm

# Clear access logs
sshpass -p "$PASSWORD" ssh "$USER"@"$SERVER" "truncate -s 0 /home/tgs/logs/access.log"




# SSH into the server and copy access logs from server to host
sshpass -p "$PASSWORD" ssh "$USER"@"$SERVER" "cat /home/tgs/logs/access.log"> access.log


# Mount server log folder to host folder
#sshpass -p "$PASSWORD" ssh "$USER"@"$SERVER" "sudo mount -t virtiofs server_logs /home/tgs/shared"



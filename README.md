# Libvirt Scripting for Dynamic Web Server Environments

This project demonstrates the use of shell scripting and the `libvirt` virtualization API to automate the deployment, management, and monitoring of a dynamic web server environment. Adhering to **Infrastructure as Code (IaC)** principles, this project provides a reusable and repeatable process for provisioning and de-provisioning virtual machines, ensuring consistency and efficiency.

The environment is composed of a host machine, a pre-configured Nginx web server VM, and multiple client VMs that are dynamically created and destroyed by the script.

### Features

* **Infrastructure as Code (IaC)**: The entire lifecycle of the virtual environment—from VM creation to network configuration and application-level actions—is defined and executed (orchestrate.sh, setup.sh, clean.sh). This approach provides a consistent, version-controlled blueprint for the infrastructure.
* **Automated VM Lifecycle Management**: The orchestrate.sh script manages the full lifecycle of client VMs, including cloning from a base image, startup, graceful shutdown, and complete cleanup. This eliminates manual configuration and reduces the risk of human error.
* **Dynamic Client Provisioning**: The program automatically provisions and connects up to three client VMs to the Nginx server in a staggered, controlled manner.
* **Automated Traffic Verification**: The script leverages SSH to remotely monitor the Nginx server's `access.log` file. By parsing the log, it automatically verifies that each client successfully connected to the server, providing a critical layer of automated quality assurance.
* **Complete Environment Teardown**: After the verification process, the script systematically shuts down and deletes all dynamically created resources, ensuring no lingering VMs or disk images are left behind.

### Scripts

* **setup.sh** - Prepares host environment and base images for client provisioning
* **orchestrate.sh** - Main orchestration script that dynamically creates clients, injects server IP, starts traffic loops, monitors server logs, and shuts down clients
* **clean.sh** - Cleans up all VMs, disk images, and temporary files

### How It Works

The project relies on shell scripts that act as the primary orchestrators. They use libvirt command-line tools (virt-clone, virsh, qemu-img) and SSH for communication with the server VM.

**1. Setup (setup.sh)**
   * Installs required dependencies (qemu, libvirt, virtinst, openssh-client, etc.)
   * Prepares a shared log directory
   * Downloads a base Ubuntu image for server and client VMs
   * Creates the server VM running Nginx and a client base VM for cloning
  
**2. Orchestration (orchestrate.sh)**
   * Dynamically detects the server IP
   * Clones multiple client VMs from the client base image
   * Each client VM continuously sends HTTP requests to the server
   * The script monitors the server’s access.log to verify client connections
   * After the cycle, clients are gracefully shut down and their disks removed

**2. Cleanup (clean.sh)**
   * Stops and removes all VMs (server, client base, cloned clients)
   * Deletes all .qcow2 disk images
   * Resets the virtual network and DHCP leases
   * Clears the host log directory, preparing for a fresh run

### Requirements

* Host machine with libvirt/KVM.
* Ubuntu 20.04 base images for server and clients.
* qemu-img, virt-install, virsh, SSH.
* Bash shell.

### Example Workflow
 ```bash
1. **Prepare the environment**  
   ./setup.sh
   
2. **Run the orchestration**  
   ./orchestrate.sh
   
3. **Cleanup the environment**  
   ./clean.sh
 ```
### Project Structure

 ```bash
.
├── setup.sh           # Prepares environment, downloads images, creates server & client-base
├── orchestrate.sh     # Clones clients, generates traffic, verifies logs
├── clean.sh           # Deletes VMs, images, resets network, clears logs
├── configs/
│   ├── server-cloud-init.yaml
│   └── client-cloud-init.yaml
└── host_logs/
    └── access.log     # Shared log file between server & host
 ```
 
### Configuration
* orchestrate.sh – Adjust the number of clients and cycles:
 ```bash
NUM_CLIENTS=3      # Number of clients per iteration
CYCLES=1           # Number of orchestration cycles
TRAFFIC_DELAY=5    # Time to allow traffic to generate
 ```
* Cloud-init files
   * `server-cloud-init.yaml` – Configures Nginx server and shared log mount
   * `client-cloud-init.yaml` – Configures clients to run traffic loop

### Notes
Designed for Ubuntu 20.04 hosts using libvirt/KVM
Requires sudo access for VM creation and network management
Can scale by adjusting NUM_CLIENTS and CYCLES in orchestrate.sh

This project highlights automated VM orchestration, dynamic client provisioning, and server verification, demonstrating practical skills for DevOps, cloud engineering, and systems administration.

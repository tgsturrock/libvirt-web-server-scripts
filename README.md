# Libvirt Scripting for Dynamic Web Server Environments

This project demonstrates the use of shell scripting and the `libvirt` virtualization API to automate the deployment, management, and monitoring of a dynamic web server environment. Adhering to **Infrastructure as Code (IaC)** principles, this project provides a reusable and repeatable process for provisioning and de-provisioning virtual machines, ensuring consistency and efficiency.

The environment is composed of a host machine, a pre-configured Nginx web server VM, and multiple client VMs that are dynamically created and destroyed by the script.

### Features

* **Infrastructure as Code (IaC)**: The entire lifecycle of the virtual environment—from VM creation to network configuration and application-level actions—is defined and executed through a single script. This approach provides a consistent, version-controlled blueprint for the infrastructure.
* **Automated VM Lifecycle Management**: The main script orchestrates the full lifecycle of client VMs, including cloning from a base image, startup, graceful shutdown, and complete cleanup. This eliminates manual configuration and reduces the risk of human error.
* **Dynamic Client Provisioning**: The program automatically provisions and connects up to three client VMs to the Nginx server in a staggered, controlled manner.
* **Automated Connection Verification**: The script leverages SSH to remotely monitor the Nginx server's `access.log` file. By parsing the log, it automatically verifies that each client successfully connected to the server, providing a critical layer of automated quality assurance.
* **Complete Environment Teardown**: After the verification process, the script systematically shuts down and deletes all dynamically created resources, ensuring no lingering VMs or disk images are left behind.

### How It Works

The project relies on a shell script that acts as the primary orchestrator. It uses `libvirt` command-line tools (`virt-clone`, `virsh`) and SSH for remote communication to the server VM.

1.  **Preparation**: The environment requires a pre-configured server VM running Nginx and a base client VM image. The host machine is set up with SSH access to the server.
2.  **Provisioning**: The script enters a loop that repeats the full deployment and verification cycle three times. Within each cycle, it dynamically clones three client VMs from the base image and starts them.
3.  **Execution**: As each client VM boots, it automatically executes a pre-configured command to request a page from the Nginx server.
4.  **Verification**: The host script remotely accesses the server's `access.log` to confirm that all three clients have successfully connected.
5.  **De-provisioning**: Upon successful verification, the script initiates a graceful shutdown of the client VMs one by one, followed by the complete deletion of their corresponding disk images and configurations.

This project showcases the ability to manage complex virtual environments in an automated and repeatable manner, a key skill for DevOps, cloud engineering, and system administration roles.

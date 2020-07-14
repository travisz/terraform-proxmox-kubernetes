Proxmox Kubernetes with Terraform
----
# WIP
This is a work in progress. I'm just getting the shell in place as I work through the setup / testing steps.

It is only using a single server for all of the instances, I'm not rich ;)

# Requirements
* Proxmox Terraform Provider: https://github.com/Telmate/terraform-provider-proxmox
* export of `PM_PASS` variable
* Fill out a "vars" file to pass to Terraform.

# Variables
| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-------:|:--------:|
| clone_name | Name of the template/clone to use for launch instances | string | `` | yes |
| instance_cores | Number of cores to allocate to each VM (default: 2) | number | `2` | no |
| instance_disk_size | Amount of disk space to allocate to each VM (default: 20G) | number | `20` | no |
| instance_memory | Amount of memory to allocate to each VM (default: 4096) | number | `4096` | no |
| instance_sockets | Number of sockets to allocate to each VM (default: 1) | number | `1` | no |
| instance_storage_name | Name of the storage to use within Proxmox | string | `` | yes |
| instance_storage_type | Type of storage to use within Proxmox | string | `` | yes |
| master_count | Number of Kubernetes Masters | number | `2` | no |
| private_key_path | Path to your private key to use with the provisioner | string | `` | yes |
| proxmox_node_name | Name of the Proxmox Node to deploy the instances on | string | `` | yes |
| proxmox_url | URL of the Proxmox API | string | `` | yes |
| proxmox_user | Valid user to access the Proxmox API | string | `` | yes |
| ssh_key | SSH Key to associate with the instance | string | `` | yes |
| worker_count | Number of Kubernetes Workers | number | `3` | no |

# Example Var File
```text
clone_name = "kubernetes-template"
instance_cores = "2"
instance_disk_size = "20"
instance_memory = "4096"
instance_sockets = "1"
instance_storage_name = "vmdata"
instance_storage_type = "dir"
master_count = "2"
proxmox_node_name = "proxmox01"
proxmox_url = "https://proxmox01.local/api2/json"
proxmox_user = "root@pam"
ssh_key = "ssh-rsa AAAAB3.... user@host"
worker_count = "3"
```

# Issues
* A `lifecycle` block is needed to ignore changes to the "network" section as subsequent applies mess with networking. This is a known issue with the Terraform Proxmox provider: https://github.com/Telmate/terraform-provider-proxmox/issues/112.

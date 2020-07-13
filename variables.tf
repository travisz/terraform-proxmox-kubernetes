variable "clone_name" {
  description = "Name of the template/clone to use for launch instances"
  type        = string
}

variable "instance_cores" {
  default     = 2
  description = "Number of cores to allocate to each VM (default: 2)"
  type        = number
}

variable "instance_disk_size" {
  default     = 20
  description = "Amount of disk space to allocate to each VM (default: 20G)"
  type        = number
}

variable "instance_memory" {
  default     = 4096
  description = "Amount of memory to allocate to each VM (default: 4096)"
  type        = number
}

variable "instance_sockets" {
  default     = 1
  description = "Number of sockets to allocate to each VM (default: 1)"
  type        = number
}

variable "instance_storage_name" {
  description = "Name of the storage to use within Proxmox"
  type        = string
}

variable "instance_storage_type" {
  description = "Type of storage to use within Proxmox"
  type        = string
}

variable "master_count" {
  default     = 2
  description = "Number of Kubernetes Masters"
  type        = number
}

variable "proxmox_node_name" {
  description = "Name of the Proxmox Node to deploy the instances on"
  type        = string
}

variable "proxmox_url" {
  description = "URL of the Proxmox API"
  type        = string
}

variable "proxmox_user" {
  description = "Valid user to access the Proxmox API"
  type        = string
}

variable "ssh_key" {
  description = "SSH Key to associate with the instance"
  type        = string
}

variable "worker_count" {
  default     = 3
  description = "Number of Kubernetes Workers"
  type        = number
}

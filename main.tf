# Requires export of PM_PASS
provider "proxmox" {
  pm_api_url = var.proxmox_url
  pm_user    = var.proxmox_user
}

# Masters
resource "proxmox_vm_qemu" "k8s-masters" {
  count       = var.master_count
  name        = "k8s-master-${count.index}"
  desc        = "k8s-master-${count.index}"
  target_node = var.proxmox_node_name
  clone       = var.clone_name
  agent       = 1
  full_clone  = true
  os_type     = "cloud-init"
  cores       = var.instance_cores
  sockets     = var.instance_sockets
  cpu         = "host"
  memory      = var.instance_memory
  scsihw      = "lsi"
  bootdisk    = "scsi0"

  disk {
    id           = 0
    size         = var.instance_disk_size
    type         = "scsi"
    storage      = var.instance_storage_name
    storage_type = var.instance_storage_type
    iothread     = true
  }

  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }

  lifecycle {
    ignore_changes = [
      network,
    ]
  }

  ipconfig0 = "ip=192.168.192.22${count.index}/24,gw=192.168.192.1"

  sshkeys = var.ssh_key
}

# Workers
resource "proxmox_vm_qemu" "k8s-workers" {
  count       = var.worker_count
  name        = "k8s-worker-${count.index}"
  desc        = "k8s-worker-${count.index}"
  target_node = var.proxmox_node_name
  clone       = var.clone_name
  agent       = 1
  full_clone  = true
  os_type     = "cloud-init"
  cores       = var.instance_cores
  sockets     = var.instance_sockets
  cpu         = "host"
  memory      = var.instance_memory
  scsihw      = "lsi"
  bootdisk    = "scsi0"

  disk {
    id           = 0
    size         = var.instance_disk_size
    type         = "scsi"
    storage      = var.instance_storage_name
    storage_type = var.instance_storage_type
    iothread     = true
  }

  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }

  lifecycle {
    ignore_changes = [
      network,
    ]
  }

  ipconfig0 = "ip=192.168.192.22${count.index + 2}/24,gw=192.168.192.1"

  sshkeys = var.ssh_key
}

terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.8.1"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_cloudinit_disk" "commoninit" {
  count = 2
  name  = "commoninit_${count.index}.iso"
  user_data = templatefile("cloud_init.cfg", {
    vlan_idx = count.index + 1
  })
  pool = "default"
}

resource "libvirt_domain" "vm" {
  count   = 2
  name    = "vm${count.index + 1}"
  vcpu    = 4
  memory  = 4096
  machine = "q35"

  network_interface {
    bridge = "ovsbr0"
  }

  network_interface {
    bridge = "ovsbr0"
  }

  disk {
    volume_id = libvirt_volume.volume[count.index].id
  }

  cloudinit = libvirt_cloudinit_disk.commoninit[count.index].id

  cpu {
    mode = "host-passthrough"
  }

  graphics {
    type        = "vnc"
    listen_type = "address"
  }

  # Makes the tty0 available via `virsh console`
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  xml {
    xslt = templatefile("patch.xsl.tpl", {
      tap_prefix = "tap${count.index + 1}"
    })
  }
}

resource "libvirt_volume" "volume" {
  count          = 2
  name           = "system_${count.index}.qcow2"
  pool           = "default"
  format         = "qcow2"
  base_volume_id = "/var/lib/libvirt/images/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2"
  size           = 500 * 1024 * 1024 * 1024
}

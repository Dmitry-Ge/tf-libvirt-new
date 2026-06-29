resource "libvirt_volume" "this" {
  name     = "${var.name}-disk.qcow2"
  pool     = "default"
  capacity = 1147483648

  target = {
    format = {
      type = "qcow2"
    }
    permissions = {
      owner = "64055"
      group = "109"
      mode  = "0640"
    }
  }

  create = {
    content = {
      url = "file:///var/lib/libvirt/images/debian-12-generic-amd64.qcow2"
    }
  }

}

resource "libvirt_cloudinit_disk" "commoninit" {
  name           = "commoninit.iso"
  user_data      = file("${path.module}/cloud_init.cfg")
  network_config = <<-EOF
    version: 2
    ethernets:
      enp1s0:
        dhcp4: true
  EOF
  meta_data      = <<-EOF
    instance-id: ${var.name}
    local-hostname: ${var.name}
  EOF
}

resource "libvirt_volume" "seed" {
  name = "${var.name}-seed.iso"
  pool = "default"
  target = {
    format = {
      type = "iso"
    }
    # permissions = {
    #   owner = "64055"
    #   group = "109"
    #   mode  = "0640"
    # }
  }
  create = {
    content = {
      url = libvirt_cloudinit_disk.commoninit.path
    }
  }
}

# Define KVM domain to create
resource "libvirt_domain" "db1" {
  name        = var.name
  memory      = "2048"
  memory_unit = "MiB"
  vcpu        = 2
  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
  }

  type = "kvm"

  devices = {
    disks = [
      {
        source = {
          volume = {
            volume = libvirt_volume.this.name
            pool   = "default"
          }
        }
        target = {
          dev = "vda"
          bus = "virtio"
        }
        driver = {
          type = "qcow2"
        }
      },
      {
        device = "cdrom"
        target = {
          bus = "sata"
          dev = "sda"
        }
        source = {
          volume = {
            pool   = libvirt_volume.seed.pool
            volume = libvirt_volume.seed.name
          }
        }
      }
    ]

    interfaces = [
      {
        type  = "network"
        model = { type = "virtio" }
        source = {
          network = {
            network = "default"
          }
        }
      }
    ]

    graphics = [
      {
        vnc = {
          auto_port = true
          listen    = "127.0.0.1"
        }
      }
    ]
  }

  running = true

}

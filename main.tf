resource "libvirt_volume" "this" {

  for_each = var.servers

  name     = "${each.value.name}-disk.qcow2"
  pool     = "default"
  capacity = var.disk_size * 1024 * 1024 * 1024


  target = {
    format = {
      type = "qcow2"
    }
    # permissions according of your libvirt config
    permissions = {
      owner = "64055" # user libvirt-qemu
      group = "109"   # group kvm
      mode  = "0640"
    }
  }

  create = {
    content = {
      url = "file:///var/lib/libvirt/images/debian-12-generic-amd64.qcow2"
    }
  }

}

resource "terraform_data" "resize_disk" {
  depends_on = [libvirt_volume.this]

  for_each = var.servers

  connection {
    type = "ssh"
    host = "localhost"
    user = "dmitryg"
    private_key = file("~/.ssh/id_rsa")
    port = 22
  }

  provisioner "remote-exec" {
    inline = [
      "sudo qemu-img resize ${libvirt_volume.this[each.key].path} +${var.disk_size}G",
    ]
  }
}


resource "libvirt_cloudinit_disk" "commoninit" {

  for_each = var.servers

  name = "${each.value.name}-commoninit.iso"

  user_data = templatefile("${path.module}/cloud_init.cfg.tpl", {
    password       = var.password,
    ssh-public-key = var.ssh-public-key,
    packages       = ["git", "qemu-guest-agent", "curl", "wireless-regdb"]
  })

  network_config = <<-EOF
    version: 2
    ethernets:
      enp1s0:
        dhcp4: true
  EOF

  meta_data = <<-EOF
    instance-id: ${each.value.name}
    local-hostname: ${each.value.name}
  EOF

}

resource "libvirt_volume" "seed" {

  for_each = var.servers

  name = "${each.value.name}-seed.iso"
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
      url = libvirt_cloudinit_disk.commoninit[each.key].path
    }
  }
}

# Define KVM domain to create
resource "libvirt_domain" "db1" {

  for_each = var.servers

  name        = each.value.name
  memory      = each.value.ram
  vcpu        = each.value.cpu
  memory_unit = "MiB"

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
            volume = libvirt_volume.this[each.key].name
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
            pool   = libvirt_volume.seed[each.key].pool
            volume = libvirt_volume.seed[each.key].name
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
# pause 30 seconds after boot
resource "time_sleep" "wait_10_seconds" {
  depends_on = [libvirt_domain.db1]
  create_duration = "10s"
}


# we need hard reset vm after deploy
resource "null_resource" "hard_reset" {

  depends_on = [time_sleep.wait_10_seconds]

  for_each = var.servers

  provisioner "remote-exec" {
    inline = [
      "sudo virsh reset ${each.value.name}",
    ]
    connection {
      type = "ssh"
      host = "localhost"
      user = "dmitryg"
      private_key = file("~/.ssh/id_rsa")
      port = 22
    }
  }
}

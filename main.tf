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
  name = "commoninit.iso"
  # user_data      = file("${path.module}/cloud_init.cfg")
  user_data      = <<-EOF
    #cloud-config
    users:
      - name: support
        gecos: Support Team
        lock-passwd: false
        shell: /bin/bash
        sudo: ALL=(ALL) NOPASSWD:ALL
        passwd: ${var.password}
        ssh_authorized_keys:
          - ${var.ssh-public-key}
    # mkpasswd --method=SHA-512 --rounds=4096

    # Enable cloud-init modules
    cloud_config_modules:
      - resolv_conf
      - runcmd
      - timezone
      - locales-all
      - package-update-upgrade-install

    timezone: Europe/Moscow

    manage_resolv_conf: true

    resolv_conf:
      nameservers: ['192.168.109.3']

    # Update/Upgrade & Reboot if necessary
    package_update: false
    package_upgrade: false
    package_reboot_if_required: true

    packages:
      - git
      - qemu-guest-agent
      - wireless-regdb  # fix bug with regulatory.db

    locale: en_US.UTF-8
    bootcmd:
      - sed -i '/en_US.UTF-8/s/^# //' /etc/locale.gen
      - locale-gen
      - update-locale LANG=en_US.UTF-8

    # кусок от RedHat-based образа
    # runcmd:
    #  - set enforce 0 sestatus
    #  - sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
    #  - yum -y remove cloud-init
    #  - systemctl enable qemu-guest-agent.service && systemctl start qemu-guest-agent.service

    # Configure where output will go
    output:
      all: ">> /var/log/cloud-init.log"

    final_message: "The system is finally up, after $UPTIME seconds"
  EOF
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

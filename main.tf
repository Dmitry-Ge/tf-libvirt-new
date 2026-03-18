#provider "libvirt" {
#  uri = "qemu:///system"
#}

#provider "libvirt" {
#  alias = "server2"
#  uri   = "qemu+ssh://root@192.168.100.10/system"
#}

resource "libvirt_pool" "this" {
  name = "centos"
  type = "dir"
  target {
    path = "/srv/libvirt/images/"
  }
}

resource "libvirt_volume" "centos7-qcow2" {
  name      = "${var.name}-disk.qcow2"
  pool      = libvirt_pool.this.name
  source = "/var/lib/libvirt/images/debian-12-generic-amd64.qcow2"
  format    = "qcow2"
}

# resource "libvirt_network" "this" {
#   name = "${var.name}-net"
#   mode = "bridge"
#   bridge = "br0"
#   autostart = true
# }

resource "libvirt_cloudinit_disk" "commoninit" {
  name      = "commoninit.iso"
  user_data = templatefile("${path.module}/cloud_init.cfg", { hostname = var.name })
  network_config = templatefile("${path.module}/network_config.cfg", { hostname = var.name })
}

# Define KVM domain to create
resource "libvirt_domain" "db1" {
  name      = "${var.name}"
  memory    = "2048"
  vcpu      = 2

  cloudinit = "${libvirt_cloudinit_disk.commoninit.id}"

  network_interface {
    # network_name = "bridged-network"
    # hostname = "master"
    # addresses = ["192.168.109.200"]
    # network_id = libvirt_network.this.id
    bridge = "br0"
    # wait_for_lease = true
    # wait for lease only need for output plugin
  }

  disk {
    volume_id = "${libvirt_volume.centos7-qcow2.id}"
  }

  #use pre-builded image cloud-init
  #disk {
  #  file = "/var/lib/libvirt/images/config.iso"
  #}

  console {
    type = "pty"
    target_type = "virtio"
    target_port = "0"
  }

  graphics {
    type = "spice"
    listen_type = "address"
    autoport = true
  }
}

# output "ips" {
#   value = "${libvirt_domain.db1.*.network_interface.0.addresses}"
# }

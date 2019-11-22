#provider "libvirt" {
#  uri = "qemu:///system"
#}

#provider "libvirt" {
#  alias = "server2"
#  uri   = "qemu+ssh://root@192.168.100.10/system"
#}

#resource "libvirt_pool" "centos" {
#  name = "centos"
#  type = "dir"
#  path = "/var/spool/centos"
#}

resource "libvirt_volume" "centos7-qcow2" {
  name      = "centos7.qcow2"
  pool      = "default"
  # source  = "https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2"
  #source   = "./CentOS-7-x86_64-GenericCloud.qcow2"
  source    = "/var/lib/libvirt/images/CentOS-7-x86_64-GenericCloud.qcow2"
  format    = "qcow2"
}

data "template_file" "user_data" {
  template  = "${file("${path.module}/cloud_init.cfg")}"
}

data "template_file" "network_config" {
  template  = "${file("${path.module}/network_config.cfg")}"
}

resource "libvirt_cloudinit_disk" "commoninit" {
  name      = "commoninit.iso"
  user_data = "${data.template_file.user_data.rendered}"
  network_config = "${data.template_file.network_config.rendered}"
  # pool    = "${libvirt_pool.centos.path}"
}

# Define KVM domain to create
resource "libvirt_domain" "db1" {
  # name    = "db1"
  name      = "${var.name}"
  memory    = "2048"
  vcpu      = 2

  cloudinit = "${libvirt_cloudinit_disk.commoninit.id}"

  network_interface {
    network_name = "default"
    wait_for_lease = true
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

output "ips" {
  value = "${libvirt_domain.db1.*.network_interface.0.addresses}"
}

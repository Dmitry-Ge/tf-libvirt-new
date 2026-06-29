
#provider "libvirt" {
#  uri = "qemu:///system"
#  alias = "server2"
#  uri   = "qemu+ssh://root@192.168.100.10/system"
#  for macos it should be
#  uri  = "qemu+ssh://user@host/system?socket=/var/run/libvirt/libvirt-sock"
#}

terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
      version = "0.9.5"
    }
  }
}

provider "libvirt" {
  # alias = "server"
  uri = "qemu+ssh://dmitryg@192.168.109.139/system?socket=/var/run/libvirt/libvirt-sock"
  # uri = "qemu+ssh://dmitryg@192.168.109.139/system?sshauth=privkey&no_verify=1"
 #  uri = "qemu:///system"
}

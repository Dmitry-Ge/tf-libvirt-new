terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.9.5"
    }
  }
}

provider "libvirt" {
  # alias = "server"
  # uri = "qemu+ssh://username@hostname/system?socket=/var/run/libvirt/libvirt-sock"
  # uri = "qemu+ssh://username@hostname/system?sshauth=privkey&no_verify=1"
  uri = "qemu:///system"
}

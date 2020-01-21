#provider "libvirt" {
#  uri = "qemu:///system"
#  alias = "server2"
#  uri   = "qemu+ssh://root@192.168.100.10/system"
#  for macos it should be
#  uri  = "qemu+ssh://user@host/system?socket=/var/run/libvirt/libvirt-sock"
#}

provider "libvirt" {
  alias = "server"
  uri   = "qemu+ssh://dmitryg@192.168.109.13/system"
}

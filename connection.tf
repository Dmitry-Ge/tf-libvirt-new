#provider "libvirt" {
#  uri = "qemu:///system"
#}

provider "libvirt" {
  alias = "server"
  uri   = "qemu+ssh://dmitryg@192.168.109.13/system"
}

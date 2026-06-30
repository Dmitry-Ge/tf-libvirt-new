output "instructions" {
  value = <<-EOF

    Virtual machines have been created!

    To find IP addresses assigned by DHCP:
      sudo virsh domifaddr ubuntu-vm1
      sudo virsh domifaddr ubuntu-vm2

    Or check the DHCP leases:
      sudo virsh net-dhcp-leases default

    To connect via SSH (once you know the IP):
      ssh root@<IP-ADDRESS>
      Password: password

    To view VM console:
      sudo virsh console ubuntu-vm1
      sudo virsh console ubuntu-vm2

    To connect via VNC:
      1. Find VNC port: sudo virsh domdisplay ubuntu-vm1
      2. Connect with VNC client to that address

    Note: It may take 30-60 seconds after boot for cloud-init to complete
          and the SSH server to be available.
  EOF
}

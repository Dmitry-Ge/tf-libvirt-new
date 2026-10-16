#cloud-config

users:
  - name: support
    gecos: Support Team
    lock-passwd: false
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    passwd: ${password}
    ssh_authorized_keys:
      - ${ssh-public-key}

# mkpasswd --method=SHA-512 --rounds=4096

# Enable cloud-init modules
cloud_config_modules:
  - resolv_conf
  - runcmd
  - timezone
  - package-update-upgrade-install

timezone: Europe/Moscow

# manage_resolv_conf: true

# resolv_conf:
#   nameservers: ['192.168.109.3']

# Update/Upgrade & Reboot if necessary
package_update: false
package_upgrade: false
package_reboot_if_required: true

packages:
%{ for pkg in packages ~}
  - ${pkg}
%{ endfor ~}
# - git
# - qemu-guest-agent
# - wireless-regdb  # fix bug with regulatory.db

# кусок от RedHat-based образа
# runcmd:
#  - set enforce 0 sestatus
#  - sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
#  - yum -y remove cloud-init
#  - systemctl enable qemu-guest-agent.service && systemctl start qemu-guest-agent.service
bootcmd:
  - echo "UMASK 027" >> /etc/login.defs

# Configure where output will go
output:
  all: ">> /var/log/cloud-init.log"

final_message: "The system is finally up, after $UPTIME seconds"

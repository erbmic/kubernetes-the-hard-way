#cloud-config
hostname: ${name}
manage_etc_hosts: true
users:
  - name: ubuntu
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    lock_passwd: true
    ssh_authorized_keys:
      - ${ssh_key}
package_update: true
package_upgrade: false
runcmd:
  - echo 'net.ipv4.ip_forward=1' | tee /etc/sysctl.d/99-hardway.conf
  - sysctl --system

version: 2
ethernets:
  eth1:
    dhcp4: false
    addresses: [${ip}]
    gateway4: ${gw}
    nameservers:
      addresses: [${dns}]

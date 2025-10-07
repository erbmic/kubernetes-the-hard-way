#!/usr/bin/env bash
set -euo pipefail

IFNAME="${1:-}"         # z.B. enp1s0 (libvirt) / enp0s8 (VBox)
THISHOST="${2:-}"

# 1) Primäre IP ermitteln
PRIMARY_IP=""

if [[ -n "${IFNAME}" ]]; then
  PRIMARY_IP="$(ip -4 -o addr show dev "$IFNAME" 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1 || true)"
fi

# Fallback: IP aus libvirt-Standardnetz 192.168.121.0/24 autodetektierten
if [[ -z "${PRIMARY_IP}" ]]; then
  PRIMARY_IP="$(ip -4 -o addr show | awk '/inet /{print $4}' | cut -d/ -f1 | grep -E '^192\.168\.121\.' | head -n1 || true)"
fi

# Letzter Fallback: irgendeine nicht-loopback IPv4 (nicht ideal)
if [[ -z "${PRIMARY_IP}" ]]; then
  PRIMARY_IP="$(ip -4 -o addr show | awk '/inet / && $2!="lo"{print $4}' | cut -d/ -f1 | head -n1 || true)"
fi

if [[ -z "${PRIMARY_IP}" ]]; then
  echo "ERROR: could not determine PRIMARY_IP" >&2
  exit 1
fi

NETWORK="$(awk -F. '{printf "%s.%s.%s", $1,$2,$3}' <<< "$PRIMARY_IP")"

# 2) Umgebung setzen
grep -q '^PRIMARY_IP=' /etc/environment || echo "PRIMARY_IP=${PRIMARY_IP}" | sudo tee -a /etc/environment >/dev/null
grep -q '^ARCH='       /etc/environment || echo "ARCH=amd64"              | sudo tee -a /etc/environment >/dev/null

# 3) Hosts-Datei nur gezielt anpassen
sudo sed -i "/\s${THISHOST}\(\s\|$\)/d" /etc/hosts || true

# Eigene Zeilen erneuern
sudo sed -i '/# BEGIN VAGRANT K8S HOSTS/,/# END VAGRANT K8S HOSTS/d' /etc/hosts
sudo tee -a /etc/hosts >/dev/null <<EOF
# BEGIN VAGRANT K8S HOSTS
${NETWORK}.11  controlplane01
${NETWORK}.12  controlplane02
${NETWORK}.21  node01
${NETWORK}.22  node02
${NETWORK}.30  loadbalancer
# END VAGRANT K8S HOSTS
EOF

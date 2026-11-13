#!/usr/bin/env bash
# Switch from iwd+systemd-networkd to NetworkManager (iwd backend) so the bar's Wi-Fi works.
# Reverts automatically if you end up offline.
set -u

online() { ping -c1 -W3 1.1.1.1 >/dev/null 2>&1; }

revert() {
  echo "==> Reverting to iwd + systemd-networkd"
  sudo systemctl disable --now NetworkManager
  sudo rm -f /etc/NetworkManager/conf.d/wifi_backend.conf
  sudo systemctl enable --now systemd-networkd iwd
  sleep 8
  online && echo "==> Back online on the old setup. Tell Claude it reverted." || echo "==> Still offline - run: sudo systemctl restart iwd systemd-networkd"
  exit 1
}

sudo -v || exit 1
echo "==> Configuring NetworkManager to use iwd"
sudo mkdir -p /etc/NetworkManager/conf.d
printf '[device]\nwifi.backend=iwd\n' | sudo tee /etc/NetworkManager/conf.d/wifi_backend.conf >/dev/null

echo "==> Switching services (connection will drop for a few seconds)"
sudo systemctl disable --now systemd-networkd.service systemd-networkd.socket systemd-networkd-wait-online.service 2>/dev/null
sudo systemctl enable iwd
sudo systemctl restart iwd
sudo systemctl enable --now NetworkManager

echo "==> Waiting for connection..."
for i in $(seq 1 20); do online && break; sleep 1; done

if ! online; then
  echo "==> Not connected yet. Pick your Wi-Fi:"
  nmcli dev wifi list
  read -rp "Wi-Fi name (SSID), or Enter to revert: " SSID
  [ -z "$SSID" ] && revert
  nmcli --ask dev wifi connect "$SSID" || revert
  sleep 5
  online || revert
fi

echo "==> Online via NetworkManager:"
nmcli -t -f DEVICE,STATE,CONNECTION dev | grep -v '^lo'
echo "==> Done. Tell Claude 'done'."

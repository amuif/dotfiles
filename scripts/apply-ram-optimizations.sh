#!/usr/bin/env bash
set -euo pipefail

echo "=== Configuring ZRAM (100% of RAM with zstd) ==="
cat << 'EOF' | sudo tee /etc/systemd/zram-generator.conf
[zram0]
zram-size = ram
compression-algorithm = zstd
EOF

echo "=== Tuning kernel sysctl for high-efficiency ZRAM swap ==="
cat << 'EOF' | sudo tee /etc/sysctl.d/99-zram.conf
# Aggressively push cold/idle pages into compressed zram
vm.swappiness = 180

# Disable page cluster readahead (zram in RAM has zero seek delay)
vm.page-cluster = 0

# Prevent latency spikes and sudden page drop freezes
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 125
EOF

echo "=== Applying sysctl settings ==="
sudo sysctl --system

echo "=== Restarting ZRAM ==="
sudo systemctl restart systemd-zram-setup@zram0.service

echo ""
echo "=== New Memory & ZRAM Status ==="
free -h
swapon --show
echo ""
echo "Done! Memory optimizations successfully applied."

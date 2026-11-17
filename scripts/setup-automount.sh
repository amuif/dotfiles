#!/usr/bin/env bash
# ==============================================================================
# Script to configure auto-mounting on boot with full user CRUD permissions
# Generated for user: amuif (UID: 1000, GID: 1000)
# ==============================================================================

set -euo pipefail

TARGET_USER="amuif"
TARGET_UID="1000"
TARGET_GID="1000"

# Check root privileges
if [[ $EUID -ne 0 ]]; then
    echo "[-] Error: This script must be run as root (use sudo)." >&2
    exit 1
fi

echo "=========================================================="
echo " Starting Auto-Mount Configuration for Arch Linux"
echo " Target user: $TARGET_USER (UID=$TARGET_UID, GID=$TARGET_GID)"
echo "=========================================================="

# Define partitions: UUID, Mountpoint, FSType, Label
declare -A PART_UUID=(
    ["Movies"]="01DB4491C79E2B20"
    ["Learning"]="01DAE189A8AB51E0"
    ["ToKeep"]="01DAE1893BD624F0"
    ["Datas"]="01DB2ADDCC90C3E0"
)

MOUNT_DIR="/mnt"
FSTAB_FILE="/etc/fstab"
BACKUP_FILE="${FSTAB_FILE}.bak.$(date +%Y%m%d_%H%M%S)"

# 1. Backup /etc/fstab
echo "[*] Creating backup of $FSTAB_FILE -> $BACKUP_FILE..."
cp "$FSTAB_FILE" "$BACKUP_FILE"

# 2. Create mount directories with proper ownership
for name in Movies Learning ToKeep Datas; do
    dir="${MOUNT_DIR}/${name}"
    echo "[*] Preparing mount point: $dir"
    mkdir -p "$dir"
    chown "$TARGET_UID:$TARGET_GID" "$dir"
    chmod 755 "$dir"
done

# 3. Clean up any existing entries for these UUIDs in /etc/fstab
for name in "${!PART_UUID[@]}"; do
    uuid="${PART_UUID[$name]}"
    sed -i "/UUID=${uuid}/d" "$FSTAB_FILE"
done
# Clean up any trailing blank lines at end of fstab
sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$FSTAB_FILE"

# 4. Append new fstab entries
echo "" >> "$FSTAB_FILE"
echo "# Auto-mounted data partitions (owner: $TARGET_USER)" >> "$FSTAB_FILE"

MOUNT_OPTS="uid=${TARGET_UID},gid=${TARGET_GID},umask=0022,iocharset=utf8,windows_names,force,nofail,x-systemd.device-timeout=5s"

for name in Movies Learning ToKeep Datas; do
    uuid="${PART_UUID[$name]}"
    mountpoint="${MOUNT_DIR}/${name}"
    printf "UUID=%-36s  %-14s  ntfs3  %-90s  0  0\n" "$uuid" "$mountpoint" "$MOUNT_OPTS" >> "$FSTAB_FILE"
    echo "[+] Added to $FSTAB_FILE: $name ($mountpoint)"
done

# 5. Reload systemd daemon
echo "[*] Reloading systemd manager configuration..."
systemctl daemon-reload

# 6. Mount all partitions
echo "[*] Mounting partitions..."
for name in Movies Learning ToKeep Datas; do
    mountpoint="${MOUNT_DIR}/${name}"
    echo " -> Mounting $mountpoint..."
    mount "$mountpoint" || {
        echo "[-] Warning: Failed to mount $mountpoint with ntfs3. Attempting with standard ntfs..."
        mount -t ntfs -o "uid=${TARGET_UID},gid=${TARGET_GID},umask=0022,iocharset=utf8,nofail" "/dev/disk/by-uuid/${PART_UUID[$name]}" "$mountpoint" || true
    }
done

# 7. Verify CRUD operations as user amuif
echo "=========================================================="
echo " Verifying User Permissions & CRUD Operations as $TARGET_USER"
echo "=========================================================="
CRUD_ALL_OK=true

for name in Movies Learning ToKeep Datas; do
    mountpoint="${MOUNT_DIR}/${name}"
    if ! mountpoint -q "$mountpoint"; then
        echo "[-] $name is NOT mounted! Skipping CRUD check."
        CRUD_ALL_OK=false
        continue
    fi

    echo -n "[*] Testing CRUD on $mountpoint... "
    TEST_FILE="${mountpoint}/.test_crud_${TARGET_USER}_$(date +%s)"
    
    # Run test as target user
    if sudo -u "$TARGET_USER" bash -c "
        # Create (C)
        echo 'crud_test_data' > '$TEST_FILE' && \
        # Read (R)
        grep -q 'crud_test_data' '$TEST_FILE' && \
        # Update (U)
        echo 'append_data' >> '$TEST_FILE' && \
        # Delete (D)
        rm -f '$TEST_FILE'
    "; then
        echo "SUCCESS (Full CRUD confirmed!)"
    else
        echo "FAILED"
        CRUD_ALL_OK=false
    fi
done

# 8. Add GTK bookmarks for Nautilus / file manager
USER_HOME=$(eval echo "~$TARGET_USER")
GTK_DIR="${USER_HOME}/.config/gtk-3.0"
BOOKMARKS_FILE="${GTK_DIR}/bookmarks"

mkdir -p "$GTK_DIR"
chown "$TARGET_UID:$TARGET_GID" "$GTK_DIR"
touch "$BOOKMARKS_FILE"
chown "$TARGET_UID:$TARGET_GID" "$BOOKMARKS_FILE"

for name in Movies Learning ToKeep Datas; do
    entry="file://${MOUNT_DIR}/${name} ${name}"
    if ! grep -qF "$entry" "$BOOKMARKS_FILE"; then
        echo "$entry" >> "$BOOKMARKS_FILE"
        echo "[+] Added Nautilus bookmark: $name"
    fi
done

echo "=========================================================="
if [ "$CRUD_ALL_OK" = true ]; then
    echo "[✓] ALL 4 PARTITIONS CONFIGURED, MOUNTED, AND FULL CRUD VERIFIED!"
else
    echo "[!] Completed with some warnings. Check partition status above."
fi
echo "=========================================================="

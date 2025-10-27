#!/bin/bash
# Fix dpkg interrupted problem
fix_dpkg() {
    pkill -9 -f 'apt|dpkg'
    rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock
    DEBIAN_FRONTEND=noninteractive dpkg --configure -a
}

echo -e "${gl_huang}System update in progress...${gl_bai}"
if command -v dnf &>/dev/null; then
    dnf -y update
    elif command -v yum &>/dev/null; then
    yum -y update
    elif command -v apt &>/dev/null; then
    fix_dpkg
    DEBIAN_FRONTEND=noninteractive apt update -y
    DEBIAN_FRONTEND=noninteractive apt full-upgrade -y
    elif command -v apk &>/dev/null; then
    apk update && apk upgrade
    elif command -v pacman &>/dev/null; then
    pacman -Syu --noconfirm
    elif command -v zypper &>/dev/null; then
    zypper refresh
    zypper update
    elif command -v opkg &>/dev/null; then
    opkg update
else
    echo "Unknown package manager!"
    return
fi
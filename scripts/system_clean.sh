#!/bin/bash
# Fix dpkg interrupted problem
fix_dpkg() {
    pkill -9 -f 'apt|dpkg'
    rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock
    DEBIAN_FRONTEND=noninteractive dpkg --configure -a
}

echo -e "${gl_huang}正在系统清理...${gl_bai}"
echo -e "${gl_huang}System cleaning in progress...${gl_bai}"
if command -v dnf &>/dev/null; then
    rpm --rebuilddb
    dnf autoremove -y
    dnf clean all
    dnf makecache
    journalctl --rotate
    journalctl --vacuum-time=1s
    journalctl --vacuum-size=500M
    
    elif command -v yum &>/dev/null; then
    rpm --rebuilddb
    yum autoremove -y
    yum clean all
    yum makecache
    journalctl --rotate
    journalctl --vacuum-time=1s
    journalctl --vacuum-size=500M
    
    elif command -v apt &>/dev/null; then
    fix_dpkg
    apt autoremove --purge -y
    apt clean -y
    apt autoclean -y
    journalctl --rotate
    journalctl --vacuum-time=1s
    journalctl --vacuum-size=500M
    
    elif command -v apk &>/dev/null; then
    echo "Cleaning package manager cache..."
    apk cache clean
    echo "Deleting system logs..."
    rm -rf /var/log/*
    echo "Deleting APK cache..."
    rm -rf /var/cache/apk/*
    echo "Deleting temporary files..."
    rm -rf /tmp/*
    
    elif command -v pacman &>/dev/null; then
    pacman -Rns $(pacman -Qdtq) --noconfirm
    pacman -Scc --noconfirm
    journalctl --rotate
    journalctl --vacuum-time=1s
    journalctl --vacuum-size=500M
    
    elif command -v zypper &>/dev/null; then
    zypper clean --all
    zypper refresh
    journalctl --rotate
    journalctl --vacuum-time=1s
    journalctl --vacuum-size=500M
    
    elif command -v opkg &>/dev/null; then
    echo "Deleting system logs..."
    rm -rf /var/log/*
    echo "Deleting temporary files..."
    rm -rf /tmp/*
    
    elif command -v pkg &>/dev/null; then
    echo "Cleaning unused dependencies..."
    pkg autoremove -y
    echo "Cleaning package manager cache..."
    pkg clean -y
    echo "Deleting system logs..."
    rm -rf /var/log/*
    echo "Deleting temporary files..."
    rm -rf /tmp/*
    
else
    echo "Unknown package manager!"
    return
fi
return

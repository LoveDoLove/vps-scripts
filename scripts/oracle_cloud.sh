#!/bin/bash
# scripts/oracle_cloud.sh
# Oracle Cloud Script Collection - Utilities for Oracle Cloud instances
# Author: LoveDoLove

# Color definitions
gl_hong='\033[31m'
gl_lv='\033[32m'
gl_huang='\033[33m'
gl_lan='\033[34m'
gl_kjlan='\033[96m'
gl_bai='\033[0m'
gl_bold='\033[1m'

# Open all ports (iptables)
open_all_ports() {
    echo -e "${gl_huang}Opening all ports via iptables...${gl_bai}"

    # Flush existing rules
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT
    iptables -F
    iptables -X

    # IPv6
    ip6tables -P INPUT ACCEPT
    ip6tables -P FORWARD ACCEPT
    ip6tables -P OUTPUT ACCEPT
    ip6tables -F
    ip6tables -X

    # Save iptables rules
    if command -v netfilter-persistent &>/dev/null; then
        netfilter-persistent save
    elif command -v iptables-save &>/dev/null; then
        iptables-save > /etc/iptables/rules.v4 2>/dev/null
        ip6tables-save > /etc/iptables/rules.v6 2>/dev/null
    fi

    # Disable Oracle Cloud firewall (firewalld)
    if systemctl is-active firewalld &>/dev/null; then
        systemctl stop firewalld
        systemctl disable firewalld
        echo -e "${gl_lv}firewalld has been stopped and disabled.${gl_bai}"
    fi

    # Disable Oracle Cloud iptables service
    if systemctl is-active oracle-cloud-agent &>/dev/null; then
        echo -e "${gl_huang}Oracle Cloud Agent detected.${gl_bai}"
    fi

    echo -e "${gl_lv}All ports are now open.${gl_bai}"
}

# Remove Oracle Cloud monitoring
remove_oracle_monitoring() {
    echo -e "${gl_huang}Removing Oracle Cloud monitoring agents...${gl_bai}"

    # Stop and disable Oracle Cloud Agent
    systemctl stop oracle-cloud-agent 2>/dev/null
    systemctl disable oracle-cloud-agent 2>/dev/null
    systemctl stop oracle-cloud-agent-updater 2>/dev/null
    systemctl disable oracle-cloud-agent-updater 2>/dev/null

    # Remove packages
    if command -v apt &>/dev/null; then
        apt remove -y oracle-cloud-agent 2>/dev/null
        apt purge -y oracle-cloud-agent 2>/dev/null
    elif command -v dnf &>/dev/null; then
        dnf remove -y oracle-cloud-agent 2>/dev/null
    elif command -v yum &>/dev/null; then
        yum remove -y oracle-cloud-agent 2>/dev/null
    fi

    echo -e "${gl_lv}Oracle Cloud monitoring agents removed.${gl_bai}"
}

# Enable IPv6
enable_ipv6() {
    echo -e "${gl_huang}Enabling IPv6...${gl_bai}"

    # Enable IPv6 in sysctl
    cat > /etc/sysctl.d/99-ipv6.conf << 'EOF'
net.ipv6.conf.all.disable_ipv6=0
net.ipv6.conf.default.disable_ipv6=0
net.ipv6.conf.lo.disable_ipv6=0
EOF
    sysctl --system >/dev/null 2>&1

    # Check GRUB for IPv6 disable
    if grep -q "ipv6.disable=1" /etc/default/grub 2>/dev/null; then
        sed -i 's/ipv6.disable=1/ipv6.disable=0/g' /etc/default/grub
        if command -v update-grub &>/dev/null; then
            update-grub
        elif command -v grub2-mkconfig &>/dev/null; then
            grub2-mkconfig -o /boot/grub2/grub.cfg
        fi
        echo -e "${gl_huang}GRUB updated. A reboot may be required.${gl_bai}"
    fi

    echo -e "${gl_lv}IPv6 has been enabled.${gl_bai}"
}

# Disable IPv6
disable_ipv6() {
    echo -e "${gl_huang}Disabling IPv6...${gl_bai}"

    cat > /etc/sysctl.d/99-ipv6.conf << 'EOF'
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.lo.disable_ipv6=1
EOF
    sysctl --system >/dev/null 2>&1

    echo -e "${gl_lv}IPv6 has been disabled.${gl_bai}"
}

# Resize boot volume (expand disk)
resize_boot_volume() {
    echo -e "${gl_huang}Expanding boot volume...${gl_bai}"

    # Find the root partition
    local root_device
    root_device=$(df / | tail -1 | awk '{print $1}')
    local disk_device
    disk_device=$(echo "$root_device" | sed 's/[0-9]*$//' | sed 's/p$//')

    echo -e "  Root partition: ${gl_lan}$root_device${gl_bai}"
    echo -e "  Disk device:    ${gl_lan}$disk_device${gl_bai}"

    if command -v growpart &>/dev/null; then
        # Get partition number
        local part_num
        part_num=$(echo "$root_device" | grep -o '[0-9]*$')
        echo -e "${gl_huang}Expanding partition $part_num on $disk_device...${gl_bai}"
        growpart "$disk_device" "$part_num"
    else
        echo -e "${gl_huang}Installing growpart...${gl_bai}"
        if command -v apt &>/dev/null; then
            apt install -y cloud-guest-utils 2>/dev/null
        elif command -v dnf &>/dev/null; then
            dnf install -y cloud-utils-growpart 2>/dev/null
        elif command -v yum &>/dev/null; then
            yum install -y cloud-utils-growpart 2>/dev/null
        fi

        local part_num
        part_num=$(echo "$root_device" | grep -o '[0-9]*$')
        growpart "$disk_device" "$part_num" 2>/dev/null
    fi

    # Resize filesystem
    if command -v resize2fs &>/dev/null; then
        resize2fs "$root_device"
    elif command -v xfs_growfs &>/dev/null; then
        xfs_growfs /
    fi

    echo -e "${gl_lv}Boot volume expansion complete.${gl_bai}"
    echo -e "${gl_huang}Current disk usage:${gl_bai}"
    df -h /
}

# Setup swap space
setup_swap() {
    echo -e "${gl_huang}Setting up swap space...${gl_bai}"

    local current_swap
    current_swap=$(free -m | awk '/Swap/{print $2}')
    echo -e "  Current swap: ${gl_lan}${current_swap}M${gl_bai}"

    read -p "Enter swap size in MB (e.g., 1024 for 1GB, 0 to disable): " swap_size

    if [ "$swap_size" = "0" ]; then
        echo -e "${gl_huang}Disabling swap...${gl_bai}"
        swapoff -a
        rm -f /swapfile
        sed -i '/swapfile/d' /etc/fstab
        echo -e "${gl_lv}Swap has been disabled.${gl_bai}"
        return
    fi

    # Remove old swap
    swapoff -a 2>/dev/null
    rm -f /swapfile 2>/dev/null

    # Create new swap
    echo -e "${gl_huang}Creating ${swap_size}M swap file...${gl_bai}"
    dd if=/dev/zero of=/swapfile bs=1M count="$swap_size" status=progress
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile

    # Add to fstab if not present
    if ! grep -q "swapfile" /etc/fstab; then
        echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
    fi

    echo -e "${gl_lv}Swap setup complete.${gl_bai}"
    free -h
}

# DD reinstall system
dd_reinstall() {
    echo -e "${gl_hong}WARNING: This will completely reinstall the system!${gl_bai}"
    echo -e "${gl_hong}All data will be lost! Make sure you have backups!${gl_bai}"
    echo ""
    echo -e "  ${gl_lv}1.${gl_bai} Debian 12"
    echo -e "  ${gl_lv}2.${gl_bai} Debian 11"
    echo -e "  ${gl_lv}3.${gl_bai} Ubuntu 22.04"
    echo -e "  ${gl_lv}4.${gl_bai} Ubuntu 20.04"
    echo -e "  ${gl_lv}5.${gl_bai} CentOS 9 Stream"
    echo -e "  ${gl_hong}0.${gl_bai} Cancel"
    read -p "Please select OS: " os_choice

    case $os_choice in
        0) return ;;
        1|2|3|4|5) ;;
        *) echo -e "${gl_hong}Invalid option!${gl_bai}"; return ;;
    esac

    read -p "Are you ABSOLUTELY sure? Type 'YES' to continue: " confirm
    if [ "$confirm" != "YES" ]; then
        echo -e "${gl_huang}Cancelled.${gl_bai}"
        return
    fi

    echo -e "${gl_huang}Running DD reinstall script...${gl_bai}"
    local tool
    if command -v curl &>/dev/null; then
        tool="curl"
    elif command -v wget &>/dev/null; then
        tool="wget"
    else
        echo -e "${gl_hong}Neither curl nor wget is available.${gl_bai}"
        return 1
    fi

    case $os_choice in
        1)
            if [ "$tool" = "curl" ]; then
                bash <(curl -fsSL https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh) -debian 12
            else
                bash <(wget -qO- https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh) -debian 12
            fi
            ;;
        2)
            if [ "$tool" = "curl" ]; then
                bash <(curl -fsSL https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh) -debian 11
            else
                bash <(wget -qO- https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh) -debian 11
            fi
            ;;
        3)
            if [ "$tool" = "curl" ]; then
                bash <(curl -fsSL https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh) -ubuntu 22.04
            else
                bash <(wget -qO- https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh) -ubuntu 22.04
            fi
            ;;
        4)
            if [ "$tool" = "curl" ]; then
                bash <(curl -fsSL https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh) -ubuntu 20.04
            else
                bash <(wget -qO- https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh) -ubuntu 20.04
            fi
            ;;
        5)
            if [ "$tool" = "curl" ]; then
                bash <(curl -fsSL https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh) -centos 9
            else
                bash <(wget -qO- https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh) -centos 9
            fi
            ;;
    esac
}

# Main menu
oracle_cloud_menu() {
    while true; do
        echo ""
        echo -e "${gl_bold}${gl_kjlan}========== Oracle Cloud Script Collection ==========${gl_bai}"
        echo -e "  ${gl_lv}1.${gl_bai} Open All Ports (iptables)"
        echo -e "  ${gl_lv}2.${gl_bai} Remove Oracle Cloud Monitoring"
        echo -e "  ${gl_lv}3.${gl_bai} Enable IPv6"
        echo -e "  ${gl_lv}4.${gl_bai} Disable IPv6"
        echo -e "  ${gl_lv}5.${gl_bai} Resize Boot Volume (Expand Disk)"
        echo -e "  ${gl_lv}6.${gl_bai} Setup Swap Space"
        echo -e "  ${gl_lv}7.${gl_bai} DD Reinstall System"
        echo ""
        echo -e "  ${gl_hong}0.${gl_bai} Return to Main Menu"
        echo -e "${gl_kjlan}=====================================================${gl_bai}"
        read -p "Please enter your choice: " choice

        case $choice in
            1) open_all_ports ;;
            2) remove_oracle_monitoring ;;
            3) enable_ipv6 ;;
            4) disable_ipv6 ;;
            5) resize_boot_volume ;;
            6) setup_swap ;;
            7) dd_reinstall ;;
            0) return ;;
            *) echo -e "${gl_hong}Invalid option!${gl_bai}" ;;
        esac

        echo ""
        echo -e "${gl_huang}Press any key to continue...${gl_bai}"
        read -n 1 -s
        clear
    done
}

oracle_cloud_menu

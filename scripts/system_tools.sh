#!/bin/bash
# scripts/system_tools.sh
# System Tools - System configuration and management utilities
# Author: LoveDoLove

# Color definitions
gl_hong='\033[31m'
gl_lv='\033[32m'
gl_huang='\033[33m'
gl_lan='\033[34m'
gl_kjlan='\033[96m'
gl_bai='\033[0m'
gl_bold='\033[1m'

# Change hostname
change_hostname() {
    local current_hostname
    current_hostname=$(hostname)
    echo -e "  Current hostname: ${gl_lan}$current_hostname${gl_bai}"
    read -p "Enter new hostname (leave blank to cancel): " new_hostname

    if [ -z "$new_hostname" ]; then
        echo -e "${gl_huang}Cancelled.${gl_bai}"
        return
    fi

    hostnamectl set-hostname "$new_hostname" 2>/dev/null
    # Update /etc/hosts
    if grep -q "$current_hostname" /etc/hosts 2>/dev/null; then
        sed -i "s/$current_hostname/$new_hostname/g" /etc/hosts
    fi

    echo -e "${gl_lv}Hostname changed to: $new_hostname${gl_bai}"
}

# Change DNS
change_dns() {
    echo -e "\n${gl_huang}Current DNS:${gl_bai}"
    cat /etc/resolv.conf | grep nameserver
    echo ""
    echo -e "  ${gl_lv}1.${gl_bai} Google DNS (8.8.8.8 / 8.8.4.4)"
    echo -e "  ${gl_lv}2.${gl_bai} Cloudflare DNS (1.1.1.1 / 1.0.0.1)"
    echo -e "  ${gl_lv}3.${gl_bai} Alibaba DNS (223.5.5.5 / 223.6.6.6)"
    echo -e "  ${gl_lv}4.${gl_bai} Tencent DNS (119.29.29.29 / 119.28.28.28)"
    echo -e "  ${gl_lv}5.${gl_bai} Custom DNS"
    echo -e "  ${gl_hong}0.${gl_bai} Cancel"
    read -p "Please select DNS: " dns_choice

    local dns1 dns2
    case $dns_choice in
        1) dns1="8.8.8.8"; dns2="8.8.4.4" ;;
        2) dns1="1.1.1.1"; dns2="1.0.0.1" ;;
        3) dns1="223.5.5.5"; dns2="223.6.6.6" ;;
        4) dns1="119.29.29.29"; dns2="119.28.28.28" ;;
        5)
            read -p "Enter primary DNS: " dns1
            read -p "Enter secondary DNS: " dns2
            ;;
        0) return ;;
        *) echo -e "${gl_hong}Invalid option!${gl_bai}"; return ;;
    esac

    if [ -n "$dns1" ]; then
        # Disable systemd-resolved if active
        if systemctl is-active systemd-resolved &>/dev/null; then
            systemctl stop systemd-resolved 2>/dev/null
            systemctl disable systemd-resolved 2>/dev/null
            rm -f /etc/resolv.conf
        fi

        cat > /etc/resolv.conf << EOF
nameserver $dns1
nameserver $dns2
EOF
        # Prevent overwrite by DHCP
        chattr +i /etc/resolv.conf 2>/dev/null

        echo -e "${gl_lv}DNS changed to: $dns1 / $dns2${gl_bai}"
    fi
}

# Change timezone
change_timezone() {
    local current_tz
    current_tz=$(timedatectl show --property=Timezone --value 2>/dev/null || cat /etc/timezone 2>/dev/null)
    echo -e "  Current timezone: ${gl_lan}$current_tz${gl_bai}"
    echo ""
    echo -e "  ${gl_lv}1.${gl_bai} Asia/Shanghai (UTC+8)"
    echo -e "  ${gl_lv}2.${gl_bai} Asia/Tokyo (UTC+9)"
    echo -e "  ${gl_lv}3.${gl_bai} Asia/Singapore (UTC+8)"
    echo -e "  ${gl_lv}4.${gl_bai} America/New_York (UTC-5)"
    echo -e "  ${gl_lv}5.${gl_bai} America/Los_Angeles (UTC-8)"
    echo -e "  ${gl_lv}6.${gl_bai} Europe/London (UTC+0)"
    echo -e "  ${gl_lv}7.${gl_bai} Custom timezone"
    echo -e "  ${gl_hong}0.${gl_bai} Cancel"
    read -p "Please select timezone: " tz_choice

    local new_tz
    case $tz_choice in
        1) new_tz="Asia/Shanghai" ;;
        2) new_tz="Asia/Tokyo" ;;
        3) new_tz="Asia/Singapore" ;;
        4) new_tz="America/New_York" ;;
        5) new_tz="America/Los_Angeles" ;;
        6) new_tz="Europe/London" ;;
        7)
            read -p "Enter timezone (e.g., Asia/Shanghai): " new_tz
            ;;
        0) return ;;
        *) echo -e "${gl_hong}Invalid option!${gl_bai}"; return ;;
    esac

    if [ -n "$new_tz" ]; then
        timedatectl set-timezone "$new_tz" 2>/dev/null || \
            ln -sf "/usr/share/zoneinfo/$new_tz" /etc/localtime
        echo -e "${gl_lv}Timezone changed to: $new_tz${gl_bai}"
        echo -e "  Current time: ${gl_lan}$(date)${gl_bai}"
    fi
}

# Manage swap
manage_swap() {
    echo -e "\n${gl_huang}Current Swap Status:${gl_bai}"
    free -h | grep -i swap
    swapon --show 2>/dev/null

    echo ""
    echo -e "  ${gl_lv}1.${gl_bai} Create/Resize Swap"
    echo -e "  ${gl_lv}2.${gl_bai} Disable Swap"
    echo -e "  ${gl_hong}0.${gl_bai} Cancel"
    read -p "Please select: " swap_choice

    case $swap_choice in
        1)
            read -p "Enter swap size in MB (e.g., 1024 for 1GB): " swap_size
            if [ -z "$swap_size" ] || [ "$swap_size" -le 0 ] 2>/dev/null; then
                echo -e "${gl_hong}Invalid size!${gl_bai}"
                return
            fi

            swapoff -a 2>/dev/null
            rm -f /swapfile 2>/dev/null

            echo -e "${gl_huang}Creating ${swap_size}M swap file...${gl_bai}"
            dd if=/dev/zero of=/swapfile bs=1M count="$swap_size" status=progress
            chmod 600 /swapfile
            mkswap /swapfile
            swapon /swapfile

            if ! grep -q "swapfile" /etc/fstab; then
                echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
            fi

            echo -e "${gl_lv}Swap created successfully.${gl_bai}"
            free -h
            ;;
        2)
            swapoff -a 2>/dev/null
            rm -f /swapfile 2>/dev/null
            sed -i '/swapfile/d' /etc/fstab
            echo -e "${gl_lv}Swap disabled.${gl_bai}"
            ;;
        0) return ;;
        *) echo -e "${gl_hong}Invalid option!${gl_bai}" ;;
    esac
}

# Change root password
change_root_password() {
    echo -e "${gl_huang}Changing root password...${gl_bai}"
    passwd root
}

# Enable/disable root SSH login
manage_root_ssh() {
    echo -e "\n${gl_huang}Root SSH Login Management:${gl_bai}"

    local current_status
    if grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config 2>/dev/null; then
        current_status="Enabled"
    elif grep -q "^PermitRootLogin no" /etc/ssh/sshd_config 2>/dev/null; then
        current_status="Disabled"
    else
        current_status="Default (check config)"
    fi

    echo -e "  Current status: ${gl_lan}$current_status${gl_bai}"
    echo ""
    echo -e "  ${gl_lv}1.${gl_bai} Enable Root SSH Login"
    echo -e "  ${gl_lv}2.${gl_bai} Disable Root SSH Login"
    echo -e "  ${gl_hong}0.${gl_bai} Cancel"
    read -p "Please select: " ssh_choice

    case $ssh_choice in
        1)
            sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
            systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
            echo -e "${gl_lv}Root SSH login enabled.${gl_bai}"
            ;;
        2)
            sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
            systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
            echo -e "${gl_lv}Root SSH login disabled.${gl_bai}"
            ;;
        0) return ;;
        *) echo -e "${gl_hong}Invalid option!${gl_bai}" ;;
    esac
}

# Change SSH port
change_ssh_port() {
    local current_port
    current_port=$(grep "^Port " /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}')
    current_port="${current_port:-22}"
    echo -e "  Current SSH port: ${gl_lan}$current_port${gl_bai}"

    read -p "Enter new SSH port (1-65535): " new_port

    if [ -z "$new_port" ]; then
        echo -e "${gl_huang}Cancelled.${gl_bai}"
        return
    fi

    if [ "$new_port" -lt 1 ] || [ "$new_port" -gt 65535 ] 2>/dev/null; then
        echo -e "${gl_hong}Invalid port number!${gl_bai}"
        return
    fi

    # Update SSH config
    if grep -q "^Port " /etc/ssh/sshd_config; then
        sed -i "s/^Port .*/Port $new_port/" /etc/ssh/sshd_config
    elif grep -q "^#Port " /etc/ssh/sshd_config; then
        sed -i "s/^#Port .*/Port $new_port/" /etc/ssh/sshd_config
    else
        echo "Port $new_port" >> /etc/ssh/sshd_config
    fi

    systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null

    echo -e "${gl_lv}SSH port changed to: $new_port${gl_bai}"
    echo -e "${gl_hong}IMPORTANT: Make sure port $new_port is open in your firewall!${gl_bai}"
}

# Manage crontab
manage_crontab() {
    echo -e "\n${gl_huang}Crontab Management:${gl_bai}"
    echo -e "  ${gl_lv}1.${gl_bai} View current crontab"
    echo -e "  ${gl_lv}2.${gl_bai} Edit crontab"
    echo -e "  ${gl_lv}3.${gl_bai} Add a reboot cron job"
    echo -e "  ${gl_hong}0.${gl_bai} Cancel"
    read -p "Please select: " cron_choice

    case $cron_choice in
        1)
            echo -e "\n${gl_lan}Current crontab entries:${gl_bai}"
            crontab -l 2>/dev/null || echo "No crontab configured."
            ;;
        2)
            crontab -e
            ;;
        3)
            echo -e "${gl_huang}Schedule auto-reboot:${gl_bai}"
            echo -e "  ${gl_lv}1.${gl_bai} Daily at 4:00 AM"
            echo -e "  ${gl_lv}2.${gl_bai} Weekly on Sunday at 4:00 AM"
            echo -e "  ${gl_lv}3.${gl_bai} Monthly on 1st at 4:00 AM"
            read -p "Please select: " reboot_choice
            local cron_expr
            case $reboot_choice in
                1) cron_expr="0 4 * * *" ;;
                2) cron_expr="0 4 * * 0" ;;
                3) cron_expr="0 4 1 * *" ;;
                *) echo -e "${gl_hong}Invalid option!${gl_bai}"; return ;;
            esac
            (crontab -l 2>/dev/null; echo "$cron_expr /sbin/reboot") | crontab -
            echo -e "${gl_lv}Auto-reboot cron job added: $cron_expr${gl_bai}"
            ;;
        0) return ;;
        *) echo -e "${gl_hong}Invalid option!${gl_bai}" ;;
    esac
}

# Enable/Disable IPv6
toggle_ipv6() {
    local ipv6_status
    ipv6_status=$(sysctl -n net.ipv6.conf.all.disable_ipv6 2>/dev/null)

    if [ "$ipv6_status" = "1" ]; then
        echo -e "  IPv6 status: ${gl_hong}Disabled${gl_bai}"
    else
        echo -e "  IPv6 status: ${gl_lv}Enabled${gl_bai}"
    fi

    echo ""
    echo -e "  ${gl_lv}1.${gl_bai} Enable IPv6"
    echo -e "  ${gl_lv}2.${gl_bai} Disable IPv6"
    echo -e "  ${gl_hong}0.${gl_bai} Cancel"
    read -p "Please select: " ipv6_choice

    case $ipv6_choice in
        1)
            sysctl -w net.ipv6.conf.all.disable_ipv6=0 >/dev/null
            sysctl -w net.ipv6.conf.default.disable_ipv6=0 >/dev/null
            cat > /etc/sysctl.d/99-ipv6.conf << 'EOF'
net.ipv6.conf.all.disable_ipv6=0
net.ipv6.conf.default.disable_ipv6=0
EOF
            echo -e "${gl_lv}IPv6 has been enabled.${gl_bai}"
            ;;
        2)
            sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null
            sysctl -w net.ipv6.conf.default.disable_ipv6=1 >/dev/null
            cat > /etc/sysctl.d/99-ipv6.conf << 'EOF'
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
EOF
            echo -e "${gl_lv}IPv6 has been disabled.${gl_bai}"
            ;;
        0) return ;;
        *) echo -e "${gl_hong}Invalid option!${gl_bai}" ;;
    esac
}

# Set system locale
set_locale() {
    echo -e "\n${gl_huang}Current locale:${gl_bai}"
    locale 2>/dev/null | head -1

    echo ""
    echo -e "  ${gl_lv}1.${gl_bai} English (en_US.UTF-8)"
    echo -e "  ${gl_lv}2.${gl_bai} Chinese Simplified (zh_CN.UTF-8)"
    echo -e "  ${gl_lv}3.${gl_bai} Japanese (ja_JP.UTF-8)"
    echo -e "  ${gl_hong}0.${gl_bai} Cancel"
    read -p "Please select: " locale_choice

    local new_locale
    case $locale_choice in
        1) new_locale="en_US.UTF-8" ;;
        2) new_locale="zh_CN.UTF-8" ;;
        3) new_locale="ja_JP.UTF-8" ;;
        0) return ;;
        *) echo -e "${gl_hong}Invalid option!${gl_bai}"; return ;;
    esac

    if command -v locale-gen &>/dev/null; then
        locale-gen "$new_locale" 2>/dev/null
    fi

    if command -v localectl &>/dev/null; then
        localectl set-locale LANG="$new_locale"
    else
        echo "LANG=$new_locale" > /etc/locale.conf 2>/dev/null
        export LANG="$new_locale"
    fi

    echo -e "${gl_lv}Locale set to: $new_locale${gl_bai}"
}

# Fail2ban management
manage_fail2ban() {
    echo -e "\n${gl_huang}Fail2ban Management:${gl_bai}"
    echo -e "  ${gl_lv}1.${gl_bai} Install Fail2ban"
    echo -e "  ${gl_lv}2.${gl_bai} Check Fail2ban Status"
    echo -e "  ${gl_lv}3.${gl_bai} View Banned IPs (SSH)"
    echo -e "  ${gl_lv}4.${gl_bai} Uninstall Fail2ban"
    echo -e "  ${gl_hong}0.${gl_bai} Cancel"
    read -p "Please select: " f2b_choice

    case $f2b_choice in
        1)
            echo -e "${gl_huang}Installing Fail2ban...${gl_bai}"
            if command -v apt &>/dev/null; then
                apt install -y fail2ban
            elif command -v dnf &>/dev/null; then
                dnf install -y fail2ban
            elif command -v yum &>/dev/null; then
                yum install -y fail2ban
            fi
            systemctl enable fail2ban 2>/dev/null
            systemctl start fail2ban 2>/dev/null
            echo -e "${gl_lv}Fail2ban installed and started.${gl_bai}"
            ;;
        2)
            if command -v fail2ban-client &>/dev/null; then
                fail2ban-client status
            else
                echo -e "${gl_hong}Fail2ban is not installed.${gl_bai}"
            fi
            ;;
        3)
            if command -v fail2ban-client &>/dev/null; then
                fail2ban-client status sshd 2>/dev/null || echo "SSH jail not configured."
            else
                echo -e "${gl_hong}Fail2ban is not installed.${gl_bai}"
            fi
            ;;
        4)
            echo -e "${gl_huang}Uninstalling Fail2ban...${gl_bai}"
            systemctl stop fail2ban 2>/dev/null
            if command -v apt &>/dev/null; then
                apt remove -y fail2ban && apt purge -y fail2ban
            elif command -v dnf &>/dev/null; then
                dnf remove -y fail2ban
            elif command -v yum &>/dev/null; then
                yum remove -y fail2ban
            fi
            echo -e "${gl_lv}Fail2ban uninstalled.${gl_bai}"
            ;;
        0) return ;;
        *) echo -e "${gl_hong}Invalid option!${gl_bai}" ;;
    esac
}

# Main menu
system_tools_menu() {
    while true; do
        echo ""
        echo -e "${gl_bold}${gl_kjlan}============ System Tools ============${gl_bai}"
        echo -e "${gl_kjlan}  --- Network Configuration ---${gl_bai}"
        echo -e "  ${gl_lv}1.${gl_bai} Change Hostname"
        echo -e "  ${gl_lv}2.${gl_bai} Change DNS"
        echo -e "  ${gl_lv}3.${gl_bai} Change SSH Port"
        echo -e "  ${gl_lv}4.${gl_bai} Toggle IPv6"
        echo -e "${gl_kjlan}  --- System Configuration ---${gl_bai}"
        echo -e "  ${gl_lv}5.${gl_bai} Change Timezone"
        echo -e "  ${gl_lv}6.${gl_bai} Set Locale"
        echo -e "  ${gl_lv}7.${gl_bai} Manage Swap"
        echo -e "  ${gl_lv}8.${gl_bai} Manage Crontab"
        echo -e "${gl_kjlan}  --- Security ---${gl_bai}"
        echo -e "  ${gl_lv}9.${gl_bai} Change Root Password"
        echo -e "  ${gl_lv}10.${gl_bai} Manage Root SSH Login"
        echo -e "  ${gl_lv}11.${gl_bai} Manage Fail2ban"
        echo ""
        echo -e "  ${gl_hong}0.${gl_bai} Return to Main Menu"
        echo -e "${gl_kjlan}=======================================${gl_bai}"
        read -p "Please enter your choice: " choice

        case $choice in
            1) change_hostname ;;
            2) change_dns ;;
            3) change_ssh_port ;;
            4) toggle_ipv6 ;;
            5) change_timezone ;;
            6) set_locale ;;
            7) manage_swap ;;
            8) manage_crontab ;;
            9) change_root_password ;;
            10) manage_root_ssh ;;
            11) manage_fail2ban ;;
            0) return ;;
            *) echo -e "${gl_hong}Invalid option!${gl_bai}" ;;
        esac

        echo ""
        echo -e "${gl_huang}Press any key to continue...${gl_bai}"
        read -n 1 -s
        clear
    done
}

system_tools_menu

#!/bin/bash
# scripts/warp_manage.sh
# WARP Management - Install, configure, and manage Cloudflare WARP
# Author: LoveDoLove

# Color definitions
gl_hong='\033[31m'
gl_lv='\033[32m'
gl_huang='\033[33m'
gl_lan='\033[34m'
gl_kjlan='\033[96m'
gl_bai='\033[0m'
gl_bold='\033[1m'

# Check if WARP is installed
check_warp_installed() {
    if command -v warp-cli &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Show WARP status
show_warp_status() {
    echo -e "\n${gl_bold}${gl_kjlan}============ WARP Status ============${gl_bai}"

    if check_warp_installed; then
        echo -e "  WARP Client:         ${gl_lv}Installed${gl_bai}"

        local warp_status
        warp_status=$(warp-cli status 2>/dev/null)
        if [ -n "$warp_status" ]; then
            echo -e "  Status:              ${gl_lan}$warp_status${gl_bai}"
        fi

        local warp_account
        warp_account=$(warp-cli account 2>/dev/null)
        if [ -n "$warp_account" ]; then
            echo -e "  Account:             ${gl_lan}$warp_account${gl_bai}"
        fi
    else
        echo -e "  WARP Client:         ${gl_hong}Not Installed${gl_bai}"
    fi

    # Check current IP info
    echo -e "\n  ${gl_huang}Current Network Info:${gl_bai}"
    local ipv4
    ipv4=$(curl -s4 --max-time 5 https://ipinfo.io/ip 2>/dev/null)
    if [ -n "$ipv4" ]; then
        echo -e "  IPv4:                ${gl_lan}$ipv4${gl_bai}"
    else
        echo -e "  IPv4:                ${gl_hong}N/A${gl_bai}"
    fi

    local ipv6
    ipv6=$(curl -s6 --max-time 5 https://v6.ipinfo.io/ip 2>/dev/null)
    if [ -n "$ipv6" ]; then
        echo -e "  IPv6:                ${gl_lan}$ipv6${gl_bai}"
    else
        echo -e "  IPv6:                ${gl_hong}N/A${gl_bai}"
    fi

    # Check if traffic goes through Cloudflare
    local cf_check
    cf_check=$(curl -s --max-time 5 https://www.cloudflare.com/cdn-cgi/trace 2>/dev/null | grep "warp=" | cut -d= -f2)
    if [ "$cf_check" = "on" ] || [ "$cf_check" = "plus" ]; then
        echo -e "  WARP Connection:     ${gl_lv}Active ($cf_check)${gl_bai}"
    else
        echo -e "  WARP Connection:     ${gl_hong}Inactive${gl_bai}"
    fi

    echo -e "${gl_kjlan}======================================${gl_bai}"
}

# Install WARP using official Cloudflare script
install_warp_official() {
    if check_warp_installed; then
        echo -e "${gl_lv}WARP is already installed.${gl_bai}"
        return 0
    fi

    echo -e "${gl_huang}Installing Cloudflare WARP...${gl_bai}"

    if command -v curl &>/dev/null; then
        curl -fsSL https://pkg.cloudflareclient.com/install | sh
    elif command -v wget &>/dev/null; then
        wget -qO- https://pkg.cloudflareclient.com/install | sh
    else
        echo -e "${gl_hong}Neither curl nor wget is available.${gl_bai}"
        return 1
    fi

    if check_warp_installed; then
        echo -e "${gl_lv}WARP installed successfully.${gl_bai}"
        echo -e "${gl_huang}Registering WARP...${gl_bai}"
        warp-cli registration new 2>/dev/null
        echo -e "${gl_lv}WARP registration complete.${gl_bai}"
    else
        echo -e "${gl_hong}WARP installation failed.${gl_bai}"
        return 1
    fi
}

# Install WARP via warp-go (fscarmen)
install_warp_fscarmen() {
    echo -e "${gl_huang}Installing WARP via fscarmen/warp script...${gl_bai}"
    echo -e "${gl_lan}This script provides additional options for WARP configuration.${gl_bai}"

    if command -v curl &>/dev/null; then
        bash <(curl -fsSL https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh)
    elif command -v wget &>/dev/null; then
        bash <(wget -qO- https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh)
    else
        echo -e "${gl_hong}Neither curl nor wget is available.${gl_bai}"
        return 1
    fi
}

# Connect WARP
connect_warp() {
    if ! check_warp_installed; then
        echo -e "${gl_hong}WARP is not installed. Please install it first.${gl_bai}"
        return 1
    fi

    echo -e "${gl_huang}Connecting WARP...${gl_bai}"
    warp-cli connect 2>/dev/null
    sleep 2

    local cf_check
    cf_check=$(curl -s --max-time 5 https://www.cloudflare.com/cdn-cgi/trace 2>/dev/null | grep "warp=" | cut -d= -f2)
    if [ "$cf_check" = "on" ] || [ "$cf_check" = "plus" ]; then
        echo -e "${gl_lv}WARP connected successfully.${gl_bai}"
    else
        echo -e "${gl_huang}WARP connect command sent. Checking status...${gl_bai}"
        warp-cli status 2>/dev/null
    fi
}

# Disconnect WARP
disconnect_warp() {
    if ! check_warp_installed; then
        echo -e "${gl_hong}WARP is not installed.${gl_bai}"
        return 1
    fi

    echo -e "${gl_huang}Disconnecting WARP...${gl_bai}"
    warp-cli disconnect 2>/dev/null
    echo -e "${gl_lv}WARP disconnected.${gl_bai}"
}

# Uninstall WARP
uninstall_warp() {
    if ! check_warp_installed; then
        echo -e "${gl_huang}WARP is not installed.${gl_bai}"
        return 0
    fi

    echo -e "${gl_hong}WARNING: This will remove Cloudflare WARP!${gl_bai}"
    read -p "Are you sure? (y/N): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo -e "${gl_huang}Cancelled.${gl_bai}"
        return 0
    fi

    echo -e "${gl_huang}Disconnecting WARP...${gl_bai}"
    warp-cli disconnect 2>/dev/null

    echo -e "${gl_huang}Uninstalling WARP...${gl_bai}"
    if command -v apt &>/dev/null; then
        apt remove -y cloudflare-warp 2>/dev/null
        apt purge -y cloudflare-warp 2>/dev/null
    elif command -v dnf &>/dev/null; then
        dnf remove -y cloudflare-warp 2>/dev/null
    elif command -v yum &>/dev/null; then
        yum remove -y cloudflare-warp 2>/dev/null
    fi

    echo -e "${gl_lv}WARP has been uninstalled.${gl_bai}"
}

# Set WARP mode
set_warp_mode() {
    if ! check_warp_installed; then
        echo -e "${gl_hong}WARP is not installed.${gl_bai}"
        return 1
    fi

    echo -e "\n${gl_huang}Select WARP Mode:${gl_bai}"
    echo -e "  ${gl_lv}1.${gl_bai} WARP (full tunnel)"
    echo -e "  ${gl_lv}2.${gl_bai} WARP + DNS over HTTPS"
    echo -e "  ${gl_lv}3.${gl_bai} Proxy mode (SOCKS5 on 127.0.0.1:40000)"
    read -p "Please enter your choice: " mode_choice

    case $mode_choice in
        1)
            warp-cli mode warp 2>/dev/null
            echo -e "${gl_lv}WARP mode set to: full tunnel${gl_bai}"
            ;;
        2)
            warp-cli mode doh 2>/dev/null
            echo -e "${gl_lv}WARP mode set to: DNS over HTTPS${gl_bai}"
            ;;
        3)
            warp-cli mode proxy 2>/dev/null
            echo -e "${gl_lv}WARP mode set to: Proxy (SOCKS5 on 127.0.0.1:40000)${gl_bai}"
            ;;
        *)
            echo -e "${gl_hong}Invalid option!${gl_bai}"
            ;;
    esac
}

# Main menu
warp_menu() {
    while true; do
        echo ""
        echo -e "${gl_bold}${gl_kjlan}============ WARP Management ============${gl_bai}"
        echo -e "  ${gl_lv}1.${gl_bai} Show WARP Status"
        echo -e "  ${gl_lv}2.${gl_bai} Install WARP (Official)"
        echo -e "  ${gl_lv}3.${gl_bai} Install WARP (fscarmen script)"
        echo -e "  ${gl_lv}4.${gl_bai} Connect WARP"
        echo -e "  ${gl_lv}5.${gl_bai} Disconnect WARP"
        echo -e "  ${gl_lv}6.${gl_bai} Set WARP Mode"
        echo -e "  ${gl_lv}7.${gl_bai} Uninstall WARP"
        echo ""
        echo -e "  ${gl_hong}0.${gl_bai} Return to Main Menu"
        echo -e "${gl_kjlan}===========================================${gl_bai}"
        read -p "Please enter your choice: " choice

        case $choice in
            1) show_warp_status ;;
            2) install_warp_official ;;
            3) install_warp_fscarmen ;;
            4) connect_warp ;;
            5) disconnect_warp ;;
            6) set_warp_mode ;;
            7) uninstall_warp ;;
            0) return ;;
            *) echo -e "${gl_hong}Invalid option!${gl_bai}" ;;
        esac

        echo ""
        echo -e "${gl_huang}Press any key to continue...${gl_bai}"
        read -n 1 -s
        clear
    done
}

warp_menu

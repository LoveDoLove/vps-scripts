#!/bin/bash
# scripts/basic_tools.sh
# Basic Tools - Install and manage commonly used tools
# Author: LoveDoLove

# Color definitions
gl_hong='\033[31m'
gl_lv='\033[32m'
gl_huang='\033[33m'
gl_lan='\033[34m'
gl_kjlan='\033[96m'
gl_bai='\033[0m'
gl_bold='\033[1m'

# Detect package manager
detect_pkg_manager() {
    if command -v dnf &>/dev/null; then
        PKG_MANAGER="dnf"
        PKG_INSTALL="dnf install -y"
        PKG_REMOVE="dnf remove -y"
    elif command -v yum &>/dev/null; then
        PKG_MANAGER="yum"
        PKG_INSTALL="yum install -y"
        PKG_REMOVE="yum remove -y"
    elif command -v apt &>/dev/null; then
        PKG_MANAGER="apt"
        PKG_INSTALL="apt install -y"
        PKG_REMOVE="apt remove -y"
    elif command -v apk &>/dev/null; then
        PKG_MANAGER="apk"
        PKG_INSTALL="apk add"
        PKG_REMOVE="apk del"
    elif command -v pacman &>/dev/null; then
        PKG_MANAGER="pacman"
        PKG_INSTALL="pacman -S --noconfirm"
        PKG_REMOVE="pacman -R --noconfirm"
    elif command -v zypper &>/dev/null; then
        PKG_MANAGER="zypper"
        PKG_INSTALL="zypper install -y"
        PKG_REMOVE="zypper remove -y"
    else
        echo -e "${gl_hong}Unsupported package manager!${gl_bai}"
        return 1
    fi
}

# Install a package
install_pkg() {
    local pkg_name="$1"
    if command -v "$pkg_name" &>/dev/null; then
        echo -e "${gl_lv}$pkg_name is already installed.${gl_bai}"
    else
        echo -e "${gl_huang}Installing $pkg_name...${gl_bai}"
        $PKG_INSTALL "$pkg_name"
        if command -v "$pkg_name" &>/dev/null; then
            echo -e "${gl_lv}$pkg_name installed successfully.${gl_bai}"
        else
            echo -e "${gl_hong}Failed to install $pkg_name.${gl_bai}"
        fi
    fi
}

# Install common tools
install_common_tools() {
    echo -e "${gl_huang}Installing common tools...${gl_bai}"
    local tools="curl wget vim git unzip tar socat jq htop tmux lsof net-tools"
    for tool in $tools; do
        install_pkg "$tool"
    done
    echo -e "${gl_lv}Common tools installation complete.${gl_bai}"
}

# Install development tools
install_dev_tools() {
    echo -e "${gl_huang}Installing development tools...${gl_bai}"
    local tools="gcc make"
    for tool in $tools; do
        install_pkg "$tool"
    done

    # Install Python3 (package name varies)
    if ! command -v python3 &>/dev/null; then
        echo -e "${gl_huang}Installing python3...${gl_bai}"
        case "$PKG_MANAGER" in
            apt) apt install -y python3 python3-pip ;;
            dnf|yum) $PKG_INSTALL python3 python3-pip ;;
            apk) apk add python3 py3-pip ;;
            pacman) pacman -S --noconfirm python python-pip ;;
            zypper) zypper install -y python3 python3-pip ;;
        esac
    else
        echo -e "${gl_lv}python3 is already installed.${gl_bai}"
    fi

    # Install Node.js
    if ! command -v node &>/dev/null; then
        echo -e "${gl_huang}Installing nodejs...${gl_bai}"
        case "$PKG_MANAGER" in
            apt) apt install -y nodejs npm ;;
            dnf|yum) $PKG_INSTALL nodejs npm ;;
            apk) apk add nodejs npm ;;
            pacman) pacman -S --noconfirm nodejs npm ;;
            zypper) zypper install -y nodejs npm ;;
        esac
    else
        echo -e "${gl_lv}nodejs is already installed.${gl_bai}"
    fi

    echo -e "${gl_lv}Development tools installation complete.${gl_bai}"
}

# Install network tools
install_network_tools() {
    echo -e "${gl_huang}Installing network tools...${gl_bai}"
    local tools="iperf3 nmap dnsutils mtr traceroute"
    case "$PKG_MANAGER" in
        apt)
            apt install -y iperf3 nmap dnsutils mtr-tiny traceroute
            ;;
        dnf|yum)
            $PKG_INSTALL iperf3 nmap bind-utils mtr traceroute
            ;;
        apk)
            apk add iperf3 nmap bind-tools mtr traceroute
            ;;
        pacman)
            pacman -S --noconfirm iperf3 nmap bind mtr traceroute
            ;;
        zypper)
            zypper install -y iperf nmap bind-utils mtr traceroute
            ;;
    esac
    echo -e "${gl_lv}Network tools installation complete.${gl_bai}"
}

# Check installed status of a tool
check_tool_status() {
    local tool_name="$1"
    if command -v "$tool_name" &>/dev/null; then
        local version
        version=$("$tool_name" --version 2>/dev/null | head -n 1)
        echo -e "  ${gl_lv}✓${gl_bai} $tool_name  ${gl_lan}$version${gl_bai}"
    else
        echo -e "  ${gl_hong}✗${gl_bai} $tool_name  ${gl_hong}(not installed)${gl_bai}"
    fi
}

# Show tools status
show_tools_status() {
    echo -e "\n${gl_bold}${gl_kjlan}============ Installed Tools Status ============${gl_bai}"
    echo -e "${gl_huang}Common Tools:${gl_bai}"
    for tool in curl wget vim git unzip tar socat jq htop tmux lsof; do
        check_tool_status "$tool"
    done
    echo -e "${gl_huang}Development Tools:${gl_bai}"
    for tool in gcc make python3 node; do
        check_tool_status "$tool"
    done
    echo -e "${gl_huang}Network Tools:${gl_bai}"
    for tool in iperf3 nmap mtr traceroute; do
        check_tool_status "$tool"
    done
    echo -e "${gl_kjlan}================================================${gl_bai}"
}

# Main menu
basic_tools_menu() {
    detect_pkg_manager

    while true; do
        echo ""
        echo -e "${gl_bold}${gl_kjlan}============ Basic Tools Management ============${gl_bai}"
        echo -e "  ${gl_lv}1.${gl_bai} Install Common Tools (curl, wget, vim, git, etc.)"
        echo -e "  ${gl_lv}2.${gl_bai} Install Development Tools (gcc, python3, nodejs)"
        echo -e "  ${gl_lv}3.${gl_bai} Install Network Tools (iperf3, nmap, mtr, etc.)"
        echo -e "  ${gl_lv}4.${gl_bai} Install All Tools"
        echo -e "  ${gl_lv}5.${gl_bai} Show Tools Status"
        echo ""
        echo -e "  ${gl_hong}0.${gl_bai} Return to Main Menu"
        echo -e "${gl_kjlan}================================================${gl_bai}"
        read -p "Please enter your choice: " choice

        case $choice in
            1) install_common_tools ;;
            2) install_dev_tools ;;
            3) install_network_tools ;;
            4)
                install_common_tools
                install_dev_tools
                install_network_tools
                ;;
            5) show_tools_status ;;
            0) return ;;
            *) echo -e "${gl_hong}Invalid option!${gl_bai}" ;;
        esac

        echo ""
        echo -e "${gl_huang}Press any key to continue...${gl_bai}"
        read -n 1 -s
        clear
    done
}

basic_tools_menu

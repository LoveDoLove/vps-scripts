#!/bin/bash
# scripts/bbr_manage.sh
# BBR Management - Enable, disable, and configure BBR
# Author: LoveDoLove

# Color definitions
gl_hong='\033[31m'
gl_lv='\033[32m'
gl_huang='\033[33m'
gl_lan='\033[34m'
gl_kjlan='\033[96m'
gl_bai='\033[0m'
gl_bold='\033[1m'

# Check kernel version for BBR compatibility (requires >= 4.9)
check_kernel_bbr_support() {
    local kernel_major kernel_minor
    kernel_major=$(uname -r | cut -d. -f1)
    kernel_minor=$(uname -r | cut -d. -f2)

    if [ "$kernel_major" -lt 4 ] || { [ "$kernel_major" -eq 4 ] && [ "$kernel_minor" -lt 9 ]; }; then
        echo -e "${gl_hong}BBR requires kernel version 4.9 or higher.${gl_bai}"
        echo -e "${gl_hong}Current kernel: $(uname -r)${gl_bai}"
        echo -e "${gl_huang}Please upgrade your kernel first.${gl_bai}"
        return 1
    fi
    return 0
}

# Check BBR status
check_bbr_status() {
    echo -e "\n${gl_bold}${gl_kjlan}============ BBR Status ============${gl_bai}"

    local congestion
    congestion=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)
    local qdisc
    qdisc=$(sysctl -n net.core.default_qdisc 2>/dev/null)
    local available
    available=$(sysctl -n net.ipv4.tcp_available_congestion_control 2>/dev/null)
    local kernel
    kernel=$(uname -r)

    echo -e "  Kernel Version:                ${gl_lan}$kernel${gl_bai}"
    echo -e "  TCP Congestion Control:        ${gl_lan}$congestion${gl_bai}"
    echo -e "  Queue Discipline:              ${gl_lan}$qdisc${gl_bai}"
    echo -e "  Available Algorithms:          ${gl_lan}$available${gl_bai}"

    if [ "$congestion" = "bbr" ]; then
        echo -e "  BBR Status:                    ${gl_lv}Enabled${gl_bai}"
    else
        echo -e "  BBR Status:                    ${gl_hong}Disabled${gl_bai}"
    fi

    echo -e "${gl_kjlan}=====================================${gl_bai}"
}

# Enable BBR
enable_bbr() {
    echo -e "${gl_huang}Enabling BBR...${gl_bai}"

    check_kernel_bbr_support || return 1

    # Check if BBR is already enabled
    local current
    current=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)
    if [ "$current" = "bbr" ]; then
        echo -e "${gl_lv}BBR is already enabled.${gl_bai}"
        return 0
    fi

    # Enable BBR
    cat > /etc/sysctl.d/99-bbr.conf << 'EOF'
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF
    sysctl --system >/dev/null 2>&1

    # Verify
    local new_congestion
    new_congestion=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)
    if [ "$new_congestion" = "bbr" ]; then
        echo -e "${gl_lv}BBR has been enabled successfully.${gl_bai}"
    else
        echo -e "${gl_hong}Failed to enable BBR.${gl_bai}"
        return 1
    fi
}

# Disable BBR (revert to cubic)
disable_bbr() {
    echo -e "${gl_huang}Disabling BBR...${gl_bai}"

    local current
    current=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)
    if [ "$current" != "bbr" ]; then
        echo -e "${gl_huang}BBR is not currently enabled.${gl_bai}"
        return 0
    fi

    # Remove BBR config
    rm -f /etc/sysctl.d/99-bbr.conf

    # Revert to cubic
    cat > /etc/sysctl.d/99-bbr.conf << 'EOF'
net.core.default_qdisc=fq_codel
net.ipv4.tcp_congestion_control=cubic
EOF
    sysctl --system >/dev/null 2>&1

    local new_congestion
    new_congestion=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)
    if [ "$new_congestion" = "cubic" ]; then
        echo -e "${gl_lv}BBR has been disabled. Reverted to cubic.${gl_bai}"
    else
        echo -e "${gl_huang}Congestion control is now: $new_congestion${gl_bai}"
    fi
}

# Enable BBR with optimized parameters
enable_bbr_optimized() {
    echo -e "${gl_huang}Enabling BBR with optimized network parameters...${gl_bai}"

    check_kernel_bbr_support || return 1

    cat > /etc/sysctl.d/99-bbr.conf << 'EOF'
# BBR congestion control
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr

# TCP optimization
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_slow_start_after_idle=0
net.ipv4.tcp_notsent_lowat=16384

# Buffer optimization
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_wmem=4096 65536 16777216

# Connection optimization
net.core.somaxconn=65535
net.ipv4.tcp_max_syn_backlog=65535
net.core.netdev_max_backlog=65535
net.ipv4.tcp_max_tw_buckets=2000000
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_fin_timeout=10
net.ipv4.tcp_mtu_probing=1
EOF
    sysctl --system >/dev/null 2>&1

    local new_congestion
    new_congestion=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)
    if [ "$new_congestion" = "bbr" ]; then
        echo -e "${gl_lv}BBR with optimized parameters has been enabled successfully.${gl_bai}"
    else
        echo -e "${gl_hong}Failed to enable BBR.${gl_bai}"
        return 1
    fi
}

# Main menu
bbr_menu() {
    while true; do
        echo ""
        echo -e "${gl_bold}${gl_kjlan}============ BBR Management ============${gl_bai}"
        echo -e "  ${gl_lv}1.${gl_bai} Check BBR Status"
        echo -e "  ${gl_lv}2.${gl_bai} Enable BBR"
        echo -e "  ${gl_lv}3.${gl_bai} Enable BBR (Optimized Parameters)"
        echo -e "  ${gl_lv}4.${gl_bai} Disable BBR (Revert to Cubic)"
        echo ""
        echo -e "  ${gl_hong}0.${gl_bai} Return to Main Menu"
        echo -e "${gl_kjlan}=========================================${gl_bai}"
        read -p "Please enter your choice: " choice

        case $choice in
            1) check_bbr_status ;;
            2) enable_bbr ;;
            3) enable_bbr_optimized ;;
            4) disable_bbr ;;
            0) return ;;
            *) echo -e "${gl_hong}Invalid option!${gl_bai}" ;;
        esac

        echo ""
        echo -e "${gl_huang}Press any key to continue...${gl_bai}"
        read -n 1 -s
        clear
    done
}

bbr_menu

#!/bin/bash
# scripts/system_tools.sh
# System Tools - System configuration, timezone, root passwd, ssh port, and locale
# Bilingual (CN / EN)
SCRIPT_PATH=$(dirname "$(readlink -f "$0")")
if [ -f "$SCRIPT_PATH/../lib/common.sh" ]; then
    . "$SCRIPT_PATH/../lib/common.sh"
elif [ -f "/tmp/vps-scripts/lib/common.sh" ]; then
    . "/tmp/vps-scripts/lib/common.sh"
fi
detect_language "$1"
require_root

# ============================================================
# i18n
# ============================================================
get_sys_msg() {
    local key="$1"
    case "$LANG_ENV" in
        CN)
            case "$key" in
                "title") echo "系統工具控制台" ;;
                "opt_1") echo "系統更新與升級" ;;
                "opt_2") echo "修改主機名" ;;
                "opt_3") echo "修改時區" ;;
                "opt_4") echo "添加虛擬內存 (Swap)" ;;
                "opt_5") echo "修改 Root 密碼" ;;
                "opt_6") echo "Root 登錄開關" ;;
                "opt_7") echo "修改 SSH 端口" ;;
                "opt_8") echo "設置系統語言 (Locale)" ;;
                "opt_9") echo "IPv6 開關" ;;
                "opt_10") echo "安裝及查看 Fail2ban 防暴力破解工具" ;;
                "opt_11") echo "切換壓縮算法 (gzip / Brotli / Zstd)" ;;
                "opt_12") echo "性能模式切換" ;;
                "opt_13") echo "DNS 優化" ;;
                "fail2ban_ok") echo "Fail2ban 服務狀態已展示。" ;;
                "comp_gzip") echo "已切換至 Gzip 壓縮" ;;
                "comp_brotli") echo "已切換至 Brotli 壓縮" ;;
                "comp_zstd") echo "已切換至 Zstd 壓縮" ;;
                "perf_standard") echo "已切換至標準性能模式" ;;
                "perf_high") echo "已切換至高性能模式" ;;
                "dns_ok") echo "DNS 已優化" ;;
                "swap_done") echo "虛擬內存已添加。" ;;
            esac
            ;;
        *)
            case "$key" in
                "title") echo "System Tools Console" ;;
                "opt_1") echo "System update & upgrade" ;;
                "opt_2") echo "Change hostname" ;;
                "opt_3") echo "Change timezone" ;;
                "opt_4") echo "Add swap space" ;;
                "opt_5") echo "Change root password" ;;
                "opt_6") echo "Toggle root login" ;;
                "opt_7") echo "Change SSH port" ;;
                "opt_8") echo "Set system locale" ;;
                "opt_9") echo "Toggle IPv6" ;;
                "opt_10") echo "Install & Monitor Fail2ban" ;;
                "opt_11") echo "Switch compression (gzip / Brotli / Zstd)" ;;
                "opt_12") echo "Performance mode" ;;
                "opt_13") echo "DNS optimization" ;;
                "fail2ban_ok") echo "Fail2ban daemon status displayed." ;;
                "comp_gzip") echo "Switched to Gzip compression" ;;
                "comp_brotli") echo "Switched to Brotli compression" ;;
                "comp_zstd") echo "Switched to Zstd compression" ;;
                "perf_standard") echo "Switched to standard performance mode" ;;
                "perf_high") echo "Switched to high performance mode" ;;
                "dns_ok") echo "DNS optimized" ;;
                "swap_done") echo "Swap space added." ;;
            esac
            ;;
    esac
}

# ============================================================
# Existing system functions
# ============================================================
upd_system() {
    install_pkgs sudo
    if command -v apt &>/dev/null; then
        apt update -y && apt upgrade -y
    elif command -v dnf &>/dev/null; then
        dnf update -y
    elif command -v yum &>/dev/null; then
        yum update -y
    elif command -v apk &>/dev/null; then
        apk update && apk upgrade
    fi
}

add_swap() {
    local size_mb="$1"
    [ -z "$size_mb" ] && size_mb=1024
    fallocate -l "${size_mb}M" /swapfile 2>/dev/null || dd if=/dev/zero of=/swapfile bs=1M count="$size_mb"
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    grep -q '/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
    echo -e "${gl_lv}$(get_sys_msg 'swap_done') ($size_mb MB)${gl_bai}"
}

upd_hostname() {
    read -p "New hostname: " new_host
    hostnamectl set-hostname "$new_host" 2>/dev/null || echo "$new_host" > /etc/hostname
}

upd_timezone() {
    tzselect 2>/dev/null || dpkg-reconfigure tzdata 2>/dev/null || echo -e "${gl_hong}Use 'timedatectl set-timezone Zone/Region'${gl_bai}"
}

upd_root_pwd() { passwd root; }

toggle_ssh_root() {
    local conf_file="/etc/ssh/sshd_config"
    [ -f /etc/ssh/sshd_config.d/99-root-login.conf ] && conf_file="/etc/ssh/sshd_config.d/99-root-login.conf"
    if grep -q "^PermitRootLogin yes" "$conf_file" 2>/dev/null; then
        sed -i 's/^PermitRootLogin yes/PermitRootLogin prohibit-password/' "$conf_file"
        echo -e "${gl_lv}Root password login disabled (key-only).${gl_bai}"
    else
        echo "PermitRootLogin yes" > "$conf_file"
        echo -e "${gl_lv}Root login enabled.${gl_bai}"
    fi
    sys_service restart sshd || sys_service restart ssh
}

upd_ssh_port() {
    read -p "New SSH port: " new_port
    sed -i "s/^#Port 22/Port $new_port/" /etc/ssh/sshd_config 2>/dev/null
    sed -i "s/^Port [0-9]*/Port $new_port/" /etc/ssh/sshd_config 2>/dev/null
    echo "Port $new_port" >> /etc/ssh/sshd_config
    sys_service restart sshd || sys_service restart ssh
    echo -e "${gl_huang}SSH port changed to $new_port. Keep current session open!${gl_bai}"
}

upd_locale() {
    if command -v localectl &>/dev/null; then
        localectl list-locales
        read -p "Enter locale (e.g. en_US.UTF-8): " new_loc
        localectl set-locale LANG="$new_loc"
    else
        read -p "Enter locale (e.g. en_US.UTF-8): " new_loc
        echo "LANG=$new_loc" > /etc/locale.conf
    fi
}

toggle_ipv6() {
    if sysctl net.ipv6.conf.all.disable_ipv6 2>/dev/null | grep -q "= 1"; then
        sysctl -w net.ipv6.conf.all.disable_ipv6=0
        sysctl -w net.ipv6.conf.default.disable_ipv6=0
        echo 0 > /proc/sys/net/ipv6/conf/all/disable_ipv6 2>/dev/null
        echo -e "${gl_lv}IPv6 enabled.${gl_bai}"
    else
        sysctl -w net.ipv6.conf.all.disable_ipv6=1
        sysctl -w net.ipv6.conf.default.disable_ipv6=1
        echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6 2>/dev/null
        echo -e "${gl_lv}IPv6 disabled.${gl_bai}"
    fi
}

# ============================================================
# Fail2ban panel (existing)
# ============================================================
fail2ban_panel() {
    while true; do
        clear
        echo -e "${gl_kjlan}$(get_sys_msg 'opt_10')${gl_bai}"
        echo -e "  ${gl_lv}1.${gl_bai} Install Fail2ban"
        echo -e "  ${gl_lv}2.${gl_bai} Monitor Fail2ban status"
        echo -e "  ${gl_lv}3.${gl_bai} Uninstall Fail2ban"
        echo -e "  ${gl_hong}0.${gl_bai} $(get_msg 'back')"
        read -p "Selection: " fb_ch
        case "$fb_ch" in
            1)
                install_pkgs fail2ban
                sys_service start fail2ban 2>/dev/null
                sys_service enable fail2ban 2>/dev/null
                break_end
                ;;
            2)
                if command -v fail2ban-client &>/dev/null; then
                    fail2ban-client status sshd 2>/dev/null || fail2ban-client status
                else
                    echo "Fail2ban is not installed."
                fi
                break_end
                ;;
            3)
                remove_pkgs fail2ban
                rm -rf /etc/fail2ban
                break_end
                ;;
            0) return ;;
            *) echo -e "${gl_hong}$(get_msg 'invalid_selection')${gl_bai}"; sleep 2 ;;
        esac
    done
}

# ============================================================
# NEW: Compression algorithm switching (gzip / Brotli / Zstd)
# ============================================================
toggle_compression() {
    echo -e "${gl_lv}1.${gl_bai} gzip"
    echo -e "${gl_lv}2.${gl_bai} Brotli"
    echo -e "${gl_lv}3.${gl_bai} Zstd"
    read -p "Select compression: " comp_ch
    case "$comp_ch" in
        1)
            if command -v apt &>/dev/null; then
                install_pkgs gzip
            fi
            cat > /etc/nginx/conf.d/compression.conf 2>/dev/null << 'EOF'
gzip on;
gzip_vary on;
gzip_proxied any;
gzip_comp_level 6;
gzip_types text/plain text/css application/json application/javascript text/xml application/xml+rss image/svg+xml;
EOF
            [ -f /etc/nginx/nginx.conf ] && sed -i 's/#\?gzip.*/gzip on;/' /etc/nginx/nginx.conf
            sys_service restart nginx 2>/dev/null || docker exec ldnmp-nginx nginx -s reload 2>/dev/null
            echo -e "${gl_lv}$(get_sys_msg 'comp_gzip')${gl_bai}"
            ;;
        2)
            if command -v apt &>/dev/null; then
                install_pkgs nginx-mod-brotli 2>/dev/null || \
                    install_pkgs libnginx-mod-brotli 2>/dev/null
            fi
            cat > /etc/nginx/conf.d/compression.conf 2>/dev/null << 'EOF'
brotli on;
brotli_comp_level 6;
brotli_types text/plain text/css application/json application/javascript text/xml application/xml+rss image/svg+xml;
EOF
            sys_service restart nginx 2>/dev/null || docker exec ldnmp-nginx nginx -s reload 2>/dev/null
            echo -e "${gl_lv}$(get_sys_msg 'comp_brotli')${gl_bai}"
            ;;
        3)
            if command -v apt &>/dev/null; then
                install_pkgs zstd 2>/dev/null
            fi
            cat > /etc/nginx/conf.d/compression.conf 2>/dev/null << 'EOF'
zstd on;
zstd_comp_level 3;
zstd_types text/plain text/css application/json application/javascript text/xml application/xml+rss image/svg+xml;
EOF
            sys_service restart nginx 2>/dev/null || docker exec ldnmp-nginx nginx -s reload 2>/dev/null
            echo -e "${gl_lv}$(get_sys_msg 'comp_zstd')${gl_bai}"
            ;;
    esac
    break_end
}

# ============================================================
# NEW: Performance mode switching
# ============================================================
performance_mode() {
    install_pkgs tuned 2>/dev/null
    echo -e "${gl_lv}1.${gl_bai} $(get_sys_msg 'perf_standard')"
    echo -e "${gl_lv}2.${gl_bai} $(get_sys_msg 'perf_high')"
    read -p "Selection: " perf_ch
    case "$perf_ch" in
        1)
            if command -v tuned-adm &>/dev/null; then
                tuned-adm profile balanced
            fi
            echo -e "${gl_lv}$(get_sys_msg 'perf_standard')${gl_bai}"
            ;;
        2)
            if command -v tuned-adm &>/dev/null && [ "$(nproc)" -ge 4 ] && [ "$(free -m | awk '/^Mem:/{print $2}')" -ge 4096 ]; then
                tuned-adm profile throughput-performance
            else
                echo -e "${gl_huang}High performance requires 4+ cores and 4GB+ RAM. Using standard.${gl_bai}"
            fi
            echo -e "${gl_lv}$(get_sys_msg 'perf_high')${gl_bai}"
            ;;
    esac
    break_end
}

# ============================================================
# NEW: DNS optimization (region-aware)
# ============================================================
optimize_dns() {
    install_pkgs curl
    # Check if likely in China
    local cn_check
    cn_check=$(curl -s --connect-timeout 3 https://www.baidu.com 2>/dev/null)
    local resolv_conf="/etc/resolv.conf"

    if [ -n "$cn_check" ]; then
        echo -e "${gl_huang}China detected — using Alibaba DNS${gl_bai}"
        cat > "$resolv_conf" << 'EOF'
nameserver 223.5.5.5
nameserver 223.6.6.6
nameserver 114.114.114.114
EOF
    else
        echo -e "${gl_huang}Global — using Cloudflare + Google DNS${gl_bai}"
        cat > "$resolv_conf" << 'EOF'
nameserver 1.1.1.1
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF
    fi
    chattr +i "$resolv_conf" 2>/dev/null
    echo -e "${gl_lv}$(get_sys_msg 'dns_ok')${gl_bai}"
    break_end
}

# ============================================================
# Main menu
# ============================================================
sys_menu() {
    while true; do
        clear
        echo -e "${gl_kjlan}$(get_sys_msg 'title')${gl_bai}"
        echo -e "  ${gl_lv}1.${gl_bai} $(get_sys_msg 'opt_1')"
        echo -e "  ${gl_lv}2.${gl_bai} $(get_sys_msg 'opt_2')"
        echo -e "  ${gl_lv}3.${gl_bai} $(get_sys_msg 'opt_3')"
        echo -e "  ${gl_lv}4.${gl_bai} $(get_sys_msg 'opt_4')"
        echo -e "  ${gl_lv}5.${gl_bai} $(get_sys_msg 'opt_5')"
        echo -e "  ${gl_lv}6.${gl_bai} $(get_sys_msg 'opt_6')"
        echo -e "  ${gl_lv}7.${gl_bai} $(get_sys_msg 'opt_7')"
        echo -e "  ${gl_lv}8.${gl_bai} $(get_sys_msg 'opt_8')"
        echo -e "  ${gl_lv}9.${gl_bai} $(get_sys_msg 'opt_9')"
        echo -e "  ${gl_lv}10.${gl_bai} $(get_sys_msg 'opt_10')"
        echo -e "  ${gl_lv}11.${gl_bai} $(get_sys_msg 'opt_11')"
        echo -e "  ${gl_lv}12.${gl_bai} $(get_sys_msg 'opt_12')"
        echo -e "  ${gl_lv}13.${gl_bai} $(get_sys_msg 'opt_13')"
        echo -e "  ${gl_hong}0.${gl_bai} $(get_msg 'back')"
        read -p "Selection: " choice
        case "$choice" in
            1) upd_system; break_end ;;
            2) upd_hostname; break_end ;;
            3) upd_timezone; break_end ;;
            4) read -p "Swap Size in MB: " s_mb && add_swap "$s_mb"; break_end ;;
            5) upd_root_pwd; break_end ;;
            6) toggle_ssh_root; break_end ;;
            7) upd_ssh_port; break_end ;;
            8) upd_locale; break_end ;;
            9) toggle_ipv6; break_end ;;
            10) fail2ban_panel ;;
            11) toggle_compression ;;
            12) performance_mode ;;
            13) optimize_dns ;;
            0) return ;;
            *) echo -e "${gl_hong}$(get_msg 'invalid_selection')${gl_bai}"; sleep 2 ;;
        esac
    done
}

sys_menu

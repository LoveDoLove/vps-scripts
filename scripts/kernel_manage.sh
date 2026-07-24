#!/bin/bash
# scripts/kernel_manage.sh
# Kernel settings and BBR parameters management
# Bilingual (CN / EN)

SCRIPT_PATH=$(dirname "$(readlink -f "$0")")
if [ -f "$SCRIPT_PATH/../lib/common.sh" ]; then
    . "$SCRIPT_PATH/../lib/common.sh"
elif [ -f "/tmp/vps-scripts/lib/common.sh" ]; then
    . "/tmp/vps-scripts/lib/common.sh"
fi

detect_language "$1"
require_root

# Local Messages
get_kernel_msg() {
    local key="$1"
    case "$LANG_ENV" in
        CN)
            case "$key" in
                "title") echo "核心升級與 BBR 加速配置管理器" ;;
                "opt_1") echo "啟用官方最新原生 BBR 擁塞控制演算法" ;;
                "opt_2") echo "停用 BBR / 回滾預設擁塞演算法" ;;
                "opt_3") echo "安裝/升級 XanMod BBRv3 第三方高性能核心 (Debian/Ubuntu Only)" ;;
                "opt_4") echo "安裝/升級 ELRepo 最新主線 Linux 核心 (CentOS/Rocky Only)" ;;
                "bbr_on") echo "BBR 演算法已成功載入並寫入 sysctl." ;;
                "bbr_off") echo "BBR 演算法已停用並還原默認 fq." ;;
                "cur_kernel") echo "當前核心版本: " ;;
                "cur_bbr") echo "當前 BBR 狀態: " ;;
            esac
            ;;
        *) # EN
            case "$key" in
                "title") echo "Kernel Upgrade & BBR Optimization Console" ;;
                "opt_1") echo "Enable Official Stock Google BBR Congestion Control" ;;
                "opt_2") echo "Disable BBR & Fallback to default congestion control" ;;
                "opt_3") echo "Install/Upgrade XanMod V3 Kernel (Debian/Ubuntu Only)" ;;
                "opt_4") echo "Install/Upgrade ELRepo mainline Kernel (CentOS/Rocky Only)" ;;
                "bbr_on") echo "BBR TCP setting resolved & saved to sysctl." ;;
                "bbr_off") echo "BBR TCP setting disabled & rollback default." ;;
                "cur_kernel") echo "Current Kernel version: " ;;
                "cur_bbr") echo "Current BBR Status: " ;;
            esac
            ;;
    esac
}

check_bbr_status() {
    local kernel_ver=$(uname -r)
    echo -e "$(get_kernel_msg 'cur_kernel') ${gl_huang}${kernel_ver}${gl_bai}"

    # Checking active TCP congested algorithm
    local val=$(sysctl net.ipv4.tcp_congestion_control | awk '{print $NF}')
    echo -e "$(get_kernel_msg 'cur_bbr') ${gl_lv}${val}${gl_bai}"
}

enable_stock_bbr() {
    # Verify supports (supported since Kernel >= 4.9)
    local ver=$(uname -r | cut -d'.' -f1-2)
    if (( $(echo "$ver < 4.9" | bc -l 2>/dev/null || echo 0) )); then
        echo "BBR requires Kernel version 4.9 or higher. Please upgrade kernel first."
        return 1
    fi

    # Flush settings to sysctl
    sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf

    echo "net.core.default_qdisc = fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control = bbr" >> /etc/sysctl.conf

    sysctl -p >/dev/null 2>&1
    echo -e "${gl_lv}$(get_kernel_msg 'bbr_on')${gl_bai}"
}

disable_bbr() {
    sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
    sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
    sysctl -p >/dev/null 2>&1
    echo -e "${gl_lv}$(get_kernel_msg 'bbr_off')${gl_bai}"
}

install_xanmod() {
    check_swap
    # Debian/Ubuntu Xanmod kernel installation workflow
    echo -e "${gl_huang}Installing dependencies for XanMod...${gl_bai}"
    install_pkgs gnupg ca-certificates wget

    local os_codename=$(. /etc/os-release && echo "$VERSION_CODENAME")
    if [[ -z "$os_codename" ]]; then
        return 1
    fi

    wget -qO - https://dl.xanmod.org/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes
    echo "deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main" > /etc/apt/sources.list.d/xanmod-release.list

    DEBIAN_FRONTEND=noninteractive apt-get update -y
    # Install standard xanmod core
    DEBIAN_FRONTEND=noninteractive apt-get install -y linux-image-xanmod
    update-grub 2>/dev/null || true

    echo -e "${gl_lv}XanMod Kernel installation finished. Please reboot system to activate.${gl_bai}"
}

install_elrepo() {
    check_swap
    # RedHat family distributions mainline kernels upgrading
    echo "Registering ELRepo GPG credentials..."
    rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
    local dist_ver=$(rpm -q --qf "%{VERSION}" $(rpm -qf /etc/os-release) 2>/dev/null | cut -d'.' -f1)

    if [[ "$dist_ver" == "8" ]]; then
        yum install -y https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm
    elif [[ "$dist_ver" == "9" ]]; then
        yum install -y https://www.elrepo.org/elrepo-release-9.el9.elrepo.noarch.rpm
    else
        echo "Mainline upgrade only supports Enterprise Linux Centos/Rocky/Alma 8 or 9."
        return 1
    fi

    yum --enablerepo=elrepo-kernel install -y kernel-ml
    grub2-mkconfig -o /boot/grub2/grub.cfg 2>/dev/null || true
    echo -e "${gl_lv}ELRepo Kernel setup process ended successfully. Reboot required.${gl_bai}"
}

kernel_menu() {
    while true; do
        clear
        echo -e "${gl_kjlan}========================================================================${gl_bai}"
        echo -e "                 $(get_kernel_msg 'title')                              "
        echo -e "${gl_kjlan}========================================================================${gl_bai}"
        check_bbr_status
        echo -e "${gl_kjlan}------------------------------------------------------------------------${gl_bai}"
        echo -e "  ${gl_lv}1.${gl_bai} $(get_kernel_msg 'opt_1')"
        echo -e "  ${gl_lv}2.${gl_bai} $(get_kernel_msg 'opt_2')"
        echo -e "  ${gl_lv}3.${gl_bai} $(get_kernel_msg 'opt_3')"
        echo -e "  ${gl_lv}4.${gl_bai} $(get_kernel_msg 'opt_4')"
        echo -e "${gl_kjlan}------------------------------------------------------------------------${gl_bai}"
        echo -e "  ${gl_hong}0.${gl_bai} $(get_msg 'press_any_key')"
        echo -e "${gl_kjlan}========================================================================${gl_bai}"

        read -p "Selection: " sub_ch
        case "$sub_ch" in
            1) enable_stock_bbr; break_end ;;
            2) disable_bbr; break_end ;;
            3) install_xanmod; break_end ;;
            4) install_elrepo; break_end ;;
            0) return ;;
            *) echo -e "${gl_hong}$(get_msg 'invalid_selection')${gl_bai}"; sleep 2 ;;
        esac
    done
}

kernel_menu

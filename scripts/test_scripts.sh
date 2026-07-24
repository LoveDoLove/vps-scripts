#!/bin/bash
# scripts/test_scripts.sh
# Network diagnostics, latency, routing traces and VPS benchmark suites
# Bilingual (CN / EN)

SCRIPT_PATH=$(dirname "$(readlink -f "$0")")
if [ -f "$SCRIPT_PATH/../lib/common.sh" ]; then
    . "$SCRIPT_PATH/../lib/common.sh"
elif [ -f "/tmp/vps-scripts/lib/common.sh" ]; then
    . "/tmp/vps-scripts/lib/common.sh"
fi

detect_language "$1"

get_test_msg() {
    local key="$1"
    case "$LANG_ENV" in
        CN)
            case "$key" in
                "title") echo "伺服器基本效能測試與網絡路由診斷工具箱" ;;
                "opt_1") echo "執行 VPS 融合硬體怪獸性能跑分 (superbench/yabs)" ;;
                "opt_2") echo "執行 Speedtest.net 國內與國際帶寬測速" ;;
                "opt_3") echo "檢查流媒體解鎖權限狀態 (IP Quality / Media Unlock)" ;;
                "opt_4") echo "安裝並執行 NextTrace 炫酷可視化回程路由追蹤" ;;
                "opt_5") echo "執行磁碟硬碟 I/O 讀寫性能評測" ;;
            esac
            ;;
        *) # EN
            case "$key" in
                "title") echo "Server Benchmark Suite & Network Diagnostics Toolkit" ;;
                "opt_1") echo "Run Visual System Benchmark (YABS / Superbench)" ;;
                "opt_2") echo "Run Network bandwidth speed test (Speedtest)" ;;
                "opt_3") echo "Perform Streaming Media Unlock diagnostics" ;;
                "opt_4") echo "Install & Run NextTrace 3D Routing logs" ;;
                "opt_5") echo "Run Disk Drive Storage I/O read-write tests" ;;
            esac
            ;;
    esac
}

run_yabs() {
    echo -e "${gl_huang}Launching Yet Another Benchmark Script (YABS)...${gl_bai}"
    curl -sL yabs.sh | bash
}

run_speedtest() {
    echo -e "${gl_huang}Running Speedtest benchmarking process...${gl_bai}"
    # Standard curl speedtest script
    bash <(curl -sL bash.icu/speedtest)
}

run_media_test() {
    echo -e "${gl_huang}Checking Netflix/Disney/OpenAI unlock configurations...${gl_bai}"
    bash <(curl -sL https://github.com/sjlleo/netflix-verify/releases/latest/download/nf_linux_amd64) 2>/dev/null || \
    bash <(curl -L -s https://raw.githubusercontent.com/loki51/RegionRestrictionCheck/main/check.sh)
}

run_nexttrace() {
    if ! command -v nexttrace &>/dev/null; then
        echo -e "${gl_huang}Installing NextTrace utility components...${gl_bai}"
        curl -sSL https://raw.githubusercontent.com/nxtrace/NTrace-core/main/n_install.sh | bash
    fi
    read -p "Enter Target IP address to trace back: " dst_ip
    dst_ip=${dst_ip:-"8.8.8.8"}
    nexttrace "$dst_ip"
}

run_disk_test() {
    echo -e "${gl_huang}Starting local disk write profile check...${gl_bai}"
    dd if=/dev/zero of=test_file bs=1M count=1024 conv=fdatasync oflag=direct 2>&1
    rm -f test_file
}

test_menu() {
    while true; do
        clear
        echo -e "${gl_kjlan}========================================================================${gl_bai}"
        echo -e "                 $(get_test_msg 'title')                                "
        echo -e "${gl_kjlan}========================================================================${gl_bai}"
        echo -e "  ${gl_lv}1.${gl_bai} $(get_test_msg 'opt_1')"
        echo -e "  ${gl_lv}2.${gl_bai} $(get_test_msg 'opt_2')"
        echo -e "  ${gl_lv}3.${gl_bai} $(get_test_msg 'opt_3')"
        echo -e "  ${gl_lv}4.${gl_bai} $(get_test_msg 'opt_4')"
        echo -e "  ${gl_lv}5.${gl_bai} $(get_test_msg 'opt_5')"
        echo -e "${gl_kjlan}------------------------------------------------------------------------${gl_bai}"
        echo -e "  ${gl_hong}0.${gl_bai} $(get_msg 'press_any_key')"
        echo -e "${gl_kjlan}========================================================================${gl_bai}"

        read -p "Selection: " sub_ch
        case "$sub_ch" in
            1) run_yabs; break_end ;;
            2) run_speedtest; break_end ;;
            3) run_media_test; break_end ;;
            4) run_nexttrace; break_end ;;
            5) run_disk_test; break_end ;;
            0) return ;;
            *) echo -e "${gl_hong}$(get_msg 'invalid_selection')${gl_bai}"; sleep 2 ;;
        esac
    done
}

test_menu

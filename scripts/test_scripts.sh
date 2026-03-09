#!/bin/bash
# scripts/test_scripts.sh
# Test Script Collection - Network speed tests, benchmarks, and diagnostics
# Author: LoveDoLove

# Color definitions
gl_hong='\033[31m'
gl_lv='\033[32m'
gl_huang='\033[33m'
gl_lan='\033[34m'
gl_kjlan='\033[96m'
gl_bai='\033[0m'
gl_bold='\033[1m'

# Helper: check for curl or wget
check_download_tool() {
    if command -v curl &>/dev/null; then
        echo "curl"
    elif command -v wget &>/dev/null; then
        echo "wget"
    else
        echo ""
    fi
}

# Run a remote script via curl or wget
run_remote_script() {
    local url="$1"
    local tool
    tool=$(check_download_tool)

    if [ "$tool" = "curl" ]; then
        bash <(curl -fsSL "$url")
    elif [ "$tool" = "wget" ]; then
        bash <(wget -qO- "$url")
    else
        echo -e "${gl_hong}Neither curl nor wget is available.${gl_bai}"
        return 1
    fi
}

# Bench.sh - Classic VPS benchmark
run_bench() {
    echo -e "${gl_huang}Running Bench.sh (VPS benchmark)...${gl_bai}"
    echo -e "${gl_lan}This test includes CPU, memory, disk I/O, and network speed.${gl_bai}"
    run_remote_script "https://bench.sh"
}

# Speedtest by Ookla
run_speedtest() {
    echo -e "${gl_huang}Running Speedtest...${gl_bai}"

    if command -v speedtest &>/dev/null; then
        speedtest
    elif command -v speedtest-cli &>/dev/null; then
        speedtest-cli
    else
        echo -e "${gl_huang}Speedtest not found. Installing...${gl_bai}"
        if command -v apt &>/dev/null; then
            apt install -y speedtest-cli 2>/dev/null && speedtest-cli
        elif command -v dnf &>/dev/null; then
            dnf install -y speedtest-cli 2>/dev/null && speedtest-cli
        elif command -v yum &>/dev/null; then
            yum install -y speedtest-cli 2>/dev/null && speedtest-cli
        else
            echo -e "${gl_huang}Trying Python pip install...${gl_bai}"
            pip3 install speedtest-cli 2>/dev/null && speedtest-cli
        fi
    fi
}

# YABS - Yet Another Bench Script
run_yabs() {
    echo -e "${gl_huang}Running YABS (Yet Another Bench Script)...${gl_bai}"
    echo -e "${gl_lan}Comprehensive benchmark including Geekbench, fio, and iperf3.${gl_bai}"
    run_remote_script "https://yabs.sh"
}

# IP Quality Test
run_ip_quality() {
    echo -e "${gl_huang}Running IP Quality Test...${gl_bai}"
    run_remote_script "https://bash.spiritlhl.net/ecs"
}

# Backtrace / Route tracing
run_backtrace() {
    echo -e "${gl_huang}Running Backtrace (Route tracing)...${gl_bai}"
    run_remote_script "https://raw.githubusercontent.com/zhucaidan/mtr_trace/main/mtr_trace.sh"
}

# NextTrace route tracing
run_nexttrace() {
    echo -e "${gl_huang}Running NextTrace route tracing...${gl_bai}"

    if ! command -v nexttrace &>/dev/null; then
        echo -e "${gl_huang}Installing NextTrace...${gl_bai}"
        local tool
        tool=$(check_download_tool)
        if [ "$tool" = "curl" ]; then
            bash <(curl -fsSL https://raw.githubusercontent.com/nxtrace/NTrace-core/main/nt_install.sh)
        elif [ "$tool" = "wget" ]; then
            bash <(wget -qO- https://raw.githubusercontent.com/nxtrace/NTrace-core/main/nt_install.sh)
        fi
    fi

    if command -v nexttrace &>/dev/null; then
        echo -e "${gl_lan}Tracing to common endpoints...${gl_bai}"
        read -p "Enter target IP or domain (default: 8.8.8.8): " target
        target="${target:-8.8.8.8}"
        nexttrace "$target"
    else
        echo -e "${gl_hong}NextTrace installation failed.${gl_bai}"
    fi
}

# Disk I/O test
run_disk_test() {
    echo -e "${gl_huang}Running Disk I/O Test...${gl_bai}"

    echo -e "${gl_lan}Testing write speed...${gl_bai}"
    dd if=/dev/zero of=/tmp/disk_test bs=1M count=1024 conv=fdatasync 2>&1 | tail -1
    rm -f /tmp/disk_test

    echo -e "${gl_lan}Testing read speed...${gl_bai}"
    dd if=/dev/zero of=/tmp/disk_test bs=1M count=1024 2>/dev/null
    dd if=/tmp/disk_test of=/dev/null bs=1M count=1024 2>&1 | tail -1
    rm -f /tmp/disk_test

    echo -e "${gl_lv}Disk I/O test complete.${gl_bai}"
}

# UnixBench
run_unixbench() {
    echo -e "${gl_huang}Running UnixBench...${gl_bai}"
    echo -e "${gl_lan}This is a comprehensive system benchmark and may take 30+ minutes.${gl_bai}"
    run_remote_script "https://raw.githubusercontent.com/teddysun/across/master/unixbench.sh"
}

# Three-network speed test (China)
run_three_network_test() {
    echo -e "${gl_huang}Running Three-Network Speed Test (China Telecom/Unicom/Mobile)...${gl_bai}"
    run_remote_script "https://raw.githubusercontent.com/zhanghanyun/backtrace/main/install.sh"
}

# Main menu
test_scripts_menu() {
    while true; do
        echo ""
        echo -e "${gl_bold}${gl_kjlan}============ Test Script Collection ============${gl_bai}"
        echo -e "${gl_kjlan}  --- Network Speed Tests ---${gl_bai}"
        echo -e "  ${gl_lv}1.${gl_bai} Bench.sh (VPS Benchmark)"
        echo -e "  ${gl_lv}2.${gl_bai} Speedtest (Ookla)"
        echo -e "  ${gl_lv}3.${gl_bai} Three-Network Speed Test (CN)"
        echo -e "${gl_kjlan}  --- System Benchmarks ---${gl_bai}"
        echo -e "  ${gl_lv}4.${gl_bai} YABS (Yet Another Bench Script)"
        echo -e "  ${gl_lv}5.${gl_bai} UnixBench"
        echo -e "  ${gl_lv}6.${gl_bai} Disk I/O Test"
        echo -e "${gl_kjlan}  --- Network Diagnostics ---${gl_bai}"
        echo -e "  ${gl_lv}7.${gl_bai} IP Quality Test"
        echo -e "  ${gl_lv}8.${gl_bai} Backtrace (Route Tracing)"
        echo -e "  ${gl_lv}9.${gl_bai} NextTrace (Route Tracing)"
        echo ""
        echo -e "  ${gl_hong}0.${gl_bai} Return to Main Menu"
        echo -e "${gl_kjlan}=================================================${gl_bai}"
        read -p "Please enter your choice: " choice

        case $choice in
            1) run_bench ;;
            2) run_speedtest ;;
            3) run_three_network_test ;;
            4) run_yabs ;;
            5) run_unixbench ;;
            6) run_disk_test ;;
            7) run_ip_quality ;;
            8) run_backtrace ;;
            9) run_nexttrace ;;
            0) return ;;
            *) echo -e "${gl_hong}Invalid option!${gl_bai}" ;;
        esac

        echo ""
        echo -e "${gl_huang}Press any key to continue...${gl_bai}"
        read -n 1 -s
        clear
    done
}

test_scripts_menu

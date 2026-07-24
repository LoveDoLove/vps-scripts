#!/bin/bash
# scripts/system_info.sh
# Display system key configurations and environment variables dashboard
# Bilingual (CN / EN)

SCRIPT_PATH=$(dirname "$(readlink -f "$0")")
if [ -f "$SCRIPT_PATH/../lib/common.sh" ]; then
    . "$SCRIPT_PATH/../lib/common.sh"
elif [ -f "/tmp/vps-scripts/lib/common.sh" ]; then
    . "/tmp/vps-scripts/lib/common.sh"
fi

detect_language "$1"

# Network configs
ipv4_address=$(curl -s --max-time 3 https://ipinfo.io/ip 2>/dev/null)
ipv6_address=$(curl -s --max-time 1 https://v6.ipinfo.io/ip 2>/dev/null)
ipinfo=$(curl -s --max-time 3 ipinfo.io 2>/dev/null)

country=$(echo "$ipinfo" | grep 'country' | awk -F': ' '{print $2}' | tr -d '",')
city=$(echo "$ipinfo" | grep 'city' | awk -F': ' '{print $2}' | tr -d '",')
isp_info=$(echo "$ipinfo" | grep 'org' | awk -F': ' '{print $2}' | tr -d '",')
dns_addresses=$(awk '/^nameserver/{printf "%s ", $2} END {print ""}' /etc/resolv.conf)

# Host specs
hostname=$(uname -n)
os_info=$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d '=' -f2 | tr -d '"')
kernel_version=$(uname -r)
cpu_arch=$(uname -m)

# Hardware components
cpu_info=$(lscpu 2>/dev/null | awk -F': +' '/Model name:/ {print $2; exit}' || grep "model name" /proc/cpuinfo 2>/dev/null | head -n1 | awk -F': ' '{print $2}')
cpu_cores=$(nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo 2>/dev/null || echo "1")
cpu_usage_percent=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* *id.*/\1/" | awk '{print 100 - $1}')

# Memory information
mem_info=$(free -m 2>/dev/null | awk 'NR==2{printf "%dM/%dM (%.2f%%)", $3, $2, $3*100/$2}')
swap_info=$(free -m 2>/dev/null | awk 'NR==3{used=$3; total=$2; if (total == 0) {percentage=0} else {percentage=used*100/total}; printf "%dM/%dM (%d%%)", used, total, percentage}')
disk_info=$(df -h 2>/dev/null | awk '$NF=="/"{printf "%s/%s (%s)", $3, $2, $5}')

congestion_algorithm=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)
queue_algorithm=$(sysctl -n net.core.default_qdisc 2>/dev/null)

current_time=$(date "+%Y-%m-%d %I:%M %p")
timezone=$(date +"%Z")

# Calculate system uptime bilingual version
calculate_uptime() {
    local raw_uptime=$(cat /proc/uptime 2>/dev/null | awk '{print int($1)}')
    if [ -z "$raw_uptime" ]; then
        echo "N/A"
        return
    fi
    local days=$((raw_uptime / 86400))
    local hours=$(( (raw_uptime % 86400) / 3600 ))
    local minutes=$(( (raw_uptime % 3600) / 60 ))

    if [[ "$LANG_ENV" == "CN" ]]; then
        echo "${days}天 ${hours}小時 ${minutes}分鐘"
    else
        echo "${days} days, ${hours} hours, ${minutes} minutes"
    fi
}

# Output dashboard
clear
echo -e "${gl_kjlan}========================================================================${gl_bai}"
if [[ "$LANG_ENV" == "CN" ]]; then
    echo -e "                   伺服器系統運維資訊大屏監控面板"
else
    echo -e "                 Server Executive System Health Monitor"
fi
echo -e "${gl_kjlan}========================================================================${gl_bai}"
echo "Hostname:       $hostname"
echo "OS Version:     $os_info"
echo "Linux Kernel:   $kernel_version"
echo "Architecture:   $cpu_arch"
echo "--------------------------------------------------------"
echo "CPU Model:      $cpu_info"
echo "CPU Cores:      $cpu_cores Cores"
echo "CPU Usage:      ${cpu_usage_percent:-0}%"
echo "Memory Info:    $mem_info"
echo "Swap Space:     $swap_info"
echo "Disk Space:     $disk_info"
echo "Network Alg:    $congestion_algorithm (Default Queue: $queue_algorithm)"
echo "--------------------------------------------------------"
echo "ISP Provider:   $isp_info"
echo "Public IPv4:    ${ipv4_address:-N/A}"
if [[ -n "$ipv6_address" && ! "$ipv6_address" =~ \{ ]]; then
    echo "Public IPv6:    $ipv6_address"
fi
echo "DNS Servers:    $dns_addresses"
echo "Geolocation:    $country $city"
echo "System Time:    $current_time ($timezone)"
echo "Uptime Watch:   $(calculate_uptime)"
echo -e "${gl_kjlan}========================================================================${gl_bai}"
break_end

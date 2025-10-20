#!/bin/bash
# scripts/system_info.sh
# Display system information overview
# Author: LoveDoLove
# Date: 2025-10-20

clear

# =================== System Information Variables ===================
# Network (IP, ISP, Location)
ipv4_address=$(curl -s https://ipinfo.io/ip 2>/dev/null)
ipv6_address=$(curl -s https://v6.ipinfo.io 2>/dev/null)
ipinfo=$(curl -s ipinfo.io 2>/dev/null)
country=$(echo "$ipinfo" | grep 'country' | awk -F': ' '{print $2}' | tr -d '",')
city=$(echo "$ipinfo" | grep 'city' | awk -F': ' '{print $2}' | tr -d '",')
isp_info=$(echo "$ipinfo" | grep 'org' | awk -F': ' '{print $2}' | tr -d '",')
dns_addresses=$(awk '/^nameserver/{printf "%s ", $2} END {print ""}' /etc/resolv.conf)

# Host and OS
hostname=$(uname -n)
os_info=$(grep PRETTY_NAME /etc/os-release 2>/dev/null | cut -d '=' -f2 | tr -d '"')
kernel_version=$(uname -r)
cpu_arch=$(uname -m)

# CPU
cpu_info=$(lscpu 2>/dev/null | awk -F': +' '/Model name:/ {print $2; exit}')
cpu_cores=$(nproc 2>/dev/null)
cpu_freq=$(cat /proc/cpuinfo 2>/dev/null | grep "MHz" | head -n 1 | awk '{printf "%.1f GHz\n", $4/1000}')
cpu_usage_percent=$(awk '{u=$2+$4; t=$2+$4+$5; if (NR==1){u1=u; t1=t;} else printf "%.0f\n", (($2+$4-u1) * 100 / (t-t1))}' <(grep 'cpu ' /proc/stat) <(sleep 1; grep 'cpu ' /proc/stat))

# Memory and Disk
mem_info=$(free -b 2>/dev/null | awk 'NR==2{printf "%.2f/%.2fM (%.2f%%)", $3/1024/1024, $2/1024/1024, $3*100/$2}')
swap_info=$(free -m 2>/dev/null | awk 'NR==3{used=$3; total=$2; if (total == 0) {percentage=0} else {percentage=used*100/total}; printf "%dM/%dM (%d%%)", used, total, percentage}')
disk_info=$(df -h 2>/dev/null | awk '$NF=="/"{printf "%s/%s (%s)", $3, $2, $5}')

# Network Algorithms
congestion_algorithm=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)
queue_algorithm=$(sysctl -n net.core.default_qdisc 2>/dev/null)

# System Time and Uptime
current_time=$(date "+%Y-%m-%d %I:%M %p")
timezone=$(date +"%Z %z")
runtime=$(cat /proc/uptime 2>/dev/null | awk -F. '{run_days=int($1 / 86400);run_hours=int(($1 % 86400) / 3600);run_minutes=int(($1 % 3600) / 60); if (run_days > 0) printf("%d天 ", run_days); if (run_hours > 0) printf("%d时 ", run_hours); printf("%d分\n", run_minutes)}')

# System Load
load=$(uptime 2>/dev/null | awk '{print $(NF-2), $(NF-1), $NF}')

echo ""
echo "================ System Information Overview ================"
echo "Hostname:       $hostname"
echo "OS Version:     $os_info"
echo "Linux Kernel:   $kernel_version"
echo "---------------------------------------------"
echo "CPU Arch:       $cpu_arch"
echo "CPU Model:      $cpu_info"
echo "CPU Cores:      $cpu_cores"
echo "CPU Frequency:  $cpu_freq"
echo "---------------------------------------------"
echo "CPU Usage:      $cpu_usage_percent%"
echo "System Load:    $load"
echo "Memory:         $mem_info"
echo "Swap:           $swap_info"
echo "Disk Usage:     $disk_info"
echo "---------------------------------------------"
echo "Network Algo:   $congestion_algorithm $queue_algorithm"
echo "---------------------------------------------"
echo "ISP:            $isp_info"
if [ -n "$ipv4_address" ]; then
    echo "IPv4 Address:   $ipv4_address"
fi
if [[ -n "$ipv6_address" && ! "$ipv6_address" =~ \{ ]]; then
    echo "IPv6 Address:   $ipv6_address"
else
    echo "IPv6 Address:   N/A"
fi
echo "DNS:            $dns_addresses"
echo "Location:       $country $city"
echo "System Time:    $timezone $current_time"
echo "---------------------------------------------"
echo "Uptime:         $runtime"
echo "============================================================="

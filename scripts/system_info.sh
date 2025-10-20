#!/bin/bash
# scripts/system_info.sh
# Display system information overview
# Author: LoveDoLove
# Date: 2025-10-20

# Print hostname and OS info
echo "================ System Information Overview ================"
echo "Hostname: $(hostname)"
echo "OS: $(uname -a)"
echo
# Print CPU info
echo "---------------- CPU Info ----------------"
lscpu | grep 'Model name\|CPU(s):\|Thread(s) per core' || cat /proc/cpuinfo | grep 'model name\|processor' | uniq
# Print Memory info
echo
free -h
# Print Disk info
echo
lsblk
# Print Network info
echo
ip addr show | grep 'inet '
echo "============================================================="

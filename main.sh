#!/bin/bash
# VPS Scripts - Main Menu
# A comprehensive VPS management toolkit
# Repository: https://github.com/LoveDoLove/vps-scripts

# Set your GitHub repository raw base URL for script downloads
GITHUB_RAW_BASE="https://raw.githubusercontent.com/LoveDoLove/vps-scripts/main/scripts"

# Color definitions
gl_hong='\033[31m'
gl_lv='\033[32m'
gl_huang='\033[33m'
gl_lan='\033[34m'
gl_zi='\033[35m'
gl_kjlan='\033[96m'
gl_bai='\033[0m'
gl_bold='\033[1m'

clear

# Function: Download and run a script
run_script() {
    local script_name="$1"
    local script_dir
    script_dir="$(cd "$(dirname "$0")" && pwd)/scripts"
    local script_path="$script_dir/$script_name"
    local github_raw_url="$GITHUB_RAW_BASE/$script_name"

    clear

    # Auto-download the script if not present
    if [ ! -f "$script_path" ]; then
        echo -e "${gl_huang}[Info] $script_name not found. Downloading from GitHub...${gl_bai}"
        mkdir -p "$script_dir"
        if command -v curl >/dev/null 2>&1; then
            curl -fsSL "$github_raw_url" -o "$script_path"
        elif command -v wget >/dev/null 2>&1; then
            wget -q "$github_raw_url" -O "$script_path"
        else
            echo -e "${gl_hong}Neither curl nor wget is available. Please install one to proceed.${gl_bai}"
            return
        fi
        chmod +x "$script_path"
    fi

    if [ -f "$script_path" ]; then
        bash "$script_path"
    else
        echo -e "${gl_hong}Failed to download $script_name from GitHub.${gl_bai}"
    fi
}

# Function: Display the main menu
main_menu() {
    echo -e "${gl_bold}${gl_kjlan}"
    echo "==========================================================="
    echo "                  VPS Scripts Main Menu                     "
    echo "==========================================================="
    echo -e "${gl_bai}"
    echo -e "  ${gl_lv}1.${gl_bai}   系 统 信 息 查 询"
    echo -e "  ${gl_lv}2.${gl_bai}   系 统 更 新"
    echo -e "  ${gl_lv}3.${gl_bai}   系 统 清 理"
    echo -e "  ${gl_lv}4.${gl_bai}   基 础 工 具"
    echo -e "  ${gl_lv}5.${gl_bai}   BBR 管 理"
    echo -e "  ${gl_lv}6.${gl_bai}   Docker 管 理"
    echo -e "  ${gl_lv}7.${gl_bai}   WARP 管 理"
    echo -e "  ${gl_lv}8.${gl_bai}   测 试 脚 本 合 集"
    echo -e "  ${gl_lv}9.${gl_bai}   甲 骨 文 云 脚 本 合 集"
    echo -e "  ${gl_lv}10.${gl_bai}  系 统 工 具"
    echo ""
    echo -e "  ${gl_hong}0.${gl_bai}   Exit"
    echo -e "${gl_kjlan}-----------------------------------------------------------${gl_bai}"
}

# Function: Handle user selection
handle_selection() {
    case $1 in
        1) run_script "system_info.sh" ;;
        2) run_script "system_update.sh" ;;
        3) run_script "system_clean.sh" ;;
        4) run_script "basic_tools.sh" ;;
        5) run_script "bbr_manage.sh" ;;
        6) run_script "docker_manage.sh" ;;
        7) run_script "warp_manage.sh" ;;
        8) run_script "test_scripts.sh" ;;
        9) run_script "oracle_cloud.sh" ;;
        10) run_script "system_tools.sh" ;;
        0)
            echo -e "${gl_lv}Exiting...${gl_bai}"
            exit 0
        ;;
        *)
            echo -e "${gl_hong}Invalid selection! Please enter a valid option.${gl_bai}"
        ;;
    esac
    echo ""
    echo -e "${gl_huang}Press any key to return to the main menu...${gl_bai}"
    read -n 1 -s
}

# Main loop
while true; do
    main_menu
    read -p "Please enter your choice [0-10]: " choice
    handle_selection "$choice"
    clear
done

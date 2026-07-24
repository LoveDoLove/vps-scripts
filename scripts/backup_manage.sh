#!/bin/bash
# scripts/backup_manage.sh
# Backup management and system cleaning module
# Bilingual (CN / EN)

SCRIPT_PATH=$(dirname "$(readlink -f "$0")")
if [ -f "$SCRIPT_PATH/../lib/common.sh" ]; then
    . "$SCRIPT_PATH/../lib/common.sh"
elif [ -f "/tmp/vps-scripts/lib/common.sh" ]; then
    . "/tmp/vps-scripts/lib/common.sh"
fi

detect_language "$1"
require_root
install_pkgs tar rsync cron

get_backup_msg() {
    local key="$1"
    case "$LANG_ENV" in
        CN)
            case "$key" in
                "title") echo "備份還原、系統清理與定時排程定時器面板" ;;
                "opt_1") echo "一鍵備份 LDNMP 整個網頁和資料庫目錄數據 (/home/web)" ;;
                "opt_2") echo "從現有備份檔案中還原站點資料" ;;
                "opt_3") echo "清理系統日誌、包管理器快取與臨時垃圾空間" ;;
                "opt_4") echo "管理 Crontab 自定義定時任務排程" ;;
                "backup_done") echo "備份作業完成！存檔路徑: " ;;
                "restore_done") echo "還原作業成功完成。" ;;
                "clean_done") echo "服務器垃圾清理完畢。" ;;
                "enter_file") echo "請輸入備份檔案之絕對路徑: " ;;
            esac
            ;;
        *) # EN
            case "$key" in
                "title") echo "Backup, Cleanup & Cron Automation Console" ;;
                "opt_1") echo "One-click Backup all LDNMP web directory (/home/web)" ;;
                "opt_2") echo "Restore domains data from an existing Tarball" ;;
                "opt_3") echo "Clean System Logs, packages metadata caches & /tmp folders" ;;
                "opt_4") echo "Configure & Edit Crontab scheduler rules" ;;
                "backup_done") echo "Backup completed! Packed file path: " ;;
                "restore_done") echo "Restore action performed successfully." ;;
                "clean_done") echo "System cleanliness routines finished." ;;
                "enter_file") echo "Please enter absolute path to the backup tarball: " ;;
            esac
            ;;
    esac
}

backup_web() {
    if [ ! -d /home/web ]; then
        echo "No /home/web directory detected to back up."
        return
    fi
    local stamp=$(date +%Y%m%d_%H%M%S)
    local dest_file="/home/web_backup_${stamp}.tar.gz"
    echo -e "${gl_huang}Packaging /home/web workspace...${gl_bai}"
    tar -czf "$dest_file" -C /home web
    echo -e "${gl_lv}$(get_backup_msg 'backup_done') ${dest_file}${gl_bai}"
}

restore_web() {
    read -p "$(get_backup_msg 'enter_file')" tar_file
    if [[ -f "$tar_file" ]]; then
        echo -e "${gl_huang}Restoring directory to /home/web...${gl_bai}"
        tar -xzf "$tar_file" -C /home
        if command -v docker &>/dev/null && [ -f /home/web/docker-compose.yml ]; then
            cd /home/web && docker compose down 2>/dev/null
            docker compose up -d
        fi
        echo -e "${gl_lv}$(get_backup_msg 'restore_done')${gl_bai}"
    else
        echo "File not found!"
    fi
}

clean_system() {
    echo -e "${gl_huang}Cleaning software caches...${gl_bai}"
    local pm=$(detect_pm)
    case "$pm" in
        apt)
            apt-get clean
            apt-get autoremove -y
            ;;
        dnf|yum)
            dnf clean all 2>/dev/null || yum clean all
            ;;
        apk)
            apk cache clean 2>/dev/null
            ;;
    esac

    # Clear logs
    rm -rf /var/log/*.log /var/log/syslog* /var/log/auth.log* 2>/dev/null
    find /var/log -type f -exec truncate -s 0 {} \;
    rm -rf /tmp/*

    echo -e "${gl_lv}$(get_backup_msg 'clean_done')${gl_bai}"
}

edit_cron() {
    # Open visual system editor for crontab
    if command -v nano &>/dev/null; then
        export EDITOR=nano
    elif command -v vi &>/dev/null; then
        export EDITOR=vi
    fi
    crontab -e
}

backup_menu() {
    while true; do
        clear
        echo -e "${gl_kjlan}========================================================================${gl_bai}"
        echo -e "                 $(get_backup_msg 'title')                              "
        echo -e "${gl_kjlan}========================================================================${gl_bai}"
        echo -e "  ${gl_lv}1.${gl_bai} $(get_backup_msg 'opt_1')"
        echo -e "  ${gl_lv}2.${gl_bai} $(get_backup_msg 'opt_2')"
        echo -e "  ${gl_lv}3.${gl_bai} $(get_backup_msg 'opt_3')"
        echo -e "  ${gl_lv}4.${gl_bai} $(get_backup_msg 'opt_4')"
        echo -e "${gl_kjlan}------------------------------------------------------------------------${gl_bai}"
        echo -e "  ${gl_hong}0.${gl_bai} $(get_msg 'press_any_key')"
        echo -e "${gl_kjlan}========================================================================${gl_bai}"

        read -p "Selection: " sub_ch
        case "$sub_ch" in
            1) backup_web; break_end ;;
            2) restore_web; break_end ;;
            3) clean_system; break_end ;;
            4) edit_cron; break_end ;;
            0) return ;;
            *) echo -e "${gl_hong}$(get_msg 'invalid_selection')${gl_bai}"; sleep 2 ;;
        esac
    done
}

backup_menu

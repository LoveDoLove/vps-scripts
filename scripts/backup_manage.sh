#!/bin/bash
# scripts/backup_manage.sh
# Backup management, system cleaning, and cron scheduling module
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
                "title") echo "備份管理與定時任務控制台" ;;
                "opt_1") echo "備份網站及數據庫" ;;
                "opt_2") echo "還原網站及數據庫" ;;
                "opt_3") echo "清理系統緩存與日誌" ;;
                "opt_4") echo "編輯定時任務 (Crontab)" ;;
                "opt_5") echo "定時任務模板 (一鍵配置)" ;;
                "backup_done") echo "備份完成。" ;;
                "restore_done") echo "還原完成。" ;;
                "clean_done") echo "系統清理完成。" ;;
                "cron_daily") echo "已添加每日備份任務。" ;;
                "cron_weekly") echo "已添加每週清理任務。" ;;
                "cron_hourly") echo "已添加每小時健康檢查任務。" ;;
                "enter_path") echo "請輸入備份路徑: " ;;
                "enter_dest") echo "請輸入目標路徑: " ;;
            esac
            ;;
        *)
            case "$key" in
                "title") echo "Backup & Cron Management Console" ;;
                "opt_1") echo "Backup websites & databases" ;;
                "opt_2") echo "Restore websites & databases" ;;
                "opt_3") echo "Clean system caches & logs" ;;
                "opt_4") echo "Edit crontab" ;;
                "opt_5") echo "Cron job templates (one-click)" ;;
                "backup_done") echo "Backup completed." ;;
                "restore_done") echo "Restore completed." ;;
                "clean_done") echo "System cleanup completed." ;;
                "cron_daily") echo "Daily backup cron added." ;;
                "cron_weekly") echo "Weekly cleanup cron added." ;;
                "cron_hourly") echo "Hourly health check cron added." ;;
                "enter_path") echo "Enter backup path: " ;;
                "enter_dest") echo "Enter destination path: " ;;
            esac
            ;;
    esac
}

# ============================================================
# Backup function
# ============================================================
backup_web() {
    read -p "$(get_backup_msg 'enter_path'): " bk_path
    read -p "$(get_backup_msg 'enter_dest'): " bk_dest
    [ -z "$bk_path" ] && bk_path="/home/web"
    [ -z "$bk_dest" ] && bk_dest="/root/backup"
    mkdir -p "$bk_dest"
    local ts=$(date +%Y%m%d_%H%M%S)
    tar -czf "${bk_dest}/backup_${ts}.tar.gz" "$bk_path"
    if command -v rsync &>/dev/null && [[ "$bk_dest" == *":"* ]]; then
        rsync -avz "${bk_dest}/backup_${ts}.tar.gz" "$bk_dest"
    fi
    echo -e "${gl_lv}$(get_backup_msg 'backup_done')${gl_bai}"
}

# ============================================================
# Restore function
# ============================================================
restore_web() {
    read -p "$(get_backup_msg 'enter_path'): " rs_path
    [ -z "$rs_path" ] && rs_path="/root/backup"
    echo -e "${gl_kjlan}Available backups:${gl_bai}"
    ls -1 "$rs_path"/*.tar.gz 2>/dev/null | head -10
    read -p "Enter backup filename: " rs_file
    [ -f "$rs_path/$rs_file" ] && tar -xzf "$rs_path/$rs_file" -C / || echo -e "${gl_hong}File not found.${gl_bai}"
    echo -e "${gl_lv}$(get_backup_msg 'restore_done')${gl_bai}"
}

# ============================================================
# System cleanup
# ============================================================
clean_system() {
    # Clean package manager caches
    if command -v apt &>/dev/null; then
        apt clean -y && apt autoremove -y
    elif command -v dnf &>/dev/null; then
        dnf clean all
    elif command -v yum &>/dev/null; then
        yum clean all
    elif command -v apk &>/dev/null; then
        apk cache clean
    fi
    # Clean logs older than 7 days
    find /var/log -name "*.log" -mtime +7 -exec rm -f {} \; 2>/dev/null
    find /var/log -name "*.gz" -mtime +7 -exec rm -f {} \; 2>/dev/null
    # Clean Docker leftovers
    if command -v docker &>/dev/null; then
        docker system prune -af --volumes 2>/dev/null
    fi
    # Clean journal logs older than 3 days
    if command -v journalctl &>/dev/null; then
        journalctl --vacuum-time=3d 2>/dev/null
    fi
    echo -e "${gl_lv}$(get_backup_msg 'clean_done')${gl_bai}"
}

# ============================================================
# Manual crontab edit
# ============================================================
edit_cron() {
    crontab -e 2>/dev/null || {
        echo -e "${gl_huang}No default editor found. Using vi.${gl_bai}"
        EDITOR=vi crontab -e
    }
}

# ============================================================
# NEW: Cron template panel
# ============================================================
cron_templates() {
    while true; do
        clear
        echo -e "${gl_kjlan}$(get_backup_msg 'opt_5')${gl_bai}"
        echo -e "  ${gl_lv}1.${gl_bai} $(get_backup_msg 'cron_daily')"
        echo -e "  ${gl_lv}2.${gl_bai} $(get_backup_msg 'cron_weekly')"
        echo -e "  ${gl_lv}3.${gl_bai} $(get_backup_msg 'cron_hourly')"
        echo -e "  ${gl_lv}4.${gl_bai} View current crontab"
        echo -e "  ${gl_lv}5.${gl_bai} Clear all my cron templates"
        echo -e "  ${gl_hong}0.${gl_bai} $(get_msg 'back')"
        read -p "Selection: " ct_ch
        case "$ct_ch" in
            1)
                (crontab -l 2>/dev/null; echo "0 3 * * * /root/backup_script.sh") | crontab -
                echo -e "${gl_lv}$(get_backup_msg 'cron_daily')${gl_bai}"
                break_end
                ;;
            2)
                (crontab -l 2>/dev/null; echo "0 4 * * 0 /root/cleanup_script.sh") | crontab -
                echo -e "${gl_lv}$(get_backup_msg 'cron_weekly')${gl_bai}"
                break_end
                ;;
            3)
                (crontab -l 2>/dev/null; echo "0 * * * * /root/health_check.sh") | crontab -
                echo -e "${gl_lv}$(get_backup_msg 'cron_hourly')${gl_bai}"
                break_end
                ;;
            4)
                crontab -l 2>/dev/null || echo "No crontab configured."
                break_end
                ;;
            5)
                crontab -r 2>/dev/null && echo -e "${gl_lv}Crontab cleared.${gl_bai}" || echo -e "${gl_hong}No crontab.${gl_bai}"
                break_end
                ;;
            0) return ;;
            *) echo -e "${gl_hong}$(get_msg 'invalid_selection')${gl_bai}"; sleep 2 ;;
        esac
    done
}

# ============================================================
# Main menu
# ============================================================
backup_menu() {
    while true; do
        clear
        echo -e "${gl_kjlan}$(get_backup_msg 'title')${gl_bai}"
        echo -e ""
        echo -e "  ${gl_lv}1.${gl_bai} $(get_backup_msg 'opt_1')"
        echo -e "  ${gl_lv}2.${gl_bai} $(get_backup_msg 'opt_2')"
        echo -e "  ${gl_lv}3.${gl_bai} $(get_backup_msg 'opt_3')"
        echo -e "  ${gl_lv}4.${gl_bai} $(get_backup_msg 'opt_4')"
        echo -e "  ${gl_lv}5.${gl_bai} $(get_backup_msg 'opt_5')"
        echo -e "${gl_kjlan}------------------------------------------------------------------------${gl_bai}"
        echo -e "  ${gl_hong}0.${gl_bai} $(get_msg 'back')"
        read -p "Selection: " sub_ch
        case "$sub_ch" in
            1) backup_web; break_end ;;
            2) restore_web; break_end ;;
            3) clean_system; break_end ;;
            4) edit_cron; break_end ;;
            5) cron_templates ;;
            0) return ;;
            *) echo -e "${gl_hong}$(get_msg 'invalid_selection')${gl_bai}"; sleep 2 ;;
        esac
    done
}

backup_menu

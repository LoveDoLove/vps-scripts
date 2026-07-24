#!/bin/bash
# scripts/docker_manage.sh
# Docker container, images, network, and disk space management
# Bilingual (CN / EN)

SCRIPT_PATH=$(dirname "$(readlink -f "$0")")
if [ -f "$SCRIPT_PATH/../lib/common.sh" ]; then
    . "$SCRIPT_PATH/../lib/common.sh"
elif [ -f "/tmp/vps-scripts/lib/common.sh" ]; then
    . "/tmp/vps-scripts/lib/common.sh"
fi

detect_language "$1"
require_root

get_dk_msg() {
    local key="$1"
    case "$LANG_ENV" in
        CN)
            case "$key" in
                "title") echo "Docker 容器與鏡像微服務配置控制器" ;;
                "opt_1") echo "安裝宿主機 Docker 主程式與 Docker Compose" ;;
                "opt_2") echo "卸載並清理宿主機 Docker 套件" ;;
                "opt_3") echo "檢視當前運行/停止的容器狀態列表" ;;
                "opt_4") echo "啟動/重啟/停止特定容器程序" ;;
                "opt_5") echo "查看指定容器輸出日誌 (Log)" ;;
                "opt_6") echo "列出與清除未使用的無效鏡像 (Prune Images)" ;;
                "opt_7") echo "執行 Docker 深度磁碟清理 (Prune Cache)" ;;
                "enter_cid") echo "請輸入容器名稱或 ID: " ;;
                "enter_opt") echo "請輸入操作選項 [start / stop / restart / rm]: " ;;
                "not_inst") echo "未發現 Docker 套件，請先安裝。" ;;
                "yes_inst") echo "Docker 已安裝且正常運作。" ;;
            esac
            ;;
        *) # EN
            case "$key" in
                "title") echo "Docker Platform & Containers Controller" ;;
                "opt_1") echo "Install Docker Engine & Docker Compose plugins" ;;
                "opt_2") echo "Uninstall Docker system dependencies entirely" ;;
                "opt_3") echo "List all active / inactive containers" ;;
                "opt_4") echo "Control Container states (Start / Stop / Restart / Delete)" ;;
                "opt_5") echo "Inspect real-time logs from selected Container" ;;
                "opt_6") echo "List and Prune unused Docker images" ;;
                "opt_7") echo "Prune System caches & free container spaces" ;;
                "enter_cid") echo "Enter Container ID or Name: " ;;
                "enter_opt") echo "Enter action [start / stop / restart / rm]: " ;;
                "not_inst") echo "Docker is not detected in your platform." ;;
                "yes_inst") echo "Docker is installed and running fine." ;;
            esac
            ;;
    esac
}

ins_docker() {
    if ! command -v docker &>/dev/null; then
        echo -e "${gl_huang}Downloading Docker configuration engine...${gl_bai}"
        curl -fsSL https://get.docker.com | bash
        systemctl enable docker && systemctl start docker
    else
        echo -e "${gl_lv}$(get_dk_msg 'yes_inst')${gl_bai}"
    fi
}

unins_docker() {
    echo -e "${gl_hong}Removing Docker packages...${gl_bai}"
    local pm=$(detect_pm)
    case "$pm" in
        apt)
            apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            apt-get autoremove -y
            ;;
        dnf|yum)
            dnf remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
    esac
    rm -rf /var/lib/docker /etc/docker
    echo "Docker uninstalled."
}

list_containers() {
    if ! command -v docker &>/dev/null; then
        echo -e "${gl_hong}$(get_dk_msg 'not_inst')${gl_bai}"
        return
    fi
    docker ps -a
}

manage_container() {
    if ! command -v docker &>/dev/null; then
        return
    fi
    list_containers
    read -p "$(get_dk_msg 'enter_cid')" cid
    read -p "$(get_dk_msg 'enter_opt')" opt

    if [[ -n "$cid" && -n "$opt" ]]; then
        case "$opt" in
            start) docker start "$cid" ;;
            stop) docker stop "$cid" ;;
            restart) docker restart "$cid" ;;
            rm) docker rm -f "$cid" ;;
        esac
    fi
}

show_logs() {
    if ! command -v docker &>/dev/null; then
        return
    fi
    list_containers
    read -p "$(get_dk_msg 'enter_cid')" cid
    if [ -n "$cid" ]; then
        docker logs --tail 100 "$cid"
    fi
}

prune_images() {
    if ! command -v docker &>/dev/null; then
        return
    fi
    docker image ls
    docker image prune -a -f
}

clean_docker() {
    if ! command -v docker &>/dev/null; then
        return
    fi
    docker system prune -a --volumes -f
}

docker_menu() {
    while true; do
        clear
        echo -e "${gl_kjlan}========================================================================${gl_bai}"
        echo -e "                 $(get_dk_msg 'title')                                  "
        echo -e "${gl_kjlan}========================================================================${gl_bai}"
        echo -e "  ${gl_lv}1.${gl_bai} $(get_dk_msg 'opt_1')"
        echo -e "  ${gl_lv}2.${gl_bai} $(get_dk_msg 'opt_2')"
        echo -e "  ${gl_lv}3.${gl_bai} $(get_dk_msg 'opt_3')"
        echo -e "  ${gl_lv}4.${gl_bai} $(get_dk_msg 'opt_4')"
        echo -e "  ${gl_lv}5.${gl_bai} $(get_dk_msg 'opt_5')"
        echo -e "  ${gl_lv}6.${gl_bai} $(get_dk_msg 'opt_6')"
        echo -e "  ${gl_lv}7.${gl_bai} $(get_dk_msg 'opt_7')"
        echo -e "${gl_kjlan}------------------------------------------------------------------------${gl_bai}"
        echo -e "  ${gl_hong}0.${gl_bai} $(get_msg 'press_any_key')"
        echo -e "${gl_kjlan}========================================================================${gl_bai}"

        read -p "Selection: " sub_ch
        case "$sub_ch" in
            1) ins_docker; break_end ;;
            2) unins_docker; break_end ;;
            3) list_containers; break_end ;;
            4) manage_container; break_end ;;
            5) show_logs; break_end ;;
            6) prune_images; break_end ;;
            7) clean_docker; break_end ;;
            0) return ;;
            *) echo -e "${gl_hong}$(get_msg 'invalid_selection')${gl_bai}"; sleep 2 ;;
        esac
    done
}

docker_menu

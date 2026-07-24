#!/bin/bash
# scripts/app_store.sh
# Docker Applications Store (One-click app deployments)
# Bilingual (CN / EN)

SCRIPT_PATH=$(dirname "$(readlink -f "$0")")
if [ -f "$SCRIPT_PATH/../lib/common.sh" ]; then
    . "$SCRIPT_PATH/../lib/common.sh"
elif [ -f "/tmp/vps-scripts/lib/common.sh" ]; then
    . "/tmp/vps-scripts/lib/common.sh"
fi

detect_language "$1"
require_root

# Translation options
get_store_msg() {
    local key="$1"
    case "$LANG_ENV" in
        CN)
            case "$key" in
                "title") echo "Docker 軟體/應用市場一鍵安裝儲存庫" ;;
                "opt_1") echo "佈署 MySQL 資料庫服務" ;;
                "opt_2") echo "佈署 Redis 快取服務" ;;
                "opt_3") echo "佈署 phpMyAdmin 資料庫網頁端" ;;
                "opt_4") echo "佈署 Nginx Proxy Manager 代理面板" ;;
                "opt_5") echo "佈署 Portainer 容器可視化管理端" ;;
                "opt_6") echo "佈署 1Panel 新一代 Linux 運維面板" ;;
                "opt_7") echo "佈署 Node.js / Python 容器端環境" ;;
                "opt_8") echo "佈署 WordPress (包含 MySQL 完整容器棧)" ;;
                "opt_9") echo "佈署 PostgreSql + pgAdmin 資料庫集成環境" ;;
                "opt_10") echo "佈署 Nginx 靜態 Web 網頁伺服器" ;;
                "opt_11") echo "佈署 Vaultwarden (Bitwarden 密碼管理器)" ;;
                "enter_port") echo "請輸入容器對外公開映射端口 [默認: " ;;
                "enter_pass") echo "請自定義資料庫/服務訪問密碼: " ;;
                "app_inst_success") echo "應用程式佈署容器完成！啟動成功。" ;;
            esac
            ;;
        *) # EN
            case "$key" in
                "title") echo "Docker App Store - Instant Deployment Launcher" ;;
                "opt_1") echo "Deploy MySQL Relational Database Server" ;;
                "opt_2") echo "Deploy Redis In-Memory Caching Server" ;;
                "opt_3") echo "Deploy phpMyAdmin Web GUI client" ;;
                "opt_4") echo "Deploy Nginx Proxy Manager Console" ;;
                "opt_5") echo "Deploy Portainer Container Visualizer Agent" ;;
                "opt_6") echo "Deploy 1Panel Next-gen Operations Panel" ;;
                "opt_7") echo "Deploy Node.js / Python Workspace containers" ;;
                "opt_8") echo "Deploy WordPress Stack (including MySQL dockerized)" ;;
                "opt_9") echo "Deploy PostgreSql + pgAdmin integrated packages" ;;
                "opt_10") echo "Deploy Nginx standalone static Web server" ;;
                "opt_11") echo "Deploy Vaultwarden Password Manager" ;;
                "enter_port") echo "Enter external network mapping port [Default: " ;;
                "enter_pass") echo "Enter secure password for service administrator: " ;;
                "app_inst_success") echo "Application Container deployed & booted successfully!" ;;
            esac
            ;;
    esac
}

# Standard check for docker environment
ensure_docker() {
    if ! command -v docker &>/dev/null; then
        echo -e "${gl_huang}Installing Docker Engine via setup script...${gl_bai}"
        curl -fsSL https://get.docker.com | bash
        systemctl enable docker && systemctl start docker
    fi
}

deploy_mysql() {
    ensure_docker
    read -p "$(get_store_msg 'enter_port') 3306]: " port
    port=${port:-3306}
    read -p "$(get_store_msg 'enter_pass')" password
    password=${password:-"sql_pwd_$(openssl rand -hex 4)"}

    docker stop mysql-standalone 2>/dev/null
    docker rm mysql-standalone 2>/dev/null
    docker run -d \
        --name mysql-standalone \
        -p "$port":3306 \
        -e MYSQL_ROOT_PASSWORD="$password" \
        --restart always \
        mysql:latest

    echo -e "${gl_lv}$(get_store_msg 'app_inst_success')${gl_bai}"
    echo "MySQL Port: $port | Root Password: $password"
}

deploy_redis() {
    ensure_docker
    read -p "$(get_store_msg 'enter_port') 6379]: " port
    port=${port:-6379}
    read -p "$(get_store_msg 'enter_pass')" password

    docker stop redis-standalone 2>/dev/null
    docker rm redis-standalone 2>/dev/null
    if [ -n "$password" ]; then
        docker run -d \
            --name redis-standalone \
            -p "$port":6379 \
            --restart always \
            redis:latest redis-server --requirepass "$password"
    else
        docker run -d \
            --name redis-standalone \
            -p "$port":6379 \
            --restart always \
            redis:latest
    fi

    echo -e "${gl_lv}$(get_store_msg 'app_inst_success')${gl_bai}"
    echo "Redis Port: $port | Require Password: $password"
}

deploy_phpmyadmin() {
    ensure_docker
    read -p "$(get_store_msg 'enter_port') 8080]: " port
    port=${port:-8080}

    docker stop phpmyadmin-standalone 2>/dev/null
    docker rm phpmyadmin-standalone 2>/dev/null
    docker run -d \
        --name phpmyadmin-standalone \
        -p "$port":80 \
        -e PMA_ARBITRARY=1 \
        --restart always \
        phpmyadmin:latest

    echo -e "${gl_lv}$(get_store_msg 'app_inst_success')${gl_bai}"
    echo "phpMyAdmin Web Access Port: http://local_ip_address:$port"
}

deploy_npm() {
    ensure_docker
    docker stop npm-standalone 2>/dev/null
    docker rm npm-standalone 2>/dev/null
    docker run -d \
        --name npm-standalone \
        -p 80:80 \
        -p 81:81 \
        -p 443:443 \
        -v /home/npm/data:/data \
        -v /home/npm/letsencrypt:/etc/letsencrypt \
        --restart always \
        jc21/nginx-proxy-manager:latest

    echo -e "${gl_lv}$(get_store_msg 'app_inst_success')${gl_bai}"
    echo "Nginx Proxy Manager GUI loaded. Admin Web Port: http://local_ip:81"
}

deploy_portainer() {
    ensure_docker
    docker stop portainer 2>/dev/null
    docker rm portainer 2>/dev/null
    docker volume create portainer_data
    docker run -d \
        --name portainer \
        -p 8000:9000 \
        -p 9443:9443 \
        --restart always \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v portainer_data:/data \
        portainer/portainer-ce:latest

    echo -e "${gl_lv}$(get_store_msg 'app_inst_success')${gl_bai}"
    echo "Portainer Web SSL Port: https://local_ip:9443 or HTTP Port: http://local_ip:8000"
}

deploy_1panel() {
    echo -e "${gl_huang}Downloading and executing 1Panel Installation Scripts...${gl_bai}"
    curl -sSL https://resource.fit2cloud.com/1panel/package/quick_start.sh -o /tmp/1panel_setup.sh
    bash /tmp/1panel_setup.sh
}

deploy_environments() {
    ensure_docker
    echo -e "Deploying Sandboxed CLI environment workspace container..."
    docker stop nodejs-env 2>/dev/null && docker rm nodejs-env 2>/dev/null
    docker run -d --name nodejs-env --restart always node:alpine tail -f /dev/null
    docker stop python-env 2>/dev/null && docker rm python-env 2>/dev/null
    docker run -d --name python-env --restart always python:alpine tail -f /dev/null
    echo -e "${gl_lv}Node.js & Python container environments initialized.${gl_bai}"
}

deploy_wordpress_stack() {
    ensure_docker
    read -p "$(get_store_msg 'enter_port') 8000]: " port
    port=${port:-8000}
    read -p "$(get_store_msg 'enter_pass')" db_pwd
    db_pwd=${db_pwd:-"admin_db_$(openssl rand -hex 4)"}

    mkdir -p /home/wp_stack 2>/dev/null
    cat <<EOF > /home/wp_stack/docker-compose.yml
version: '3.8'

services:
  db:
    image: mysql:8.0
    restart: always
    environment:
      MYSQL_DATABASE: wordpress
      MYSQL_ROOT_PASSWORD: $db_pwd
    volumes:
      - db_data:/var/lib/mysql

  wordpress:
    depends_on:
      - db
    image: wordpress:latest
    restart: always
    ports:
      - "$port:80"
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_USER: root
      WORDPRESS_DB_PASSWORD: $db_pwd
      WORDPRESS_DB_NAME: wordpress
    volumes:
      - wp_data:/var/www/html

volumes:
  db_data:
  wp_data:
EOF
    cd /home/wp_stack && docker compose up -d
    echo -e "${gl_lv}$(get_store_msg 'app_inst_success')${gl_bai}"
    echo "WordPress URL: http://local_ip:$port (MySQL root Pass: $db_pwd)"
}

deploy_postgres() {
    ensure_docker
    read -p "$(get_store_msg 'enter_port') 5432]: " port
    port=${port:-5432}
    read -p "$(get_store_msg 'enter_pass')" password
    password=${password:-"postgres_pwd_$(openssl rand -hex 4)"}

    docker stop postgres-standalone 2>/dev/null
    docker rm postgres-standalone 2>/dev/null
    docker run -d \
        --name postgres-standalone \
        -p "$port":5432 \
        -e POSTGRES_PASSWORD="$password" \
        --restart always \
        postgres:latest

    # Deploy companion pgAdmin tool at port 5050
    docker stop pgadmin-companion 2>/dev/null
    docker rm pgadmin-companion 2>/dev/null
    docker run -d \
        --name pgadmin-companion \
        -p 5050:80 \
        -e PGADMIN_DEFAULT_EMAIL="admin@postgres.com" \
        -e PGADMIN_DEFAULT_PASSWORD="$password" \
        --restart always \
        dpage/pgadmin4:latest

    echo -e "${gl_lv}$(get_store_msg 'app_inst_success')${gl_bai}"
    echo "Postgres Port: $port | User: postgres | Pass: $password"
    echo "pgAdmin Console Port: http://local_ip:5050 | Login: admin@postgres.com / $password"
}

deploy_standalone_nginx() {
    ensure_docker
    read -p "$(get_store_msg 'enter_port') 8081]: " port
    port=${port:-8081}

    docker stop nginx-standalone 2>/dev/null
    docker rm nginx-standalone 2>/dev/null
    docker run -d \
        --name nginx-standalone \
        -p "$port":80 \
        --restart always \
        nginx:alpine

    echo -e "${gl_lv}$(get_store_msg 'app_inst_success')${gl_bai}"
    echo "Standalone Nginx Web Port: http://local_ip:$port"
}

deploy_vaultwarden() {
    ensure_docker
    read -p "$(get_store_msg 'enter_port') 8088]: " port
    port=${port:-8088}

    docker stop vaultwarden-standalone 2>/dev/null
    docker rm vaultwarden-standalone 2>/dev/null
    docker run -d \
        --name vaultwarden-standalone \
        -p "$port":80 \
        -v /home/vaultwarden/data:/data \
        --restart always \
        vaultwarden/server:latest

    echo -e "${gl_lv}$(get_store_msg 'app_inst_success')${gl_bai}"
    echo "Vaultwarden Password Manager Access: http://local_ip:$port (SSL Proxy highly recommended for HTTPS API)"
}

store_menu() {
    while true; do
        clear
        echo -e "${gl_kjlan}========================================================================${gl_bai}"
        echo -e "                 $(get_store_msg 'title')                               "
        echo -e "${gl_kjlan}========================================================================${gl_bai}"
        echo -e "  ${gl_lv}1.${gl_bai} $(get_store_msg 'opt_1')          ${gl_lv}6.${gl_bai} $(get_store_msg 'opt_6')"
        echo -e "  ${gl_lv}2.${gl_bai} $(get_store_msg 'opt_2')          ${gl_lv}7.${gl_bai} $(get_store_msg 'opt_7')"
        echo -e "  ${gl_lv}3.${gl_bai} $(get_store_msg 'opt_3')          ${gl_lv}8.${gl_bai} $(get_store_msg 'opt_8')"
        echo -e "  ${gl_lv}4.${gl_bai} $(get_store_msg 'opt_4')          ${gl_lv}9.${gl_bai} $(get_store_msg 'opt_9')"
        echo -e "  ${gl_lv}5.${gl_bai} $(get_store_msg 'opt_5')         ${gl_lv}10.${gl_bai} $(get_store_msg 'opt_10')"
        echo -e "  ${gl_lv}11.${gl_bai} $(get_store_msg 'opt_11')"
        echo -e "${gl_kjlan}------------------------------------------------------------------------${gl_bai}"
        echo -e "  ${gl_hong}0.${gl_bai} $(get_msg 'press_any_key')"
        echo -e "${gl_kjlan}========================================================================${gl_bai}"

        read -p "Selection: " sub_ch
        case "$sub_ch" in
            1) deploy_mysql; break_end ;;
            2) deploy_redis; break_end ;;
            3) deploy_phpmyadmin; break_end ;;
            4) deploy_npm; break_end ;;
            5) deploy_portainer; break_end ;;
            6) deploy_1panel; break_end ;;
            7) deploy_environments; break_end ;;
            8) deploy_wordpress_stack; break_end ;;
            9) deploy_postgres; break_end ;;
            10) deploy_standalone_nginx; break_end ;;
            11) deploy_vaultwarden; break_end ;;
            0) return ;;
            *) echo -e "${gl_hong}$(get_msg 'invalid_selection')${gl_bai}"; sleep 2 ;;
        esac
    done
}

store_menu

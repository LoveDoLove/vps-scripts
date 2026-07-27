#!/bin/bash
# scripts/web_manage.sh
# LDNMP (Linux Nginx MySQL PHP Redis) Docker Environment, Site Deployment & Management
# Bilingual (CN / EN)
SCRIPT_PATH=$(dirname "$(readlink -f "$0")")
if [ -f "$SCRIPT_PATH/../lib/common.sh" ]; then
    . "$SCRIPT_PATH/../lib/common.sh"
elif [ -f "/tmp/vps-scripts/lib/common.sh" ]; then
    . "/tmp/vps-scripts/lib/common.sh"
fi
detect_language "$1"
require_root
install_pkgs openssl curl wget

# ============================================================
# i18n
# ============================================================
get_web_msg() {
    local key="$1"
    case "$LANG_ENV" in
        CN)
            case "$key" in
                "title") echo "LDNMP Web 站點管理 (Nginx + MySQL + PHP + Redis)" ;;
                "opt_1") echo "安裝 LDNMP 基礎環境 (Nginx + MySQL + PHP + Redis)" ;;
                "opt_2") echo "部署 WordPress 站點" ;;
                "opt_3") echo "配置反向代理 (IP:Port / 域名)" ;;
                "opt_4") echo "配置負載均衡反向代理 (多後端)" ;;
                "opt_5") echo "配置 Stream 四層代理 (TCP/UDP)" ;;
                "opt_6") echo "站點列表" ;;
                "opt_7") echo "站點列表" ;;
                "opt_8") echo "刪除站點" ;;
                "choose_site") echo "請選擇要操作的站點: " ;;
                "site_deleted") echo "站點已刪除。" ;;
                "wp_done") echo "WordPress 站點已部署。" ;;
                "proxy_done") echo "反向代理已配置。" ;;
                "upstream_done") echo "負載均衡反向代理已配置。" ;;
                "stream_done") echo "Stream 四層代理已配置。" ;;
                "enter_domain") echo "請輸入域名: " ;;
                "enter_target") echo "請輸入目標地址 (IP:Port 或 域名): " ;;
                "enter_backends") echo "請輸入後端伺服器 (每行一個 IP:Port，空行結束): " ;;
                "enter_listen_port") echo "請輸入監聽端口: " ;;
                "enter_proto") echo "請選擇協議 (tcp/udp): " ;;
            esac
            ;;
        *)
            case "$key" in
                "title") echo "LDNMP Web Stack (Nginx + MySQL + PHP + Redis)" ;;
                "opt_1") echo "Install LDNMP stack (Nginx + MySQL + PHP + Redis)" ;;
                "opt_2") echo "Deploy WordPress site" ;;
                "opt_3") echo "Configure reverse proxy (IP:Port / Domain)" ;;
                "opt_4") echo "Configure load-balanced reverse proxy (multi-backend)" ;;
                "opt_5") echo "Configure Stream 4-layer proxy (TCP/UDP)" ;;
                "opt_6") echo "Site list" ;;
                "opt_7") echo "Site list" ;;
                "opt_8") echo "Delete site" ;;
                "choose_site") echo "Choose a site: " ;;
                "site_deleted") echo "Site deleted." ;;
                "wp_done") echo "WordPress site deployed." ;;
                "proxy_done") echo "Reverse proxy configured." ;;
                "upstream_done") echo "Load-balanced reverse proxy configured." ;;
                "stream_done") echo "Stream 4-layer proxy configured." ;;
                "enter_domain") echo "Enter domain: " ;;
                "enter_target") echo "Enter target (IP:Port or Domain): " ;;
                "enter_backends") echo "Enter backend servers (one IP:Port per line, blank line to finish): " ;;
                "enter_listen_port") echo "Enter listen port: " ;;
                "enter_proto") echo "Select protocol (tcp/udp): " ;;
            esac
            ;;
    esac
}

# ============================================================
# LDNMP base environment
# ============================================================
install_ldnmp_base() {
    install_pkgs docker-ce docker-compose-plugin
    mkdir -p /home/web/html /home/web/mysql /home/web/certs /home/web/conf.d /home/web/stream.d /home/web/redis
    mkdir -p /home/web/log/nginx /home/web/letsencrypt

    local db_root_pwd db_user_pwd db_user_name
    db_root_pwd=$(openssl rand -base64 24)
    db_user_pwd=$(openssl rand -base64 24)
    db_user_name="dbuser_$(openssl rand -hex 4)"

    cat > /home/web/docker-compose.yml << YAML
version: '3.8'
services:
  nginx:
    image: nginx:alpine
    container_name: ldnmp-nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./html:/usr/share/nginx/html
      - ./conf.d:/etc/nginx/conf.d
      - ./stream.d:/etc/nginx/stream.d
      - ./certs:/etc/nginx/certs
      - ./log/nginx:/var/log/nginx
      - ./letsencrypt:/var/www/letsencrypt
    depends_on: [php]
    restart: always

  mysql:
    image: mysql:8.0
    container_name: ldnmp-mysql
    environment:
      MYSQL_ROOT_PASSWORD: ${db_root_pwd}
      MYSQL_DATABASE: wordpress
      MYSQL_USER: ${db_user_name}
      MYSQL_PASSWORD: ${db_user_pwd}
    volumes:
      - ./mysql:/var/lib/mysql
    restart: always

  php:
    image: php:8.2-fpm-alpine
    container_name: ldnmp-php
    volumes:
      - ./html:/usr/share/nginx/html
      - ./conf.d:/etc/nginx/conf.d
    restart: always

  redis:
    image: redis:7-alpine
    container_name: ldnmp-redis
    volumes:
      - ./redis:/data
    restart: always

  certbot:
    image: certbot/certbot
    container_name: ldnmp-certbot
    volumes:
      - ./letsencrypt:/var/www/letsencrypt
      - ./certs:/etc/letsencrypt
    entrypoint: ["/bin/sh", "-c"]
    command: ["trap exit TERM; while :; do certbot renew; sleep 12h & wait \$\$\"; done"]
YAML

    cd /home/web && docker compose up -d
    echo -e "${gl_lv}LDNMP stack is up. MySQL root password: ${db_root_pwd}${gl_bai}"
}

# ============================================================
# WordPress deployment
# ============================================================
deploy_wordpress() {
    read -p "$(get_web_msg 'enter_domain'): " wp_domain
    [ -z "$wp_domain" ] && { echo -e "${gl_hong}Domain required.${gl_bai}"; return; }

    mkdir -p /home/web/html/$wp_domain
    wget -q -O /tmp/latest.tar.gz https://wordpress.org/latest.tar.gz
    tar xzf /tmp/latest.tar.gz -C /home/web/html/$wp_domain --strip-components=1
    rm -f /tmp/latest.tar.gz
    chown -R 82:82 /home/web/html/$wp_domain

    cat > /home/web/conf.d/${wp_domain}.conf << NGX
server {
    listen 80;
    server_name ${wp_domain};
    root /usr/share/nginx/html/${wp_domain};
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }
    location ~ \.php\$ {
        fastcgi_pass php:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
    location ~ /\.ht {
        deny all;
    }
}
NGX

    docker exec ldnmp-nginx nginx -s reload 2>/dev/null
    echo -e "${gl_lv}$(get_web_msg 'wp_done') — http://${wp_domain}${gl_bai}"
}

# ============================================================
# Simple reverse proxy (single backend)
# ============================================================
setup_proxy() {
    read -p "$(get_web_msg 'enter_domain'): " pr_domain
    read -p "$(get_web_msg 'enter_target'): " pr_target
    [ -z "$pr_domain" ] && { echo -e "${gl_hong}Domain required.${gl_bai}"; return; }

    cat > /home/web/conf.d/${pr_domain}.conf << NGX
server {
    listen 80;
    server_name ${pr_domain};
    location / {
        proxy_pass http://${pr_target};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
NGX
    docker exec ldnmp-nginx nginx -s reload 2>/dev/null
    echo -e "${gl_lv}$(get_web_msg 'proxy_done') — ${pr_domain} -> ${pr_target}${gl_bai}"
}

# ============================================================
# NEW: Load-balanced reverse proxy (multiple backends)
# ============================================================
setup_upstream_proxy() {
    read -p "$(get_web_msg 'enter_domain'): " up_domain
    echo -e "${gl_huang}$(get_web_msg 'enter_backends')${gl_bai}"
    local backends=()
    while IFS= read -r line; do
        [ -z "$line" ] && break
        backends+=("$line")
    done

    [ ${#backends[@]} -eq 0 ] && { echo -e "${gl_hong}At least one backend required.${gl_bai}"; return; }

    local upstream_block=""
    local i=1
    for be in "${backends[@]}"; do
        upstream_block+="        server ${be};\n"
        i=$((i+1))
    done

    cat > /home/web/conf.d/${up_domain}.conf << NGX
upstream backend_${up_domain//./_} {
    $(printf "%s" "$upstream_block")
}
server {
    listen 80;
    server_name ${up_domain};
    location / {
        proxy_pass http://backend_${up_domain//./_};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
NGX
    docker exec ldnmp-nginx nginx -s reload 2>/dev/null
    echo -e "${gl_lv}$(get_web_msg 'upstream_done') — ${up_domain} -> ${#backends[@]} backends${gl_bai}"
}

# ============================================================
# NEW: Stream 4-layer proxy (TCP/UDP)
# ============================================================
setup_stream_proxy() {
    read -p "$(get_web_msg 'enter_listen_port'): " stream_port
    read -p "$(get_web_msg 'enter_target'): " stream_target
    read -p "$(get_web_msg 'enter_proto') (tcp/udp): " stream_proto
    [ -z "$stream_port" ] && { echo -e "${gl_hong}Port required.${gl_bai}"; return; }
    [ -z "$stream_proto" ] && stream_proto="tcp"

    cat > /home/web/stream.d/stream_${stream_port}.conf << NGX
stream {
    server {
        listen ${stream_port};
        proxy_connect_timeout 30s;
        proxy_timeout 300s;
        proxy_pass ${stream_target};
    }
}
NGX
    docker exec ldnmp-nginx nginx -s reload 2>/dev/null
    echo -e "${gl_lv}$(get_web_msg 'stream_done') — 0.0.0.0:${stream_port} -> ${stream_target} (${stream_proto})${gl_bai}"
}

# ============================================================
# Site listing
# ============================================================
list_sites() {
    echo -e "${gl_kjlan}$(get_web_msg 'opt_6')${gl_bai}"
    ls -1 /home/web/conf.d/*.conf 2>/dev/null | sed 's|/home/web/conf.d/||; s|\.conf$||' || echo -e "${gl_hong}No sites configured.${gl_bai}"
}

# ============================================================
# Delete a site
# ============================================================
delete_site() {
    list_sites
    read -p "$(get_web_msg 'choose_site'): " del_site
    [ -z "$del_site" ] && return
    rm -f /home/web/conf.d/${del_site}.conf
    rm -rf /home/web/html/${del_site} 2>/dev/null
    docker exec ldnmp-nginx nginx -s reload 2>/dev/null
    echo -e "${gl_hong}$(get_web_msg 'site_deleted') — $del_site${gl_bai}"
}

# ============================================================
# Main menu
# ============================================================
web_menu() {
    while true; do
        clear
        echo -e "${gl_kjlan}$(get_web_msg 'title')${gl_bai}"
        echo -e "  ${gl_lv}1.${gl_bai} $(get_web_msg 'opt_1')"
        echo -e "  ${gl_lv}2.${gl_bai} $(get_web_msg 'opt_2')"
        echo -e "  ${gl_lv}3.${gl_bai} $(get_web_msg 'opt_3')"
        echo -e "  ${gl_lv}4.${gl_bai} $(get_web_msg 'opt_4')"
        echo -e "  ${gl_lv}5.${gl_bai} $(get_web_msg 'opt_5')"
        echo -e "  ${gl_lv}6.${gl_bai} $(get_web_msg 'opt_6')"
        echo -e "  ${gl_lv}7.${gl_bai} $(get_web_msg 'opt_7')"
        echo -e "  ${gl_lv}8.${gl_bai} $(get_web_msg 'opt_8')"
        echo -e "  ${gl_hong}0.${gl_bai} $(get_msg 'back')"
        read -p "Selection: " sub_ch
        case "$sub_ch" in
            1) install_ldnmp_base; break_end ;;
            2) deploy_wordpress; break_end ;;
            3) setup_proxy; break_end ;;
            4) setup_upstream_proxy; break_end ;;
            5) setup_stream_proxy; break_end ;;
            6) list_sites; break_end ;;
            7) list_sites; break_end ;;
            8) delete_site; break_end ;;
            0) return ;;
            *) echo -e "${gl_hong}$(get_msg 'invalid_selection')${gl_bai}"; sleep 2 ;;
        esac
    done
}

web_menu

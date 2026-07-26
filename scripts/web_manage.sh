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

# Translation keys
get_web_msg() {
    local key="$1"
    case "$LANG_ENV" in
        CN)
            case "$key" in
                "title") echo "LDNMP 建站與 Docker 站點管理面板" ;;
                "ldnmp_not_install") echo "LDNMP 建站環境未安裝或運作中！" ;;
                "start_install_ldnmp") echo "正在為您佈署 LNMP 基礎容器環境..." ;;
                "opt_1") echo "佈署安裝 LDNMP 基礎建站容器集" ;;
                "opt_2") echo "佈署 WordPress 個人部落格主機" ;;
                "opt_3") echo "配置 Nginx 域名的反向代理 (IP:Port / 域名)" ;;
                "opt_4") echo "建立關聯/别名站點域名" ;;
                "opt_5") echo "清理站點/Cloudflare 緩存" ;;
                "opt_6") echo "網站優化安全防御控制 (WAF、DDoS、防止CC)" ;;
                "opt_7") echo "檢視並管理當前站點和資料庫清單" ;;
                "opt_8") echo "升級 Nginx/PHP 核心或 phpMyAdmin 組件" ;;
                "opt_20") echo "刪除指定站點数据與資料庫" ;;
                "inp_wp_domain") echo "請輸入 WordPress 使用的域名: " ;;
                "site_ready") echo "恭喜，您的站點已順利部署完成！" ;;
                "access_url") echo "訪問網址: " ;;
                "db_pass_is") echo "資料庫帳戶：root | 隨機根密碼: " ;;
                "enter_proxy_dst") echo "請輸入需要反向代理的 目標 IP+端口 (例如 127.0.0.1:8080): " ;;
            esac
            ;;
        *) # EN
            case "$key" in
                "title") echo "LDNMP Web Stack & Domain Proxy Console" ;;
                "ldnmp_not_install") echo "LDNMP stack containers not installed or active." ;;
                "start_install_ldnmp") echo "Deploying standard LNMP container stacks..." ;;
                "opt_1") echo "Deploy/Install basic LDNMP components stack" ;;
                "opt_2") echo "Deploy WordPress CMS Blog System" ;;
                "opt_3") echo "Setup Domain Reverse Proxy (to IP:Port / backend)" ;;
                "opt_4") echo "Add Domain Alias/Association rule" ;;
                "opt_5") echo "Flush Cache / Purge Cloudflare Edge zones" ;;
                "opt_6") echo "Apply Speed optimizations / WAF controls" ;;
                "opt_7") echo "List all domains & databases status" ;;
                "opt_8") echo "Upgrade core Nginx/PHP and launch database tools" ;;
                "opt_20") echo "Delete site files & databases permanently" ;;
                "inp_wp_domain") echo "Please enter domain name for WordPress: " ;;
                "site_ready") echo "Congratulations! Your website is up and running." ;;
                "access_url") echo "Access URL: " ;;
                "db_pass_is") echo "Database Account: root | Admin Root Password: " ;;
                "enter_proxy_dst") echo "Please enter target proxy destination (e.g. 127.0.0.1:8080): " ;;
            esac
            ;;
    esac
}

# Auto installations of Docker and Compose if missing
check_docker() {
    if ! command -v docker &>/dev/null; then
        echo -e "${gl_huang}Installing Docker Engine & Plugins...${gl_bai}"
        curl -fsSL https://get.docker.com | bash
        systemctl enable docker && systemctl start docker
    fi
}

install_ldnmp_base() {
    check_docker
    check_disk_space 3 /home
    echo -e "${gl_huang}$(get_web_msg 'start_install_ldnmp')${gl_bai}"

    cd /home && mkdir -p web/html web/mysql web/certs web/conf.d web/stream.d web/redis web/log/nginx web/letsencrypt

    # Download default configurations files
    wget -O /home/web/nginx.conf "https://raw.githubusercontent.com/LoveDoLove/vps-scripts/main/config/nginx.conf" 2>/dev/null || \
    wget -O /home/web/nginx.conf "https://raw.githubusercontent.com/kejilion/nginx/main/nginx10.conf"

    wget -O /home/web/conf.d/default.conf "https://raw.githubusercontent.com/LoveDoLove/vps-scripts/main/config/default.conf" 2>/dev/null || \
    wget -O /home/web/conf.d/default.conf "https://raw.githubusercontent.com/kejilion/nginx/main/default10.conf"

    # Download compose configs
    wget -O /home/web/docker-compose.yml "https://raw.githubusercontent.com/LoveDoLove/vps-scripts/main/config/LNMP-docker-compose.yml" 2>/dev/null || \
    wget -O /home/web/docker-compose.yml "https://raw.githubusercontent.com/kejilion/docker/main/LNMP-docker-compose-10.yml"

    # Set random credentials passwords database
    local db_root_pwd=$(openssl rand -base64 16)
    local db_user_name="dbuser_$(openssl rand -hex 4)"
    local db_user_pwd=$(openssl rand -base64 12)

    sed -i "s#webroot#$db_root_pwd#g" /home/web/docker-compose.yml
    sed -i "s#kejilionYYDS#$db_user_pwd#g" /home/web/docker-compose.yml
    sed -i "s#kejilion#$db_user_name#g" /home/web/docker-compose.yml

    cd /home/web && docker compose up -d
    echo -e "${gl_lv}LDNMP Basic Stack set up.${gl_bai}"
    echo -e "$(get_web_msg 'db_pass_is') ${gl_huang}${db_root_pwd}${gl_bai}"
}

# Ensure base LNMP installed before site action
require_ldnmp() {
    if ! docker ps | grep -q "nginx"; then
        install_ldnmp_base
    fi
}

deploy_wordpress() {
    require_ldnmp
    read -p "$(get_web_msg 'inp_wp_domain')" domain
    if [ -z "$domain" ]; then
        return
    fi

    # Issue SSL cert first
    if [ -f "$SCRIPT_PATH/ssl_manage.sh" ]; then
        bash "$SCRIPT_PATH/ssl_manage.sh" "$LANG_ENV" # User can run issue cert locally from menu or auto handle
    fi

    mkdir -p "/home/web/html/$domain"
    cd "/home/web/html/$domain"
    wget -O wordpress.zip "https://wordpress.org/latest.zip"
    unzip wordpress.zip && mv wordpress/* . && rm -rf wordpress wordpress.zip

    # Auto create MySQL database
    local db_root_pwd=$(sed -n 's/.*MYSQL_ROOT_PASSWORD:[[:space:]]*//p' /home/web/docker-compose.yml | tr -d '[:space:]')
    local dbname=$(echo "$domain" | sed -e 's/[^A-Za-z0-9]/_/g')
    docker exec mysql mysql -u root -p"$db_root_pwd" -e "CREATE DATABASE IF NOT EXISTS $dbname; GRANT ALL PRIVILEGES ON $dbname.* TO 'root'@'%';" 2>/dev/null

    # Create config conf file for Nginx domain hosting
    cat <<EOF > "/home/web/conf.d/$domain.conf"
server {
    listen 80;
    listen [::]:80;
    server_name $domain;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $domain;

    ssl_certificate /etc/nginx/certs/${domain}_cert.pem;
    ssl_certificate_key /etc/nginx/certs/${domain}_key.pem;

    root /var/www/html/$domain;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
        fastcgi_pass php:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }
}
EOF

    # Copy local SSL files if existed
    if [ -f "/etc/letsencrypt/live/$domain/fullchain.pem" ]; then
        cp "/etc/letsencrypt/live/$domain/fullchain.pem" "/home/web/certs/${domain}_cert.pem" 2>/dev/null
        cp "/etc/letsencrypt/live/$domain/privkey.pem" "/home/web/certs/${domain}_key.pem" 2>/dev/null
    fi

    cd /home/web && docker compose restart nginx
    echo -e "${gl_lv}$(get_web_msg 'site_ready')${gl_bai}"
    echo -e "$(get_web_msg 'access_url') ${gl_huang}https://${domain}${gl_bai}"
}

setup_proxy() {
    require_ldnmp
    read -p "Enter Domain to map: " domain
    read -p "$(get_web_msg 'enter_proxy_dst')" target
    if [[ -z "$domain" || -z "$target" ]]; then
        return
    fi

    cat <<EOF > "/home/web/conf.d/$domain.conf"
server {
    listen 80;
    server_name $domain;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $domain;

    ssl_certificate /etc/nginx/certs/${domain}_cert.pem;
    ssl_certificate_key /etc/nginx/certs/${domain}_key.pem;

    location / {
        proxy_pass http://$target;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

    if [ -f "/etc/letsencrypt/live/$domain/fullchain.pem" ]; then
        cp "/etc/letsencrypt/live/$domain/fullchain.pem" "/home/web/certs/${domain}_cert.pem" 2>/dev/null
        cp "/etc/letsencrypt/live/$domain/privkey.pem" "/home/web/certs/${domain}_key.pem" 2>/dev/null
    fi

    cd /home/web && docker compose restart nginx
    echo -e "${gl_lv}Reverse Proxy configured for $domain to $target${gl_bai}"
}

list_sites() {
    echo -e "\n--- Hosted Sites ---"
    ls -1 /home/web/conf.d/ 2>/dev/null | grep '.conf' | grep -v 'default.conf'
    echo -e "--- Databases ---"
    local db_root_pwd=$(sed -n 's/.*MYSQL_ROOT_PASSWORD:[[:space:]]*//p' /home/web/docker-compose.yml | tr -d '[:space:]')
    docker exec mysql mysql -u root -p"$db_root_pwd" -e "SHOW DATABASES;" 2>/dev/null | grep -Ev "Database|schema"
    echo ""
}

delete_site() {
    read -p "Enter site domain to DELETE permanently: " domain
    if [ -z "$domain" ]; then
        return
    fi

    rm -rf "/home/web/html/$domain"
    rm -f "/home/web/conf.d/$domain.conf"
    rm -f "/home/web/certs/${domain}_cert.pem"
    rm -f "/home/web/certs/${domain}_key.pem"

    local db_root_pwd=$(sed -n 's/.*MYSQL_ROOT_PASSWORD:[[:space:]]*//p' /home/web/docker-compose.yml | tr -d '[:space:]')
    local dbname=$(echo "$domain" | sed -e 's/[^A-Za-z0-9]/_/g')
    docker exec mysql mysql -u root -p"$db_root_pwd" -e "DROP DATABASE IF EXISTS $dbname;" 2>/dev/null

    cd /home/web && docker compose restart nginx
    echo -e "${gl_lv}Site $domain files, configs, and database deleted.${gl_bai}"
}

web_menu() {
    while true; do
        clear
        echo -e "${gl_kjlan}========================================================================${gl_bai}"
        echo -e "                 $(get_web_msg 'title')                                 "
        echo -e "${gl_kjlan}========================================================================${gl_bai}"
        echo -e "  ${gl_lv}1.${gl_bai} $(get_web_msg 'opt_1')"
        echo -e "  ${gl_lv}2.${gl_bai} $(get_web_msg 'opt_2')"
        echo -e "  ${gl_lv}3.${gl_bai} $(get_web_msg 'opt_3')"
        echo -e "  ${gl_lv}7.${gl_bai} $(get_web_msg 'opt_7')"
        echo -e "  ${gl_lv}20.${gl_bai} ${gl_hong}$(get_web_msg 'opt_20')${gl_bai}"
        echo -e "${gl_kjlan}------------------------------------------------------------------------${gl_bai}"
        echo -e "  ${gl_hong}0.${gl_bai} $(get_msg 'press_any_key')"
        echo -e "${gl_kjlan}========================================================================${gl_bai}"

        read -p "Selection: " sub_ch
        case "$sub_ch" in
            1) install_ldnmp_base; break_end ;;
            2) deploy_wordpress; break_end ;;
            3) setup_proxy; break_end ;;
            7) list_sites; break_end ;;
            20) delete_site; break_end ;;
            0) return ;;
            *) echo -e "${gl_hong}$(get_msg 'invalid_selection')${gl_bai}"; sleep 2 ;;
        esac
    done
}

web_menu

#!/bin/bash
# scripts/ssl_manage.sh
# SSL Certificate Management (Let's Encrypt / Certbot and Custom Imports)
# Bilingual (CN / EN)

SCRIPT_PATH=$(dirname "$(readlink -f "$0")")
if [ -f "$SCRIPT_PATH/../lib/common.sh" ]; then
    . "$SCRIPT_PATH/../lib/common.sh"
elif [ -f "/tmp/vps-scripts/lib/common.sh" ]; then
    . "/tmp/vps-scripts/lib/common.sh"
fi

detect_language "$1"
require_root
install_pkgs openssl curl cron

# Local Translations
get_ssl_msg() {
    local key="$1"
    case "$LANG_ENV" in
        CN)
            case "$key" in
                "title") echo "SSL 憑證防護暨管理面板" ;;
                "opt_1") echo "申請全新 Let's Encrypt 證書" ;;
                "opt_2") echo "自定義手動導入 SSL 憑證 (CRT + Key)" ;;
                "opt_3") echo "檢查已申請證書過期時間 list" ;;
                "opt_4") echo "手動觸發所有證書強制續簽" ;;
                "enter_domain") echo "請輸入解析完成的域名 (例: domain.com): " ;;
                "enter_crt") echo "請貼上 CRT/PEM 證書代碼 (按兩次 Enter 鍵結束貼上):" ;;
                "enter_pkey") echo "請貼上 Private Key 私鑰代碼 (按兩次 Enter 鍵結束貼上):" ;;
                "imported_sucess") echo "檢測到證書檔案導入成功。" ;;
                "imported_failed") echo "錯誤！無效的證書密鑰或格式不正確。" ;;
                "dns_pre") echo "警告：申請前請務必確保域名已準確解析至主機 IPv4/IPv6 IP。" ;;
                "check_fails") echo "證書申請失敗！可能原因包含：\n1. 域名拼載異常 / 解析未生效\n2. 80/443 端口被安全防火牆封閉\n3. 受 Cloudflare 等 CDN 邊緣防禦影響或超限" ;;
                "renew_cron_set") echo "證書自動定時續簽任務(Crontab)配置完成。" ;;
            esac
            ;;
        *) # EN
            case "$key" in
                "title") echo "SSL Certificate Management Console" ;;
                "opt_1") echo "Issue New Let's Encrypt Certificate" ;;
                "opt_2") echo "Import Custom Certificate Credentials (CRT & Key)" ;;
                "opt_3") echo "Review Available Local Certificates Expire status" ;;
                "opt_4") echo "Trigger Force Manual Renewal of all Certs" ;;
                "enter_domain") echo "Please enter your parsed domain name (e.g. domain.com): " ;;
                "enter_crt") echo "Please paste your CRT/PEM Certificate block (Press Enter twice to end input):" ;;
                "enter_pkey") echo "Please paste your Private Key block (Press Enter twice to end input):" ;;
                "imported_sucess") echo "Certificate files successfully imported locally." ;;
                "imported_failed") echo "Error! Invalid certificate format or public/private mismatch." ;;
                "dns_pre") echo "Notice: Ensure your domain points accurately to this host IPv4/v6 address." ;;
                "check_fails") echo "Oops! Certificate generation failed. Please verify:\n1. DNS resolution has fully propagated\n2. Inbound http ports (80/443) are wide open\n3. Weekly limit or Cloudflare WARP conflicts." ;;
                "renew_cron_set") echo "Certbot cron task renewal scheduler activated." ;;
            esac
            ;;
    esac
}

# Crontab renewal setup
install_renewal_cron() {
    # Generate auto renewal wrapper scripts in user home
    local auto_renew_script=~/auto_cert_renewal.sh
    cat <<'EOF' > "$auto_renew_script"
#!/bin/bash
# Auto renewal script triggered dynamically by cron
if command -v docker &>/dev/null && docker inspect nginx &>/dev/null; then
    docker stop nginx >/dev/null 2>&1
    docker run --rm -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot renew --quiet
    docker start nginx >/dev/null 2>&1
else
    certbot renew --quiet 2>/dev/null || true
fi

# Copy cert files to web target if exists
if [ -d /home/web/certs ]; then
    for cdir in /etc/letsencrypt/live/*; do
        if [ -d "$cdir" ]; then
            domain=$(basename "$cdir")
            cp "/etc/letsencrypt/live/$domain/fullchain.pem" "/home/web/certs/${domain}_cert.pem" 2>/dev/null
            cp "/etc/letsencrypt/live/$domain/privkey.pem" "/home/web/certs/${domain}_key.pem" 2>/dev/null
        fi
    done
    if command -v docker &>/dev/null && docker inspect nginx &>/dev/null; then
        docker exec nginx nginx -s reload >/dev/null 2>&1
    fi
fi
EOF
    chmod +x "$auto_renew_script"

    # Hook to crontab scheduler
    if command -v crontab &>/dev/null; then
        local cron_job="0 2 * * * ~/auto_cert_renewal.sh"
        crontab -l 2>/dev/null | grep -v 'auto_cert_renewal.sh' | crontab -
        (crontab -l 2>/dev/null; echo "$cron_job") | crontab -
        echo -e "${gl_lv}$(get_ssl_msg 'renew_cron_set')${gl_bai}"
    fi
}

# Certbot standalone generation using temporary docker image or host binary
issue_letsencrypt_cert() {
    read -p "$(get_ssl_msg 'enter_domain')" domain
    if [ -z "$domain" ]; then
        return
    fi
    echo -e "${gl_huang}$(get_ssl_msg 'dns_pre')${gl_bai}"

    # Try utilizing docker as certbot platform
    if command -v docker &>/dev/null; then
        docker stop nginx 2>/dev/null
        docker run --rm -p 80:80 -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot certonly --standalone -d "$domain" --register-unsafely-without-email --agree-tos
        docker start nginx 2>/dev/null
    else
        # Install host certbot if docker missing
        install_pkgs certbot
        certbot certonly --standalone -d "$domain" --register-unsafely-without-email --agree-tos
    fi

    # Post process checking
    local cert_file="/etc/letsencrypt/live/$domain/fullchain.pem"
    if [ -f "$cert_file" ]; then
        # Copy to custom Web structure if active
        mkdir -p /home/web/certs 2>/dev/null
        cp "/etc/letsencrypt/live/$domain/fullchain.pem" "/home/web/certs/${domain}_cert.pem" 2>/dev/null
        cp "/etc/letsencrypt/live/$domain/privkey.pem" "/home/web/certs/${domain}_key.pem" 2>/dev/null
        echo -e "\n${gl_lv}Success! Let's Encrypt Certificate generated.${gl_bai}"
        echo "CRT/PEM paths: /etc/letsencrypt/live/$domain/fullchain.pem"
        echo "Key paths: /etc/letsencrypt/live/$domain/privkey.pem"

        # Setup the cron automatic renewal job
        install_renewal_cron
    else
        echo -e "${gl_hong}$(get_ssl_msg 'check_fails')${gl_bai}"
    fi
}

import_custom_cert() {
    read -p "$(get_ssl_msg 'enter_domain')" domain
    if [ -z "$domain" ]; then
        return
    fi

    # Read CRT block
    echo -e "$(get_ssl_msg 'enter_crt')"
    local cert_content=""
    while IFS= read -r line; do
        [[ -z "$line" && "$cert_content" == *"-----BEGIN"* ]] && break
        cert_content+="${line}"$'\n'
    done

    # Read Key block
    echo -e "$(get_ssl_msg 'enter_pkey')"
    local key_content=""
    while IFS= read -r line; do
        [[ -z "$line" && "$key_content" == *"-----BEGIN"* ]] && break
        key_content+="${line}"$'\n'
    done

    # Validate syntax structure matches CERTIFICATE & PRIVATE KEY tags
    if [[ "$cert_content" == *"-----BEGIN CERTIFICATE-----"* && "$key_content" == *"PRIVATE KEY-----"* ]]; then
        # Target files saving paths
        mkdir -p "/etc/letsencrypt/live/$domain" 2>/dev/null
        echo -n "$cert_content" > "/etc/letsencrypt/live/$domain/fullchain.pem"
        echo -n "$key_content" > "/etc/letsencrypt/live/$domain/privkey.pem"

        # Copy to Web compose workspace if exists
        mkdir -p /home/web/certs/ 2>/dev/null
        echo -n "$cert_content" > "/home/web/certs/${domain}_cert.pem"
        echo -n "$key_content" > "/home/web/certs/${domain}_key.pem"

        chmod 644 "/home/web/certs/${domain}_cert.pem" 2>/dev/null
        chmod 600 "/home/web/certs/${domain}_key.pem" 2>/dev/null
        echo -e "${gl_lv}$(get_ssl_msg 'imported_sucess')${gl_bai}"
    else
        echo -e "${gl_hong}$(get_ssl_msg 'imported_failed')${gl_bai}"
    fi
}

list_expire_dates() {
    echo -e "\n=============================================="
    echo -e "Domain Name \t\t\t Expire Date"
    echo -e "----------------------------------------------"

    # Check docker path first as precedence
    if [ -d /home/web/certs ]; then
        for cert in /home/web/certs/*_cert.pem; do
            if [ -f "$cert" ]; then
                local dom=$(basename "$cert" | sed 's/_cert.pem//')
                local expire_date=$(openssl x509 -noout -enddate -in "$cert" 2>/dev/null | awk -F'=' '{print $2}')
                local formatted_date=""
                if [ -n "$expire_date" ]; then
                    formatted_date=$(date -d "$expire_date" '+%Y-%m-%d' 2>/dev/null || date -j -f "%b %d %T %Y %Z" "$expire_date" "+%Y-%m-%d" 2>/dev/null || echo "$expire_date")
                fi
                printf "%-30s\t%s\n" "$dom" "$formatted_date"
            fi
        done
    fi

    # Traversal in standard certbot folders
    if [ -d /etc/letsencrypt/live ]; then
        for cdir in /etc/letsencrypt/live/*; do
            if [ -f "$cdir/fullchain.pem" ]; then
                local dom=$(basename "$cdir")
                local expire_date=$(openssl x509 -noout -enddate -in "$cdir/fullchain.pem" 2>/dev/null | awk -F'=' '{print $2}')
                local formatted_date=""
                if [ -n "$expire_date" ]; then
                    formatted_date=$(date -d "$expire_date" '+%Y-%m-%d' 2>/dev/null || date -j -f "%b %d %T %Y %Z" "$expire_date" "+%Y-%m-%d" 2>/dev/null || echo "$expire_date")
                fi
                printf "%-30s\t%s\n" "$dom" "$formatted_date"
            fi
        done
    fi
    echo -e "==============================================\n"
}

force_renewal() {
    echo -e "${gl_huang}Triggering certbot force renewal action...${gl_bai}"
    if command -v docker &>/dev/null && docker inspect nginx &>/dev/null; then
        docker stop nginx >/dev/null 2>&1
        docker run --rm -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot renew --force-renewal
        docker start nginx >/dev/null 2>&1
    else
        certbot renew --force-renewal 2>/dev/null || true
    fi
    # Re-copy files to active components
    if [ -d /home/web/certs ]; then
        for cdir in /etc/letsencrypt/live/*; do
            if [ -d "$cdir" ]; then
                domain=$(basename "$cdir")
                cp "/etc/letsencrypt/live/$domain/fullchain.pem" "/home/web/certs/${domain}_cert.pem" 2>/dev/null
                cp "/etc/letsencrypt/live/$domain/privkey.pem" "/home/web/certs/${domain}_key.pem" 2>/dev/null
            fi
        done
    fi
}

# Action loop
ssl_menu() {
    while true; do
        clear
        echo -e "${gl_kjlan}========================================================================${gl_bai}"
        echo -e "                 $(get_ssl_msg 'title')                                 "
        echo -e "${gl_kjlan}========================================================================${gl_bai}"
        echo -e "  ${gl_lv}1.${gl_bai} $(get_ssl_msg 'opt_1')"
        echo -e "  ${gl_lv}2.${gl_bai} $(get_ssl_msg 'opt_2')"
        echo -e "  ${gl_lv}3.${gl_bai} $(get_ssl_msg 'opt_3')"
        echo -e "  ${gl_lv}4.${gl_bai} $(get_ssl_msg 'opt_4')"
        echo -e "${gl_kjlan}------------------------------------------------------------------------${gl_bai}"
        echo -e "  ${gl_hong}0.${gl_bai} $(get_msg 'press_any_key')"
        echo -e "${gl_kjlan}========================================================================${gl_bai}"

        read -p "Selection: " sub_ch
        case "$sub_ch" in
            1) issue_letsencrypt_cert; break_end ;;
            2) import_custom_cert; break_end ;;
            3) list_expire_dates; break_end ;;
            4) force_renewal; break_end ;;
            0) return ;;
            *) echo -e "${gl_hong}$(get_msg 'invalid_selection')${gl_bai}"; sleep 2 ;;
        esac
    done
}

ssl_menu

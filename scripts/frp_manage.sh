#!/bin/bash
# scripts/frp_manage.sh
# FRP tunneling & Prometheus/Grafana Monitoring Stack
# Bilingual (CN / EN)

SCRIPT_PATH=$(dirname "$(readlink -f "$0")")
if [ -f "$SCRIPT_PATH/../lib/common.sh" ]; then
    . "$SCRIPT_PATH/../lib/common.sh"
elif [ -f "/tmp/vps-scripts/lib/common.sh" ]; then
    . "/tmp/vps-scripts/lib/common.sh"
fi

detect_language "$1"
require_root
install_pkgs curl wget openssl

get_frp_msg() {
    local key="$1"
    case "$LANG_ENV" in
        CN)
            case "$key" in
                "title") echo "FRP 穿透服務暨 Prometheus 監控告警面板" ;;
                "opt_1") echo "搭建安裝 FRP 穿透服務端(frps)容器及生成隨機配置" ;;
                "opt_2") echo "搭建安裝 FRP 穿透客戶端(frpc)" ;;
                "opt_3") echo "添加 FRP 新增端口映射端口服務進程" ;;
                "opt_4") echo "完全卸載清理 FRP 客戶/服務端" ;;
                "opt_5") echo "搭建 Prometheus + Grafana 服務器監控告警系統" ;;
                "opt_6") echo "卸載 Prometheus + Grafana 監控套件" ;;
                "enter_fserver") echo "請輸入遠端 FRPS 服務器公網 IP: " ;;
                "enter_token") echo "請輸入 FRPS 連接金鑰 Token: " ;;
                "local_port") echo "請輸入內網本機需要轉發的端口 (例: 80): " ;;
                "remote_port") echo "請輸入在公網服務器監聽的外網映射端口 (例: 8080): " ;;
                "frp_success") echo "FRP 容器設定完成！" ;;
                "mon_success") echo "Prometheus (端口 9090) 與 Grafana (端口 3000) 初始化成功。" ;;
            esac
            ;;
        *) # EN
            case "$key" in
                "title") echo "FRP Tunnel & Prometheus Monitoring Dashboard" ;;
                "opt_1") echo "Install FRP Server daemon (frps) & Config generation" ;;
                "opt_2") echo "Install FRP Client daemon (frpc)" ;;
                "opt_3") echo "Add new Port Forwarding Mapping rule to frpc" ;;
                "opt_4") echo "Uninstall/Clean FRP Server and Client completely" ;;
                "opt_5") echo "Install Prometheus + Grafana Web System Monitor" ;;
                "opt_6") echo "Uninstall Prometheus + Grafana Monitoring system" ;;
                "enter_fserver") echo "Enter Remote FRPS Public IP address: " ;;
                "enter_token") echo "Enter FRPS Connection security Token: " ;;
                "local_port") echo "Enter backend local port to map (e.g. 80): " ;;
                "remote_port") echo "Enter public listening port on FRPS server (e.g. 8080): " ;;
                "frp_success") echo "FRP container setup finished." ;;
                "mon_success") echo "Prometheus (Port 9090) & Grafana (Port 3000) successfully booted." ;;
            esac
            ;;
    esac
}

ensure_docker() {
    if ! command -v docker &>/dev/null; then
        echo -e "${gl_huang}Installing Docker Engine via setup script...${gl_bai}"
        curl -fsSL https://get.docker.com | bash
        systemctl enable docker && systemctl start docker
    fi
}

install_frps() {
    ensure_docker
    local bind_port=8055
    local dashboard_port=8056
    local token=$(openssl rand -hex 16)
    local d_user="admin"
    local d_pwd=$(openssl rand -hex 8)

    mkdir -p /home/frp
    cat <<EOF > /home/frp/frps.toml
[common]
bind_port = $bind_port
authentication_method = token
token = $token
dashboard_port = $dashboard_port
dashboard_user = $d_user
dashboard_pwd = $d_pwd
EOF

    docker stop frps-container 2>/dev/null
    docker rm frps-container 2>/dev/null
    docker run -d \
        --name frps-container \
        --restart=always \
        --network host \
        -v /home/frp/frps.toml:/frp/frps.toml \
        kjlion/frp:alpine \
        /frp/frps -c /frp/frps.toml

    get_ip_address
    echo -e "${gl_lv}$(get_frp_msg 'frp_success')${gl_bai}"
    echo "FRP Bind Port: $bind_port"
    echo "FRP Token: $token"
    echo "Dashboard URL: http://${public_ipv4:-$local_ipv4}:$dashboard_port"
    echo "User: $d_user | Password: $d_pwd"
}

install_frpc() {
    ensure_docker
    read -p "$(get_frp_msg 'enter_fserver')" server_ip
    read -p "$(get_frp_msg 'enter_token')" token
    if [[ -z "$server_ip" || -z "$token" ]]; then
        return
    fi

    mkdir -p /home/frp
    cat <<EOF > /home/frp/frpc.toml
[common]
server_addr = $server_ip
server_port = 8055
token = $token
EOF

    docker stop frpc-container 2>/dev/null
    docker rm frpc-container 2>/dev/null
    docker run -d \
        --name frpc-container \
        --restart=always \
        --network host \
        -v /home/frp/frpc.toml:/frp/frpc.toml \
        kjlion/frp:alpine \
        /frp/frpc -c /frp/frpc.toml

    echo -e "${gl_lv}$(get_frp_msg 'frp_success')${gl_bai}"
}

add_forward_rule() {
    read -p "Mapping rule name (e.g. ssh_forward): " m_name
    read -p "$(get_frp_msg 'local_port')" l_port
    read -p "$(get_frp_msg 'remote_port')" r_port
    if [[ -z "$m_name" || -z "$l_port" || -z "$r_port" ]]; then
        return
    fi

    if [ ! -f /home/frp/frpc.toml ]; then
        echo "frpc.toml file missing! Please install frpc first."
        return
    fi

    cat <<EOF >> /home/frp/frpc.toml

[$m_name]
type = tcp
local_ip = 127.0.0.1
local_port = $l_port
remote_port = $r_port
EOF

    docker restart frpc-container 2>/dev/null
    echo -e "${gl_lv}Success: Forwarding rule appended to client config.${gl_bai}"
}

uninstall_frp() {
    docker stop frps-container frpc-container 2>/dev/null
    docker rm frps-container frpc-container 2>/dev/null
    rm -rf /home/frp
    echo "FRP containers & configuration directories pruned."
}

install_monitoring() {
    ensure_docker
    mkdir -p /home/prometheus /home/grafana
    chown -R 472:472 /home/grafana

    cat <<EOF > /home/prometheus/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'node'
    static_configs:
      - targets: ['node-exporter:9100']
EOF

    docker network create monitor-net 2>/dev/null

    docker stop node-exporter prometheus grafana 2>/dev/null
    docker rm node-exporter prometheus grafana 2>/dev/null

    docker run -d --name node-exporter --restart always --network monitor-net prom/node-exporter:latest
    docker run -d --name prometheus --restart always --network monitor-net -p 9090:9090 -v /home/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml prom/prometheus:latest
    docker run -d --name grafana --restart always --network monitor-net -p 3000:3000 -v /home/grafana:/var/lib/grafana grafana/grafana:latest

    echo -e "${gl_lv}$(get_frp_msg 'mon_success')${gl_bai}"
}

uninstall_monitoring() {
    docker stop node-exporter prometheus grafana 2>/dev/null
    docker rm node-exporter prometheus grafana 2>/dev/null
    rm -rf /home/prometheus /home/grafana
    echo "Monitoring system container instances deleted."
}

frp_menu() {
    while true; do
        clear
        echo -e "${gl_kjlan}========================================================================${gl_bai}"
        echo -e "                 $(get_frp_msg 'title')                                 "
        echo -e "${gl_kjlan}========================================================================${gl_bai}"
        echo -e "  ${gl_lv}1.${gl_bai} $(get_frp_msg 'opt_1')"
        echo -e "  ${gl_lv}2.${gl_bai} $(get_frp_msg 'opt_2')"
        echo -e "  ${gl_lv}3.${gl_bai} $(get_frp_msg 'opt_3')"
        echo -e "  ${gl_lv}4.${gl_bai} $(get_frp_msg 'opt_4')"
        echo -e "${gl_kjlan}------------------------------------------------------------------------${gl_bai}"
        echo -e "  ${gl_lv}5.${gl_bai} $(get_frp_msg 'opt_5')"
        echo -e "  ${gl_lv}6.${gl_bai} $(get_frp_msg 'opt_6')"
        echo -e "${gl_kjlan}------------------------------------------------------------------------${gl_bai}"
        echo -e "  ${gl_hong}0.${gl_bai} $(get_msg 'press_any_key')"
        echo -e "${gl_kjlan}========================================================================${gl_bai}"

        read -p "Selection: " sub_ch
        case "$sub_ch" in
            1) install_frps; break_end ;;
            2) install_frpc; break_end ;;
            3) add_forward_rule; break_end ;;
            4) uninstall_frp; break_end ;;
            5) install_monitoring; break_end ;;
            6) uninstall_monitoring; break_end ;;
            0) return ;;
            *) echo -e "${gl_hong}$(get_msg 'invalid_selection')${gl_bai}"; sleep 2 ;;
        esac
    done
}

frp_menu

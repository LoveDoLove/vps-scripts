#!/bin/bash
# scripts/docker_manage.sh
# Docker Management - Install, manage containers, images, and Docker Compose
# Author: LoveDoLove

# Color definitions
gl_hong='\033[31m'
gl_lv='\033[32m'
gl_huang='\033[33m'
gl_lan='\033[34m'
gl_kjlan='\033[96m'
gl_bai='\033[0m'
gl_bold='\033[1m'

# Check if Docker is installed
check_docker_installed() {
    if command -v docker &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Show Docker status
show_docker_status() {
    echo -e "\n${gl_bold}${gl_kjlan}============ Docker Status ============${gl_bai}"
    if check_docker_installed; then
        local docker_version
        docker_version=$(docker --version 2>/dev/null)
        echo -e "  Docker:              ${gl_lv}Installed${gl_bai}"
        echo -e "  Version:             ${gl_lan}$docker_version${gl_bai}"

        if systemctl is-active docker &>/dev/null; then
            echo -e "  Service Status:      ${gl_lv}Running${gl_bai}"
        else
            echo -e "  Service Status:      ${gl_hong}Stopped${gl_bai}"
        fi

        # Docker Compose check
        if docker compose version &>/dev/null; then
            local compose_version
            compose_version=$(docker compose version 2>/dev/null)
            echo -e "  Docker Compose:      ${gl_lv}$compose_version${gl_bai}"
        elif command -v docker-compose &>/dev/null; then
            local compose_version
            compose_version=$(docker-compose --version 2>/dev/null)
            echo -e "  Docker Compose:      ${gl_lv}$compose_version${gl_bai}"
        else
            echo -e "  Docker Compose:      ${gl_hong}Not Installed${gl_bai}"
        fi

        # Container count
        local running_count total_count
        running_count=$(docker ps -q 2>/dev/null | wc -l)
        total_count=$(docker ps -aq 2>/dev/null | wc -l)
        echo -e "  Containers:          ${gl_lan}$running_count running / $total_count total${gl_bai}"

        # Image count
        local image_count
        image_count=$(docker images -q 2>/dev/null | wc -l)
        echo -e "  Images:              ${gl_lan}$image_count${gl_bai}"

        # Docker disk usage
        local disk_usage
        disk_usage=$(docker system df 2>/dev/null | tail -n +2)
        if [ -n "$disk_usage" ]; then
            echo -e "\n  ${gl_huang}Disk Usage:${gl_bai}"
            echo "$disk_usage"
        fi
    else
        echo -e "  Docker:              ${gl_hong}Not Installed${gl_bai}"
    fi
    echo -e "${gl_kjlan}========================================${gl_bai}"
}

# Install Docker
install_docker() {
    if check_docker_installed; then
        echo -e "${gl_lv}Docker is already installed.${gl_bai}"
        return 0
    fi

    echo -e "${gl_huang}Installing Docker...${gl_bai}"

    if command -v curl &>/dev/null; then
        curl -fsSL https://get.docker.com | sh
    elif command -v wget &>/dev/null; then
        wget -qO- https://get.docker.com | sh
    else
        echo -e "${gl_hong}Neither curl nor wget is available. Please install one first.${gl_bai}"
        return 1
    fi

    # Start and enable Docker service
    systemctl start docker 2>/dev/null
    systemctl enable docker 2>/dev/null

    if check_docker_installed; then
        echo -e "${gl_lv}Docker installed successfully.${gl_bai}"
        docker --version
    else
        echo -e "${gl_hong}Docker installation failed.${gl_bai}"
        return 1
    fi
}

# Uninstall Docker
uninstall_docker() {
    if ! check_docker_installed; then
        echo -e "${gl_huang}Docker is not installed.${gl_bai}"
        return 0
    fi

    echo -e "${gl_hong}WARNING: This will remove Docker and all containers/images!${gl_bai}"
    read -p "Are you sure? (y/N): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo -e "${gl_huang}Cancelled.${gl_bai}"
        return 0
    fi

    echo -e "${gl_huang}Stopping Docker service...${gl_bai}"
    systemctl stop docker 2>/dev/null
    systemctl disable docker 2>/dev/null

    echo -e "${gl_huang}Removing Docker...${gl_bai}"
    if command -v apt &>/dev/null; then
        apt remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null
        apt purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null
        apt autoremove -y 2>/dev/null
    elif command -v dnf &>/dev/null; then
        dnf remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null
    elif command -v yum &>/dev/null; then
        yum remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null
    fi

    rm -rf /var/lib/docker /var/lib/containerd /etc/docker

    echo -e "${gl_lv}Docker has been removed.${gl_bai}"
}

# List containers
list_containers() {
    if ! check_docker_installed; then
        echo -e "${gl_hong}Docker is not installed.${gl_bai}"
        return 1
    fi

    echo -e "\n${gl_bold}${gl_kjlan}============ Running Containers ============${gl_bai}"
    docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
    echo -e "\n${gl_bold}${gl_kjlan}============ All Containers ============${gl_bai}"
    docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}"
}

# Start/stop/restart a container
manage_container() {
    local action="$1"
    if ! check_docker_installed; then
        echo -e "${gl_hong}Docker is not installed.${gl_bai}"
        return 1
    fi

    echo -e "\n${gl_huang}Current containers:${gl_bai}"
    docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"
    echo ""
    read -p "Enter container name or ID: " container_id

    if [ -z "$container_id" ]; then
        echo -e "${gl_hong}No container specified.${gl_bai}"
        return 1
    fi

    case $action in
        start)
            echo -e "${gl_huang}Starting container $container_id...${gl_bai}"
            docker start "$container_id"
            ;;
        stop)
            echo -e "${gl_huang}Stopping container $container_id...${gl_bai}"
            docker stop "$container_id"
            ;;
        restart)
            echo -e "${gl_huang}Restarting container $container_id...${gl_bai}"
            docker restart "$container_id"
            ;;
        remove)
            echo -e "${gl_hong}Removing container $container_id...${gl_bai}"
            docker rm -f "$container_id"
            ;;
        logs)
            echo -e "${gl_huang}Showing logs for $container_id (last 50 lines)...${gl_bai}"
            docker logs --tail 50 "$container_id"
            ;;
    esac
}

# Manage images
manage_images() {
    if ! check_docker_installed; then
        echo -e "${gl_hong}Docker is not installed.${gl_bai}"
        return 1
    fi

    echo -e "\n${gl_bold}${gl_kjlan}============ Docker Images ============${gl_bai}"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}"
}

# Remove unused images
prune_images() {
    if ! check_docker_installed; then
        echo -e "${gl_hong}Docker is not installed.${gl_bai}"
        return 1
    fi

    echo -e "${gl_huang}Removing unused Docker images...${gl_bai}"
    docker image prune -af
    echo -e "${gl_lv}Unused images removed.${gl_bai}"
}

# Docker system cleanup
docker_cleanup() {
    if ! check_docker_installed; then
        echo -e "${gl_hong}Docker is not installed.${gl_bai}"
        return 1
    fi

    echo -e "${gl_hong}WARNING: This will remove all unused containers, networks, images, and build cache!${gl_bai}"
    read -p "Are you sure? (y/N): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo -e "${gl_huang}Cancelled.${gl_bai}"
        return 0
    fi

    echo -e "${gl_huang}Cleaning up Docker system...${gl_bai}"
    docker system prune -af --volumes
    echo -e "${gl_lv}Docker system cleanup complete.${gl_bai}"
}

# Main menu
docker_menu() {
    while true; do
        echo ""
        echo -e "${gl_bold}${gl_kjlan}============ Docker Management ============${gl_bai}"
        echo -e "  ${gl_lv}1.${gl_bai} Show Docker Status"
        echo -e "  ${gl_lv}2.${gl_bai} Install Docker"
        echo -e "  ${gl_lv}3.${gl_bai} Uninstall Docker"
        echo -e "${gl_kjlan}  --- Container Management ---${gl_bai}"
        echo -e "  ${gl_lv}4.${gl_bai} List Containers"
        echo -e "  ${gl_lv}5.${gl_bai} Start a Container"
        echo -e "  ${gl_lv}6.${gl_bai} Stop a Container"
        echo -e "  ${gl_lv}7.${gl_bai} Restart a Container"
        echo -e "  ${gl_lv}8.${gl_bai} Remove a Container"
        echo -e "  ${gl_lv}9.${gl_bai} View Container Logs"
        echo -e "${gl_kjlan}  --- Image Management ---${gl_bai}"
        echo -e "  ${gl_lv}10.${gl_bai} List Images"
        echo -e "  ${gl_lv}11.${gl_bai} Remove Unused Images"
        echo -e "  ${gl_lv}12.${gl_bai} Docker System Cleanup"
        echo ""
        echo -e "  ${gl_hong}0.${gl_bai} Return to Main Menu"
        echo -e "${gl_kjlan}===========================================${gl_bai}"
        read -p "Please enter your choice: " choice

        case $choice in
            1) show_docker_status ;;
            2) install_docker ;;
            3) uninstall_docker ;;
            4) list_containers ;;
            5) manage_container "start" ;;
            6) manage_container "stop" ;;
            7) manage_container "restart" ;;
            8) manage_container "remove" ;;
            9) manage_container "logs" ;;
            10) manage_images ;;
            11) prune_images ;;
            12) docker_cleanup ;;
            0) return ;;
            *) echo -e "${gl_hong}Invalid option!${gl_bai}" ;;
        esac

        echo ""
        echo -e "${gl_huang}Press any key to continue...${gl_bai}"
        read -n 1 -s
        clear
    done
}

docker_menu

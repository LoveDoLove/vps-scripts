# Docker App Store

Module option **7** from the main menu. One-click deployment of popular Docker
applications with automatic port collision detection.

## Available Applications

| # | Application | Default Port | Description |
|---|-------------|-------------|-------------|
| 1 | **MySQL** | 3306 | Relational database server with configurable root password |
| 2 | **Redis** | 6379 | In-memory caching server with optional password |
| 3 | **phpMyAdmin** | 8080 | Web-based MySQL/MariaDB administration interface |
| 4 | **Nginx Proxy Manager** | 80/81/443 | Web-based Nginx reverse proxy management console |
| 5 | **Portainer** | 8000/9443 | Docker container visual management UI |
| 6 | **1Panel** | — | Next-gen Linux server operations panel (uses official installer) |
| 7 | **Node.js / Python Sandbox** | — | CLI workspace containers (no ports exposed) |
| 8 | **WordPress Stack** | 8000 | WordPress + MySQL via Docker Compose |
| 9 | **PostgreSQL + pgAdmin** | 5432/5050 | Postgres database with pgAdmin web console |
| 10 | **Standalone Nginx** | 8081 | Lightweight static web server |
| 11 | **Vaultwarden** | 8088 | Self-hosted Bitwarden-compatible password manager |

## Key Features

- **Port collision detection** — `check_port_taken()` verifies ports before binding
- **Auto Docker install** — `ensure_docker()` installs Docker if missing
- **Random passwords** — auto-generated secure passwords when not specified
- **Restart policy** — all containers run with `--restart always`

## Script

`scripts/app_store.sh`

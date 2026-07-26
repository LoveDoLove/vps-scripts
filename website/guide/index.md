# Introduction

VPS Scripts is a comprehensive, modular VPS operations toolkit. The original monolithic
scriptbase was completely refactored into a modular architecture with full bilingual support
(Traditional Chinese / English).

## Philosophy

- **Do one thing well** — each script handles one domain
- **Run anywhere** — one-liner remote execution, no permanent install needed
- **Speak your language** — full bilingual UI, auto-detected from system locale
- **Docker-first** — app store and web stack built on containers with port safety checks

## Architecture

```
vps-scripts/
├── main.sh          # Interactive menu entrypoint
├── lib/
│   └── common.sh    # Colors, package managers, translations, utilities
├── scripts/
│   ├── system_tools.sh
│   ├── firewall_manage.sh
│   ├── kernel_manage.sh
│   ├── ssl_manage.sh
│   ├── web_manage.sh
│   ├── docker_manage.sh
│   ├── app_store.sh     # 11 one-click Docker deployments
│   ├── frp_manage.sh
│   ├── backup_manage.sh
│   ├── test_scripts.sh
│   ├── warp_manage.sh
│   ├── dd_system.sh
│   ├── oracle_cloud.sh
│   └── system_info.sh   # Dashboard display
└── images/
    └── logo.png
```

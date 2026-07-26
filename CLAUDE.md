# LoveDoLove VPS Management Toolkit

A comprehensive, modular VPS management toolkit with bilingual (Chinese/English) support. Automates VPS setup, management, and maintenance through an interactive menu system.

GitHub: https://github.com/LoveDoLove/vps-scripts

## Architecture

- **`main.sh`** — Main entry point. Interactive numbered menu for all 14 modules.
- **`lib/common.sh`** — Shared core library (colors, package manager detection, bilingual i18n, system checks).
- **`scripts/*.sh`** — Modular functional scripts, each handling one domain.
- **`website/`** — VitePress documentation site (EN + ZH), deployed to Cloudflare Pages.
- **`memory/`** — Project knowledge and memory files.

## Tech Stack

- **Runtime:** Bash (POSIX `/bin/bash`)
- **Package managers:** apt (Debian/Ubuntu), dnf/yum (RHEL/Rocky/AlmaLinux/CentOS), apk (Alpine)
- **Containers:** Docker, Docker Compose
- **Documentation:** VitePress ^1.6.0, pnpm, Wrangler 4.x
- **Deployment:** Cloudflare Pages (via `wrangler pages deploy`)
- **License:** MIT

## Operational Standards

1. **Modular Principles** — No individual script under `scripts/*.sh` should declare local color variables (`gl_hong`, `gl_lv`, etc.) or re-implement base package manager routines. All standard terminal formatting, colors, package operations, and system dependency validations MUST import `lib/common.sh`.

2. **Bilingual Localization** — The UI must support both Traditional Chinese (CN) and English (EN) regions. Localized text must hook into `get_msg "key"` in `lib/common.sh` or module-level bilingual translation functions.

3. **Portability / Unix Compatibility** — Shell scripts must use POSIX-compliant `/bin/bash` shebangs and be verified across Debian/Ubuntu (apt), RHEL/Rocky/AlmaLinux/CentOS (dnf/yum), and Alpine Linux (apk/rc-service).

4. **Security Warnings** — When modifying critical network settings (SSH port changes, firewall flushes, DD OS replacements), always print explicit warning strings about cloud provider firewalls to prevent server disconnections.

5. **GH_PROXY Configuration** — Default proxy is `https://gh.kejilion.pro/` in `lib/common.sh` for optimizing GitHub raw file downloads in mainland China. Must be handled across all modules.

6. **Docker App Store Extensions** — `scripts/app_store.sh` contains one-click templates for MySQL, Redis, phpMyAdmin, Nginx Proxy Manager, Portainer, 1Panel, Sandboxed Environments (Node/Python CLI), WordPress Stack, Postgres+pgAdmin, Standalone Nginx, and Vaultwarden. New templates must conform to containerized isolation best practices.

7. **Oracle Cloud Integration** — Oracle Cloud configs (`scripts/oracle_cloud.sh`) are under Option 13 in `main.sh`. Local ports config, live growth partitions, oracle agents cleaning, and DD network tools installer paths must use standard helpers and support Chinese/English output.

## Commands

- **Preview documentation site:** `cd website && pnpm run docs:dev`
- **Build documentation:** `cd website && pnpm run docs:build`
- **Deploy documentation:** `cd website && pnpm run docs:deploy`
- **Run toolkit:** `bash main.sh`
- **Remote load:** `bash <(curl -sL https://raw.githubusercontent.com/LoveDoLove/vps-scripts/main/main.sh)`

## Custom Agents

Custom agent definitions are in [AGENTS.md](AGENTS.md) and `.claude/agents/`. Use `/agent-name` to invoke a specific agent.

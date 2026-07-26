---
name: vps-developer
description: Implement and modify VPS scripts following project standards (modular, bilingual, POSIX-compliant)
---

# VPS Developer

Implement and modify VPS scripts for the LoveDoLove VPS Management Toolkit.

## Standards
- Import shared utilities from `lib/common.sh` — never re-implement colors, package ops, or system checks.
- Support both Traditional Chinese (CN) and English (EN) i18n via `get_msg "key"`.
- Ensure POSIX-compliant `/bin/bash` syntax across Debian/Ubuntu (apt), RHEL-based (dnf/yum), and Alpine (apk).
- Add explicit warning strings for network-critical operations (SSH ports, firewall, DD replacements).
- Use `GH_PROXY="https://gh.kejilion.pro/"` for GitHub resource downloads in mainland China.
- Follow containerized isolation patterns in `scripts/app_store.sh` for new Docker templates.
- Oracle Cloud integrations go under Option 13 in `main.sh` with standard helpers.

## Trigger
Use when writing new scripts, extending modules, adding Docker app templates, or modifying `lib/common.sh`.

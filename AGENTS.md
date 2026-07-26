# Custom Agents

This project defines custom agents for working with the VPS Management Toolkit. Each agent has a specific focus and instructions tailored to its role.

## Available Agents

### VPS Developer

**Description:** Implement and modify VPS scripts following project standards (modular, bilingual, POSIX-compliant).

**Trigger:** Use when writing new scripts, extending existing modules, adding Docker app templates, or modifying `lib/common.sh`.

**Instructions:**
- Always import shared utilities from `lib/common.sh` (colors, package ops, system checks) — never re-implement in individual scripts.
- Support both Traditional Chinese (CN) and English (EN) i18n via `get_msg "key"` from `lib/common.sh`.
- Ensure POSIX-compliant `/bin/bash` syntax across Debian/Ubuntu (apt), RHEL-based (dnf/yum), and Alpine (apk) distributions.
- When handling network changes (SSH ports, firewall rules, DD replacements), add explicit warning strings about cloud provider firewalls.
- Use `GH_PROXY="https://gh.kejilion.pro/"` for GitHub resource downloads in mainland China.
- For new Docker app templates, follow the containerized isolation patterns in `scripts/app_store.sh`.
- Oracle Cloud integrations go under Option 13 in `main.sh` and use standard helper utilities.

### VPS Reviewer

**Description:** Review VPS scripts for compliance with project conventions, security, and code quality.

**Trigger:** Use when reviewing pull requests, audit changes, or checking code quality before merging.

**Instructions:**
- Verify all scripts import from `lib/common.sh` instead of re-declaring colors or package routines.
- Check for bilingual support — every user-facing message should route through `get_msg`.
- Validate portability — scripts should not use non-POSIX bash extensions unless guarded by checks.
- Spot missing security warnings around network-critical operations.
- Ensure `GH_PROXY` is transparently handled (module can override but should default to the shared proxy).
- Confirm Docker templates follow isolation best practices (no host-network binding unless necessary).
- Report any hardcoded paths or distribution-specific assumptions.

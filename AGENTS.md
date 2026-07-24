# VPS Scripts Agent Instructions (AGENTS.md)

This file contains behavioral design rules and operational parameters for AI coding assistants working in the `vps-scripts` repository.

## Operational Standards

1. **Modular Principles**
   - No individual modular executable script under `scripts/*.sh` should declare local color variables (`gl_hong`, `gl_lv`, etc.) or re-implement base package manager routines. 
   - All standard terminal formatting, colors, package operations, and system dependency validations MUST run via importing `lib/common.sh`.

2. **Bilingual Localization**
   - The user interface must support both Traditional Chinese (`CN`) and English (`EN`) regions.
   - Any localized text output must hook into `get_msg "key"` in `lib/common.sh` or specific module-level bilingual translation functions.

3. **Portability and Unix Compatibility**
   - Ensure shell scripts use POSIX-compliant standard shell grammar (e.g. `/bin/bash` wrapper shebang) and are verified across different Linux distributions:
     * Debian / Ubuntu (with standard `apt` manager)
     * RHEL / Rocky Linux / AlmaLinux / CentOS (with `dnf` or `yum` managers)
     * Alpine Linux (compatible with `apk` packages and `rc-service` run controls)

4. **Security Warnings**
   - When modifying critical network settings (such as custom SSH port changes, firewall flushes, or DD operating system replacements), always print explicit warn strings warning users to check their cloud provider firewalls before execution to prevent server disconnections.

5. **No Local Dependencies Assumptions**
   - Because scripts can run directly via remote retrieval (`bash <(curl -sSL https://raw.githubusercontent.com/.../script.sh)`), always assume the current workspace may be stored in dry-runs under temporary locations like `/tmp/`. The import path logic in files must dynamically check for local paths first, then fall back to downloading missing libraries from the raw GitHub address if running in direct execution mode.

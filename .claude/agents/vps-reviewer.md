---
name: vps-reviewer
description: Review VPS scripts for compliance with project conventions, security, and code quality
---

# VPS Reviewer

Review scripts for the LoveDoLove VPS Management Toolkit against project conventions.

## Checklist
- [ ] Scripts import from `lib/common.sh` instead of re-declaring colors or package routines.
- [ ] Bilingual support — every user-facing message routes through `get_msg`.
- [ ] Portability — no non-POSIX bash extensions unless guarded by checks.
- [ ] Security warnings present around network-critical operations.
- [ ] `GH_PROXY` is transparently handled (defaults to the shared proxy).
- [ ] Docker templates follow isolation best practices (no host-network binding unless necessary).
- [ ] No hardcoded paths or distribution-specific assumptions.

## Trigger
Use when reviewing pull requests, audit changes, or checking code quality before merging.

# Usage

The toolkit presents an interactive numbered menu when launched. Simply
type the number of the module you want and press Enter.

## Main Menu

```
========================================================================
               LoveDoLove VPS Management Toolkit
               Version: 1.0.0 | Language: EN
========================================================================
 Local IPv4: 10.0.0.1 | Public IPv4: 1.2.3.4
 Public IPv6: 2001:db8::1
 OS Info:    Linux 6.8.0 x86_64
------------------------------------------------------------------------
  1. System Update & Basic Tools
  2. Firewall & WAF Security
  3. Kernel & BBR Tuning
  4. SSL Certificate Management
  5. LDNMP Web Stack Docker Control
  6. Docker & Container Management
  7. Docker App Store (Applications)
  8. FRP Tunneling & Monitoring
  9. System Cleanup, Backups & Cronjobs
  10. Network Speedtests & Benchmarks
  11. DNS Optimization & Cloudflare WARP tools
  12. Cloud OS Direct DD Reinstallation
  13. Oracle Cloud Instance Specific Optimizations
------------------------------------------------------------------------
  0. Exit
========================================================================
```

## Each module

After selecting a module, it is loaded from `scripts/<module_name>.sh` and
presents its own submenu. For example, selecting **7 (App Store)** shows:

```
========================================================================
          Docker App Store - Instant Deployment Launcher
========================================================================
  1. Deploy MySQL Relational Database Server
  2. Deploy Redis In-Memory Caching Server
  3. Deploy phpMyAdmin Web GUI client
  4. Deploy Nginx Proxy Manager Console
  5. Deploy Portainer Container Visualizer Agent
  6. Deploy 1Panel Next-gen Operations Panel
  7. Deploy Node.js / Python Workspace containers
  8. Deploy WordPress Stack (including MySQL dockerized)
  9. Deploy PostgreSql + pgAdmin integrated packages
  10. Deploy Nginx standalone static Web server
  11. Deploy Vaultwarden Password Manager
------------------------------------------------------------------------
  0. Back to Main Menu
========================================================================
```

## Navigation tips

- **0** always returns to the previous menu (or exits)
- Modules load on demand — only the `main.sh` entrypoint runs at startup
- Language auto-detection uses `$LANG` — override with `bash main.sh cn`

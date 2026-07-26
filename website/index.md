---
# https://vitepress.dev/reference/default-theme-home-page
layout: home

hero:
  name: "VPS Scripts"
  text: "Modular VPS Management Toolkit"
  tagline: One-command server ops with bilingual support — system tools, firewall, SSL, Docker, kernel tuning, and more
  image:
    src: /logo.png
    alt: VPS Scripts Logo
  actions:
    - theme: brand
      text: Get Started
      link: /guide/
    - theme: alt
      text: View on GitHub
      link: https://github.com/LoveDoLove/vps-scripts
    - theme: brand
      text: Run Now →
      link: /guide/installation#remote-one-liner

features:
  - icon: 🧩
    title: Modular Architecture
    details: Each feature is its own script under scripts/, loaded on demand from the central main.sh menu.
  - icon: 🌐
    title: Bilingual by Default
    details: Auto-detects your system language ($LANG) and renders all menus in English or Traditional Chinese.
  - icon: ⚡
    title: One-Command Run
    details: No download needed — run directly from GitHub with bash &lt;(curl -fsSL ...).
  - icon: 🐳
    title: Docker App Store
    details: One-click deploy MySQL, Redis, WordPress, Nginx Proxy Manager, Portainer, and more with port collision detection.
  - icon: 🖥️
    title: Cross-Distro Compatible
    details: Verified on Debian, Ubuntu, RHEL, Rocky, Alma, CentOS, Alpine, Arch, openSUSE, and more.
  - icon: 🔒
    title: Security First
    details: Built-in firewall management, WAF, DDoS protection, geo-blocking (ipset), and SSL auto-renewal.
---

## Quick Start

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/LoveDoLove/vps-scripts/main/main.sh)
```

Press a number to select a module — it's that simple.

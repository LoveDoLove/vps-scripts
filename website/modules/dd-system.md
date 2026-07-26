# DD System Reinstallation

Module option **12** from the main menu.

## Features

- **Linux reinstall** — one-click DD (disk dump) reinstall to a clean Linux distribution
- **Windows reinstall** — DD reinstall to Windows Server or desktop editions
- **Custom ISO** — support for custom DD images via URL
- **Architecture selection** — choose between x86_64 and ARM64
- **Network restore** — automatic network configuration after reinstall

## Warning

This operation **destroys all data** on the server. Ensure you have backups
and that your cloud provider's out-of-band console (VNC/iKVM) is accessible
before proceeding.

## Script

`scripts/dd_system.sh`

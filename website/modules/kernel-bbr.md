# Kernel & BBR Tuning

Module option **3** from the main menu.

## Features

- **TCP BBR** — enable Google's BBR congestion control algorithm
- **XanMod kernel** — install a high-performance third-party kernel with BBRv3 support
- **ELRepo kernel** — upgrade to the latest mainline kernel via ELRepo (RHEL-based distros)
- **Queue algorithm** — configure `fq` or `fq_codel` as the default qdisc

## Script

`scripts/kernel_manage.sh`

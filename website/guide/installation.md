# Installation

## Prerequisites

- **Root access** — most operations require `root` privileges
- **curl** or **wget** — for remote module loading
- **Docker** (optional) — required for App Store and LDNMP features

## Option 1: Remote one-liner (recommended)

No download or install needed. Run directly from GitHub:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/LoveDoLove/vps-scripts/main/main.sh)
```

The toolkit auto-detects your system language. To force a specific language:

```bash
# Force English
bash <(curl -fsSL https://raw.githubusercontent.com/LoveDoLove/vps-scripts/main/main.sh) en

# Force Chinese
bash <(curl -fsSL https://raw.githubusercontent.com/LoveDoLove/vps-scripts/main/main.sh) cn
```

## Option 2: Clone and run locally

```bash
git clone https://github.com/LoveDoLove/vps-scripts.git
cd vps-scripts
chmod +x main.sh scripts/*.sh lib/*.sh
bash main.sh
```

## Option 3: Single-module execution

Each script under `scripts/` can be run independently:

```bash
bash scripts/docker_manage.sh
bash scripts/app_store.sh
```

Note: scripts source `lib/common.sh` from their relative path. If running from
outside the project directory, they fall back to a `/tmp/vps-scripts` download.

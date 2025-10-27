echo -e "${gl_huang}正在系统更新...${gl_bai}"
if command -v dnf &>/dev/null; then
    dnf -y update
    elif command -v yum &>/dev/null; then
    yum -y update
    elif command -v apt &>/dev/null; then
    fix_dpkg
    DEBIAN_FRONTEND=noninteractive apt update -y
    DEBIAN_FRONTEND=noninteractive apt full-upgrade -y
    elif command -v apk &>/dev/null; then
    apk update && apk upgrade
    elif command -v pacman &>/dev/null; then
    pacman -Syu --noconfirm
    elif command -v zypper &>/dev/null; then
    zypper refresh
    zypper update
    elif command -v opkg &>/dev/null; then
    opkg update
else
    echo "未知的包管理器!"
    return
fi
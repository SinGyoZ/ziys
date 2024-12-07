#!/usr/bin/env bash

set -e

# 检查是否以 root 权限运行
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Please use sudo or run as root."
    exit 1
fi

# 更新和安装基本工具
echo "开始执行更新和基础工具安装..."
apt update && apt upgrade -y
timedatectl set-timezone Asia/Shanghai

echo "安装必要的工具: wget, curl, sudo, chrony, btrfs-progs, dos2unix, ufw, jq..."
apt install -y wget curl sudo chrony btrfs-progs dos2unix ufw jq

# 禁用 ufw 防火墙
echo "禁用 ufw 防火墙..."
ufw disable

# 配置系统网络参数
echo "配置系统网络参数: 启用 BBR 拥塞控制和 fq 默认队列..."
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p

# 显示当前 TCP 拥塞控制
sysctl net.ipv4.tcp_available_congestion_control
lsmod | grep bbr
lsmod | grep fq

# 安装 gpg（如果尚未安装）
if ! command -v gpg &>/dev/null; then
    echo "gpg 未安装，正在安装..."
    apt-get install -y gnupg
fi

# 显示 GPG 密钥信息
echo "下载并显示 GPG 密钥信息..."
curl -fsSL https://pkgs.zabbly.com/key.asc | gpg --show-keys --fingerprint

# 创建目录并下载密钥
echo "创建密钥目录并下载密钥..."
mkdir -p /etc/apt/keyrings/
curl -fsSL https://pkgs.zabbly.com/key.asc -o /etc/apt/keyrings/zabbly.asc

# 添加 apt 源（Stable）
echo "添加 Incus 源..."
cat <<EOF >/etc/apt/sources.list.d/zabbly-incus-stable.sources
Enabled: yes
Types: deb
URIs: https://pkgs.zabbly.com/incus/stable
Suites: $(. /etc/os-release && echo ${VERSION_CODENAME})
Components: main
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/zabbly.asc
EOF

# 更新软件包列表并安装 incus
echo "更新软件包列表并安装 incus..."
apt-get update
apt-get install -y incus

echo "Incus 安装完成"

# 提示用户进一步操作
echo "
安装完成后，您可以按照以下教程初始化 Incus：
https://linuxcontainers.org/incus/docs/main/tutorial/first_steps/

如果您希望避免使用 sudo 来运行 Incus，可以将您的用户添加到 incus-admin 组。
运行以下命令：

    sudo usermod -aG incus-admin \$USER

添加后，您需要注销并重新登录以使更改生效。
"

echo "脚本执行完成！"

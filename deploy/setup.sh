#!/bin/bash
set -e

echo "=========================================="
echo " SnapShop 服务器环境初始化"
echo "=========================================="

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "无法检测操作系统，仅支持 Ubuntu/Debian/CentOS"
    exit 1
fi

echo "[1/5] 更新系统包..."
case $OS in
    ubuntu|debian)
        apt-get update -y && apt-get upgrade -y
        ;;
    centos|rhel)
        yum update -y
        ;;
    *)
        echo "不支持的操作系统: $OS"
        exit 1
        ;;
esac

echo "[2/5] 安装 Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com | bash
    systemctl enable docker
    systemctl start docker
    echo "Docker 安装完成"
else
    echo "Docker 已安装，跳过"
fi

echo "[3/5] 安装 Docker Compose..."
if ! command -v docker &> /dev/null; then
    echo "Docker 未安装，请先安装 Docker"
    exit 1
fi

if ! docker compose version &> /dev/null 2>&1; then
    echo "正在安装 Docker Compose 插件..."
    case $OS in
        ubuntu|debian)
            apt-get install -y docker-compose-plugin
            ;;
        centos|rhel)
            yum install -y docker-compose-plugin
            ;;
    esac
fi
echo "Docker Compose 版本: $(docker compose version)"

echo "[4/5] 配置防火墙..."
if command -v ufw &> /dev/null; then
    ufw allow 22/tcp
    ufw allow 80/tcp
    ufw --force enable
    echo "UFW 防火墙已配置 (开放 22, 80 端口)"
elif command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-service=ssh
    firewall-cmd --permanent --add-port=80/tcp
    firewall-cmd --reload
    echo "firewalld 已配置 (开放 22, 80 端口)"
else
    echo "警告: 未检测到防火墙，请确保云服务器安全组已开放 22 和 80 端口"
fi

echo "[5/5] 系统优化..."
sysctl -w vm.overcommit_memory=1
echo "vm.overcommit_memory=1" >> /etc/sysctl.conf

echo ""
echo "=========================================="
echo " 环境初始化完成!"
echo "=========================================="
echo ""
echo "下一步:"
echo "  1. 将项目上传到 /opt/snapshop"
echo "  2. cd /opt/snapshop/backend"
echo "  3. cp .env.production .env && nano .env"
echo "  4. bash ../deploy/deploy.sh"

#!/bin/bash
set -e

# ============================================================
#  SnapShop 一键部署脚本
#  在全新的云服务器上运行此脚本即可完成全部部署
#
#  用法:
#    方式1 (服务器已克隆项目):
#      cd /opt/snapshop && bash bootstrap.sh
#
#    方式2 (远程一键):
#      curl -fsSL https://raw.githubusercontent.com/for2006/AI-Shopping/main/bootstrap.sh | bash -s -- --ghcr-user=for2006
#
#  选项:
#    --ghcr-user=NAME       GitHub 用户名 (拉取 GHCR 镜像, 默认: for2006)
#    --ghcr-token=TOKEN     GitHub PAT (私有镜像需要, 也可用环境变量 GITHUB_TOKEN)
#    --build                本地构建镜像 (不使用 GHCR)
#    --non-interactive      非交互模式, 自动生成密码
#    --project-dir=PATH     项目目录 (默认: /opt/snapshop)
# ============================================================

# ── 解析参数 ──────────────────────────────────────────────
GHCR_USER="for2006"
GHCR_TOKEN="${GITHUB_TOKEN:-}"
BUILD_LOCAL=false
NON_INTERACTIVE=false
PROJECT_DIR="/opt/snapshop"

for arg in "$@"; do
    case $arg in
        --ghcr-user=*)   GHCR_USER="${arg#*=}" ;;
        --ghcr-token=*)  GHCR_TOKEN="${arg#*=}" ;;
        --build)         BUILD_LOCAL=true ;;
        --non-interactive) NON_INTERACTIVE=true ;;
        --project-dir=*) PROJECT_DIR="${arg#*=}" ;;
        *) echo "未知参数: $arg"; exit 1 ;;
    esac
done

# ── 颜色 ──────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[x]${NC} $1"; exit 1; }

echo ""
echo "=============================================="
echo "  SnapShop — 一键部署"
echo "=============================================="
echo ""

# ── 权限检查 ──────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
    error "请以 root 身份运行: sudo bash bootstrap.sh"
fi

# ── 操作系统检测 ──────────────────────────────────────────
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    error "无法检测操作系统"
fi

case $OS in
    ubuntu|debian) PKG_MGR="apt-get" ;;
    centos|rhel|fedora) PKG_MGR="yum" ;;
    *) error "不支持的操作系统: $OS (仅支持 Ubuntu/Debian/CentOS)" ;;
esac
info "检测到操作系统: $OS"

# ── 1. 安装 Docker ───────────────────────────────────────
info "[1/7] 安装 Docker..."
if command -v docker &> /dev/null; then
    info "Docker 已安装, 跳过"
else
    curl -fsSL https://get.docker.com | bash
    systemctl enable docker
    systemctl start docker
    info "Docker 安装完成"
fi

# ── 2. 安装 Docker Compose ───────────────────────────────
info "[2/7] 安装 Docker Compose..."
if docker compose version &> /dev/null 2>&1; then
    info "Docker Compose 已安装, 跳过"
else
    case $OS in
        ubuntu|debian) apt-get install -y docker-compose-plugin ;;
        centos|rhel|fedora) yum install -y docker-compose-plugin ;;
    esac
    info "Docker Compose 安装完成"
fi

# ── 3. 安装 Git ──────────────────────────────────────────
info "[3/7] 确保 Git 可用..."
if ! command -v git &> /dev/null; then
    case $OS in
        ubuntu|debian) apt-get install -y git ;;
        centos|rhel|fedora) yum install -y git ;;
    esac
fi

# ── 4. 克隆/定位项目 ─────────────────────────────────────
info "[4/7] 准备项目代码..."
BACKEND_DIR="$PROJECT_DIR/backend"
COMPOSE_FILE="$BACKEND_DIR/docker-compose.prod.yml"

if [ -f "$COMPOSE_FILE" ]; then
    info "项目已存在于 $PROJECT_DIR, 跳过克隆"
    cd "$PROJECT_DIR"
    git pull origin main 2>/dev/null || warn "git pull 失败, 使用现有代码继续"
else
    REPO_URL="https://github.com/${GHCR_USER}/AI-Shopping.git"
    info "克隆项目: $REPO_URL"
    git clone "$REPO_URL" "$PROJECT_DIR"
    cd "$PROJECT_DIR"
fi

# ── 5. 配置 .env ─────────────────────────────────────────
info "[5/7] 配置环境变量..."
if [ -f "$BACKEND_DIR/.env" ]; then
    info "$BACKEND_DIR/.env 已存在, 保留现有配置"
else
    if [ "$NON_INTERACTIVE" = true ]; then
        # 自动生成安全密码
        PG_PASS=$(openssl rand -base64 24 | tr -d '/+=' | head -c 24)
        MINIO_PASS=$(openssl rand -base64 24 | tr -d '/+=' | head -c 24)
        JWT_SECRET=$(openssl rand -base64 48 | tr -d '/+=' | head -c 43)

        cp "$BACKEND_DIR/.env.production" "$BACKEND_DIR/.env"
        sed -i "s/CHANGE_ME_postgres_password/$PG_PASS/g" "$BACKEND_DIR/.env"
        sed -i "s/CHANGE_ME_minio_password/$MINIO_PASS/g" "$BACKEND_DIR/.env"
        sed -i "s/CHANGE_ME_minio_secret_key/$MINIO_PASS/g" "$BACKEND_DIR/.env"
        sed -i "s/CHANGE_ME_generate_with_python_secrets/$JWT_SECRET/g" "$BACKEND_DIR/.env"

        info "非交互模式: 已自动生成密码并写入 .env"
        warn "请保存以下密码 (仅显示一次):"
        echo ""
        echo "  POSTGRES_PASSWORD:  $PG_PASS"
        echo "  MINIO_ROOT_PASSWORD: $MINIO_PASS"
        echo "  JWT_SECRET:          $JWT_SECRET"
        echo ""
    else
        info "交互模式: 请输入配置信息 (直接回车使用自动生成值)"

        read -p "  数据库密码 (留空自动生成): " PG_PASS
        PG_PASS="${PG_PASS:-$(openssl rand -base64 24 | tr -d '/+=' | head -c 24)}"

        read -p "  MinIO 密码 (留空自动生成): " MINIO_PASS
        MINIO_PASS="${MINIO_PASS:-$(openssl rand -base64 24 | tr -d '/+=' | head -c 24)}"

        read -p "  JWT 密钥 (留空自动生成): " JWT_SECRET
        JWT_SECRET="${JWT_SECRET:-$(openssl rand -base64 48 | tr -d '/+=' | head -c 43)}"

        read -p "  火山方舟 API Key (可选, 回车跳过): " ARK_API_KEY
        ARK_API_KEY="${ARK_API_KEY:-你的火山方舟_API_Key}"

        read -p "  VLM Endpoint ID (可选, 回车跳过): " ARK_VLM_ID
        ARK_VLM_ID="${ARK_VLM_ID:-ep-xxxxxx}"

        read -p "  LLM Endpoint ID (可选, 回车跳过): " ARK_LLM_ID
        ARK_LLM_ID="${ARK_LLM_ID:-ep-xxxxxx}"

        cp "$BACKEND_DIR/.env.production" "$BACKEND_DIR/.env"
        sed -i "s/CHANGE_ME_postgres_password/$PG_PASS/g" "$BACKEND_DIR/.env"
        sed -i "s/CHANGE_ME_minio_password/$MINIO_PASS/g" "$BACKEND_DIR/.env"
        sed -i "s/CHANGE_ME_minio_secret_key/$MINIO_PASS/g" "$BACKEND_DIR/.env"
        sed -i "s/CHANGE_ME_generate_with_python_secrets/$JWT_SECRET/g" "$BACKEND_DIR/.env"
        sed -i "s|你的火山方舟_API_Key|$ARK_API_KEY|g" "$BACKEND_DIR/.env"
        sed -i "s|ep-xxxxxx|$ARK_VLM_ID|g" "$BACKEND_DIR/.env"
        # 第二个 ep-xxxxxx 是 LLM
        sed -i "s|^ARK_LLM_ENDPOINT_ID=.*|ARK_LLM_ENDPOINT_ID=$ARK_LLM_ID|g" "$BACKEND_DIR/.env"

        info ".env 配置完成"
    fi
fi

# ── 6. 系统优化 ──────────────────────────────────────────
info "[6/7] 系统优化..."
sysctl -w vm.overcommit_memory=1 2>/dev/null || true
grep -q "vm.overcommit_memory=1" /etc/sysctl.conf 2>/dev/null || \
    echo "vm.overcommit_memory=1" >> /etc/sysctl.conf

# 配置防火墙
if command -v ufw &> /dev/null; then
    ufw allow 22/tcp 2>/dev/null || true
    ufw allow 80/tcp 2>/dev/null || true
    ufw --force enable 2>/dev/null || true
    info "UFW 防火墙已配置"
elif command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-service=ssh 2>/dev/null || true
    firewall-cmd --permanent --add-port=80/tcp 2>/dev/null || true
    firewall-cmd --reload 2>/dev/null || true
    info "firewalld 已配置"
else
    warn "未检测到防火墙, 请确保云服务器安全组已开放 80 端口"
fi

# ── 7. 部署 ───────────────────────────────────────────────
info "[7/7] 启动服务..."

cd "$BACKEND_DIR"

# 停止旧服务
docker compose -f "$COMPOSE_FILE" down --remove-orphans 2>/dev/null || true

if [ "$BUILD_LOCAL" = true ]; then
    info "模式: 本地构建"
    docker compose -f "$COMPOSE_FILE" build --no-cache backend
    docker compose -f "$COMPOSE_FILE" up -d
else
    info "模式: 从 GHCR 拉取镜像"

    IMAGE_NAME="ghcr.io/${GHCR_USER}/snapshop-backend:latest"

    # 尝试登录 GHCR
    if docker pull "$IMAGE_NAME" 2>/dev/null; then
        info "公开镜像拉取成功"
    else
        if [ -n "$GHCR_TOKEN" ]; then
            echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USER" --password-stdin
        else
            warn "镜像需要认证但未提供 GHCR_TOKEN, 尝试继续..."
        fi
        docker compose -f "$COMPOSE_FILE" pull
    fi

    docker compose -f "$COMPOSE_FILE" pull
    docker compose -f "$COMPOSE_FILE" up -d
fi

# 等待服务就绪
info "等待服务启动..."
sleep 8

# 数据库迁移
info "运行数据库迁移..."
docker compose -f "$COMPOSE_FILE" exec -T backend alembic upgrade head 2>/dev/null || \
    warn "迁移可能已是最新, 或者 backend 尚未就绪"

# ── 完成 ──────────────────────────────────────────────────
SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
[ -z "$SERVER_IP" ] && SERVER_IP="你的服务器IP"

echo ""
echo "=============================================="
echo "  部署完成!"
echo "=============================================="
echo ""
echo "  健康检查:  curl http://${SERVER_IP}/health"
echo "  API 文档:   http://${SERVER_IP}/docs"
echo ""
echo "  服务状态:"
docker compose -f "$COMPOSE_FILE" ps 2>/dev/null || true
echo ""
echo "  后续更新:  cd $PROJECT_DIR && bash deploy/update.sh"
echo ""

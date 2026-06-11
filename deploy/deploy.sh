#!/bin/bash
set -e

echo "=========================================="
echo " SnapShop 项目部署 (GHCR 镜像模式)"
echo "=========================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKEND_DIR="$PROJECT_DIR/backend"
COMPOSE_FILE="$BACKEND_DIR/docker-compose.prod.yml"
IMAGE_NAME="ghcr.io/for2006/snapshop-backend:latest"

if [ ! -f "$BACKEND_DIR/.env" ]; then
    echo "错误: $BACKEND_DIR/.env 不存在"
    echo "请先执行: cp $BACKEND_DIR/.env.production $BACKEND_DIR/.env"
    echo "并编辑 .env 填入真实配置后重试"
    exit 1
fi

MODE="${1:-pull}"

if [ "$MODE" = "build" ]; then
    echo "[1/4] 停止旧服务..."
    cd "$BACKEND_DIR"
    docker compose -f "$COMPOSE_FILE" down --remove-orphans 2>/dev/null || true

    echo "[2/4] 本地构建镜像（不使用 GHCR）..."
    docker compose -f "$COMPOSE_FILE" build --no-cache backend

    echo "[3/4] 启动服务..."
    docker compose -f "$COMPOSE_FILE" up -d

    echo "[4/4] 等待服务就绪..."
    sleep 5
else
    echo "[1/5] 登录 GitHub Container Registry..."
    if [ -n "$GITHUB_TOKEN" ]; then
        echo "$GITHUB_TOKEN" | docker login ghcr.io -u for2006 --password-stdin
    elif [ -n "$CR_PAT" ]; then
        echo "$CR_PAT" | docker login ghcr.io -u for2006 --password-stdin
    else
        echo "提示: 未设置 GITHUB_TOKEN 或 CR_PAT，尝试作为公开镜像拉取..."
    fi

    echo "[2/5] 停止旧服务..."
    cd "$BACKEND_DIR"
    docker compose -f "$COMPOSE_FILE" down --remove-orphans 2>/dev/null || true

    echo "[3/5] 拉取最新镜像..."
    docker compose -f "$COMPOSE_FILE" pull

    echo "[4/5] 启动服务..."
    docker compose -f "$COMPOSE_FILE" up -d

    echo "[5/5] 等待服务就绪..."
    sleep 5

    echo "[+] 运行数据库迁移..."
    docker compose -f "$COMPOSE_FILE" exec -T backend alembic upgrade head || echo "迁移可能已是最新"
fi

echo ""
echo "=========================================="
echo " 服务状态"
echo "=========================================="
docker compose -f "$COMPOSE_FILE" ps

echo ""
echo "=========================================="
echo " 部署完成!"
echo "=========================================="
echo ""
echo "验证部署:"
echo "  curl http://\$(hostname -I | awk '{print \$1}')/health"
echo ""
echo "Swagger 文档:"
echo "  http://\$(hostname -I | awk '{print \$1}')/docs"
echo ""
echo "后续更新:"
echo "  bash deploy/update.sh"

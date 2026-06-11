#!/bin/bash
set -e

echo "=========================================="
echo " SnapShop 一键更新 (GHCR 镜像模式)"
echo "=========================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKEND_DIR="$PROJECT_DIR/backend"
COMPOSE_FILE="$BACKEND_DIR/docker-compose.prod.yml"

if [ ! -f "$BACKEND_DIR/.env" ]; then
    echo "错误: $BACKEND_DIR/.env 不存在，请先完成首次部署"
    exit 1
fi

IMAGE_NAME="ghcr.io/for2006/snapshop-backend:latest"

echo "[1/5] 登录 GitHub Container Registry..."
if docker pull "$IMAGE_NAME" 2>/dev/null; then
    echo "已登录或镜像为公开，跳过登录"
else
    if [ -n "$GITHUB_TOKEN" ]; then
        echo "$GITHUB_TOKEN" | docker login ghcr.io -u for2006 --password-stdin
    elif [ -n "$CR_PAT" ]; then
        echo "$CR_PAT" | docker login ghcr.io -u for2006 --password-stdin
    else
        echo "错误: 需要设置 GITHUB_TOKEN 或 CR_PAT 环境变量来拉取私有镜像"
        echo "  在服务器上设置: export GITHUB_TOKEN=你的GitHub_Personal_Access_Token"
        echo "  或: export CR_PAT=你的GitHub_Personal_Access_Token"
        exit 1
    fi
fi

echo "[2/5] 拉取最新镜像..."
DOCKER_CONFIG="${DOCKER_CONFIG:-$HOME/.docker}"
if [ -f "$DOCKER_CONFIG/config.json" ]; then
    docker compose -f "$COMPOSE_FILE" pull backend
else
    if [ -n "$GITHUB_TOKEN" ]; then
        echo "$GITHUB_TOKEN" | docker login ghcr.io -u for2006 --password-stdin
    fi
    docker compose -f "$COMPOSE_FILE" pull backend
fi

echo "[3/5] 重新创建后端容器..."
docker compose -f "$COMPOSE_FILE" up -d --no-deps backend

echo "[4/5] 运行数据库迁移..."
docker compose -f "$COMPOSE_FILE" exec -T backend alembic upgrade head

echo "[5/5] 清理旧镜像..."
docker image prune -f

echo ""
echo "=========================================="
echo " 更新完成!"
echo "=========================================="
echo ""
echo "运行状态:"
docker compose -f "$COMPOSE_FILE" ps
echo ""
echo "验证: curl http://localhost/health"

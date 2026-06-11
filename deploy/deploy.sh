#!/bin/bash
set -e

echo "=========================================="
echo " SnapShop 项目部署"
echo "=========================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BACKEND_DIR="$PROJECT_DIR/backend"

if [ ! -f "$BACKEND_DIR/.env" ]; then
    echo "错误: $BACKEND_DIR/.env 不存在"
    echo "请先执行: cp $BACKEND_DIR/.env.production $BACKEND_DIR/.env"
    echo "并编辑 .env 填入真实配置后重试"
    exit 1
fi

echo "[1/4] 停止旧服务..."
cd "$BACKEND_DIR"
docker compose -f docker-compose.prod.yml down --remove-orphans 2>/dev/null || true

echo "[2/4] 构建镜像..."
docker compose -f docker-compose.prod.yml build --no-cache

echo "[3/4] 启动服务..."
docker compose -f docker-compose.prod.yml up -d

echo "[4/4] 等待服务就绪..."
sleep 5

echo ""
echo "=========================================="
echo " 服务状态"
echo "=========================================="
docker compose -f docker-compose.prod.yml ps

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

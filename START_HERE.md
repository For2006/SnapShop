# SnapShop — 比赛运行指南

> **SnapShop**：AI 拍照识物与智能比价购物助手 — 拍照即搜，聚合多平台比价，自然语言筛选，一站式「识别→检索→决策」购物体验。

---

## 1. 环境要求

| 组件 | 版本要求 | 说明 |
|------|---------|------|
| Python | 3.12+ | 后端 FastAPI 运行环境 |
| Flutter SDK | 3.2+ (Dart >=3.2.0) | 前端跨平台框架 |
| Docker & Docker Compose | 最新稳定版 | 编排 PostgreSQL、Redis、MinIO |
| PostgreSQL | 16（Docker 提供） | 主数据库 |
| Redis | 7（Docker 提供） | 缓存与限流 |

**可选**：Android Studio 或 Xcode（用于编译运行 Flutter 移动端应用）。

---

## 2. 快速启动

### 步骤 1：启动后端服务

```bash
# 1. 进入后端目录
cd backend

# 2. 复制环境变量模板（模板已预填比赛 AI 密钥，可直接使用）
cp .env.example .env

# 3. （可选）如需修改配置，编辑 .env
#    AI 密钥已预填，JWT_SECRET 开发模式会自动生成

# 4. 启动所有 Docker 服务（API + PostgreSQL + Redis + MinIO）
docker compose up -d

# 5. 创建 MinIO 存储桶（首次启动必须执行）
#    等待 MinIO 就绪后，访问 http://localhost:9001 用 minioadmin/minioadmin123 登录
#    手动创建名为 snapshop-images 的 bucket

# 6. 等待约 10~30 秒，验证后端是否就绪
curl http://localhost:8000/health
# 预期返回：{"status":"healthy"}
```

> 如果 `docker compose` 命令不可用，请尝试 `docker-compose up -d`（旧版语法）。

### 步骤 2：启动前端应用

```bash
# 1. 进入前端目录
cd snapshop

# 2. 安装依赖
flutter pub get

# 3. 运行（确保已有 Android 模拟器 / iOS 模拟器 / 真机连接）
flutter run
```

前端默认连接后端地址为 `http://localhost:8000`（Android 模拟器使用 `10.0.2.2:8000`，Flutter 代码中已自动适配）。

---

## 3. 后端 `.env` 配置说明

编辑 `backend/.env` 文件，按下方表格配置：

### 3.1 比赛专用 AI 资源（必填）

这些是大赛组委会提供的火山方舟 AI 推理资源，用于视觉识别（VLM）和智能建议生成（LLM）：

| 配置项 | 值 | 说明 |
|--------|-----|------|
| `ARK_API_KEY` | `你的火山方舟 API Key` | 火山方舟 API Key（比赛专用资源） |
| `ARK_VLM_ENDPOINT_ID` | `ep-xxxxxx` | VLM 端点（Doubao-Seed-2.0-lite） |
| `ARK_LLM_ENDPOINT_ID` | `ep-xxxxxx` | LLM 端点（Doubao-Seed-2.0-lite） |
| `AI_MOCK_MODE` | `false` | 关闭 Mock 模式，使用真实 AI 推理 |

### 3.2 数据库与缓存（默认即可）

使用 `docker compose up -d` 启动的本地 Docker 服务，以下值为默认配置：

| 配置项 | 值 | 说明 |
|--------|-----|------|
| `POSTGRES_USER` | `snapshop` | 数据库用户名 |
| `POSTGRES_PASSWORD` | `自行设置` | 数据库密码，需与下方 DATABASE_URL 保持一致 |
| `POSTGRES_DB` | `snapshop` | 数据库名称 |
| `DATABASE_URL` | `postgresql+asyncpg://snapshop:你的密码@localhost:5432/snapshop` | 本地连接 |
| `REDIS_URL` | `redis://localhost:6379/0` | 本地 Redis |

### 3.3 JWT 密钥（必填）

生产环境必须设置强随机 JWT 密钥，否则应用将拒绝启动：

```bash
# 在终端执行以下命令生成随机密钥，然后填入 .env 的 JWT_SECRET 字段：
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

将生成的字符串填入：
```
JWT_SECRET=<生成的随机密钥>
```

> 开发模式下（`DEBUG=true`），若未设置 `JWT_SECRET`，应用启动时会自动生成一个临时密钥，但每次重启都会变化，导致登录 token 失效。

### 3.4 MinIO 对象存储（Docker 提供，默认即可）

| 配置项 | 值 | 说明 |
|--------|-----|------|
| `MINIO_ROOT_USER` | `minioadmin`（自定义） | MinIO 管理员用户名 |
| `MINIO_ROOT_PASSWORD` | `minioadmin123`（自定义） | MinIO 管理员密码 |
| `MINIO_ENDPOINT` | `localhost:9000` | MinIO S3 API 地址 |
| `MINIO_ACCESS_KEY` | 与 MINIO_ROOT_USER 相同 | S3 Access Key |
| `MINIO_SECRET_KEY` | 与 MINIO_ROOT_PASSWORD 相同 | S3 Secret Key |
| `MINIO_BUCKET` | `snapshop-images` | 图片存储桶名称 |

### 3.5 电商平台 API 密钥（可选）

可用于接入京东联盟、拼多多开放平台的真实商品数据。留空则自动使用内置 Mock 数据。

| 配置项 | 说明 |
|--------|------|
| `JD_APP_KEY` / `JD_APP_SECRET` / `JD_ACCESS_TOKEN` | 京东联盟 API |
| `PDD_CLIENT_ID` / `PDD_CLIENT_SECRET` / `PDD_ACCESS_TOKEN` | 拼多多开放平台 API |

---

## 4. 最小功能验证（6 条路径）

以下测试用例用于快速验证核心链路是否正常工作。所有测试均在 **Flutter 应用运行后** 通过 App 界面完成。

### TC001：拍照识物全流程

| 步骤 | 操作 | 预期结果 |
|------|------|----------|
| 1 | 打开 SnapShop App，进入首页 | 显示品牌 Logo、搜索栏 |
| 2 | 点击搜索栏左侧 **📷 相机图标** | 唤起系统原生相机 |
| 3 | 对任意商品（如耳机、水杯、鞋子）拍照 | 自动上传并跳转识别结果页 |
| 4 | 等待识别完成 | 显示 VLM 识别的商品属性标签（类目、品牌、颜色、风格等） |
| 5 | 查看下方商品列表 | 显示多平台比价商品卡片（含价格、平台标识） |
| 6 | 查看建议卡片区域 | 显示 LLM 动态生成的智能建议（如"查看同款低价""只看旗舰店"） |

### TC002：相册选图识别

| 步骤 | 操作 | 预期结果 |
|------|------|----------|
| 1 | 在首页点击搜索栏右侧 **🖼️ 相册按钮** | 搜索栏向上抬升，露出相册图片网格 |
| 2 | 点击任意一张已存储的商品图片 | 上传并跳转识别结果页 |
| 3 | 等待识别完成 | 与 TC001 步骤 4-6 相同 |

### TC003：智能建议卡片交互

| 步骤 | 操作 | 预期结果 |
|------|------|----------|
| 1 | 完成 TC001 或 TC002 的识别流程 | 进入识别结果页，建议卡片区域可见 |
| 2 | 点击"只看旗舰店"建议卡片 | 商品列表过滤为仅显示官方旗舰店商品 |
| 3 | 点击"按价格排序"建议卡片 | 商品列表按价格从低到高重新排序 |
| 4 | 点击"查看同款低价"建议卡片 | 商品列表聚焦同款低价商品 |

### TC004：自然语言筛选

| 步骤 | 操作 | 预期结果 |
|------|------|----------|
| 1 | 完成识别流程，停留在识别结果页 | 筛选输入栏可见 |
| 2 | 在筛选输入栏输入"只要黑色的，500以内" | SSE 流式逐条推送新商品 |
| 3 | 等待推送完成 | 商品列表更新，显示黑色且价格低于 500 的商品 |

### TC005：属性修正

| 步骤 | 操作 | 预期结果 |
|------|------|----------|
| 1 | 完成识别流程，识别结果页显示属性标签 | 例如识别出颜色"蓝色" |
| 2 | 点击颜色属性标签（如"蓝色"） | 弹出属性编辑面板 |
| 3 | 将颜色修改为"黑色"，点击确认 | 触发重新搜索，商品列表更新为黑色相关商品 |

### TC006：文字搜索（不拍照）

| 步骤 | 操作 | 预期结果 |
|------|------|----------|
| 1 | 在首页搜索栏输入关键词，如"蓝牙耳机" | 文字输入完成 |
| 2 | 点击发送按钮 | 跳转识别结果页（跳过 VLM，直接关键词检索） |
| 3 | 查看结果 | 显示"蓝牙耳机"相关商品列表及预设建议卡片 |

---

## 5. API 文档入口

后端启动后，访问以下地址查看完整的交互式 API 文档：

> **[http://localhost:8000/docs](http://localhost:8000/docs)** — Swagger UI（可直接在浏览器中调试 API）

主要接口一览：

| 方法 | 路径 | 说明 |
|------|------|------|
| `GET` | `/health` | 健康检查 |
| `POST` | `/api/v1/recognize` | 图片上传 + VLM 识别 |
| `POST` | `/api/v1/search` | 文字搜索 |
| `GET` | `/api/v1/products/{session_id}` | 获取识别会话的商品列表 |
| `GET` | `/api/v1/filter/stream` | SSE 流式自然语言筛选 |
| `POST` | `/api/v1/suggestions/action` | 执行建议卡片动作 |
| `PATCH` | `/api/v1/recognize/{session_id}/attributes` | 属性修正 |
| `GET` | `/api/v1/history` | 搜索 & 浏览历史 |
| `POST` / `DELETE` | `/api/v1/favorites` | 收藏管理 |

---

## 6. 常见问题排查

### 端口冲突

**现象**：`docker compose up -d` 报端口占用错误。

```bash
# 检查哪些端口被占用（8000, 5432, 6379, 9000, 9001）
netstat -ano | findstr "8000 5432 6379 9000 9001"

# 如果需要，先停止冲突的本地 PostgreSQL/Redis 服务
# 或修改 docker-compose.yml 中的端口映射
```

### Docker 未启动

**现象**：`docker compose up -d` 报 `docker: command not found` 或连接错误。

```powershell
# 确保 Docker Desktop 已启动（Windows 托盘图标应为运行状态）
# 验证 Docker 是否正常工作：
docker ps
```

### 图片上传失败

**现象**：拍照或选图后无响应或报错。

| 可能原因 | 解决方法 |
|----------|----------|
| MinIO 未正确启动 | `docker compose logs minio` 查看日志 |
| MinIO bucket 未创建 | 访问 http://localhost:9001 手动创建 `snapshop-images` bucket |
| 图片过大 | 前端自动压缩至 ≤2MB，确保 `image_picker` 和 `flutter_image_compress` 插件正常 |
| AI Mock 模式 | 检查 `.env` 中 `AI_MOCK_MODE=false` 且 AI 密钥正确 |

### 数据库连接失败

**现象**：后端日志报 `connection refused`。

```bash
# 检查 PostgreSQL 是否就绪
docker compose ps db
# 状态应为 "healthy"

# 如果不健康，查看日志：
docker compose logs db
```

### Flutter 编译错误

```bash
# 清理并重新获取依赖
cd snapshop
flutter clean
flutter pub get
flutter run
```

### 环境变量未生效

修改 `.env` 后需要重启后端服务：

```bash
cd backend
docker compose down
docker compose up -d
```

---

## 7. 文档索引

- [产品需求文档 (PRD)](docs/PRD.md)
- [架构设计文档](docs/architecture.md)
- [API 说明文档](docs/api.md)
- [功能结构图](docs/功能结构图.md)
- [Mock 模拟数据说明](docs/mock-data.md)
- [AI 使用总结](docs/ai-usage-summary.md)
- [标准测试用例](docs/test-cases.md)
- [项目分工说明](docs/team-division.md)

---

## 8. 阿里云 ECS 部署

### 8.1 前置条件

| 项目 | 要求 |
|------|------|
| ECS 配置 | 2核4GB 及以上（推荐 Ubuntu 22.04 / CentOS 7.9） |
| 安全组规则 | 开放端口: 22 (SSH), 80 (HTTP) |
| 域名 | 可选，无域名时直接使用服务器公网 IP |

### 8.2 部署步骤

#### 步骤 1：上传项目到服务器

```bash
# 在本地项目根目录执行，将项目上传至服务器
# 方式一：使用 scp（替换 YOUR_SERVER_IP 为实际 IP）
scp -r . root@YOUR_SERVER_IP:/opt/snapshop

# 方式二：使用 rsync（增量同步，推荐）
rsync -avz --exclude '.git' --exclude '*.pyc' --exclude '__pycache__' \
  ./ root@YOUR_SERVER_IP:/opt/snapshop/
```

#### 步骤 2：执行环境初始化脚本

```bash
# SSH 登录服务器
ssh root@YOUR_SERVER_IP

# 进入项目目录
cd /opt/snapshop/backend

# 运行环境初始化（安装 Docker + Docker Compose）
bash ../deploy/setup.sh
```

#### 步骤 3：配置生产环境变量

```bash
# 复制生产环境变量模板
cp .env.production .env

# 编辑 .env，修改以下必填项：
# - POSTGRES_PASSWORD、MINIO_ROOT_PASSWORD：设置强密码
# - JWT_SECRET：运行 python3 -c "import secrets; print(secrets.token_urlsafe(32))" 生成
# - ARK_API_KEY 等 AI 配置已预填比赛专用值，无需修改
nano .env
```

#### 步骤 4：启动服务

```bash
# 启动所有服务（后端 + 数据库 + Redis + MinIO + Nginx）
docker compose -f docker-compose.prod.yml up -d

# 查看服务状态
docker compose -f docker-compose.prod.yml ps

# 查看日志
docker compose -f docker-compose.prod.yml logs -f
```

#### 步骤 5：验证部署

```bash
# 健康检查
curl http://YOUR_SERVER_IP/health

# 预期返回：{"status":"healthy"}

# 测试 API
curl http://YOUR_SERVER_IP/api/v1/history
```

### 8.3 更新与重启

```bash
# 拉取最新代码
cd /opt/snapshop && git pull

# 重新构建并重启
cd backend
docker compose -f docker-compose.prod.yml up -d --build
```

### 8.4 前端 APK 构建

部署后端后，修改 `snapshop/lib/core/network/api_client.dart` 中的 `_productionBaseUrl` 为服务器 IP，然后构建 APK：

```bash
cd snapshop
flutter build apk --release
# APK 位于 build/app/outputs/flutter-apk/app-release.apk
```

### 8.5 端口说明

| 端口 | 服务 | 对外 | 说明 |
|------|------|:--:|------|
| 80 | Nginx | ✅ | HTTP 入口，反向代理到后端 |
| 8000 | FastAPI | ❌ | 仅 Docker 内网 |
| 5432 | PostgreSQL | ❌ | 仅 Docker 内网 |
| 6379 | Redis | ❌ | 仅 Docker 内网 |
| 9000 | MinIO | ✅ | 图片上传/访问 |

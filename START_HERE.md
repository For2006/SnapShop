# SnapShop — 比赛运行指南

> **SnapShop**：AI 拍照识物与智能比价购物助手 — 拍照即搜，聚合多平台比价，自然语言筛选，一站式「识别→检索→决策」购物体验。

---

## 1. 环境要求

### 1.1 服务器端（部署后端）

| 资源 | 最低配置 | 推荐配置 |
|------|---------|---------|
| CPU | 2 核 | 4 核及以上 |
| 内存 | 4 GB | 8 GB 及以上 |
| 磁盘 | 20 GB | 40 GB 及以上 (SSD) |
| 带宽 | 5 Mbps | 10 Mbps 及以上 |
| 操作系统 | Ubuntu 22.04 / Debian 12 / CentOS 7.9 | Ubuntu 22.04 LTS |

| 软件 | 版本 | 用途 |
|------|------|------|
| Docker | 24.0+ | 容器运行时 |
| Docker Compose Plugin | 2.20+ | 多容器编排 |
| Git | 2.40+ | 代码拉取 |

> 如果使用 GHCR 预构建镜像，服务器只需 Docker + Docker Compose + Git，无需 Python/Node.js 等运行时。

### 1.2 网络端口

| 端口 | 方向 | 用途 |
|------|:----:|------|
| 22 | 入站 | SSH 远程管理 |
| 80 | 入站 | HTTP 访问 (Nginx 反向代理) |
| 443 | 入站 | HTTPS 访问 (可选) |

> PostgreSQL (5432)、Redis (6379)、MinIO (9000/9001) 仅 Docker 内网通信，**无需对外开放**。云服务器安全组需开放 22 和 80 端口。

### 1.3 本地开发环境（运行 Flutter 前端）

| 组件 | 版本要求 | 说明 |
|------|---------|------|
| Python | 3.12+ | 后端 FastAPI 运行环境 |
| Flutter SDK | 3.2+ (Dart >=3.2.0) | 前端跨平台框架 |
| Docker & Docker Compose | 最新稳定版 | 编排 PostgreSQL、Redis、MinIO |
| PostgreSQL | 16 (Docker 提供) | 主数据库 |
| Redis | 7 (Docker 提供) | 缓存与限流 |

**可选**：Android Studio 或 Xcode（用于编译运行 Flutter 移动端应用）。

---

## 2. 快速启动（本地开发）

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

## 8. 云服务器一键部署

### 8.1 前置条件

| 项目 | 要求 |
|------|------|
| 云服务器 | 2核4GB 及以上（推荐 Ubuntu 22.04 / CentOS 7.9） |
| 安全组规则 | 开放端口: 22 (SSH), 80 (HTTP) |
| 域名 | 可选，无域名时直接使用服务器公网 IP |

### 8.2 一键部署（推荐）

项目根目录的 `bootstrap.sh` 整合了环境初始化、密码生成、镜像拉取、服务启动等全部步骤。在全新云服务器上只需一条命令：

#### 方式 A：远程一键部署

```bash
# SSH 登录服务器后，直接执行（无需提前克隆项目）
curl -fsSL https://raw.githubusercontent.com/For2006/SnapShop/main/bootstrap.sh | sudo bash -s -- --non-interactive
```

脚本会自动完成：
1. 安装 Docker + Docker Compose + Git
2. 克隆项目到 `/opt/snapshop`
3. 自动生成并保存所有密码
4. 从 GitHub Container Registry 拉取预构建镜像
5. 启动全部 6 个容器（backend + PostgreSQL + Redis + MinIO + Nginx）
6. 运行数据库迁移

> **注意**：自动生成的密码会在屏幕上显示一次，请妥善保存。若需自定义配置，使用下面的交互模式。

#### 方式 B：交互模式（自定义配置）

```bash
# 克隆项目
git clone https://github.com/For2006/SnapShop.git /opt/snapshop
cd /opt/snapshop

# 交互式部署（逐个询问配置项，回车使用自动生成值）
sudo bash bootstrap.sh
```

#### 方式 C：本地构建模式（不用 GHCR 镜像）

```bash
cd /opt/snapshop
sudo bash bootstrap.sh --build
```

### 8.3 命令行选项

| 选项 | 说明 |
|------|------|
| `--ghcr-user=NAME` | GitHub 用户名（默认 `for2006`） |
| `--ghcr-token=TOKEN` | GitHub Personal Access Token，私有镜像需要 |
| `--build` | 在服务器上本地构建镜像，不从 GHCR 拉取 |
| `--non-interactive` | 非交互模式，自动生成所有密码和密钥 |
| `--project-dir=PATH` | 自定义项目安装目录（默认 `/opt/snapshop`） |

### 8.4 手动部署（不使用 bootstrap.sh）

如果不使用一键脚本，也可以逐步手动部署：

#### 步骤 1：上传项目并初始化环境

```bash
# 上传项目（任选一种方式）
git clone https://github.com/For2006/SnapShop.git /opt/snapshop
# 或: rsync -avz --exclude '.git' ./ root@YOUR_SERVER_IP:/opt/snapshop/

# SSH 登录，运行环境初始化
cd /opt/snapshop/backend
bash ../deploy/setup.sh
```

#### 步骤 2：配置环境变量

```bash
cp .env.production .env
nano .env
```

需要修改的必填项：
- `POSTGRES_PASSWORD`、`MINIO_ROOT_PASSWORD`：设置强密码
- `JWT_SECRET`：运行 `python3 -c "import secrets; print(secrets.token_urlsafe(32))"` 生成
- AI 配置（ARK_*）已预填比赛专用值，无需修改

#### 步骤 3：启动服务

```bash
# 一键部署（拉取 GHCR 镜像并启动）
bash ../deploy/deploy.sh

# 或手动执行：
docker compose -f docker-compose.prod.yml up -d
docker compose -f docker-compose.prod.yml exec backend alembic upgrade head
```

#### 步骤 4：验证

```bash
curl http://YOUR_SERVER_IP/health
# 预期返回：{"status":"healthy"}
```

### 8.5 后续更新

代码推送到 main 分支后，GitHub Actions 会自动构建新镜像推送到 GHCR。在服务器上执行：

```bash
cd /opt/snapshop && bash deploy/update.sh
```

该脚本会自动拉取最新镜像、仅重建 backend 容器（不中断其他服务）、运行新迁移。

### 8.6 前端 APK 构建与分发

部署后端后，构建前端 APK 安装包供用户下载安装。

#### 8.6.1 在服务器上构建 APK

**1. 安装 Flutter SDK**

```bash
cd /opt
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.22.0-stable.tar.xz
tar xf flutter_linux_3.22.0-stable.tar.xz
echo 'export PATH="$PATH:/opt/flutter/bin"' >> ~/.bashrc
source ~/.bashrc
flutter doctor
```

**2. 安装 Android SDK 和 JDK**

```bash
# JDK 17
apt-get install -y openjdk-17-jdk-headless

# Android 命令行工具
mkdir -p /opt/android-sdk/cmdline-tools
cd /opt/android-sdk/cmdline-tools
wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
unzip commandlinetools-linux-11076708_latest.zip
mv cmdline-tools latest

export ANDROID_HOME=/opt/android-sdk
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"

yes | sdkmanager --licenses
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"
```

**3. 配置后端地址**

修改 `snapshop/lib/core/network/api_client.dart` 中的生产环境地址：

```dart
static const String _productionBaseUrl = 'http://你的服务器IP';
```

**4. 配置 APK 签名（推荐）**

```bash
# 生成签名密钥
keytool -genkey -v -keystore /opt/snapshop/snapshop-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias snapshop-release -storetype JKS
```

创建 `snapshop/android/key.properties`：
```
storePassword=你的密钥库密码
keyPassword=你的密钥密码
keyAlias=snapshop-release
storeFile=/opt/snapshop/snapshop-release-key.jks
```

编辑 `snapshop/android/app/build.gradle.kts`，在文件顶部 `android` 块之前添加：

```kotlin
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

在 `android` 块内添加 `signingConfigs`，并将 `buildTypes.release.signingConfig` 改为：

```kotlin
signingConfigs {
    create("release") {
        keyAlias = keystoreProperties["keyAlias"] as String?
        keyPassword = keystoreProperties["keyPassword"] as String?
        storeFile = keystoreProperties["storeFile"] ? file(keystoreProperties["storeFile"]) : null
        storePassword = keystoreProperties["storePassword"] as String?
    }
}
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
    }
}
```

> 跳过签名步骤时，APK 将使用 debug 密钥签名，不影响功能测试。

**5. 构建 APK**

```bash
cd /opt/snapshop/snapshop
flutter pub get
flutter build apk --release
# APK 输出路径: build/app/outputs/flutter-apk/app-release.apk
```

#### 8.6.2 在本地 Windows 开发机构建

```bash
cd snapshop

# 修改后端地址为服务器 IP
# 编辑 lib/core/network/api_client.dart

# 构建 Release APK
flutter build apk --release
```

或使用 `start.ps1` 一键完成（自动检测 ADB 设备、构建 APK、安装并启动）：

```powershell
.\start.ps1
```

#### 8.6.3 分发 APK

| 方式 | 操作 |
|------|------|
| **Nginx 静态下载** | 将 APK 放入 Nginx 静态目录，用户访问 `http://服务器IP/app-release.apk` 下载 |
| **ADB 安装** | USB 连接手机后 `adb install app-release.apk` |
| **二维码分发** | 生成 APK 下载链接的二维码，手机扫码下载安装 |

> Android 设备需开启「设置 → 安全 → 允许安装未知来源应用」才能安装非应用商店的 APK。

### 8.7 端口说明

| 端口 | 服务 | 对外 | 说明 |
|------|------|:--:|------|
| 80 | Nginx | ✅ | HTTP 入口，反向代理到后端 |
| 8000 | FastAPI | ❌ | 仅 Docker 内网 |
| 5432 | PostgreSQL | ❌ | 仅 Docker 内网 |
| 6379 | Redis | ❌ | 仅 Docker 内网 |
| 9000 | MinIO | ✅ | 图片上传/访问 |

### 8.8 部署架构

```
互联网 (80端口)
    │
    ▼
┌──────────┐
│  Nginx   │  反向代理
└────┬─────┘
     │
     ├── /api/*   →  backend:8000  (FastAPI)
     ├── /images/ →  minio:9000    (图片直连)
     ├── /docs    →  backend:8000  (Swagger UI)
     └── /health  →  backend:8000  (健康检查)
           │
     ┌─────┴──────┬──────────┐
     ▼            ▼          ▼
  backend     postgres    redis
  (FastAPI)   (端口5432)   (端口6379)
     │
     ▼
  minio:9000
  (对象存储)
```

---

## 9. 完整部署到发布流程速查

从零开始，一条路径走通：**服务器部署后端 → 构建前端 APK → 分发安装**。

```
┌─────────────────────────────────────────────────────┐
│  1. 准备云服务器                                      │
│     - 2核4GB+, Ubuntu 22.04, 开放 22/80 端口          │
├─────────────────────────────────────────────────────┤
│  2. 一键部署后端                                      │
│     curl .../bootstrap.sh | sudo bash --non-interactive │
│     记录屏幕输出的密码, 验证 curl http://IP/health      │
├─────────────────────────────────────────────────────┤
│  3. 构建 APK                                         │
│     (服务器或本地) flutter build apk --release        │
│     生成: build/app/outputs/flutter-apk/app-release.apk │
├─────────────────────────────────────────────────────┤
│  4. 分发 APK                                         │
│     - Nginx 静态下载 / 二维码 / ADB 安装 / 应用商店      │
│     - 用户安装后即可连接后端使用                         │
└─────────────────────────────────────────────────────┘
```

### 关键命令速查

```bash
# 服务器部署
curl -fsSL https://raw.githubusercontent.com/For2006/SnapShop/main/bootstrap.sh | sudo bash -s -- --non-interactive

# 验证后端
curl http://服务器IP/health

# 更新后端
cd /opt/snapshop && bash deploy/update.sh

# 构建 APK (服务器)
cd /opt/snapshop/snapshop && flutter pub get && flutter build apk --release

# 构建 APK (本地)
cd snapshop && flutter build apk --release

# ADB 安装 APK
adb install build/app/outputs/flutter-apk/app-release.apk

# 查看容器状态
docker compose -f /opt/snapshop/backend/docker-compose.prod.yml ps

# 查看后端日志
docker compose -f /opt/snapshop/backend/docker-compose.prod.yml logs -f backend
```

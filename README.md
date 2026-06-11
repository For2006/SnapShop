# SnapShop — AI 拍照识物与智能比价购物助手

拍照即搜，聚合多平台比价，自然语言筛选 —— 一站式「识别→检索→决策」购物体验。

## 架构

```
┌──────────────────────────────────────────┐
│              展示层 (Flutter)              │
│  首页 · 相机 · 识别结果 · 商品列表 · 设置   │
│                    HTTP/SSE               │
├──────────────────────────────────────────┤
│              服务层 (FastAPI)              │
│  图像识别 · 商品检索 · 跨平台比价 · 流式筛选  │
├──────────────────────────────────────────┤
│              数据层                        │
│  PostgreSQL · Redis · MinIO · 火山方舟 AI  │
└──────────────────────────────────────────┘
```

## 技术栈

| 层 | 技术 |
|---|---|
| 前端 | Flutter 3.2+ · Riverpod · GoRouter · Dio |
| 后端 | Python FastAPI · SQLAlchemy · PostgreSQL · Redis |
| AI | 火山方舟 VLM (豆包视觉) · LLM (豆包/DeepSeek) |
| 部署 | Docker Compose (PostgreSQL 16 + Redis 7 + MinIO + Nginx) |
| 电商 | 拼多多联盟 API · 京东联盟 API |

## 服务器要求

### 硬件要求

| 资源 | 最低配置 | 推荐配置 |
|------|---------|---------|
| CPU | 2 核 | 4 核及以上 |
| 内存 | 4 GB | 8 GB 及以上 |
| 磁盘 | 20 GB | 40 GB 及以上 (SSD) |
| 带宽 | 5 Mbps | 10 Mbps 及以上 |

> 最低配置可满足后端服务 + 数据库 + 缓存 + 对象存储的基本运行。推荐配置可保证图片上传、VLM 识别等场景的流畅体验。

### 软件要求

| 组件 | 版本 | 用途 |
|------|------|------|
| 操作系统 | Ubuntu 22.04+ / Debian 12+ / CentOS 7.9+ | 服务器运行环境 |
| Docker | 24.0+ | 容器运行时 |
| Docker Compose Plugin | 2.20+ | 多容器编排 |
| Git | 2.40+ | 代码拉取 |
| Python | 3.12+ (仅本地构建需要) | 后端运行环境 |
| Flutter SDK | 3.2+ (仅构建 APK 需要) | 前端跨平台框架 |
| Android SDK | 34+ (仅构建 APK 需要) | Android 编译工具链 |
| JDK | 17 (仅构建 APK 需要) | Java 编译环境 |

> 如果使用 GHCR 镜像模式部署后端，服务器上只需安装 Docker + Docker Compose + Git，无需 Python。Flutter/Android SDK/JDK 仅在需要从服务器构建 APK 时才需安装。

### 网络要求

| 端口 | 方向 | 用途 |
|------|:----:|------|
| 22 | 入站 | SSH 远程管理 |
| 80 | 入站 | HTTP 访问 (Nginx 反向代理) |
| 443 | 入站 | HTTPS 访问 (可选，需配置 SSL 证书) |

> 云服务器安全组需开放以上端口。PostgreSQL (5432)、Redis (6379)、MinIO (9000/9001) 仅 Docker 内网通信，无需对外开放。

## 项目结构

```
├── backend/                # Python FastAPI 后端
│   ├── app/
│   │   ├── api/v1/         # REST + SSE 路由 (13 个端点)
│   │   ├── services/       # 业务逻辑层
│   │   ├── clients/        # 火山方舟 / 电商平台客户端
│   │   ├── models/         # SQLAlchemy 数据模型
│   │   └── schemas/        # Pydantic 请求/响应模型
│   ├── tests/              # pytest (5 个测试文件)
│   ├── Dockerfile          # 多阶段 Docker 构建
│   ├── docker-compose.yml       # 开发环境编排
│   ├── docker-compose.prod.yml  # 生产环境编排
│   └── .env.production     # 生产环境变量模板
├── snapshop/               # Flutter 前端
│   └── lib/
│       ├── config/         # 路由 · 主题 · 国际化
│       ├── core/           # 网络层 · 工具类
│       ├── features/       # 功能模块 (首页/识别/商品/筛选/设置/收藏)
│       └── shared/         # 共用组件
├── deploy/                 # 部署配置与脚本
│   ├── nginx/              # Nginx 反向代理配置
│   ├── setup.sh            # 服务器环境初始化脚本
│   ├── deploy.sh           # 一键部署脚本
│   └── update.sh           # 滚动更新脚本
└── docs/                   # PRD · 架构设计 · 功能结构图 · Mock数据说明
```

## 核心功能

- **拍照识物** — 系统相机/相册选图，VLM 视觉识别商品属性
- **属性修正** — 对识别不准确的属性进行手动纠正，触发重新搜索
- **跨平台比价** — 拼多多 + 京东双平台商品聚合，同款对齐排序
- **智能建议** — LLM 动态生成购物建议卡片（如"查看相似款""按销量排序"）
- **流式筛选** — SSE 推送，用自然语言追加筛选条件（如"只要黑色的、500以内"）
- **收藏 & 浏览记录** — 商品收藏、搜索历史、浏览足迹
- **主题 & 国际化** — 浅色/深色自适应，中英文切换
- **字号调节** — 支持小/标准/大/超大四档字体

## 快速开始（本地开发）

### 环境要求

- Flutter SDK >= 3.2.0
- Python >= 3.12
- Docker Desktop (含 Docker Compose)

### 1. 启动后端

```bash
cd backend

# 复制环境变量配置
cp .env.example .env
# 编辑 .env 填入火山方舟 API Key 等必要配置

# 启动所有服务 (API + PostgreSQL + Redis + MinIO)
docker compose up -d
```

后端 API 运行在 `http://localhost:8000`，Swagger 文档在 `http://localhost:8000/docs`。

### 2. 启动前端

```bash
cd snapshop

# 安装依赖
flutter pub get

# 运行 (选择已连接的设备或模拟器)
flutter run
```

## 从服务器构建到发布 APK（完整流程）

以下是从全新云服务器开始，部署后端服务、构建前端 APK 安装包、并分发给用户的完整步骤。

### 阶段一：服务器环境准备

**1. 选购云服务器**

参考配置：2核4GB 以上，系统盘 40GB SSD，操作系统 Ubuntu 22.04。

**2. 配置安全组**

在云服务商控制台开放入站端口：`22` (SSH)、`80` (HTTP)。

**3. SSH 登录并初始化环境**

```bash
ssh root@你的服务器IP

# 安装 Docker
curl -fsSL https://get.docker.com | bash
systemctl enable docker && systemctl start docker

# 安装 Docker Compose 插件
apt-get update && apt-get install -y docker-compose-plugin git

# 验证安装
docker --version && docker compose version
```

### 阶段二：部署后端服务

**方式 A：一键部署（推荐）**

```bash
curl -fsSL https://raw.githubusercontent.com/For2006/SnapShop/main/bootstrap.sh | sudo bash -s -- --non-interactive
```

脚本自动完成：安装依赖 → 克隆项目 → 生成密码 → 拉取镜像 → 启动服务 → 数据库迁移。部署完成后记录屏幕上显示的密码。

**方式 B：手动部署**

```bash
# 克隆项目
git clone https://github.com/For2006/SnapShop.git /opt/snapshop
cd /opt/snapshop/backend

# 配置环境变量
cp .env.production .env
# 编辑 .env：修改 POSTGRES_PASSWORD、MINIO_ROOT_PASSWORD、JWT_SECRET
# 生成 JWT 密钥: python3 -c "import secrets; print(secrets.token_urlsafe(32))"

# 启动服务
docker compose -f docker-compose.prod.yml up -d

# 运行数据库迁移
docker compose -f docker-compose.prod.yml exec backend alembic upgrade head

# 验证
curl http://localhost/health
```

**验证后端就绪：**

```bash
curl http://服务器IP/health
# 预期: {"status":"healthy"}
```

浏览器访问 `http://服务器IP/docs` 可查看 API 文档。

### 阶段三：构建前端 APK

APK 可以在服务器上构建，也可以在本地开发机上构建。以下按场景说明。

#### 场景 A：在服务器上构建 APK

**1. 安装 Flutter SDK**

```bash
# 下载 Flutter SDK
cd /opt
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.22.0-stable.tar.xz
tar xf flutter_linux_3.22.0-stable.tar.xz
echo 'export PATH="$PATH:/opt/flutter/bin"' >> ~/.bashrc
source ~/.bashrc

# 验证
flutter doctor
```

**2. 安装 Android SDK**

```bash
# 安装 Java 17
apt-get install -y openjdk-17-jdk-headless

# 安装 Android 命令行工具
mkdir -p /opt/android-sdk/cmdline-tools
cd /opt/android-sdk/cmdline-tools
wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
unzip commandlinetools-linux-11076708_latest.zip
mv cmdline-tools latest

# 设置环境变量
export ANDROID_HOME=/opt/android-sdk
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"

# 接受许可并安装必要组件
yes | sdkmanager --licenses
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"
```

**3. 配置后端地址**

编辑 `snapshop/lib/core/network/api_client.dart`，将生产环境地址修改为你的服务器 IP：

```dart
static const String _productionBaseUrl = 'http://你的服务器IP';
```

**4. 配置 Android 签名（生产环境必须）**

```bash
# 生成签名密钥
keytool -genkey -v -keystore /opt/snapshop/snapshop-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias snapshop-release -storetype JKS

# 创建 key.properties
cat > /opt/snapshop/snapshop/android/key.properties << 'EOF'
storePassword=你的密钥库密码
keyPassword=你的密钥密码
keyAlias=snapshop-release
storeFile=/opt/snapshop/snapshop-release-key.jks
EOF
```

编辑 `snapshop/android/app/build.gradle.kts`，在 `android` 块之前添加签名配置：

```kotlin
// 加载签名配置
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ... 现有内容 ...

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
}
```

> 如果暂时不需要签名，可跳过此步骤，构建时使用 debug 签名。

**5. 构建 APK**

```bash
cd /opt/snapshop/snapshop
flutter pub get
flutter build apk --release
```

构建完成后，APK 位于 `build/app/outputs/flutter-apk/app-release.apk`。

#### 场景 B：在本地 Windows 开发机构建

**⚠️ 必须先配置后端地址**：编辑 `snapshop/lib/core/network/api_client.dart` 第 105 行：

```dart
// 方式 A：ADB 反向代理（手机 USB 连电脑，电脑运行后端）
static const _productionBaseUrl = 'http://localhost:8000/api/v1';

// 方式 B：连接云服务器（替换为你的服务器 IP）
static const _productionBaseUrl = 'http://你的服务器IP/api/v1';
```

| 方式 | 场景 | 额外操作 |
|------|------|----------|
| `localhost` | 手机 USB 连电脑 | 需执行 `adb reverse tcp:8000 tcp:8000` |
| 服务器 IP | 后端已部署到云服务器 | 无需额外操作 |

```bash
cd snapshop

# 构建 Release APK
flutter build apk --release
# APK 输出路径: build/app/outputs/flutter-apk/app-release.apk
```

或使用项目自带的 `start.ps1` 一键完成（自动检测 ADB 设备、构建 APK、安装并启动）：

```powershell
.\start.ps1
```

### 阶段四：分发 APK

构建完成后，可通过以下方式分发：

| 方式 | 说明 |
|------|------|
| 直接下载链接 | 将 APK 放到 Nginx 静态目录，用户通过 URL 下载 |
| 内网传输 | 通过局域网文件共享或 ADB 直接安装 |
| 应用商店 | 提交到 Google Play / 国内应用商店 (需额外审核) |
| 二维码分发 | 生成 APK 下载链接的二维码，手机扫码下载安装 |

**使用 Nginx 提供 APK 下载（推荐）：**

```bash
# 将 APK 复制到 Nginx 可访问的目录
mkdir -p /opt/snapshop/deploy/nginx/www
cp /opt/snapshop/snapshop/build/app/outputs/flutter-apk/app-release.apk /opt/snapshop/deploy/nginx/www/

# 在 docker-compose.prod.yml 的 nginx 服务中添加挂载:
#   volumes:
#     - ../deploy/nginx/www:/usr/share/nginx/html:ro
```

之后用户访问 `http://服务器IP/app-release.apk` 即可下载安装。

> Android 设备安装 APK 时需开启「允许安装未知来源应用」。首次安装建议通过 USB 连接电脑使用 `adb install app-release.apk`。

### 阶段五：后续更新

**后端更新：**

代码推送到 GitHub main 分支后，CI 自动构建新镜像推送到 GHCR。在服务器执行：

```bash
cd /opt/snapshop && bash deploy/update.sh
```

**前端更新：**

修改代码后重新构建 APK，用户重新安装即可（versionCode 递增以确保覆盖安装）。

```bash
# 在 pubspec.yaml 中递增版本号 (version: X.Y.Z+code)
cd snapshop
flutter build apk --release
```

---

## 部署

### 云服务器一键部署（推荐）

在全新云服务器上，只需一条命令：

```bash
curl -fsSL https://raw.githubusercontent.com/For2006/SnapShop/main/bootstrap.sh | sudo bash -s -- --non-interactive
```

部署完成后访问 `http://服务器IP/docs` 即可使用。

### 命令行选项

| 选项 | 说明 |
|---|---|
| `--ghcr-user=NAME` | GitHub 用户名（默认 `for2006`） |
| `--ghcr-token=TOKEN` | GitHub PAT，私有镜像需要 |
| `--build` | 服务器本地构建（不走 GHCR） |
| `--non-interactive` | 非交互模式，自动生成密码 |
| `--project-dir=PATH` | 自定义安装目录（默认 `/opt/snapshop`） |

### 部署架构

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

## 环境变量参考

### 必填项

| 变量 | 说明 | 示例 |
|------|------|------|
| `POSTGRES_PASSWORD` | 数据库密码 | 强随机密码 |
| `MINIO_ROOT_PASSWORD` | MinIO 对象存储密码 | 强随机密码 |
| `MINIO_SECRET_KEY` | MinIO S3 Secret Key | 与 MINIO_ROOT_PASSWORD 相同 |
| `JWT_SECRET` | JWT 签名密钥 | `python -c "import secrets; print(secrets.token_urlsafe(32))"` |
| `ARK_API_KEY` | 火山方舟 API Key | 比赛专用资源 |
| `ARK_VLM_ENDPOINT_ID` | VLM 视觉模型端点 | `ep-xxxxxx` |
| `ARK_LLM_ENDPOINT_ID` | LLM 语言模型端点 | `ep-xxxxxx` |

### 可选项

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `AI_MOCK_MODE` | Mock 降级模式 (true=不调用真实 AI) | `false` |
| `DEBUG` | 调试模式 | `false` |
| `ALLOWED_ORIGINS` | CORS 允许来源 | `*` |
| `JD_APP_KEY` / `JD_APP_SECRET` / `JD_ACCESS_TOKEN` | 京东联盟 API | 空 (使用 Mock) |
| `PDD_CLIENT_ID` / `PDD_CLIENT_SECRET` / `PDD_ACCESS_TOKEN` | 拼多多开放平台 API | 空 (使用 Mock) |

## 文档

- [比赛运行指南 (START_HERE)](START_HERE.md)
- [产品需求文档 (PRD)](docs/PRD.md)
- [架构设计文档](docs/architecture.md)
- [API 说明文档](docs/api.md)
- [功能结构图](docs/功能结构图.md)
- [Mock 模拟数据说明](docs/mock-data.md)
- [项目分工说明](docs/team-division.md)
- [AI 使用总结](docs/ai-usage-summary.md)
- [标准测试用例](docs/test-cases.md)

# SnapShop — 项目启动指南

> **SnapShop**：AI 拍照识物与智能比价购物助手 — 拍照即搜，聚合多平台比价，自然语言筛选，一站式「识别→检索→决策」购物体验。

---

本文档提供两种部署方式：

| 部署方式 | 适用场景 | 操作系统 |
|----------|----------|----------|
| **[A. 云服务器部署](#a-云服务器部署)** | 生产环境 / 评委远程访问 / 对外服务 | Linux (Ubuntu/Debian/CentOS) |
| **[B. 本地开发环境部署](#b-本地开发环境部署)** | 开发调试 / 本地演示 / 学习研究 | Windows (本文档) / macOS |

---

## A. 云服务器部署

### A.1 环境要求

#### 硬件

| 资源 | 最低配置 | 推荐配置 |
|------|---------|---------|
| CPU | 2 核 | 4 核及以上 |
| 内存 | 4 GB | 8 GB 及以上 |
| 磁盘 | 20 GB | 40 GB 及以上 (SSD) |
| 带宽 | 5 Mbps | 10 Mbps 及以上 |
| 操作系统 | Ubuntu 22.04 / Debian 12 / CentOS 7.9 | Ubuntu 22.04 LTS |

#### 软件

| 软件 | 版本 | 用途 |
|------|------|------|
| Docker | 24.0+ | 容器运行时 |
| Docker Compose Plugin | 2.20+ | 多容器编排 |
| Git | 2.40+ | 代码拉取 |

> 使用 GHCR 预构建镜像时，服务器只需 Docker + Docker Compose + Git，无需 Python/Node.js 等运行时。

#### 网络端口

| 端口 | 方向 | 用途 |
|------|:----:|------|
| 22 | 入站 | SSH 远程管理 |
| 80 | 入站 | HTTP 访问 (Nginx 反向代理) |
| 443 | 入站 | HTTPS 访问 (可选) |

> PostgreSQL (5432)、Redis (6379)、MinIO (9000/9001) 仅 Docker 内网通信，**无需对外开放**。云服务器安全组需开放 22 和 80 端口。

---

### A.2 一键部署（推荐）

在全新云服务器上只需一条命令，脚本自动完成：安装依赖 → 克隆项目 → 生成密码 → 拉取镜像 → 启动全部 6 个容器 → 数据库迁移。

```bash
# SSH 登录服务器后执行
curl -fsSL https://raw.githubusercontent.com/For2006/SnapShop/main/bootstrap.sh | sudo bash -s -- --non-interactive
```

> 自动生成的密码会在屏幕上显示一次，**请立即记录下来**。若需自定义配置，使用下面的交互模式。

**交互模式**（逐个询问配置项，回车使用自动生成值）：

```bash
# 先克隆项目
git clone https://github.com/For2006/SnapShop.git /opt/snapshop
cd /opt/snapshop

# 交互式部署
sudo bash bootstrap.sh
```

**本地构建模式**（不从 GHCR 拉取，在服务器上本地编译镜像）：

```bash
cd /opt/snapshop
sudo bash bootstrap.sh --build
```

**命令行选项**：

| 选项 | 说明 |
|------|------|
| `--ghcr-user=NAME` | GitHub 用户名（默认 `for2006`） |
| `--ghcr-token=TOKEN` | GitHub Personal Access Token，私有镜像需要 |
| `--build` | 在服务器上本地构建镜像，不从 GHCR 拉取 |
| `--non-interactive` | 非交互模式，自动生成所有密码和密钥 |
| `--project-dir=PATH` | 自定义项目安装目录（默认 `/opt/snapshop`） |

---

### A.3 手动部署

如果不使用一键脚本，也可以逐步手动部署。

#### 步骤 1：初始化服务器环境

```bash
# SSH 登录服务器
ssh root@你的服务器IP

# 安装 Docker
curl -fsSL https://get.docker.com | bash
systemctl enable docker && systemctl start docker

# 安装 Docker Compose 插件 + Git
apt-get update && apt-get install -y docker-compose-plugin git
```

#### 步骤 2：克隆项目并配置

```bash
git clone https://github.com/For2006/SnapShop.git /opt/snapshop
cd /opt/snapshop/backend

# 复制生产环境变量模板
cp .env.production .env

# 编辑配置
nano .env
```

需要修改的必填项：

- `POSTGRES_PASSWORD`、`MINIO_ROOT_PASSWORD`、`MINIO_SECRET_KEY`：设置强密码
- `JWT_SECRET`：运行 `python3 -c "import secrets; print(secrets.token_urlsafe(32))"` 生成
- AI 配置（ARK_*）已预填比赛专用值，无密钥可开启 `AI_MOCK_MODE=true`

#### 步骤 3：启动服务

```bash
cd /opt/snapshop/backend

# 拉取 GHCR 镜像并启动
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d

# 运行数据库迁移
docker compose -f docker-compose.prod.yml exec backend alembic upgrade head
```

#### 步骤 4：验证

```bash
curl http://localhost/health
# 预期返回：{"status":"healthy"}
```

浏览器访问 `http://服务器IP/docs` 可查看 Swagger API 文档。

---

### A.4 部署架构

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

#### 端口一览

| 端口 | 服务 | 对外 | 说明 |
|------|------|:--:|------|
| 80 | Nginx | ✅ | HTTP 入口，反向代理到后端 |
| 8000 | FastAPI | ❌ | 仅 Docker 内网 |
| 5432 | PostgreSQL | ❌ | 仅 Docker 内网 |
| 6379 | Redis | ❌ | 仅 Docker 内网 |
| 9000 | MinIO | ✅ | 图片上传/访问 |

---

### A.5 后续更新

代码推送到 main 分支后，GitHub Actions 会自动构建新镜像推送到 GHCR。在服务器上执行：

```bash
cd /opt/snapshop && bash deploy/update.sh
```

该脚本会自动拉取最新镜像、仅重建 backend 容器（不中断其他服务）、运行新迁移。

---

### A.6 前端 APK 构建与分发

部署后端后，构建前端 APK 安装包供用户下载安装。

#### 在服务器上构建 APK

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
apt-get install -y openjdk-17-jdk-headless

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

编辑 `snapshop/lib/core/network/api_client.dart`，将生产环境地址改为服务器 IP：

```dart
static const String _productionBaseUrl = 'http://你的服务器IP';
```

**4. 构建 APK**

```bash
cd /opt/snapshop/snapshop
flutter pub get
flutter build apk --release
# APK 输出: build/app/outputs/flutter-apk/app-release.apk
```

#### 在本地 Windows 开发机构建

> **⚠️ 重要**：构建 Release APK 前必须配置正确的后端地址。编辑 `snapshop/lib/core/network/api_client.dart` 第 105 行：

```dart
// 方式 A：使用 ADB 反向代理（手机 USB 连接电脑，电脑运行后端）
static const _productionBaseUrl = 'http://localhost:8000/api/v1';

// 方式 B：连接云服务器（替换为你的服务器 IP）
static const _productionBaseUrl = 'http://你的服务器IP/api/v1';
```

| 方式 | 场景 | 额外操作 |
|------|------|----------|
| `localhost` | 手机 USB 连电脑 | 需执行 `adb reverse tcp:8000 tcp:8000` |
| 服务器 IP | 后端已部署到云服务器 | 无需额外操作 |

```powershell
cd snapshop

# 构建 Release APK
flutter build apk --release
# 输出: build\app\outputs\flutter-apk\app-release.apk
```

#### 分发 APK

| 方式 | 操作 |
|------|------|
| Nginx 静态下载 | 将 APK 放入 Nginx 静态目录，访问 `http://服务器IP/app-release.apk` |
| ADB 安装 | USB 连接手机后 `adb install app-release.apk` |
| 二维码分发 | 生成 APK 下载链接二维码，手机扫码下载安装 |

> Android 设备需开启「设置 → 安全 → 允许安装未知来源应用」。

---

### A.7 部署命令速查

```bash
# 一键部署
curl -fsSL https://raw.githubusercontent.com/For2006/SnapShop/main/bootstrap.sh | sudo bash -s -- --non-interactive

# 验证后端
curl http://服务器IP/health

# 更新后端
cd /opt/snapshop && bash deploy/update.sh

# 构建 APK (服务器)
cd /opt/snapshop/snapshop && flutter pub get && flutter build apk --release

# 构建 APK (本地 Windows)
cd snapshop && flutter build apk --release

# ADB 安装 APK
adb install build/app/outputs/flutter-apk/app-release.apk

# 查看容器状态
docker compose -f /opt/snapshop/backend/docker-compose.prod.yml ps

# 查看后端日志
docker compose -f /opt/snapshop/backend/docker-compose.prod.yml logs -f backend
```

---

## B. 本地开发环境部署

> 以下步骤以 **Windows** 为例，macOS 用户可参照对应命令（差异处已标注）。

### B.0 一键部署（推荐）

项目根目录提供了 `bootstrap.ps1` 脚本，整合了环境检查、克隆项目、自动配置 `.env`、启动 Docker、创建存储桶、数据库迁移、健康验证等全部步骤。

**前置条件**：仅需安装 Docker Desktop 和 Git（Python 为可选，无 Python 时自动用 PowerShell 生成密钥）。

```powershell
# 方式一：在当前目录一键部署
cd "f:\AI Shopping"
.\bootstrap.ps1

# 方式二：从 GitHub 克隆并部署（项目不存在时自动克隆）
.\bootstrap.ps1 -ProjectDir "f:\AI Shopping"

# 方式三：仅构建 Docker 镜像，不启动服务
.\bootstrap.ps1 -BuildOnly

# 方式四：跳过克隆，使用已有项目
.\bootstrap.ps1 -SkipClone
```

**脚本自动完成的事情**：

| 步骤 | 说明 |
|------|------|
| 检查前提条件 | Git、Docker Desktop 是否安装并运行 |
| 准备代码 | 自动 `git clone`（如果不存在）或 `git pull` 拉取最新 |
| 配置 `.env` | 自动生成随机密码和 JWT 密钥，写入 `.env` |
| 镜像加速检测 | 提示是否已配置 Docker 镜像加速 |
| 构建 & 启动 | `docker compose build` + `docker compose up -d`，等待所有容器就绪 |
| MinIO 存储桶 | `docker-compose.yml` 中的 `minio-init` 服务会自动创建 `snapshop-images` 桶 |
| 数据库迁移 | 自动执行 `alembic upgrade head` |
| 健康检查 | 验证 `http://localhost:8000/health` 返回 healthy |

> 自动生成的密码和密钥会在屏幕上显示一次，**请记录下来**。`.env` 已存在时脚本不会覆盖。

**命令行选项**：

| 选项 | 说明 |
|------|------|
| `-ProjectDir PATH` | 项目目录（默认 `f:\AI Shopping`） |
| `-SkipClone` | 跳过克隆，使用已有项目代码 |
| `-BuildOnly` | 仅构建 Docker 镜像，不启动服务 |

如果一键脚本无法使用（例如 PowerShell 执行策略限制），请参考下方 **B.1~B.9** 的手动部署步骤。

---

### B.1 前置环境要求

开始前请确认以下工具已安装并可正常使用：

| 工具 | 检查命令 | 最低版本 | 下载地址 |
|------|----------|----------|----------|
| Git | `git --version` | 2.40+ | https://git-scm.com/download/win |
| Docker Desktop | `docker ps` | 24.0+ | https://www.docker.com/products/docker-desktop/ |
| Python | `python --version` | 3.12+ | https://www.python.org/downloads/ |
| Flutter SDK | `flutter doctor` | 3.2+ | https://docs.flutter.dev/get-started/install/windows |

**安装注意事项**：

- **Docker Desktop**：安装后确保任务栏托盘图标为运行状态；首次启动可能需要启用 WSL2（按提示操作即可）
- **Flutter**：解压到不含空格的路径（如 `C:\flutter`），并将 `C:\flutter\bin` 加入系统 PATH；运行 `flutter doctor` 检查缺失项
- **Python**：安装时勾选 "Add Python to PATH"

---

### B.2 克隆项目

```powershell
# 在任意工作目录执行，例如 C:\Projects
cd \
git clone https://github.com/For2006/SnapShop.git "f:\AI Shopping"
cd "f:\AI Shopping"
```

克隆后项目结构：

```
f:\AI Shopping\
├── backend/          # Python FastAPI 后端
├── snapshop/         # Flutter 前端
├── deploy/           # 部署脚本 + Nginx 配置
├── docs/             # 文档
├── bootstrap.sh      # 一键部署脚本（Linux 服务器用）
├── START_HERE.md     # 本文档
└── README.md
```

---

### B.3 配置 Docker 镜像加速（可选）

如果拉取 Docker 镜像速度很慢，可以在 Docker Desktop 中配置国内镜像加速：

1. 打开 Docker Desktop → **Settings（设置）** → **Docker Engine**
2. 在 JSON 配置中添加 `registry-mirrors`：

```json
{
  "registry-mirrors": [
    "https://docker.m.daocloud.io",
    "https://mirror.ccs.tencentyun.com"
  ]
}
```

3. 点击 **Apply & Restart**

---

### B.4 配置后端 `.env`

```powershell
cd "f:\AI Shopping\backend"

# 复制环境变量模板
copy .env.example .env

# 用文本编辑器打开 .env（任选其一）
notepad .env
# 或 code .env（VS Code）
```

按以下说明逐项修改 `.env` 文件：

#### B.4.1 数据库连接

将默认的 SQLite 注释掉，启用 PostgreSQL：

```env
# 注释掉这行
# DATABASE_URL=sqlite+aiosqlite:///./snapshop.db

# 启用 PostgreSQL（密码与下方 POSTGRES_PASSWORD 保持一致）
DATABASE_URL=postgresql+asyncpg://snapshop:你的密码@localhost:5432/snapshop
```

同时设置密码：

```env
POSTGRES_USER=snapshop
POSTGRES_PASSWORD=你的密码（如 snapshop123）
POSTGRES_DB=snapshop
```

#### B.4.2 MinIO 对象存储

```env
MINIO_ENDPOINT=localhost:9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=你的MinIO密码（如 minioadmin123）
MINIO_BUCKET=snapshop-images
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=你的MinIO密码（同上）
```

#### B.4.3 JWT 密钥

在 PowerShell 中生成随机密钥：

```powershell
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

将生成的字符串填入：

```env
JWT_SECRET=粘贴生成的32位随机字符串
```

#### B.4.4 AI 配置

有火山方舟 API 密钥时填入真实值；没有时开启 Mock 模式也能跑通全流程：

```env
# 有 AI 密钥
ARK_API_KEY=你的API_Key
ARK_VLM_ENDPOINT_ID=ep-xxxxxx
ARK_LLM_ENDPOINT_ID=ep-xxxxxx
AI_MOCK_MODE=false

# 没有密钥 → 开启 Mock 模式
AI_MOCK_MODE=true
ARK_API_KEY=
ARK_VLM_ENDPOINT_ID=
ARK_LLM_ENDPOINT_ID=
```

#### B.4.5 配置完成检查清单

`.env` 文件修改完毕后，确认以下字段已正确填写：

- [ ] `DATABASE_URL` 指向 `postgresql+asyncpg://snapshop:你的密码@localhost:5432/snapshop`
- [ ] `POSTGRES_PASSWORD` 已设置
- [ ] `MINIO_ROOT_PASSWORD` 和 `MINIO_SECRET_KEY` 已设置（保持一致）
- [ ] `JWT_SECRET` 已填入随机生成的 32 位字符串
- [ ] `DEBUG=true`（开发模式）

---

### B.5 启动 Docker 服务

```powershell
cd "f:\AI Shopping\backend"

# 启动所有容器（首次启动会构建 backend 镜像并拉取依赖镜像）
docker compose up -d
```

> 首次启动约需 3-10 分钟（取决于网络速度），后续启动通常不到 30 秒。

**等待所有容器就绪后，检查状态**：

```powershell
docker compose ps
```

预期输出：4 个容器全部显示 `healthy` 或 `running`：

| 容器名 | 状态 | 端口 |
|--------|------|------|
| backend-backend-1 | running | 8000 |
| backend-db-1 | healthy | 5432 |
| backend-redis-1 | healthy | 6379 |
| backend-minio-1 | running | 9000, 9001 |

---

### B.6 MinIO 存储桶配置

`docker compose up -d` 启动时会自动执行 `minio-init` 服务，创建 `snapshop-images` 存储桶。可以通过以下方式验证：

```powershell
# 查看 minio-init 日志，确认桶已创建
docker compose logs minio-init | Select-String "snapshop-images ready"
```

如果 `minio-init` 未自动创建，可手动操作：

1. 浏览器访问 **[http://localhost:9001](http://localhost:9001)**
2. 输入用户名和密码（你在 `.env` 中设置的 `MINIO_ROOT_USER` 和 `MINIO_ROOT_PASSWORD`）
3. 点击左侧 **Buckets** → **Create Bucket**
4. Bucket Name 输入 `snapshop-images` → 点击 **Create Bucket**

> 该步骤**首次启动只需执行一次**，后续重启 Docker 不需要重复操作。

---

### B.7 数据库迁移 & 验证

```powershell
cd "f:\AI Shopping\backend"

# 运行数据库迁移（创建表结构）
docker compose exec backend alembic upgrade head

# 预期输出: INFO  [alembic.runtime.migration] Running upgrade ... -> 2025_01_01_0000, initial migration
```

**验证后端是否就绪**：

```powershell
curl http://localhost:8000/health
# 预期返回：{"status":"healthy"}
```

也可以浏览器打开 **[http://localhost:8000/docs](http://localhost:8000/docs)** 查看 Swagger API 交互文档。

---

### B.8 启动 Flutter 前端

```powershell
cd "f:\AI Shopping\snapshop"

# 安装依赖（首次执行）
flutter pub get

# 启动应用
flutter run
```

> 前端代码已自动适配连接地址：
> - **Windows 桌面 / iOS 模拟器** → `http://localhost:8000`
> - **Android 模拟器** → `http://10.0.2.2:8000`
>
> 无需手动修改任何配置。

**选择运行目标**：

- `flutter run` 会自动检测可用设备并列出，输入编号选择
- 指定设备：`flutter run -d windows`（桌面）或 `flutter run -d <设备ID>`

---

### B.9 连接安卓真机调试

如果想在安卓手机上调试（后端在电脑上运行），需要让手机能访问电脑的 `localhost`。

#### 方法一：ADB 反向代理（推荐，手机 USB 连电脑）

```powershell
# 1. 手机开启「开发者选项」→ 开启「USB 调试」
# 2. USB 连接电脑

# 3. 验证 ADB 可用
adb devices

# 4. 建立反向代理（将手机 8000 端口转发到电脑 8000）
adb reverse tcp:8000 tcp:8000

# 5. 启动 Flutter
cd "f:\AI Shopping\snapshop"
flutter run
```

#### 方法二：局域网 IP 直连

如果手机和电脑在同一 Wi-Fi 下：

```powershell
# 查看电脑局域网 IP
ipconfig

# 找到「无线局域网适配器 WLAN」或「以太网适配器」下的 IPv4 地址
# 例如: 192.168.1.100
```

然后编辑 `snapshop\lib\core\network\api_client.dart`，将 localhost 改为该 IP：

```dart
static const String _baseUrl = 'http://192.168.1.100:8000';
```

> 这种方式需要确保 Windows 防火墙允许 8000 端口入站连接。

---

## C. 后端 `.env` 配置详解

以下为 `.env` 所有字段的完整说明，按用途分类。

### C.1 比赛专用 AI 资源

大赛组委会提供的火山方舟 AI 推理资源，用于视觉识别（VLM）和智能建议生成（LLM）：

| 配置项 | 值 | 说明 |
|--------|-----|------|
| `ARK_API_KEY` | `你的火山方舟 API Key` | 火山方舟 API Key |
| `ARK_VLM_ENDPOINT_ID` | `ep-xxxxxx` | VLM 视觉模型端点 |
| `ARK_LLM_ENDPOINT_ID` | `ep-xxxxxx` | LLM 语言模型端点 |
| `ARK_BASE_URL` | `https://ark.cn-beijing.volces.com/api/v3` | API 基础地址 |
| `AI_MOCK_MODE` | `false`（真实 AI）/ `true`（Mock 降级） | Mock 模式不调用真实 AI |

### C.2 数据库与缓存

| 配置项 | 本地开发值 | 说明 |
|--------|-----------|------|
| `POSTGRES_USER` | `snapshop` | 数据库用户名 |
| `POSTGRES_PASSWORD` | 自行设置 | 数据库密码 |
| `POSTGRES_DB` | `snapshop` | 数据库名称 |
| `DATABASE_URL` | `postgresql+asyncpg://snapshop:密码@localhost:5432/snapshop` | 本地连接 |
| `REDIS_URL` | `redis://localhost:6379/0` | 本地 Redis |

### C.3 JWT 密钥

```powershell
# 生成随机密钥
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

```env
JWT_SECRET=生成的随机密钥
```

> 开发模式下（`DEBUG=true`）若未设置 `JWT_SECRET`，应用启动时会自动生成临时密钥，但每次重启都会变化，导致登录 token 失效。

### C.4 MinIO 对象存储

| 配置项 | 本地值 | 说明 |
|--------|--------|------|
| `MINIO_ENDPOINT` | `localhost:9000` | MinIO S3 API 地址 |
| `MINIO_ACCESS_KEY` | `minioadmin` | S3 Access Key |
| `MINIO_SECRET_KEY` | 自行设置 | S3 Secret Key |
| `MINIO_BUCKET` | `snapshop-images` | 图片存储桶名称 |
| `MINIO_ROOT_USER` | `minioadmin` | MinIO 管理员用户名 |
| `MINIO_ROOT_PASSWORD` | 自行设置（与 SECRET_KEY 相同） | MinIO 管理员密码 |

### C.5 电商平台 API 密钥（可选）

可用于接入京东联盟、拼多多开放平台的真实商品数据。留空则自动使用内置 Mock 数据。

| 配置项 | 说明 |
|--------|------|
| `JD_APP_KEY` / `JD_APP_SECRET` / `JD_ACCESS_TOKEN` | 京东联盟 API |
| `PDD_CLIENT_ID` / `PDD_CLIENT_SECRET` / `PDD_ACCESS_TOKEN` | 拼多多开放平台 API |

---

## D. 最小功能验证（6 条核心路径）

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

## E. API 文档入口

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

## F. 常见问题排查

### Docker 相关

**Docker 未启动**

```powershell
# 现象：docker compose up -d 报连接错误
# 解决：确保 Docker Desktop 已启动（Windows 托盘图标应为运行状态）
docker ps
```

**端口冲突**

```powershell
# 检查哪些端口被占用
netstat -ano | findstr "8000 5432 6379 9000 9001"

# 如果需要，停止冲突的本地服务
# 或修改 docker-compose.yml 中的端口映射
```

**镜像拉取速度慢**

在 Docker Desktop `Settings → Docker Engine` 中添加镜像加速（见 [B.3 节](#b3-配置-docker-镜像加速可选)）。

### 后端相关

**数据库连接失败**

```powershell
# 检查 PostgreSQL 是否就绪
docker compose ps db
# 状态应为 "healthy"

# 如果不健康，查看日志：
docker compose logs db
```

**环境变量未生效**

修改 `.env` 后需要重启后端服务：

```powershell
cd "f:\AI Shopping\backend"
docker compose down
docker compose up -d
```

### 前端相关

**Flutter 编译错误**

```powershell
cd "f:\AI Shopping\snapshop"
flutter clean
flutter pub get
flutter run
```

### 图片上传相关

**图片上传失败**

| 可能原因 | 解决方法 |
|----------|----------|
| MinIO 未正确启动 | `docker compose logs minio` 查看日志 |
| MinIO bucket 未创建 | 访问 http://localhost:9001 手动创建 `snapshop-images` bucket |
| 图片过大 | 前端自动压缩至 ≤2MB，确保 `image_picker` 和 `flutter_image_compress` 插件正常 |
| AI Mock 模式 | 检查 `.env` 中 `AI_MOCK_MODE=true` 或用 Mock 模式测试 |

---

## G. 文档索引

- [产品需求文档 (PRD)](docs/PRD.md)
- [架构设计文档](docs/architecture.md)
- [API 说明文档](docs/api.md)
- [功能结构图](docs/功能结构图.md)
- [Mock 模拟数据说明](docs/mock-data.md)
- [AI 使用总结](docs/ai-usage-summary.md)
- [标准测试用例](docs/test-cases.md)
- [项目分工说明](docs/team-division.md)

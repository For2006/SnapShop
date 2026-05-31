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
| 部署 | Docker Compose (PostgreSQL 16 + Redis 7 + MinIO) |
| 电商 | 拼多多联盟 API · 京东联盟 API |

## 快速开始

### 环境要求

- Flutter SDK >= 3.2.0
- Python >= 3.12
- Docker Desktop

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

## 项目结构

```
├── backend/                # Python FastAPI 后端
│   ├── app/
│   │   ├── api/v1/         # REST + SSE 路由 (10 个端点)
│   │   ├── services/       # 业务逻辑层
│   │   ├── clients/        # 火山方舟 / 电商平台客户端
│   │   ├── models/         # SQLAlchemy 数据模型
│   │   └── schemas/        # Pydantic 请求/响应模型
│   ├── tests/              # pytest (32 tests)
│   └── docker-compose.yml  # 服务编排
├── snapshop/               # Flutter 前端
│   └── lib/
│       ├── config/         # 路由 · 主题 · 国际化
│       ├── core/           # 网络层 · 工具类
│       ├── features/       # 功能模块 (首页/识别/商品/筛选/设置/收藏)
│       └── shared/         # 共用组件
└── docs/                   # PRD · 架构设计 · 功能结构图
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

## 文档

- [产品需求文档 (PRD)](docs/PRD.md)
- [架构设计文档](docs/architecture.md)
- [功能结构图](docs/功能结构图.md)
- [开发任务跟踪](docs/tasks.md)

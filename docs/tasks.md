# SnapShop 后端构建 — 分阶段开发计划

> **最后更新**: 2026-05-30 | **进度**: ✅ 全部完成 (32/32 tests pass)

---

## 最终架构

```
backend/        ← 全部完成 ✅
snapshop/       ← 前端接入完成 ✅
```

---

## 完成总览

| 阶段 | 内容 | 状态 |
|------|------|------|
| 第一部分 | 基础设施与数据层 | ✅ |
| 第二部分 | 基础能力层 (6项) | ✅ |
| 第三部分 | 核心业务服务层 (6个Service) | ✅ |
| 第四部分 | API 路由层 (11个端点) | ✅ |
| 第五部分 | 前端接入适配 (4阶段) | ✅ |
| 第六部分 | 用户认证系统 (JWT) | ✅ |
| 第七部分 | 收藏 + 浏览记录功能 | ✅ |
| 第八部分 | 测试与验证 (32 tests) | ✅ |

---

## 第六部分: 用户认证系统

- **后端新增**: `models/user.py`, `core/security.py`, `api/v1/auth.py`, `schemas/auth.py`
- **API 端点**: `POST /auth/register`, `POST /auth/login`
- **认证方式**: JWT Bearer token (python-jose) + bcrypt 密码哈希 (passlib)
- **前端**: `login_page.dart` 对接真实接口, `api_client.dart` 自动注入 Bearer token

## 第七部分: 收藏 + 浏览记录

- **后端新增**: `models/favorite.py`, `models/browse_history.py`, `api/v1/favorites.py`, `api/v1/browse.py`, `api/v1/stats.py`, `services/browse_recorder.py`
- **API 端点**: `POST/DELETE/GET /favorites`, `POST/GET /browse`, `GET /user/stats`
- **前端新增**: `features/profile/profile_page.dart`, `features/favorites/favorites_tab.dart`, `features/profile/browse_list_tab.dart`
- **前端修改**: 首页移除浏览记录, 设置页卡片跳转个人中心 + 显示收藏/浏览统计, 商品卡片新增收藏按钮

## 已移除内容

- Mock 种子商品库 (`seed_products.json`) — 已删除
- Mock 平台客户端 (`mock_platform_client.py`) — 已删除
- Mock VLM 识别常量 (`ark_vlm_client.py`, `ark_llm_client.py`) — 已删除
- 前端硬编码 Mock 常量数据 — 已删除
- 前端设置页硬编码收藏/足迹统计 — 已删除

> 注: `mock_data.dart` 保留其数据模型类定义 (MockProduct/MockAttribute/MockSuggestion/MockRecognitionResult)，被 14 个文件引用作为类型定义使用，但不再包含硬编码的假数据内容。

---

## 最终统计

| 层级 | 文件数 | 测试 |
|------|--------|------|
| 配置/入口 | 5 | — |
| 数据模型 | 7 | — |
| Pydantic Schema | 7 | — |
| AI 客户端 | 3 | — |
| 策略/容错 | 2 | 12 |
| 平台客户端 | 2 | — |
| 业务服务 | 7 | 5 |
| API 路由 | 10 | 15 |
| 前端新增页面 | 6 | — |
| 前端修改 | 12 | — |
| **总计** | **61** | **32** |

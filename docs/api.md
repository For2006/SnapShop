# SnapShop — API 说明文档

> **项目**：SnapShop — AI 拍照识物与智能比价购物助手
> **规范**：OpenAPI 3.0（FastAPI 自动生成，访问 `/docs` 或 `/openapi.json`）
> **更新日期**：2026-06-11

---

## 1. 概述

SnapShop 后端基于 FastAPI 构建，所有 API 以 `/api/v1/` 为前缀。后端启动后提供两种 API 文档入口：

- **`http://localhost:8000/docs`** — Swagger UI 交互式文档（可直接在浏览器中调试 API）
- **`http://localhost:8000/openapi.json`** — OpenAPI 3.0 规范 JSON（机器可读）

### 1.1 认证方式

部分接口需要认证。认证采用 JWT Bearer Token：

```
Authorization: Bearer <access_token>
```

匿名用户通过 `X-Device-Id` 请求头标识设备：
```
X-Device-Id: <device_uuid>
```

### 1.2 通用响应格式

**成功响应**：
```json
{
  "field1": "value",
  "field2": 123
}
```

**错误响应**：
```json
{
  "error_code": "ERROR_CODE",
  "message": "人类可读的错误描述",
  "detail": null
}
```

### 1.3 限流

| 接口类型 | 限制 |
|---------|------|
| 图片识别 (`/recognize`) | 10 次/分钟/设备 |
| 自然语言筛选 (`/filter`) | 30 次/分钟/设备 |
| 登录/注册 (`/auth/*`) | 5 次/分钟/设备 |

---

## 2. 商品识别

### 2.1 图片上传识别

```
POST /api/v1/recognize
```

**描述**：上传商品图片，VLM 视觉模型识别商品属性并触发后台跨平台搜索。

**认证**：无需登录（通过 `X-Device-Id` 标注设备）

**请求**：`multipart/form-data`

| 字段 | 类型 | 必填 | 说明 |
|------|------|:--:|------|
| `image` | File | ✅ | 商品图片，支持 JPEG / PNG / WebP，≤5MB |

**响应**：

```json
{
  "session_id": "550e8400-e29b-41d4-a716-446655440000",
  "recognition": {
    "category": "运动鞋",
    "attributes": [
      {"key": "category", "label": "品类", "value": "运动鞋"},
      {"key": "brand", "label": "品牌", "value": "Nike"},
      {"key": "color", "label": "颜色", "value": "黑色"},
      {"key": "style", "label": "风格", "value": "运动"}
    ],
    "suggestions": [
      {"id": "sort_price", "title": "查看同款低价", "icon": "trending-down", "action": "sort", "type": "normal"},
      {"id": "sort_sales", "title": "按销量排序", "icon": "trending-up", "action": "sort", "type": "normal"}
    ]
  },
  "suggestions": [],
  "products": [],
  "price_summary": []
}
```

> **注意**：`products` 初始为空，后台异步搜索完成后通过轮询 `GET /products/{session_id}` 获取商品列表。

**错误码**：

| 状态码 | 错误码 | 说明 |
|--------|--------|------|
| 400 | `INVALID_IMAGE` | 图片格式不支持或文件为空 |
| 400 | `RECOGNITION_FAILED` | VLM 未识别到商品 |
| 400 | `IMAGE_TOO_LARGE` | 图片超过 5MB |
| 429 | `RATE_LIMITED` | 请求过于频繁 |

---

### 2.2 属性修正

```
PATCH /api/v1/recognize/{session_id}/attributes
```

**描述**：用户修正 VLM 识别不准确的属性值，触发重新检索（纯结构化操作，不调用 LLM）。

**认证**：无需登录

**路径参数**：

| 参数 | 类型 | 说明 |
|------|------|------|
| `session_id` | UUID | 识别会话 ID |

**请求体**：

```json
{
  "attribute": "color",
  "new_value": "深蓝色"
}
```

**响应**：

```json
{
  "updated_attributes": [
    {"key": "category", "label": "品类", "value": "运动鞋"},
    {"key": "brand", "label": "品牌", "value": "Nike"},
    {"key": "color", "label": "颜色", "value": "深蓝色"}
  ],
  "products": [
    {
      "id": "...",
      "name": "Nike Air Max 270 透气缓震跑步鞋",
      "price": 599.00,
      "platform": "jd",
      "shop_name": "京东自营官方旗舰店",
      "rating": 4.8,
      "sales_count": 12580,
      "image_url": "...",
      "product_url": "...",
      "is_mock": true,
      "tags": ["自营", "京东物流"]
    }
  ]
}
```

---

## 3. 文字搜索

### 3.1 关键词搜索

```
POST /api/v1/search
```

**描述**：直接输入关键词搜索商品，跳过 VLM 视觉识别环节。

**认证**：无需登录

**请求体**：

```json
{
  "keywords": ["蓝牙耳机", "降噪"]
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|:--:|------|
| `keywords` | string[] | ✅ | 搜索关键词列表 |

**响应**：

```json
{
  "session_id": "550e8400-e29b-41d4-a716-446655440001",
  "suggestions": [
    {"id": "sort_price", "title": "查看同款低价", "icon": "trending-down", "action": "sort", "type": "normal"},
    {"id": "sort_sales", "title": "按销量排序", "icon": "trending-up", "action": "sort", "type": "normal"},
    {"id": "sort_rating", "title": "按评分排序", "icon": "star", "action": "sort", "type": "normal"},
    {"id": "filter_official", "title": "只看官方旗舰店", "icon": "shield-check", "action": "filter", "type": "normal"}
  ],
  "products": [
    {
      "id": "...",
      "name": "Apple AirPods Pro 2 主动降噪耳机",
      "price": 1599.00,
      "original_price": 1899.00,
      "platform": "jd",
      "shop_name": "京东自营官方旗舰店",
      "shop_type": "self_operated",
      "rating": 4.9,
      "sales_count": 56700,
      "image_url": "...",
      "product_url": "...",
      "is_mock": true,
      "attributes": {"brand": "Apple", "category": "蓝牙耳机"},
      "tags": ["自营", "京东物流"]
    }
  ],
  "price_summary": [
    {"platform": "京东", "platform_code": "jd", "min_price": 199.00, "avg_price": 899.00, "count": 15},
    {"platform": "拼多多", "platform_code": "pdd", "min_price": 159.00, "avg_price": 699.00, "count": 12}
  ]
}
```

---

## 4. 商品列表

### 4.1 获取会话商品

```
GET /api/v1/products/{session_id}
```

**描述**：获取指定识别会话的商品列表，支持排序、分页和平台筛选。

**认证**：无需登录

**路径参数**：

| 参数 | 类型 | 说明 |
|------|------|------|
| `session_id` | UUID | 识别会话 ID |

**查询参数**：

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `page` | int | 1 | 页码（≥1） |
| `size` | int | 20 | 每页条数（1~100） |
| `sort_by` | string | `comprehensive` | 排序方式：`comprehensive` / `price_asc` / `price_desc` / `sales` / `rating` |
| `platform` | string | — | 平台筛选：`taobao` / `jd` / `pdd` |

**响应**：

```json
{
  "items": [
    {
      "id": "...",
      "name": "Nike Air Max 270 男子气垫跑步鞋",
      "price": 599.00,
      "original_price": 799.00,
      "platform": "jd",
      "shop_name": "京东自营官方旗舰店",
      "shop_type": "self_operated",
      "rating": 4.9,
      "sales_count": 12580,
      "image_url": "...",
      "product_url": "...",
      "is_mock": true,
      "attributes": {"brand": "Nike", "category": "运动鞋"},
      "tags": []
    }
  ],
  "total": 45,
  "page": 1,
  "size": 20
}
```

---

## 5. 智能建议

### 5.1 执行建议卡片动作

```
POST /api/v1/suggestions/action
```

**描述**：用户点击建议卡片后，执行对应的排序或筛选动作。

**认证**：无需登录

**请求体**：

```json
{
  "session_id": "550e8400-e29b-41d4-a716-446655440000",
  "card_id": "sort_price",
  "params": {}
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|:--:|------|
| `session_id` | str | ✅ | 搜索会话 ID |
| `card_id` | str | ✅ | 卡片 ID（如 `sort_price`、`filter_official`） |
| `params` | object | — | 卡片参数 |

**响应**：

```json
{
  "products": [
    {
      "id": "...",
      "name": "特步动力巢T20 马拉松竞速鞋",
      "price": 299.00,
      "platform": "jd",
      "...": "..."
    }
  ]
}
```

---

## 6. 自然语言筛选

### 6.1 SSE 流式筛选

```
GET /api/v1/filter/stream?session_id={uuid}&filter_text={text}
```

**描述**：通过自然语言追加筛选条件，SSE 流式逐条推送匹配商品。

**认证**：无需登录

**查询参数**：

| 参数 | 类型 | 必填 | 说明 |
|------|------|:--:|------|
| `session_id` | UUID | ✅ | 搜索会话 ID |
| `filter_text` | string | ✅ | 自然语言筛选条件（如 "500元以内黑色 评分4.5以上"） |

**响应格式**：`text/event-stream`

```
data: {"type": "parsing", "filters": {"price_max": 500, "color": "黑色", "min_rating": 4.5}}

data: {"type": "product", "product": {"id": "...", "name": "黑色运动鞋 A", "price": 399, ...}}

data: {"type": "product", "product": {"id": "...", "name": "黑色运动鞋 B", "price": 299, ...}}

data: {"type": "summary", "total": 15, "platforms": {"jd": 8, "pdd": 7}}

data: {"type": "done"}
```

**SSE 事件类型**：

| 事件类型 | 说明 |
|----------|------|
| `parsing` | LLM 解析出的结构化过滤参数 |
| `product` | 逐条推送的匹配商品 |
| `summary` | 筛选结果汇总（总量、平台分布） |
| `done` | 推送完成 |

---

### 6.2 筛选卡片解析（非流式）

```
POST /api/v1/filter
```

**描述**：将自然语言解析为可交互的筛选卡片，不返回商品。

**认证**：无需登录

**请求体**：

```json
{
  "session_id": "550e8400-e29b-41d4-a716-446655440000",
  "filter_text": "200元以内 红色 自营"
}
```

**响应**：

```json
{
  "filters": {
    "price_max": 200.00,
    "color": "红色",
    "shop_type": "self_operated"
  },
  "cards": [
    {"id": "filter_price", "title": "200元以内", "type": "filter"},
    {"id": "filter_color", "title": "红色", "type": "filter"},
    {"id": "filter_shop", "title": "仅自营", "type": "filter"}
  ]
}
```

---

## 7. 用户认证

### 7.1 注册

```
POST /api/v1/auth/register
```

**描述**：使用手机号和密码注册账号。

**认证**：无（限流：5次/分钟）

**请求体**：

```json
{
  "phone": "13800138000",
  "password": "Pass1234"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|:--:|------|
| `phone` | string | ✅ | 11位手机号 |
| `password` | string | ✅ | 密码（≥8位，含字母和数字） |

**响应**（201 Created）：

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "bearer",
  "user": {
    "id": "uuid",
    "phone": "138****8000",
    "nickname": "用户8000",
    "avatar_url": null,
    "bio": null
  }
}
```

**错误码**：

| 状态码 | 错误码 | 说明 |
|--------|--------|------|
| 409 | `PHONE_ALREADY_EXISTS` | 手机号已被注册 |
| 429 | `RATE_LIMITED` | 请求过于频繁 |

---

### 7.2 登录

```
POST /api/v1/auth/login
```

**描述**：使用手机号和密码登录。

**认证**：无（限流：5次/分钟）

**请求体**：同注册

**响应**：同注册（200 OK）

**错误码**：

| 状态码 | 错误码 | 说明 |
|--------|--------|------|
| 401 | `INVALID_CREDENTIALS` | 手机号或密码错误 |
| 429 | `RATE_LIMITED` | 请求过于频繁 |

---

### 7.3 短信验证码登录

```
POST /api/v1/auth/sms-login
```

**描述**：发送短信验证码 → 验证码登录。新手机号自动注册。

**步骤1：发送验证码**

```
POST /api/v1/auth/send-sms-code
```

**请求体**：

```json
{
  "phone": "13800138000",
  "scene": "login"
}
```

**响应**：

```json
{
  "success": true,
  "debug_code": "123456"
}
```

> `debug_code` 仅开发环境返回，生产环境不返回。

**步骤2：验证码登录**

```
POST /api/v1/auth/sms-login
```

**请求体**：

```json
{
  "phone": "13800138000",
  "code": "123456"
}
```

**响应**：同登录（200 OK）

---

### 7.4 退出登录

```
POST /api/v1/auth/logout
```

**描述**：吊销当前 JWT Token。

**认证**：需要（`Bearer <token>`）

**请求头**：
```
Authorization: Bearer <token>
```

**响应**：

```json
{
  "success": true,
  "message": "登出成功，Token 已吊销"
}
```

---

### 7.5 修改密码

```
POST /api/v1/auth/change-password
```

**描述**：登录后修改密码，同时吊销当前 Token。

**认证**：需要（`Bearer <token>`）

**请求体**：

```json
{
  "old_password": "OldPass1234",
  "new_password": "NewPass5678"
}
```

**响应**：

```json
{
  "success": true,
  "message": "密码修改成功"
}
```

**错误码**：

| 状态码 | 错误码 | 说明 |
|--------|--------|------|
| 400 | `OLD_PASSWORD_MISMATCH` | 原密码不正确 |

---

### 7.6 换绑手机号

```
POST /api/v1/auth/change-phone
```

**描述**：验证密码 + 新手机号验证码后换绑。

**认证**：需要（`Bearer <token>`）

**请求体**：

```json
{
  "password": "Pass1234",
  "new_phone": "13900139000",
  "new_phone_code": "654321"
}
```

**响应**：

```json
{
  "success": true,
  "message": "手机号换绑成功",
  "new_masked_phone": "139****9000"
}
```

---

### 7.7 更新个人资料

```
PATCH /api/v1/auth/profile
```

**描述**：更新昵称、头像、个人简介。

**认证**：需要（`Bearer <token>`）

**请求体**：

```json
{
  "nickname": "新昵称",
  "avatar_url": "https://example.com/avatar.jpg",
  "bio": "这是我的个人简介"
}
```

> 三个字段均为可选，传入的字段才更新。

**响应**：

```json
{
  "id": "uuid",
  "phone": "138****8000",
  "nickname": "新昵称",
  "avatar_url": "https://example.com/avatar.jpg",
  "bio": "这是我的个人简介"
}
```

---

## 8. 收藏管理

> 以下接口均需登录认证（`Bearer <token>`）。

### 8.1 添加收藏

```
POST /api/v1/favorites
```

**请求体**：

```json
{
  "product_id": "jd_运动鞋_0_123456",
  "product_snapshot": {
    "name": "Nike Air Max 270 男子气垫跑步鞋",
    "price": 599.00,
    "original_price": 799.00,
    "platform": "jd",
    "shop_name": "京东自营官方旗舰店",
    "rating": 4.9,
    "sales_count": 12580,
    "image_url": "...",
    "product_url": "...",
    "tags": ["自营"],
    "attributes": {"brand": "Nike", "category": "运动鞋"}
  }
}
```

**响应**（201 Created）：

```json
{
  "id": "uuid",
  "product_id": "jd_运动鞋_0_123456",
  "product_snapshot": {
    "name": "Nike Air Max 270 男子气垫跑步鞋",
    "price": 599.00,
    "...": "..."
  },
  "created_at": "2026-06-11T12:00:00Z"
}
```

---

### 8.2 取消收藏

```
DELETE /api/v1/favorites/{product_id}
```

**路径参数**：

| 参数 | 类型 | 说明 |
|------|------|------|
| `product_id` | string | 商品 ID |

**响应**：

```json
{
  "message": "ok"
}
```

---

### 8.3 收藏列表

```
GET /api/v1/favorites?page=1&size=20
```

**查询参数**：

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `page` | int | 1 | 页码（≥1） |
| `size` | int | 20 | 每页条数（1~50） |

**响应**：

```json
{
  "items": [
    {
      "id": "uuid",
      "product_id": "jd_运动鞋_0_123456",
      "product_snapshot": {
        "name": "Nike Air Max 270",
        "price": 599.00,
        "...": "..."
      },
      "created_at": "2026-06-11T12:00:00Z"
    }
  ],
  "total": 3,
  "page": 1,
  "size": 20
}
```

---

## 9. 浏览记录

### 9.1 记录浏览

```
POST /api/v1/browse
```

**描述**：记录一次商品浏览。当天同一商品不重复记录。

**认证**：可选（已登录关联 `user_id`，未登录关联 `X-Device-Id`）

**请求头**（未登录时）：
```
X-Device-Id: device-uuid-xxx
```

**请求体**：

```json
{
  "product_id": "jd_运动鞋_0_123456",
  "product_snapshot": {
    "name": "Nike Air Max 270",
    "price": 599.00,
    "...": "..."
  }
}
```

**响应**：

```json
{
  "message": "ok"
}
```

---

### 9.2 浏览记录列表

```
GET /api/v1/browse?page=1&size=20
```

**查询参数**：同收藏列表

**响应**：

```json
{
  "items": [
    {
      "id": "uuid",
      "product_id": "jd_运动鞋_0_123456",
      "product_snapshot": {
        "name": "Nike Air Max 270",
        "price": 599.00,
        "...": "..."
      },
      "viewed_at": "2026-06-11T11:00:00Z"
    }
  ],
  "total": 15,
  "page": 1,
  "size": 20
}
```

---

### 9.3 删除单条浏览记录

```
DELETE /api/v1/browse/{browse_id}
```

---

### 9.4 清空全部浏览记录

```
DELETE /api/v1/browse
```

**响应**：

```json
{
  "ok": true,
  "cleared": true
}
```

---

## 10. 搜索历史

### 10.1 获取搜索历史

```
GET /api/v1/history?page=1&size=10
```

**描述**：获取当前设备的已完成搜索记录。

**认证**：无需登录（通过 `X-Device-Id` 识别设备）

**查询参数**：

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `page` | int | 1 | 页码 |
| `size` | int | 10 | 每页条数（1~50） |

**响应**：

```json
{
  "items": [
    {
      "session_id": "uuid",
      "image_url": null,
      "category": "运动鞋",
      "search_type": "text",
      "search_query": "运动鞋",
      "created_at": "2026-06-11T10:00:00Z"
    }
  ],
  "total": 5,
  "page": 1,
  "size": 10
}
```

---

### 10.2 清空全部搜索历史

```
DELETE /api/v1/history
```

**响应**：

```json
{
  "ok": true,
  "cleared": 5
}
```

---

### 10.3 删除单条搜索历史

```
DELETE /api/v1/history/{session_id}
```

---

## 11. 用户统计

```
GET /api/v1/user/stats
```

**描述**：获取当前用户的收藏数和浏览数。

**认证**：可选（已登录返回完整统计，未登录仅返回设备浏览数）

**请求头**（未登录时）：
```
X-Device-Id: device-uuid-xxx
```

**响应**：

```json
{
  "favorite_count": 3,
  "browse_count": 15
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `favorite_count` | int | 收藏数（未登录为 0） |
| `browse_count` | int | 浏览记录数 |

---

## 12. 健康检查

```
GET /health
```

**描述**：检查服务是否正常运行（不参与限流、不记录日志）。

**响应**：

```json
{
  "status": "healthy"
}
```

---

## 13. 错误码汇总

| HTTP 状态码 | 错误码 | 说明 |
|-------------|--------|------|
| 400 | `VALIDATION_ERROR` | 请求参数校验失败 |
| 400 | `INVALID_IMAGE` | 图片格式/大小不合法 |
| 400 | `RECOGNITION_FAILED` | VLM 未识别到商品 |
| 400 | `IMAGE_TOO_LARGE` | 图片超过 5MB |
| 400 | `OLD_PASSWORD_MISMATCH` | 原密码不正确 |
| 401 | `UNAUTHORIZED` | 未登录或 Token 过期 |
| 401 | `INVALID_CREDENTIALS` | 手机号或密码错误 |
| 401 | `INVALID_SMS_CODE` | 验证码错误或已过期 |
| 404 | `NOT_FOUND` | 记录不存在 |
| 409 | `PHONE_ALREADY_EXISTS` | 手机号已被注册 |
| 413 | `IMAGE_TOO_LARGE` | 图片过大（Nginx 层 10MB） |
| 429 | `RATE_LIMITED` | 请求过于频繁 |
| 429 | `SMS_CODE_TOO_FREQUENT` | 验证码发送过于频繁 |
| 500 | `INTERNAL_ERROR` | 服务器内部错误 |
| 500 | `AI_SERVICE_ERROR` | VLM/LLM 服务异常 |
| 503 | `SERVICE_UNAVAILABLE` | 服务降级中 |

---

## 14. 完整端点索引

| # | 方法 | 路径 | 认证 | 说明 |
|---|------|------|:--:|------|
| 1 | `POST` | `/api/v1/recognize` | — | 图片上传 + VLM 识别 |
| 2 | `PATCH` | `/api/v1/recognize/{id}/attributes` | — | 属性修正 |
| 3 | `POST` | `/api/v1/search` | — | 文字关键词搜索 |
| 4 | `GET` | `/api/v1/products/{id}` | — | 获取会话商品列表 |
| 5 | `POST` | `/api/v1/suggestions/action` | — | 执行建议卡片动作 |
| 6 | `GET` | `/api/v1/filter/stream` | — | SSE 自然语言流式筛选 |
| 7 | `POST` | `/api/v1/filter` | — | 自然语言筛选卡片解析 |
| 8 | `POST` | `/api/v1/auth/register` | — | 用户注册 |
| 9 | `POST` | `/api/v1/auth/login` | — | 用户登录 |
| 10 | `POST` | `/api/v1/auth/sms-login` | — | 短信验证码登录 |
| 11 | `POST` | `/api/v1/auth/send-sms-code` | — | 发送验证码 |
| 12 | `POST` | `/api/v1/auth/logout` | ✅ | 退出登录 |
| 13 | `POST` | `/api/v1/auth/change-password` | ✅ | 修改密码 |
| 14 | `POST` | `/api/v1/auth/change-phone` | ✅ | 换绑手机号 |
| 15 | `PATCH` | `/api/v1/auth/profile` | ✅ | 更新个人资料 |
| 16 | `POST` | `/api/v1/favorites` | ✅ | 添加收藏 |
| 17 | `DELETE` | `/api/v1/favorites/{id}` | ✅ | 取消收藏 |
| 18 | `GET` | `/api/v1/favorites` | ✅ | 收藏列表 |
| 19 | `POST` | `/api/v1/browse` | — | 记录浏览 |
| 20 | `GET` | `/api/v1/browse` | — | 浏览记录列表 |
| 21 | `DELETE` | `/api/v1/browse/{id}` | — | 删除单条浏览 |
| 22 | `DELETE` | `/api/v1/browse` | — | 清空全部浏览 |
| 23 | `GET` | `/api/v1/history` | — | 搜索历史列表 |
| 24 | `DELETE` | `/api/v1/history` | — | 清空搜索历史 |
| 25 | `DELETE` | `/api/v1/history/{id}` | — | 删除单条搜索历史 |
| 26 | `GET` | `/api/v1/user/stats` | — | 用户统计 |
| 27 | `GET` | `/health` | — | 健康检查 |

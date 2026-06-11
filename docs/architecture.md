# AI 拍照识物与智能比价购物助手 — 架构设计文档

> **产品名称**：SnapShop | **技术栈**：基于 Flutter 构建，MVP 阶段优先交付 Android/iOS 双端，架构层通过 Platform Channel 抽象预留纯原生鸿蒙（OpenHarmony）的适配扩展能力 | **日期**：2026-05-23

---

## 1. 系统架构总览

### 1.1 四层架构

```
┌─────────────────────────────────────────────────────────────────────┐
│                        展示层 (Flutter)                              │
│    MVP阶段优先交付Android/iOS双端，架构预留鸿蒙扩展能力               │
│  搜索栏 · 相机预览 · 相册选择 · 识别结果 · 建议卡片 · 商品列表       │
│                         HTTP/SSE (HTTPS)                            │
├─────────────────────────────────────────────────────────────────────┤
│                        网关层                                       │
│              Nginx — 反向代理 · TLS 终止 · 限流 · 图片上传大小控制    │
├─────────────────────────────────────────────────────────────────────┤
│                        服务层 (FastAPI)                              │
│  ┌─────────────────┐ ┌──────────────────┐ ┌────────────────────┐   │
│  │ 图像识别服务      │ │ 商品检索&比价服务 │ │ 导购决策服务         │   │
│  │ VLM调用 · 属性   │ │ 跨平台召回 · 聚合 │ │ 建议卡片 · LLM筛选  │   │
│  │ 解析 · 纠错处理  │ │ 排序 · 缓存策略   │ │ StreamingResponse   │   │
│  └─────────────────┘ └──────────────────┘ └────────────────────┘   │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │              共享基础设施: Auth · RateLimit · Logging          │  │
│  └──────────────────────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────────────────────────┤
│                        数据层                                       │
│  火山引擎方舟 (VLM+LLM) · PostgreSQL (主库) · Redis (缓存/限流)     │
└─────────────────────────────────────────────────────────────────────┘
```

### 1.2 各层职责

| 层 | 职责 | 组件 |
|----|------|------|
| 展示层 | 相机拍照、相册选图、文字搜索、图片预览与裁剪、识别结果展示、建议卡片交互、商品列表渲染、自然语言输入、多维度排序 | Flutter、Riverpod、dio、camera |
| 网关层 | TLS 终止、反向代理、限流、图片上传 body 大小限制（5M，配合前端≤2MB策略，预留合理传输开销和容错空间） | Nginx |
| 服务层 | 图像上传→VLM 识别→属性解析→商品检索→跨平台比价→建议卡片生成→自然语言筛选的完整编排 | FastAPI、ArkClient、SQLAlchemy |
| 数据层 | VLM 视觉推理 + LLM 意图理解；商品数据持久化；高频查询缓存 | 火山方舟、PostgreSQL、Redis |

### 1.3 技术选型论证

| 层 | 选型 | 核心理由 |
|----|------|----------|
| 前端 | **Flutter** | MVP阶段优先交付Android/iOS双端，架构层通过Platform Channel抽象预留鸿蒙适配扩展能力（远期扩展）；`camera` 插件调用原生摄像头；Riverpod 响应式 UI 适合流式交互 |
| 后端 | **Python FastAPI** | 原生 `asyncio` + `StreamingResponse` 支持 SSE 流式筛选；Pydantic 自动校验图片大小/格式；AI 生态（火山引擎 SDK）无缝集成 |
| AI 视觉 | **火山方舟 VLM**（豆包视觉模型） | 云端推理，所有 AI 计算在服务端完成；支持多模态输入直接解析商品图像 |
| AI 语言 | **火山方舟 LLM**（豆包/DeepSeek） | 结构化输出 + Prompt 工程实现意图理解、建议卡片生成、筛选条件解析 |
| 数据库 | **PostgreSQL + Redis** | PG JSONB 灵活存储商品属性；Redis 缓存高频比价结果 + 按用户限流计数器 |
| 对象存储 | **火山引擎 TOS** | 用户上传图片持久化，CDN 加速缩略图回显 |

---

## 2. 核心数据流

### 2.1 端到端主链路

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│  输入     │───▶│  VLM     │───▶│  多平台   │───▶│  建议    │───▶│  购买    │
│  上传     │    │  识别    │    │  比价    │    │  卡片    │    │  决策    │
└──────────┘    └──────────┘    └──────────┘    └──────────┘    └──────────┘
     │               │               │               │               │
     ▼               ▼               ▼               ▼               ▼
相机/相册      类目+属性        同款商品        引导交互       用户点击
文字搜索      结构化解析      价格聚合        LLM生成        外部链接
```

### 2.2 请求时序（拍照识物 + 比价全流程）

```
Flutter App                 FastAPI                   火山方舟          PostgreSQL
    │                          │                         │                 │
    │── POST /recognize ──────▶│                         │                 │
    │   multipart: image       │                         │                 │
    │                          │── VLM chat.completions ▶│                 │
    │                          │   (image + system       │                 │
    │                          │    prompt)              │                 │
    │                          │◀── 结构化 JSON ────────│                 │
    │                          │   {category, brand,     │                 │
    │                          │    color, style, ...}   │                 │
    │                          │                         │                 │
    │                          │── INSERT search_session │                │
    │                          │   + recognition_result ───────────────▶│
    │                          │                         │                 │
    │                          │── 多平台检索 (电商API)   │                 │
    │                          │   按关键词并行查询       │                 │
    │                          │◀── 聚合比价结果         │                 │
    │                          │                         │                 │
    │                          │── LLM chat.completions─▶│                 │
    │                          │   (识别结果+商品数→     │                 │
    │                          │    生成建议卡片)        │                 │
    │                          │◀── 建议卡片列表 ───────│                 │
    │                          │                         │                 │
    │◀── JSON ─────────────────│                         │                 │
    │   {recognition,          │                         │                 │
    │    suggestions[],        │                         │                 │
    │    products[]}           │                         │                 │
    │                          │                         │                 │
    │   [用户点击"只看旗舰店"]   │                         │                 │
    │── GET /filter/stream ──▶│                         │                 │
    │   {session_id,           │                         │                 │
    │    filter_text}          │                         │                 │
    │                          │── LLM 解析筛选条件 ────▶│                 │
    │                          │◀── 结构化筛选参数 ─────│                 │
    │                          │── 重排商品列表          │                 │
    │◀── SSE stream ──────────│                         │                 │
    │   (逐商品推送)           │                         │                 │
```

### 2.3 文字搜索独立链路时序（跳过VLM）

```
Flutter App                 FastAPI                   PostgreSQL
    │                          │                 │
    │── POST /search ────────▶│                 │
    │   {keywords: ["黑色蓝牙耳机"]} │         │
    │                          │
    │                          │── INSERT search_session │
    │                          │   (无VLM识别结果) ───────▶│
    │                          │
    │                          │── 多平台检索 (电商API)   │
    │                          │   按关键词并行查询       │
    │                          │◀── 聚合比价结果         │
    │                          │
    │◀── JSON ─────────────────│                 │
    │   {suggestions[],        │                 │  ← 文字搜索使用预设固定卡片，不调用LLM动态生成，避免幻觉
    │    products[]}           │                 │
```

**文字搜索链路说明**：
- 完全跳过VLM视觉识别，仅调用一次轻量级LLM将用户输入文本快速泛化为临时属性（如：关键词="黑色蓝牙耳机" → 临时属性: category="蓝牙耳机", color="黑色"）
- 前端统一渲染属性标签，保证主链路上后续的「属性修正」和「流式筛选」共享同一套上下文机制
- suggestions[]返回预设固定卡片（查看同款低价、只看官方旗舰店），避免缺少识别属性时LLM产生幻觉
- 链路更短，响应速度更快

---

## 3. Flutter 前端架构

### 3.1 首页交互设计：三层布局 + 滑动手势抽屉

**首页布局**：顶部按钮栏 + 中央品牌 Logo 区域 + 底部搜索栏（三层视觉结构），支持向右滑动手势打开历史记录抽屉面板。

```
┌─────────────────────────────────────────────────┐
│ ☰                               ⚙             │ ← 顶部：菜单按钮(打开历史抽屉) + 设置按钮
├─────────────────────────────────────────────────┤
│                                                 │
│            ＳｎａｐＳｈｏｐ                        │ ← 品牌渐变 Logo
│         拍照识物 · 智能比价                      │ ← 品牌标语
│                                                 │
│          [ 品牌蓝紫光晕脉冲背景 ]                 │ ← 进场动效背景
├─────────────────────────────────────────────────┤
│  📷  │  搜索商品...                 │  🖼️     │ ← 底部搜索栏：相机 + 输入 + 搜索 + 相册
└─────────────────────────────────────────────────┘

← 向右滑动或点击 ☰ → 主页右移 305px
┌──────────────────────┬──────────────────────────┐
│                      │  ○ 历史记录              │
│  [ 圆角 + 阴影 ]      │  搜索记录 · 浏览记录     │
│                      │                          │
└──────────────────────┴──────────────────────────┘
```

**进场动效**：页面加载时，品牌 Logo 从上方下落弹入（easeOutBack 缓动 + 缩放淡入），搜索栏从下方上浮走入，品牌蓝紫光晕背景随时间逐渐消退。返回首页时动画重新播放。

**交互状态1：默认状态**
- 顶部固定菜单按钮（☰，打开历史抽屉）和设置按钮（⚙，跳转设置页）
- 中央展示 SnapShop 品牌渐变 Logo（ShaderMask 蓝紫渐变）和标语"拍照识物 · 智能比价"
- 底部固定显示搜索栏，左侧相机图标，右侧相册按钮，中间文字输入区
- 进场动效：Logo 下落弹入 + 搜索栏上浮走入 + 光晕消退

**交互状态2：点击左侧相机图标**
- 直接唤起系统原生相机进行拍照
- 拍摄完成后跳转识别结果页

**交互状态3：点击右侧相册按钮**
- 底部搜索栏平滑向上抬升至距顶部 172px
- 搜索栏下方露出相册图片网格（AnimatedSlide，纵向滑入）
- 相册按钮变为关闭图标，再次点击关闭相册

**交互状态4：点击菜单按钮或向右滑动手势**
- 主页整体沿 X 轴向右平移（0→305px），圆角半径从 0→24px，左侧增加阴影
- 右侧露出历史记录抽屉面板，包含搜索记录区域和浏览记录区域
- 点击半透明遮罩或向左滑动可关闭抽屉
- 抽屉关闭时历史记录状态刷新，下次打开为全新状态

**四种启动路径**：
1. **路径A：文字搜索** → 在搜索栏输入关键词 → 点击发送按钮 → 跳转识别结果页（跳过VLM，直接走关键词检索）
2. **路径B：拍照识物** → 点击搜索栏左侧相机图标 → 唤起系统相机 → 拍摄商品 → 跳转识别页
3. **路径C：相册选图** → 点击搜索栏右侧相册按钮 → 搜索栏抬升 → 选择图片 → 上传识别
4. **路径D：历史抽屉** → 向右滑动或点击菜单按钮 → 打开历史抽屉 → 选择搜索/浏览记录 → 跳转结果页

### 3.2 项目分层

```
lib/
├── main.dart                          # 入口
├── app.dart                           # MaterialApp + 主题 + 路由 + 国际化
├── config/
│   ├── app_colors.dart                # 全局颜色常量
│   ├── app_theme.dart                 # ThemeData 工厂（浅色/深色 + 字体缩放）
│   ├── theme_context.dart             # 上下文感知颜色 + 字体缩放扩展
│   ├── app_router.dart                # GoRouter 路由表
│   ├── route_observer.dart            # 路由观察者
│   └── l10n/
│       └── app_localizations.dart     # 中英文双语翻译映射
├── core/
│   ├── network/
│   │   ├── api_client.dart            # dio 封装
│   │   └── sse_client.dart            # SSE 流消费
│   ├── utils/
│   │   ├── image_compress.dart        # 图片压缩
│   │   ├── debouncer.dart             # 输入防抖
│   │   └── system_camera.dart         # 系统相机抽象
├── features/
│   ├── home/                          # 首页模块
│   │   ├── home_page.dart             # 首页主界面
│   │   ├── home_provider.dart         # 首页状态管理
│   │   ├── main_search_bar.dart       # 底部搜索栏
│   │   └── gallery_picker_sheet.dart  # 底部抬升相册选择
│   ├── recognition/                   # 识别结果模块
│   │   ├── recognition_page.dart      # 识别结果展示
│   │   ├── recognition_provider.dart  # 识别状态管理
│   │   ├── attribute_edit_sheet.dart  # 属性修正弹层
│   │   └── widgets/
│   │       └── attribute_chip.dart    # 属性标签组件
│   ├── suggestions/                   # 智能建议卡片模块
│   │   ├── suggestion_card.dart       # 单个建议卡片
│   │   └── suggestion_list.dart       # 卡片横向滚动列表
│   ├── product_list/                  # 商品列表模块
│   │   ├── product_card.dart          # 商品卡片
│   │   ├── price_summary_bar.dart     # 各平台价格汇总条
│   │   ├── product_provider.dart      # 列表状态管理
│   │   └── sort_bar.dart              # 排序栏
│   ├── filter/                        # 自然语言筛选模块
│   │   ├── filter_input_bar.dart      # 筛选输入框
│   │   └── filter_provider.dart       # 筛选状态管理
├── history/
  │   └── history_page.dart
  ├── settings/
  │   ├── settings_page.dart
  │   ├── settings_provider.dart
  │   └── login_page.dart
  ├── favorites/
  │   └── favorites_tab.dart
  ├── profile/
  │   ├── profile_page.dart
  │   └── browse_list_tab.dart
  └── shared/
      └── widgets/
          ├── loading_indicator.dart
          ├── error_retry.dart
          ├── platform_badge.dart
          └── search_history_section.dart
```

### 3.3 SSE 流式局部刷新机制

filter_provider.dart 中 Riverpod 配合 ListView.builder 实现增量渲染：
1. 每收到一条 `type: product` SSE 事件，仅向 List 末尾追加单个商品对象
2. 瀑布流网格通过增量追加方式实现局部刷新，无全列表闪烁
3. 网络偶发性中断时，由前端自动发起重新请求，无需复杂的分布式流状态恢复

### 3.4 核心设计决策

| 决策点 | 方案 | 理由 |
|--------|------|------|
| 三端目标 | MVP阶段聚焦Android/iOS，架构支持开放鸿蒙生态 | Flutter 3.27+ 正式支持 OpenHarmony 平台；MVP阶段优先交付Android/iOS双端，架构预留鸿蒙适配层扩展能力（远期扩展），后续可无缝迁移 |
| 状态管理 | Riverpod | `AsyncNotifier` 天然支持识别/比价异步流；无 context 依赖，便于测试 |
| 路由 | GoRouter | 声明式路由：首页→预览→结果→列表，深度链接支持 |
| 图片上传 | dio `MultipartFile` + 预压缩 | 原生 camera 输出可能 >5MB，`flutter_image_compress` 压缩至 ≤2MB 再上传 |
| 网络层 | dio + SSE 手动解析 | `ResponseType.stream` 支持 SSE，按 `\n\n` 分帧解析筛选推送；Last-Event-ID 断线重连 |
| 相机 | `camera` 插件 + 鸿蒙适配层 | Android / iOS 用官方 `camera` 插件；鸿蒙通过 `ohos_camera` 适配层（远期扩展）桥接原生相机 |
| UI 渲染 | 原生 Widget + `cached_network_image` + 瀑布流布局（`flutter_staggered_grid_view`）增量渲染 | 商品卡片缩略图加载优化 + PRD 4.6.4 瀑布流布局要求；SSE 逐条推送无全列表闪烁 |
| 属性修正 | BottomSheet + 自由文本输入 | 用户点击属性标签弹出修改面板，支持任意文本修正后重新检索 |
| 平台差异化 | Platform Channel 抽象 | 相机权限申请 / 图片存储路径 / 推送通知通过统一 Channel 接口适配 |
| 主题系统 | `ThemeAwareColors` + `context.colors` / `context.fs()` 扩展 | 根据 `Brightness` 自动切换浅/深色值；字体大小通过 `SettingsProvider` 全局缩放，一处修改处处生效 |
| 国际化 | `AppLocalizations` + `LocalizationsDelegate` | 内联翻译映射（`_localizedStrings` Map），getter 自动按语言返回对应文案；Riverpod + `SharedPreferences` 持久化语言选择 |
| 设置状态 | 统一 `SettingsNotifier` (Riverpod StateNotifier) | 集中管理语言/外观/字体/通知偏好/用户信息/登录状态，`SharedPreferences` 持久化全部设置键值 |

### 3.5 设置模块架构

settings_provider.dart 中的 `SettingsNotifier` 是整个应用的全局设置状态中心，管理以下状态域：
- **语言**：`LocaleOption` (zh / en)，切换后 `app.dart` 中的 `MaterialApp.router.locale` 立即响应
- **外观**：`ThemeModeOption` (light / dark / system)，切换后 `MaterialApp.router.themeMode` 切换
- **字体**：`FontSizeOption` (small 0.85x / standard 1.0x / large 1.15x)，切换后 `app_theme.dart` 重算 textTheme 字号
- **通知**：`pushEnabled` / `inAppAlertsEnabled` (bool)，SharedPreferences 持久化
- **用户信息**：`avatarPath` / `nickname` / `bio` / `isLoggedIn`，支持头像选取 (image_picker)、昵称和简介编辑

settings_page.dart 使用底部弹窗（showModalBottomSheet）模式展示各设置选项，与语言弹窗风格统一：
- `_showLanguagePicker()` — 语言选择弹窗
- `_showAppearancePicker()` — 外观选择弹窗
- `_showFontSizePicker()` — 字体大小选择弹窗（含 "Aa" 预览效果）
- `_showNotificationPicker()` — 消息通知偏好弹窗
- `_showClearCacheDialog()` — 缓存清理确认对话框
- `_showProfileEditSheet()` — ~~个人信息编辑弹窗~~（已删除）
- 个人资料卡片：未登录点击跳转 `/login`，已登录点击跳转 `/profile` 个人中心页（收藏+浏览记录）。卡片在已登录时显示从 `/user/stats` API 获取的收藏数和浏览数统计。

login_page.dart 提供登录/注册页面（对接后端 JWT 认证 + bcrypt 密码）：
- 手机号 + 密码输入，调用 POST /auth/login 和 POST /auth/register 接口
- 登录后 `isLoggedIn = true`，ApiClient 自动注入 Bearer token
- 退出登录时弹出确认对话框，确认后清除 token 和所有用户数据

### 3.6 主题上下文系统

theme_context.dart 提供两个 `BuildContext` 扩展方法，使所有 widget 自适应主题和字体设置：

- **`context.colors`**：`ThemeAwareColors` 实例，根据 `Theme.of(context).brightness` 自动在浅色/深色色值间切换。覆盖 12 种常用颜色属性（primaryBg、secondaryBg、surface、cardBg、textPrimary、textSecondary、textTertiary、divider、border、searchBarBg、searchIconBg、white）。品牌色（brandBlue/Purple、priceRed）、语义色（warningAmber/successGreen/errorRed）、平台色（taobaoOrange/jdRed/pddRed）保持固定，不随主题变化。
- **`context.fs(double base)`**：从 `SettingsProvider` 读取当前 `FontSizeOption.scale` 并返回 `base * scale`。替代所有硬编码 `fontSize: N`，使字体大小设置全局即时生效。

app_theme.dart 中的 `lightTheme()` 和 `darkTheme()` 方法通过 `_buildTheme(Brightness, double fontSizeScale)` 统一构建 ThemeData，textTheme 中所有字号乘以 fontSizeScale 参数。

### 3.7 国际化系统

app_localizations.dart 中的 `AppLocalizations` 类使用内联翻译映射 `_localizedStrings`，通过 `AppLocalizationsDelegate` 注册为 Flutter 的 Localizations delegate。

翻译键管理采用 getter 模式：
```dart
String get settingsTitle => get('settings_title');
```

语言切换通过 `SettingsNotifier.setLocale()` → `await prefs.setString('app_locale', option.name)` 持久化，`app.dart` 中的 `locale: settingsState.localeOption.locale` 即时响应。

目前已覆盖 70+ 翻译键，覆盖设置页、加载页、错误页、搜索栏、相册、识别结果、属性编辑、筛选、排序、价格汇总、缓存清理、通知偏好、登录页、个人资料编辑等全部 UI 文案。

---

## 4. Python 后端架构

### 4.1 分层结构

```
backend/app/
├── main.py                            # FastAPI 入口 + 中间件注册 + 静态文件挂载
├── config.py                          # pydantic-settings 配置
├── api/
│   ├── deps.py                        # 依赖注入（DB、用户、各 Service）
│   └── v1/
│       ├── recognize.py               # POST /recognize — 图片上传+识别
│       ├── search.py                  # POST /search — 纯文字搜索（跳过VLM）
│       ├── products.py                # GET /products — 商品列表/比价
│       ├── filter.py                  # POST /filter/stream — SSE 自然语言筛选
│       ├── suggestions.py             # POST /suggestions — 点击建议卡片后续
│       ├── auth.py                    # 注册/登录（可选，MVP 可匿名）
│       ├── favorites.py
│       ├── browse.py
│       ├── stats.py
├── core/
│   ├── security.py                    # JWT（或设备指纹）签发与验证
│   ├── rate_limit.py                  # 按用户/设备限流中间件
│   └── exceptions.py                  # 统一异常处理
├── models/
│   ├── search_session.py              # 搜索会话
│   ├── recognition_result.py          # 识别结果
│   ├── product.py                     # 商品记录
│   ├── user.py
│   ├── favorite.py
│   ├── browse_history.py
│   ├── filter_action.py
├── schemas/
│   ├── recognize.py                   # 请求/响应 Schema
│   ├── search.py                      # 纯文字搜索请求/响应 Schema
│   ├── product.py                     # 商品 Schema
│   └── filter.py                      # 筛选请求/SSE chunk Schema
├── services/
│   ├── recognition_service.py         # 图像识别编排
│   ├── text_search_service.py         # 纯文字搜索编排（跳过VLM）
│   ├── search_service.py              # 多平台商品检索
│   ├── comparison_service.py          # 跨平台比价聚合
│   ├── suggestion_service.py          # 建议卡片生成
│   ├── filter_service.py              # 自然语言筛选
│   ├── browse_recorder.py
│   └── product_serializer.py
├── clients/
│   ├── base_platform_client.py
│   ├── _base_ark.py
│   ├── ark_vlm_client.py
│   ├── ark_llm_client.py
│   ├── real_jd_client.py
│   ├── real_pdd_client.py
│   └── strategy/
│       └── llm_fallback_strategy.py
```

### 4.2 核心设计决策

| 决策点 | 方案 | 理由 |
|--------|------|------|
| 调用链 | `Router → Service → Client` | 三层解耦：Router 校验参数并序列化响应，Service 编排业务逻辑，Client 封装外部 API；便于单元测试与依赖替换 |
| 图像识别 | VLM（豆包视觉）`system prompt` 约束输出 JSON Schema | 一次 VLM 调用同时完成类目+多属性提取；Prompt 工程确保稳定输出结构化 JSON |
| 自然语言筛选 | `StreamingResponse` + async generator | 用户输入自然语言条件→LLM 解析为结构化参数→过滤结果逐条 SSE 推送，实时刷新前端卡片 |
| 建议卡片 | LLM 生成结构化卡片列表 | 根据识别结果+召回数量动态生成 3-6 张建议卡片 |
| 属性修正 | 纯结构化数据操作→前端直接携带修正后的键值对→后端组装关键词重新检索 | 用户修改属性后，后端直接组装新关键词重新检索，完全不调用LLM，速度更快 |
| 异步 DB | SQLAlchemy 2.0 async + asyncpg | 与 asyncio 事件循环一致，VLM/LLM 调用期间不阻塞 DB 操作 |
| 图片存储 | 上传至火山 TOS，DB 仅存 URL | 避免 BLOB 拖慢主库；TOS 支持 CDN 加速前端回显 |

### 4.3 服务层依赖关系

```
RecognitionService
    ├── ArkVLMClient                 ──► 火山方舟 VLM (视觉识别)
    ├── AsyncSession                  ──► PostgreSQL (保存识别记录)
    └── (返回识别结果后触发)

SearchService                          ◄── 由 RecognitionService 结果触发
    ├── TaobaoClient                 ──► 淘宝/天猫 API 商品检索（淘宝/天猫客户端暂未实现，远期规划）
    ├── JDClient                     ──► 京东 API 商品检索
    └── PDDClient                    ──► 拼多多 API 商品检索
    └── AsyncSession                  ──► PostgreSQL (商品结果持久化)

ComparisonService                      ◄── 由 SearchService 结果触发
    ├── 文本 Embedding / Levenshtein  ──► 同款商品相似度打分与去重
    ├── 聚合多平台价格                  ──► 计算最低价 / 均价 / 平台分布
    └── Redis                         ──► 缓存比价结果 (TTL 10min)

SuggestionService                      ◄── 由 SearchService 结果触发
    ├── ArkLLMClient                  ──► 火山方舟 LLM (生成建议卡片)
    └── 无需持久化 (纯计算)

FilterService                          ◄── 用户主动触发
    ├── ArkLLMClient                  ──► 火山方舟 LLM (仅做意图解析器，输出结构化过滤条件)
    ├── AsyncSession                  ──► PostgreSQL (SQL级过滤商品集，避免大上下文处理)
    └── Redis                         ──► 缓存当前会话商品集 + 用户纠错属性结构体
                                          （用户手动修正属性后，同步更新至Redis的会话Context中，
                                          供FilterService解析时作为System Prompt的补充基准，防止AI后续对话产生幻觉）
```

### 4.4 Mock 种子商品库

> 此前 `data/seed_products.json` 用于演示兜底和开发测试，该文件已在后续迭代中删除。当前 Mock 数据改为通过拼多多/京东真实 API 拉取后缓存提供。

### 4.5 同款对齐与轻量级 Rerank 机制

各大平台商品标题充斥大量 SEO 垃圾词（如【官方正品】2026夏轻薄款...），ComparisonService 中增加两步关键处理：
1. **Levenshtein 距离初筛**：快速过滤掉与 VLM 解析出的 keywords 归一化编辑距离 > 0.6 的低相关商品
2. **文本 Embedding 向量余弦相似度精排**：对初筛后的候选集，计算商品标题向量与识别关键词向量的余弦相似度，实现真正的同款精准去重与聚合比价

---

## 5. AI Pipeline 架构

### 5.1 两阶段 AI 编排 + Self-Correction 自省状态机

```python
# services/recognition_service.py
class RecognitionService:
    async def recognize_with_self_correction(self, image_bytes: bytes, max_retries: int = 2):
        """
        Self-Correction 自省状态机完整实现
        max_retries: 最大自省重试次数，默认 2 次
        """
        for attempt in range(max_retries + 1):
            result = await self.ark_vlm_client.recognize(image_bytes)
            
            # 检查置信度是否全部达标
            all_confidence_ok = all(
                conf >= 0.7 
                for conf in result.confidence.values()
            )
            
            if all_confidence_ok and self._is_json_complete(result):
                # 置信度达标且 JSON 完整，直接返回
                return result
            
            # 置信度不足，进入自省重试循环
            if attempt < max_retries:
                result = await self.ark_llm_client.self_correct(result)
                continue
        
        # 多次重试仍失败，生成意图对齐引导卡片
        return await self._generate_intention_guide_card(result)
    
    def _is_json_complete(self, result) -> bool:
        """检查结构化 JSON 是否关键字段完整"""
        required_fields = ["category", "keywords"]
        return all(getattr(result, field, None) for field in required_fields)
```

```
                    ┌──────────┐
                    │  输入     │
                    │  (图片/文字)│
                    └────┬─────┘
                         │
              ┌──────────▼──────────┐
              │   阶段一：视觉识别    │
              │  模型: 豆包 VLM      │
              │  输入: image +       │
              │    System Prompt     │
              │  输出: 结构化 JSON   │
              └──────────┬──────────┘
                         │
         ┌───────────────┴───────────────┐
         ▼                               ▼
  JSON 完整且                     缺失字段 / confidence < 0.7
  全部置信度达标                         │
         │                               ▼
         │                    ┌──────────────────────┐
         │                    │  LLM 自省重试循环      │
         │                    │  Self-Correction     │
         │                    └──────────┬──────────┘
         │                               │
         │                               ▼
         │                    ┌──────────────────────┐
         │                    │  意图对齐引导卡片      │
         │                    │  "您拍的是衣服还是     │
         │                    │   数码产品？"          │
         │                    └──────────┬──────────┘
         │                               │
         └───────────────┬───────────────┘
                         │
              ┌──────────────────────┐
              │   属性纠错 (可选)     │
              │  用户修正 → 合并属性  │
              └──────────┬──────────┘
                         │
              ┌──────────────────────┐
              │   多平台商品检索      │
              │  关键词召回 + 聚合    │
              └──────────┬──────────┘
                         │
              ┌──────────────────────┐
              │   阶段二：语言理解    │
              │  模型: 豆包 LLM      │
              │                     │
              │  ┌─ 建议卡片生成     │
              │  └─ 筛选条件解析     │
              └─────────────────────┘
```

### 5.2 VLM Prompt 设计（阶段一：视觉识别）

**System Prompt 核心设计原则**：
- 严格约束输出 JSON Schema（Pydantic 可校验）
- 提供分类层次结构，限定商品大类范围
- 对不确定属性标注 `confidence`，低置信度属性供用户纠错
- 输出中英双语关键词，便于跨平台检索

```
# 角色
你是一个专业的商品识别助手。

# 任务
分析用户上传的商品图片，输出商品的类目和关键属性。

# 输出格式（严格 JSON）
{
  "category": "三级类目，如: 运动鞋/连衣裙/T恤/双肩包/蓝牙耳机",
  "brand": "识别到的品牌名，未识别则为 null",
  "color": "主要颜色，如: 黑色/白色/蓝色",
  "style": "风格描述，如: 休闲/商务/运动/复古",
  "material": "材质，如: 皮革/纯棉/尼龙",
  "shape": "造型特征，如: 圆领/高帮/方形",
  "keywords": ["检索用关键词列表，中英混合"],
  "confidence": {"category": 0.9, "brand": 0.3, "color": 0.85, ...}
}

# 规则
- 无法确定的值设为 null，不要猜测
- keywords 包含品类通用名和特征词的多种表述
- 颜色优先使用中文常见色名
```

### 5.3 LLM Prompt 设计（阶段二：建议卡片生成）

**System Prompt**：根据识别结果和商品召回量，动态生成引导用户决策的建议卡片。

```
# 角色
你是一个智能购物导购助手。

# 输入
- 识别结果：{category, brand, color, style, price_range}
- 召回统计：{total_count, platform_distribution, price_range}

# 任务
基于输入生成 3-6 张可交互建议卡片，引导用户进一步筛选。

# 输出格式（严格 JSON Array）
[
  {
    "id": "card_1",
    "title": "查看同款低价",
    "icon": "price_down",
    "action_type": "sort",
    "params": {"sort_by": "price_asc"},
    "priority": 1
  },
  {
    "id": "card_2",
    "title": "只看官方旗舰店",
    "icon": "verified",
    "action_type": "filter",
    "params": {"shop_type": "official"},
    "priority": 2
  }
]

# 生成规则
- 价格跨度大（max/min > 3）→ 生成"按预算筛选"卡片
- 品牌不置信 / 颜色多样 / 尺码不确定 → 生成"筛选：颜色/品牌/尺码"卡片
- 平台分散 → 生成"只看某平台"卡片
- 按 priority 降序排列
```

### 5.4 LLM Prompt 设计（自然语言筛选解析）

**System Prompt**：将用户的自然语言筛选意图转换为结构化筛选参数。

```
# 角色
你是一个购物筛选条件解析器。

# 输入
- 用户自然语言输入: "{user_input}"
- 当前上下文: 识别类目={category}, 商品价格区间=[{min}, {max}]

# 任务
解析用户的筛选条件，输出结构化过滤参数。

# 输出格式（严格 JSON）
{
  "filters": {
    "price_min": 500,
    "price_max": 1000,
    "color": "黑色",
    "brand": null,
    "shop_type": null,
    "min_rating": 4.8,
    "sort_by": "comprehensive"
  },
  "user_intent": "寻找中端价位的高评价黑色款"
}

# 规则
- 数值区间要从文本中精确提取
- "以内""不超过"→ price_max；"以上""不低于"→ price_min
- 颜色映射到标准色名（与识别阶段一致）
- 无法解析的参数设为 null
```

### 5.5 AI 容错策略 + 策略模式熔断降级

采用策略模式实现三级熔断降级，火山引擎方舟 API 熔断时秒级切换到本地离线规则：

```python
# clients/strategy/llm_fallback_strategy.py
class BaseLLMFallbackStrategy(ABC):
    @abstractmethod
    def parse_filter(self, user_input: str) -> dict: ...

class ArkLLMStrategy(BaseLLMFallbackStrategy):
    """正常模式：调用火山方舟 LLM"""
    async def parse_filter(self, user_input: str) -> dict:
        return await ark_client.call(user_input)

class RegexOfflineStrategy(BaseLLMFallbackStrategy):
    """熔断模式：本地正则规则解析，零外部依赖"""
    def parse_filter(self, user_input: str) -> dict:
        # 硬编码离线规则："500元以内" → price_max=500，"黑色" → color="黑色"
        return regex_parser.extract(user_input)
```

```
ArkVLMClient.recognize()
    │
    ├── 正常 → 结构化 JSON → Pydantic 校验 → 通过 → 返回
    │
    ├── JSON 解析失败 → retry 1 次 (调整 temperature=0.1) → 仍失败 → 返回基础关键词
    │
    ├── 429 限流 → 指数退避 (1s→2s→4s，最多 3 次)
    │
    ├── 5xx 服务错误 → 同上退避重试
    │
    └── 重试耗尽 → 策略模式自动切换 → RegexOfflineStrategy 本地规则兜底

ArkLLMClient.generate()
    │
    ├── function_calling 返回格式错误 → Pydantic 校验 → 失败则降级为规则生成
    │      建议卡片降级：使用预设模板
    │      筛选解析降级：关键词正则匹配
    │
    └── 超时 (15s) → 降级返回规则结果
```

---

## 6. 数据架构

### 6.1 核心实体关系

```
SearchSession (1) ──────── (1) RecognitionResult
      │
      │  id (UUID)
      │  device_id (设备指纹或 user_id)
      │  image_url (TOS)
      │  status (recognizing | completed | failed)
      │  created_at
      │
      ├──────── (N) Product
      │              │  id (UUID)
      │              │  session_id (FK)
      │              │  name
      │              │  image_url
      │              │  price
      │              │  original_price
      │              │  platform (taobao/jd/pdd)
      │              │  shop_name
      │              │  shop_type (official/self_operated/third_party)
      │              │  rating
      │              │  sales_count
      │              │  product_url (商品链接)
      │              │  attributes (JSONB)
      │              │  created_at
      │
      └──────── (N) FilterAction
                     │  id (UUID)
                     │  session_id (FK)
                     │  action_type (sort/filter/text_filter)
                     │  filter_text
                     │  params (JSONB)
                     │  result_count
                     │  created_at
```

```
User ────────── (1) Favorite
│               │  id (UUID)
│  id (UUID)     │  user_id (FK)
│  phone         │  product_id
│  hashed_password│  product_snapshot (JSONB)
│  nickname      │  created_at
│  avatar_url    │
│  bio          └── (N) BrowseHistory
│  created_at           │  id (UUID)
                        │  user_id (FK, nullable)
                        │  device_id (nullable)
                        │  product_id
                        │  product_snapshot (JSONB)
                        │  viewed_at
                        │  view_date
```

### 6.2 关键表结构

**recognition_results**

| 列 | 类型 | 说明 |
|----|------|------|
| id | UUID | PK |
| session_id | UUID | FK → search_sessions |
| category | VARCHAR(100) | 三级类目 |
| attributes | JSONB | `{brand, color, style, material, shape, keywords}` |
| raw_response | JSONB | VLM 原始响应（调试用） |
| confidence | JSONB | `{category: 0.9, brand: 0.3, ...}` |
| created_at | TIMESTAMPTZ | |

**products**

| 列 | 类型 | 说明 |
|----|------|------|
| id | UUID | PK |
| session_id | UUID | FK → search_sessions |
| name | VARCHAR(500) | 商品名称 |
| image_url | VARCHAR(2000) | 商品图 URL |
| price | DECIMAL(10,2) | 当前价格 |
| original_price | DECIMAL(10,2) | 原价（划线价） |
| platform | VARCHAR(20) | 平台标识 |
| shop_name | VARCHAR(200) | 店铺名称 |
| shop_type | VARCHAR(30) | official/self_operated/third_party |
| rating | DECIMAL(2,1) | 评分 |
| sales_count | INTEGER | 销量 |
| product_url | VARCHAR(2000) | 商品链接 |
| attributes | JSONB | 商品属性 + 营销标签（如"百亿补贴""超级品牌日"等） |
| created_at | TIMESTAMPTZ | |

### 6.3 存储策略

| 数据 | 存储 | 策略 |
|------|------|------|
| 用户上传图片 | 火山 TOS | 上传后压缩缩略图；原图保留 7 天自动过期 |
| 识别结果 | PostgreSQL JSONB | 支持按属性检索历史识别记录 |
| 商品列表 | PostgreSQL | 按 session 关联，支持复合排序查询 |
| 比价聚合 | Redis `SETEX` | 同一 session 的比价结果缓存 10min，避免重复计算 |
| 搜索关键词热度 | Redis Sorted Set | 热门搜索词排名，辅助建议卡片生成 |
| 限流计数器 | Redis `INCR` + `EXPIRE` | 原子操作，滑动窗口 |

### 6.4 索引策略

| 表 | 索引 | 用途 |
|----|------|------|
| `search_sessions` | `device_id, created_at DESC` | 用户历史搜索列表 |
| `products` | `(session_id, price)` | 按会话+价格排序 |
| `products` | `(session_id, rating DESC)` | 按好评率排序 |
| `products` | `(session_id, sales_count DESC)` | 按销量排序 |
| `products` | `attributes` (GIN) | JSONB 属性过滤查询 |
| `recognition_results` | `session_id` | 关联查询 |

---

## 7. 安全架构

```
┌─────────────────────────────────────────────────┐
│                    安全层级                       │
├───────────────┬─────────────────────────────────┤
│ 传输安全       │ HTTPS (TLS 1.3)                  │
├───────────────┼─────────────────────────────────┤
│ 认证           │ JWT (设备指纹 + 短期 token)       │
│               │ MVP 支持匿名模式                  │
├───────────────┼─────────────────────────────────┤
│ 授权           │ 行级隔离 (session 归属校验)       │
├───────────────┼─────────────────────────────────┤
│ 输入校验       │ Pydantic Schema 校验             │
│               │ 图片: 类型/大小/分辨率白名单        │
│               │ 文本: 长度限制 + XSS 过滤          │
├───────────────┼─────────────────────────────────┤
│ 密钥管理       │ AK/SK 仅存后端环境变量            │
│               │ 前端仅持有 JWT                    │
├───────────────┼─────────────────────────────────┤
│ 流量控制       │ 识别接口: 10 req/min/device       │
│               │ 筛选 SSE: 30 req/min/device       │
├───────────────┼─────────────────────────────────┤
│ 上传安全       │ 白名单: image/jpeg, image/png     │
│               │ 最大 10MB，超限拒绝 413            │
└───────────────┴─────────────────────────────────┘
```

**核心原则**：
- 火山引擎 AK/SK **仅存后端环境变量**，前端不可见
- 所有数据库查询强制 `WHERE device_id = ?` 行级隔离
- 图片上传仅允许 `image/jpeg`、`image/png`，后端校验 MIME type + 文件头魔数
- 用户上传图片 7 天后自动清理，不永久存储

---

## 8. 部署架构

### 8.1 开发环境

```
docker-compose.yml
├── backend (FastAPI + uvicorn)    :8000  (hot-reload)
├── db (PostgreSQL 16)            :5432
├── redis (Redis 7)               :6379
└── minio (S3 兼容, 替代 TOS)     :9000  (本地图片存储)
```

### 8.2 生产部署拓扑（阿里云 ECS 单机）

生产环境通过 `docker-compose.prod.yml` 在单台阿里云 ECS 上编排全部服务，Nginx 作为统一入口：

```
                    公网 HTTP :80
                          │
                   ┌──────┴──────┐
                   │    Nginx     │
                   │  (反向代理)   │
                   └──────┬──────┘
                          │
           ┌──────────────┼──────────────┐
           │              │              │
    /api/* → backend    /images/* →    /docs → backend
           :8000        minio:9000     :8000/docs
              │              │
    ┌─────────┴─────────┐   │
    │                   │   │
  PostgreSQL 16       Redis 7  MinIO
  (Docker 内网)     (Docker 内网) (图片存储)
```

**端口策略**：

| 端口 | 服务 | 对外 | 说明 |
|------|------|:--:|------|
| 80 | Nginx | ✅ | HTTP 统一入口 |
| 8000 | FastAPI | ❌ | 仅 Docker 内网 |
| 5432 | PostgreSQL | ❌ | 仅 Docker 内网 |
| 6379 | Redis | ❌ | 仅 Docker 内网 |
| 9000 | MinIO API | ✅ | 图片上传/访问 |

### 8.3 生产与开发配置分离

项目提供两套 Docker Compose 配置，按环境选择：

| 文件 | 用途 | 差异 |
|------|------|------|
| `docker-compose.yml` | 本地开发 | 端口全暴露、代码卷挂载热重载、debug 模式 |
| `docker-compose.prod.yml` | 服务器生产 | db/redis 仅内网、无代码挂载、叠加 Nginx 反向代理 |

开发环境直接使用 IDE 调试，生产环境所有流量经 Nginx 入口：

```
开发:  docker compose up -d
生产:  docker compose -f docker-compose.prod.yml up -d
```

**Nginx 配置**位于 `deploy/nginx/`：
- `nginx.conf` — 主配置（gzip、连接优化、日志格式）
- `default.conf.template` — 站点模板（反向代理规则、SSE 支持、安全头、上传限制）

Nginx 反向代理路由：

| 路径 | 目标 | 特殊处理 |
|------|------|----------|
| `/health` | `backend:8000/health` | 关闭访问日志 |
| `/api/` | `backend:8000/api/` | SSE 流式支持（proxy_buffering off）、300s 超时、10MB 上传限制 |
| `/images/` | `minio:9000/snapshop-images/` | 7 天浏览器缓存 |
| `/docs` | `backend:8000/docs` | Swagger 文档 |

**一键部署脚本**位于 `deploy/`：
- `setup.sh` — ECS 环境初始化（Docker + Compose + 防火墙 + 内核参数）
- `deploy.sh` — 项目部署（停止旧服务 → 构建镜像 → 启动）

### 8.4 CI/CD

```
Git Push → GitHub Actions
  |
  ├── [后端]
  │   ├── Lint (ruff) + Type Check (mypy) + Test (pytest)
  │   ├── Build Docker Image
  │   ├── Push → 火山引擎镜像仓库 (CR)
  │   └── Deploy → ECS 滚动更新 (零停机)
  │
  └── [前端 Flutter]
      ├── Flutter Analyze + Test
      ├── Build Android APK/AAB
      ├── Build iOS IPA (需 macOS runner)
      ├── Build HarmonyOS HAP
      └── Upload → 内部制品仓库 / 各应用商店
```

### 8.5 环境变量

生产环境使用 `.env.production` 模板（`backend/.env.production`），预填了比赛专用 AI 密钥。

| 变量 | 说明 | 示例 |
|------|------|------|
| `ARK_API_KEY` | 火山方舟 API Key | `ark_xxx` |
| `ARK_VLM_ENDPOINT_ID` | VLM 推理端点 ID | `ep-vision-xxx` |
| `ARK_LLM_ENDPOINT_ID` | LLM 推理端点 ID | `ep-llm-xxx` |
| `DATABASE_URL` | PostgreSQL 连接串 | `postgresql+asyncpg://...` |
| `REDIS_URL` | Redis 连接串 | `redis://...` |
| `JWT_SECRET` | JWT 签名密钥 | (随机生成) |
| `JD_APP_KEY` | 京东开普勒 App Key | `jd_xxx` |
| `JD_APP_SECRET` | 京东开普勒 App Secret | `jd_secret_xxx` |
| `PDD_CLIENT_ID` | 拼多多开放平台 Client ID | `pdd_xxx` |
| `PDD_CLIENT_SECRET` | 拼多多开放平台 Client Secret | `pdd_secret_xxx` |
| `API_TIMEOUT` | 电商 API 超时（秒） | `10` |
| `API_MAX_RETRIES` | 电商 API 最大重试次数 | `3` |

### 8.6 Flutter 三端构建与分发

```
# Android
flutter build apk --release          # → app-release.apk
flutter build appbundle --release    # → Google Play

# iOS
flutter build ipa --release          # → Xcode Archive → App Store Connect

# HarmonyOS（远期扩展）
flutter build ohos --release         # → .hap → AppGallery / 企业分发
```

**三端差异管理**：

| 端 | 相机适配 | 文件存储 | 推送服务 | 发布渠道 |
|----|---------|---------|---------|---------|
| Android | CameraX (原生) | Scoped Storage | FCM / 火山推送 | Google Play / APK 直装 |
| iOS | AVFoundation | Sandbox | APNs / 火山推送 | App Store / TestFlight |
| HarmonyOS | ohos.camera | 沙箱存储 | 鸿蒙推送服务 | AppGallery / HAP 分发（远期扩展） |

三端共享同一 Dart 业务层 + Riverpod 状态管理；仅 `core/platform/` 下的适配器按端注入不同实现。通过 `flutter_flavor` 配置三套环境变量，打不同包时自动切换。

---

## 9. API 设计

### 9.1 RESTful 端点

| 方法 | 路径 | 说明 | 请求体 | 响应 |
|------|------|------|--------|------|
| POST | `/api/v1/recognize` | 图片上传+识别 | `multipart/form-data: image` | `{session_id, recognition, suggestions[], products[], price_summary[]}` |
| POST | `/api/v1/search` | 纯文字搜索（跳过VLM） | `{keywords: ["黑色蓝牙耳机"]}` | `{session_id, suggestions[], products[], price_summary[]}` |
| GET | `/api/v1/products/{session_id}` | 获取商品列表 | query: `sort_by`, `page`, `size` | `{products[], total, page, price_summary[]}` |
| POST | `/api/v1/products/{session_id}/filter` | 非流式筛选（远期规划） | `{filter_text}` | `{products[], applied_filters}` |
| GET | `/api/v1/filter/stream` | **SSE 自然语言筛选** | `{session_id, filter_text}` | SSE stream: `data: {product}\n\n` |
| POST | `/api/v1/suggestions/action` | 点击建议卡片 | `{session_id, card_id, params}` | `{products[]}` |
| PATCH | `/api/v1/recognize/{session_id}/attributes` | 修正识别属性（纯结构化操作） | `{attribute, new_value}` | `{updated_attributes, products[]}` |
| GET | `/api/v1/history` | 用户搜索历史 | query: `page` | `{sessions[]}` |
| POST | `/api/v1/auth/register` | 用户注册 | `{phone, password}` | `{access_token, token_type, user}` |
| POST | `/api/v1/auth/login` | 用户登录 | `{phone, password}` | `{access_token, token_type, user}` |
| POST | `/api/v1/favorites` | 添加收藏 | `{product_id, product_snapshot}` | `FavoriteItemResponse` |
| DELETE | `/api/v1/favorites/{product_id}` | 取消收藏 | — | `{message}` |
| GET | `/api/v1/favorites` | 收藏列表 | query: `page`, `size` | `{items[], total}` |
| POST | `/api/v1/browse` | 记录浏览 | `{product_id, product_snapshot}` | `{message}` |
| GET | `/api/v1/browse` | 浏览记录 | query: `page`, `size` | `{items[], total}` |
| GET | `/api/v1/user/stats` | 用户统计 | — | `{favorite_count, browse_count}` |

### 9.2 SSE 筛选流协议

```
# 请求
GET /api/v1/filter/stream
Content-Type: application/json

{
  "session_id": "uuid",
  "filter_text": "帮我找 1000 元以内的黑色款，评价 4.8 分以上"
}

# 响应流
Content-Type: text/event-stream
X-Accel-Buffering: no

data: {"type": "parsing", "filters": {"price_max": 1000, "color": "黑色", "min_rating": 4.8}}

data: {"type": "product", "product": {"id": "...", "name": "...", "price": 899, ...}}

data: {"type": "product", "product": {"id": "...", "name": "...", "price": 799, ...}}

data: {"type": "summary", "total": 15, "platforms": {...}}

data: {"type": "done"}
```

### 9.3 错误码规范

| HTTP 状态码 | 错误码 | 说明 |
|-------------|--------|------|
| 400 | `INVALID_IMAGE` | 图片格式/大小不合法 |
| 400 | `RECOGNITION_FAILED` | VLM 未识别到商品 |
| 413 | `IMAGE_TOO_LARGE` | 图片超过 2MB（后端Pydantic Schema硬性拦截） |
| 413 | `NGINX_IMAGE_TOO_LARGE` | 图片超过 10MB（Nginx网关层留安全余量） |
| 429 | `RATE_LIMITED` | 请求过于频繁 |
| 500 | `AI_SERVICE_ERROR` | VLM/LLM 服务异常 |
| 503 | `SERVICE_UNAVAILABLE` | 服务降级中 |

**图片大小双重校验机制**：
1. 前端：图片上传前自动压缩至 ≤2MB
2. 后端：Pydantic Schema 明确加入 content-length ≤ 2MB 硬性拦截
3. Nginx：网关层设置 client_max_body_size 10M（匹配生产配置），配合前端≤2MB策略，预留合理传输开销和容错空间

---

## 10. 扩展性设计

### 10.1 数据源可插拔

```python
# clients/base_platform_client.py
class BasePlatformClient(ABC):
    """电商平台客户端抽象基类"""

    @abstractmethod
    async def search(self, keywords: list[str], **filters) -> list[Product]:
        """按关键词检索商品"""
        ...

    @property
    @abstractmethod
    def platform_name(self) -> str:
        """平台标识"""
        ...

# clients/taobao_client.py
class TaobaoClient(BasePlatformClient):
    """淘宝/天猫 API 客户端"""
    ...

# clients/jd_client.py
class JDClient(BasePlatformClient):
    """京东 API 客户端"""
    ...

# clients/pdd_client.py
class PDDClient(BasePlatformClient):
    """拼多多 API 客户端"""
    ...

# services/search_service.py
class SearchService:
    def __init__(self, platform_clients: list[BasePlatformClient]):
        self.clients = platform_clients  # 依赖注入，新增平台只需添加到列表中

    async def search_all(self, keywords: list[str]) -> list[Product]:
        results = await asyncio.gather(
            *[client.search(keywords) for client in self.clients]
        )
        return [p for sublist in results for p in sublist]
```

### 10.2 AI 模型可插拔

```python
# clients/base_vlm_client.py
class BaseVLMClient(ABC):
    @abstractmethod
    async def recognize(self, image_bytes: bytes) -> RecognitionResult:
        ...

# 当前: 火山方舟 VLM
# 未来可替换为: OpenAI GPT-4V / 通义千问 VL / Claude Vision
# 仅需实现 BaseVLMClient 接口，Service 层零改动
```

### 10.3 功能扩展方向

| 扩展 | 说明 | 架构支撑 |
|------|------|----------|
| 历史价格走势 | 接入价格追踪数据源，展示 30/90 天价格曲线 | Product 表扩展 `price_history` JSONB |
| 用户偏好学习 | 记录用户浏览/点击行为，个性化推荐排序 | 新增 `user_preference` 表 + 推荐权重计算 |
| 社交分享 | 生成商品卡片分享图 | 后端渲染服务 (Pillow) → TOS CDN |
| 多图识别 | 支持多角度拍摄，综合识别 | VLM 支持多图输入，取并集属性 |
| 语音输入 | 语音转文字后走自然语言筛选流程 | 前端集成 ASR，后端筛选链路不变 |
| 收藏/比价单 | 用户可保存商品到比价单，跨会话对比 | 新增 `wishlist` + `wishlist_item` 表 |

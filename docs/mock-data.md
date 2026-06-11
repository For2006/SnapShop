# SnapShop — 商品模拟数据说明文档

> **项目**：SnapShop — AI 拍照识物与智能比价购物助手
> **更新日期**：2026-06-11

---

## 1. 概述

由于电商平台真实 API（京东联盟、拼多多开放平台）需要企业资质审核和密钥配置，本项目在真实 API 不可用时，通过**多层 Mock 商品数据**进行兜底，确保核心功能链路完整可演示。

Mock 系统设计遵循原则：
- **真实 API 优先**：有密钥时走真实 API，无密钥或 API 失败时自动降级到 Mock
- **分层兜底**：从前端到后端共 4 层防护，确保任何情况下都有商品数据返回
- **`is_mock` 标记**：所有 Mock 商品均携带 `is_mock: true` 字段，与真实数据明确区分

Mock 总开关位于 [config.py](../backend/app/config.py#L38)：

```python
use_mock_fallback: bool = True
```

---

## 2. 架构总览

```
用户搜索请求
    │
    ▼
SearchService.search_all()
    │
    ├── 并行调用 3 个平台客户端
    │       │
    │       ├── RealJDClient.search()
    │       │   ├── 真实 API 调用（有密钥时）
    │       │   └── 结果不足 → JDMockDatabase 补充（第1层）
    │       │
    │       ├── RealPDDClient.search()
    │       │   ├── 真实 API 调用（有密钥时）
    │       │   └── 失败/空 → 返回 []（无内部Mock）
    │       │
    │       └── TaobaoPlatformClient.search()
    │           ├── 真实 API 调用（有密钥时）
    │           └── use_mock=True → TaobaoMockDatabase（第2层）
    │
    ├── 全部失败/全部空 → MockProductGenerator（第3层，60条）
    │
    ▼
返回给 Flutter 前端
    │
    └── 仍为空 → mock_products.dart 本地库（第4层最终兜底）
```

---

## 3. 第1层：JDMockDatabase（京东 Mock 数据库）

**文件**：[backend/app/clients/jd_mock_database.py](../backend/app/clients/jd_mock_database.py)

**触发条件**：京东真实 API 调用后返回商品数 < `page_size / 2`，且 `use_mock_fallback = True`

**数据规模**：10 分类 × 50 条/分类 = **500 条**（每分类 15 个标题模板，随机构建）

### 3.1 分类与价格区间

| 分类 | 价格区间 |
|------|---------|
| 运动鞋 | ¥200 – ¥1,500 |
| 连衣裙 | ¥100 – ¥800 |
| 蓝牙耳机 | ¥200 – ¥3,000 |
| 手机 | ¥2,000 – ¥15,000 |
| T恤 | ¥50 – ¥300 |
| 双肩包 | ¥100 – ¥2,000 |
| 笔记本电脑 | ¥4,000 – ¥30,000 |
| 手表 | ¥500 – ¥100,000 |
| 护肤品 | ¥200 – ¥5,000 |
| 家电 | ¥500 – ¥20,000 |

### 3.2 每分类商品标题模板

#### 运动鞋（15 个）
1. Nike Air Max 270 男子气垫跑步鞋
2. Adidas Ultraboost 22 男女运动跑鞋
3. 李宁赤兔6 Pro 专业竞速跑步鞋
4. 安踏KT7 汤普森篮球鞋
5. New Balance 574 复古休闲运动鞋
6. Jordan Air Jordan 1 高帮篮球鞋
7. 特步动力巢 缓震跑步鞋
8. 361°飞燃 碳板竞速跑鞋
9. Puma Suede Classic 复古休闲鞋
10. Asics Gel-Kayano 30 支撑跑鞋
11. Skechers Go Walk 舒适健步鞋
12. Mizuno Wave Rider 26 慢跑鞋
13. Under Armour HOVR 芯片跑步鞋
14. Vans Old Skool 经典板鞋
15. Converse Chuck Taylor All Star 帆布鞋

#### 连衣裙（15 个）
1. 2024夏季新款雪纺连衣裙女士
2. 韩版修身显瘦碎花中长裙
3. 优雅气质真丝连衣裙高端
4. 法式复古方领泡泡袖连衣裙
5. 波西米亚风海边度假沙滩裙
6. 通勤职业西装领连衣裙
7. 甜美可爱洛丽塔公主裙
8. 轻奢刺绣晚礼服宴会裙
9. 棉麻文艺森系连衣裙
10. 针织收腰显瘦包臀连衣裙
11. A字大摆显瘦连衣裙
12. 吊带露背性感连衣裙
13. 旗袍改良版中国风连衣裙
14. 牛仔连衣裙减龄少女款
15. 运动休闲卫衣连衣裙

#### 蓝牙耳机（15 个）
1. Apple AirPods Pro 2 主动降噪耳机
2. Sony WH-1000XM5 头戴式降噪耳机
3. Bose QuietComfort 45 无线消噪耳机
4. 华为FreeBuds Pro 3 蓝牙耳机
5. 小米Buds 4 Pro 真无线降噪耳机
6. 漫步者NeoBuds Pro 圈铁耳机
7. JBL Tune 760NC 头戴式蓝牙耳机
8. Beats Studio Pro 无线耳机
9. 三星Galaxy Buds2 Pro 耳机
10. OPPO Enco X2 丹拿联合调音耳机
11. vivo TWS 3 Pro 真无线耳机
12. 荣耀Earbuds 3 Pro 测温耳机
13. Skullcandy Crusher ANC 重低音耳机
14. Sennheiser Momentum 4 耳机
15. 铁三角ATH-M50xBT2 专业监听耳机

#### 手机（15 个）
1. iPhone 15 Pro Max 256GB 钛金属
2. 华为Mate 60 Pro 5G手机
3. 小米14 Ultra 徕卡影像旗舰
4. OPPO Find X7 Ultra 双潜望手机
5. vivo X100 Pro 蔡司影像手机
6. 三星Galaxy S24 Ultra AI手机
7. 一加12 哈苏影像手机
8. 荣耀Magic6 Pro 鹰眼相机
9. Redmi K70 Pro 骁龙8Gen3手机
10. realme GT5 240W快充手机
11. iQOO 12 Pro 电竞游戏手机
12. 魅族21 骁龙8Gen3手机
13. 努比亚Z60 Ultra 屏下摄像手机
14. 摩托罗拉X50 Ultra 折叠屏
15. 索尼Xperia 1 V 4K HDR手机

#### T恤（15 个）
1. 优衣库纯棉圆领短袖T恤
2. Nike运动速干透气T恤
3. Adidas三叶草经典logoT恤
4. 李宁国潮印花短袖T恤
5. Gap重磅棉宽松T恤
6. H&M基础款纯色T恤
7. ZARA时尚设计感T恤
8. 无印良品新疆棉T恤
9. Champion经典刺绣T恤
10. Supreme街头潮流T恤
11. Stussy世界巡游印花T恤
12. Bape猿人头迷彩T恤
13. 北面户外速干T恤
14. 哥伦比亚防晒速干T恤
15. Levi's牛仔印花T恤

#### 双肩包（15 个）
1. Nike Elite Pro 篮球双肩包
2. Adidas Originals 三叶草背包
3. The North Face 北面户外登山包
4. JanSport经典校园双肩包
5. Herschel Supply 休闲背包
6. Doughnut Macaroon 甜甜圈背包
7. TUMI Alpha 3 商务通勤背包
8. Samsonite新秀丽电脑背包
9. 小米极简都市双肩包
10. 华为原装智能背包
11. Lululemon运动健身背包
12. Under Armour安德玛运动包
13. Deuter多特户外徒步背包
14. Osprey小鹰登山背包
15. Fjallraven北极狐Kanken背包

#### 笔记本电脑（15 个）
1. Apple MacBook Pro 16英寸 M3 Max
2. 华为MateBook X Pro 2024款
3. 联想ThinkPad X1 Carbon 商务本
4. 戴尔XPS 15 9540 轻薄本
5. 华硕ROG幻16 游戏本
6. 微星雷影17 满血游戏本
7. 惠普暗影精灵10 游戏笔记本
8. 拯救者Y9000P 2024款
9. MacBook Air M3 15英寸轻薄本
10. LG Gram 17 超轻薄笔记本
11. 雷蛇灵刃16 电竞游戏本
12. 技嘉AORUS 17X 旗舰游戏本
13. 宏碁非凡Go 青春轻薄本
14. 荣耀MagicBook Pro 16
15. 小米Redmi G 游戏本

#### 手表（15 个）
1. Apple Watch Series 9 智能手表
2. 华为Watch GT 4 运动手表
3. 小米Watch S3 eSIM版
4. OPPO Watch 4 Pro 全智能手表
5. 三星Galaxy Watch 6 Classic
6. Garmin佳明Forerunner 965
7. Tissot天梭力洛克机械表
8. Casio卡西欧G-Shock手表
9. Rolex劳力士水鬼潜航者
10. Omega欧米茄海马系列
11. Longines浪琴名匠系列
12. Swatch斯沃琪瑞士腕表
13. Seiko精工5号机械表
14. Citizen西铁城光动能表
15. TAG Heuer泰格豪雅竞潜

#### 护肤品（15 个）
1. SK-II神仙水精华液230ml
2. 兰蔻小黑瓶肌底精华100ml
3. 雅诗兰黛小棕瓶眼霜15ml
4. 资生堂红腰子精华50ml
5. 欧莱雅紫熨斗眼霜
6. 珀莱雅双抗精华液
7. 薇诺娜特护霜敏感肌
8. 修丽可色修精华
9. 海蓝之谜经典面霜60ml
10. 娇兰帝皇蜂姿复原蜜
11. 香奈儿山茶花保湿乳
12. 迪奥花蜜活颜丝悦系列
13. 雅顿金胶精华胶囊
14. 科颜氏高保湿面霜
15. 倩碧黄油无油版

#### 家电（15 个）
1. 海尔500L对开门冰箱
2. 美的10kg滚筒洗衣机
3. 格力3匹立式空调柜机
4. 戴森V15无线吸尘器
5. 科沃斯T20 PRO扫地机器人
6. 小米空气净化器4 Pro H
7. 西门子嵌入式洗碗机
8. 方太抽油烟机燃气灶套装
9. 老板电器大吸力油烟机
10. 九阳破壁机家用多功能
11. 苏泊尔电饭煲4L球釜
12. 美的微波炉智能变频
13. 飞利浦电动牙刷钻石9系
14. 松下智能马桶盖
15. 索尼75英寸4K智能电视

### 3.3 店铺名称（15 个）
京东自营官方旗舰店、品牌官方旗舰店、京东家电专卖店、京东运动户外店、京东数码专营店、京东美妆馆、京东服饰内衣店、京东手机通讯店、京东电脑办公店、京东家居日用店、京东超市自营、京东国际自营、品牌授权专卖店、京东品质生活馆、京东新品首发店

### 3.4 每分类品牌（各 10 个）

| 分类 | 品牌 |
|------|------|
| 运动鞋 | Nike, Adidas, 李宁, 安踏, New Balance, Jordan, 特步, 361°, Puma, Asics |
| 连衣裙 | 优衣库, ZARA, H&M, ONLY, VERO MODA, 欧时力, 太平鸟, 乐町, 伊芙丽, 诗凡黎 |
| 蓝牙耳机 | Apple, Sony, Bose, 华为, 小米, 漫步者, JBL, Beats, 三星, OPPO |
| 手机 | Apple, 华为, 小米, OPPO, vivo, 三星, 一加, 荣耀, Redmi, realme |
| T恤 | 优衣库, Nike, Adidas, 李宁, Gap, Champion, 北面, 哥伦比亚, Levi's, 无印良品 |
| 双肩包 | Nike, Adidas, 北面, TUMI, 新秀丽, 小米, Herschel, Fjallraven, Osprey, Deuter |
| 笔记本电脑 | Apple, 华为, 联想, 戴尔, 华硕, 惠普, 拯救者, LG, 雷蛇, 小米 |
| 手表 | Apple, 华为, 小米, Garmin, Tissot, Casio, Rolex, Omega, Longines, Swatch |
| 护肤品 | SK-II, 兰蔻, 雅诗兰黛, 资生堂, 欧莱雅, 珀莱雅, 薇诺娜, 修丽可, 海蓝之谜, 科颜氏 |
| 家电 | 海尔, 美的, 格力, 戴森, 科沃斯, 小米, 西门子, 方太, 老板, 索尼 |

### 3.5 京东数据字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `item_id` | str | 京东商品ID |
| `title` | str | 品牌 + 标题模板组合 |
| `category` | str | 所属分类 |
| `price` | float | 当前售价 = 原价 × 0.7~1.0 |
| `original_price` | float | 划线价 |
| `sales_count` | int | 100~50000 随机 |
| `rating` | float | 4.2~5.0 随机 |
| `review_count` | int | 50~sales_count 随机 |
| `shop_name` | str | 15个预设店铺中随机 |
| `shop_type` | str | self_operated / third_party |
| `is_self_operated` | bool | 60%概率为自营 |
| `is_jd_logistics` | bool | 75%概率京东物流 |
| `coupon_amount` | float | 0~200 随机 |
| `brand` | str | 从分类品牌列表随机 |
| `tags` | list[str] | 京东自营、京东物流、热销爆款、新品上市、限时特惠、PLUS会员、品质保障 |
| `is_mock` | bool | 固定为 `True` |

---

## 4. 第2层：TaobaoMockDatabase（淘宝 Mock 数据库）

**文件**：[backend/app/clients/taobao_mock_database.py](../backend/app/clients/taobao_mock_database.py)

**触发条件**：配置项 `use_mock_fallback = True` 时，`RealTaobaoClient` 直接使用 Mock 路径

**数据规模**：10 分类 × 50 条/分类 = **500 条**（每分类 10 个标题模板，随机构建）

### 4.1 分类与子分类

| 分类 | 子分类（各5个） |
|------|----------------|
| 时尚服饰 | 男装、女装、鞋靴、箱包、配饰 |
| 数码家电 | 手机、电脑、耳机、家电、数码配件 |
| 家居生活 | 家具、家纺、厨具、日用品、装饰 |
| 美妆个护 | 护肤、彩妆、香水、个护、美容仪器 |
| 食品生鲜 | 零食、生鲜、粮油、饮料、滋补 |
| 运动户外 | 运动鞋服、健身器材、户外装备、球类运动、游泳用品 |
| 母婴用品 | 婴儿服饰、奶粉辅食、孕妈用品、童车童床、安全座椅 |
| 玩具乐器 | 积木、遥控玩具、娃娃、模型、益智玩具 |
| 办公文具 | 办公纸品、办公文具、办公设备、收纳用品、桌面用品 |
| 宠物用品 | 主粮、零食、猫砂、宠物用品、宠物玩具 |

### 4.2 每分类商品标题模板

#### 时尚服饰（10 个）
1. 2024新款夏季纯棉短袖T恤男士
2. 韩版修身显瘦连衣裙女装
3. 潮流运动休闲鞋老爹鞋
4. 轻薄透气防晒衣男女同款
5. 时尚牛仔外套夹克上衣
6. 百搭阔腿裤垂感长裤
7. 优雅气质真丝衬衫女士
8. 保暖加绒毛衣针织衫
9. 高端商务正装皮鞋
10. 时尚双肩包旅行背包

#### 数码家电（10 个）
1. 2024最新款智能手机旗舰版
2. 高清4K智能液晶电视
3. 无线蓝牙耳机降噪Pro
4. 超薄笔记本电脑轻薄款
5. 大容量移动电源快充
6. 智能手表运动健康监测
7. 家用空气净化器除甲醛
8. 全自动智能扫地机器人
9. 便携蓝牙音箱低音炮
10. 机械键盘电竞游戏专用

#### 家居生活（10 个）
1. 北欧风简约实木餐桌
2. 记忆棉护颈枕头枕芯
3. 全棉四件套床上用品
4. 智能恒温电热水壶
5. 大容量冰箱家用节能
6. 滚筒全自动洗衣机
7. 创意LED护眼台灯
8. 多功能厨房料理机
9. 防滑浴室地垫吸水
10. 轻奢风客厅装饰画

#### 美妆个护（10 个）
1. 大牌正品口红持久不脱色
2. 深层补水保湿面膜套装
3. 美白精华液淡斑提亮
4. 氨基酸温和洗面奶洁面乳
5. 防晒喷雾SPF50+防水
6. 气垫BB霜遮瑕持久
7. 香水女士持久淡香
8. 男士护肤套装控油
9. 电动牙刷声波震动
10. 美容仪脸部按摩导入

#### 食品生鲜（10 个）
1. 进口零食大礼包组合装
2. 新鲜水果当季整箱包邮
3. 正宗四川麻辣火锅底料
4. 手工曲奇饼干礼盒装
5. 有机纯牛奶整箱24盒
6. 即食燕窝滋补营养品
7. 咖啡豆新鲜烘焙现磨
8. 网红奶茶粉袋装速溶
9. 东北大米10斤装五常
10. 香辣牛肉干特产零食

#### 运动户外（10 个）
1. 专业跑步鞋减震透气
2. 瑜伽垫加厚防滑健身垫
3. 动感单车家用静音款
4. 羽毛球拍正品全碳素
5. 游泳衣女款显瘦连体
6. 登山包户外旅行大容量
7. 篮球标准7号耐磨
8. 运动手环心率监测
9. 哑铃男士健身器材
10. 滑板初学者专业双翘

#### 母婴用品（10 个）
1. 新生儿纯棉婴儿衣服套装
2. 进口奶粉婴幼儿配方
3. 宝宝安全座椅汽车用
4. 婴儿推车轻便折叠可坐躺
5. 纸尿裤超薄透气尿不湿
6. 儿童益智早教玩具
7. 孕妇护肤品专用套装
8. 奶瓶消毒器带烘干
9. 婴儿辅食机多功能
10. 宝宝学步鞋软底防滑

#### 玩具乐器（10 个）
1. 乐高积木拼装益智玩具
2. 遥控汽车高速漂移赛车
3. 芭比娃娃套装大礼盒
4. 无人机航拍高清专业
5. 拼图1000片成人减压
6. 魔方三阶顺滑比赛专用
7. 儿童电子琴多功能玩具
8. 手办模型动漫周边
9. 泡泡机全自动网红款
10. 桌游卡牌多人聚会游戏

#### 办公文具（10 个）
1. A4打印纸整箱500张
2. 人体工学办公椅护腰
3. 中性笔黑色签字笔12支
4. 文件资料袋透明档案袋
5. 桌面收纳盒文具整理
6. 订书机重型加厚省力
7. 笔记本子商务记事本
8. 标签打印机便携式
9. 白板支架式家用教学
10. U盘64G高速正品

#### 宠物用品（10 个）
1. 猫粮成猫幼猫全价粮
2. 狗狗零食磨牙棒骨头
3. 猫砂豆腐砂除臭无尘
4. 宠物自动喂食器定时
5. 猫窝四季通用可拆洗
6. 狗狗牵引绳胸背带
7. 宠物沐浴露杀菌除臭
8. 猫爬架大型猫树一体
9. 宠物玩具逗猫棒套装
10. 航空箱宠物外出便携

### 4.3 店铺名称（20 个）
天猫官方旗舰店、淘宝精选店铺、品牌直营专卖店、全球购海外店、工厂直销批发店、网红直播带货店、88VIP专属店、品质生活生活馆、时尚潮流先锋店、数码科技体验店、家居好物优选店、美妆护肤专柜、美食特产专营店、运动户外装备店、母婴用品母婴坊、玩具总动员乐园、办公文具一站式、萌宠之家宠物店、时尚穿搭工作室、数码家电大卖场

### 4.4 店铺等级（6 个）
红心1钻、蓝冠3冠、金冠5冠、天猫旗舰店、天猫超市、企业店铺

### 4.5 淘宝数据字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `item_id` | str | 淘宝商品ID |
| `title` | str | 随机选取的标题模板 |
| `category` | str | 所属分类 |
| `sub_category` | str | 子分类 |
| `price` | float | ¥19.90~2999.90 随机 |
| `original_price` | float | 价格 × 1.2~2.0 |
| `sales_count` | int | 10~99999 随机 |
| `shop_name` | str | 20个预设店铺中随机 |
| `shop_level` | str | 6个店铺等级中随机 |
| `rating` | float | 4.0~5.0 随机 |
| `review_count` | int | 50~50000 随机 |
| `coupon_amount` | float | 0~100 随机 |
| `commission_rate` | float | 1%~50% 随机 |
| `is_tianmao` | bool | 50%概率为天猫 |
| `is_hot` | bool | 销量 > 5000 为热销 |
| `is_mock` | bool | 固定为 `True` |
| `tags` | list[str] | 淘宝直播、88VIP、淘金币、包邮、7天无理由、天猫正品、新品上市、热销爆款、限时特惠、官方旗舰店 |

---

## 5. 第3层：MockProductGenerator（通用动态生成器）

**文件**：[backend/app/clients/mock_product_generator.py](../backend/app/clients/mock_product_generator.py)

**触发条件**：所有平台搜索均失败或均返回空，且 `use_mock_fallback = True`

**数据规模**：京东/拼多多/淘宝 各 20 条 = **60 条**（每次按需动态生成）

### 5.1 分类体系与品牌

| 分类 | 价格区间 | 品牌 |
|------|---------|------|
| 运动鞋 | ¥199 – ¥1,299 | Nike, Adidas, 安踏, 李宁, New Balance, 特步, 361°, 鸿星尔克, Puma, Asics |
| 连衣裙 | ¥59 – ¥499 | 韩都衣舍, UR, 茵曼, ONLY, 优衣库, ZARA, 太平鸟, 乐町, 三彩, 红袖 |
| 蓝牙耳机 | ¥99 – ¥2,999 | Apple, Sony, 小米, 漫步者, 华为, Bose, JBL, OPPO, vivo, 三星 |
| 手机 | ¥1,299 – ¥15,999 | Apple, 华为, 小米, OPPO, vivo, Samsung, 荣耀, 一加, realme, iQOO |
| T恤 | ¥29 – ¥299 | 优衣库, Nike, MUJI, Gap, 中国李宁, Adidas, HM, 森马, 美特斯邦威, 凡客诚品 |
| 双肩包 | ¥79 – ¥1,299 | The North Face, 小米, JanSport, Deuter, Lululemon, Nike, Adidas, 新秀丽, 瑞士军刀, 国家地理 |
| 笔记本电脑 | ¥3,999 – ¥39,999 | Apple, 联想, 华为, 戴尔, 惠普, 华硕, 微星, 雷蛇, 小米, 机械革命 |
| 手表 | ¥199 – ¥199,999 | Apple, 华为, 小米, OPPO, vivo, 三星, 卡西欧, 天梭, 浪琴, 劳力士 |
| 护肤品 | ¥89 – ¥3,999 | 兰蔻, 雅诗兰黛, SK-II, 欧莱雅, 资生堂, 珀莱雅, 百雀羚, 自然堂, 玉兰油, 海蓝之谜 |
| 家电 | ¥599 – ¥29,999 | 美的, 格力, 海尔, 小米, 海信, TCL, 创维, 西门子, 松下, 索尼 |

### 5.2 每分类基础名称模板（各 10 个，{brand} 为品牌占位符）

#### 运动鞋
1. {brand} Air Max 气垫跑步鞋 透气缓震
2. {brand} Ultraboost 回弹运动休闲鞋
3. {brand} 氢跑4.0 超轻专业竞速鞋
4. {brand} 赤兔6 Pro 高弹耐磨训练跑鞋
5. {brand} 574 经典复古休闲运动鞋
6. {brand} 动力巢T20 马拉松轻便透气鞋
7. {brand} 飞燃2 碳板竞速专业跑鞋
8. {brand} 星云9.0 缓震舒适运动鞋
9. {brand} 篮球鞋 实战高帮耐磨战靴
10. {brand} 老爹鞋 复古潮流增高休闲鞋

#### 连衣裙
1. {brand} 2024夏季新款碎花雪纺连衣裙 显瘦中长款
2. {brand} 法式复古收腰气质连衣裙 温柔风长裙
3. {brand} 棉麻文艺范宽松连衣裙 森系小清新
4. {brand} 性感V领蕾丝连衣裙 晚宴派对小礼服
5. {brand} 运动风休闲连衣裙 减龄显瘦T恤裙
6. {brand} 吊带连衣裙 海边度假沙滩裙
7. {brand} 衬衫连衣裙 通勤职业气质中长裙
8. {brand} 牛仔连衣裙 复古减龄A字短裙
9. {brand} 针织连衣裙 秋冬修身显瘦包臀裙
10. {brand} 旗袍连衣裙 中国风改良年轻款

#### 蓝牙耳机
1. {brand} AirPods Pro 2 主动降噪无线蓝牙耳机
2. {brand} WF-1000XM5 旗舰级降噪豆 无线耳机
3. {brand} Buds 5 半入耳降噪蓝牙耳机 长续航
4. {brand} LolliPods Pro 2 降噪蓝牙耳机 性价比之选
5. {brand} FreeBuds Pro 3 星闪技术 无线耳机
6. {brand} QuietComfort Ultra 消噪耳塞
7. {brand} Tune 230NC TWS 真无线降噪耳机
8. {brand} Enco X2 双重降噪蓝牙耳机
9. {brand} TWS 3 Pro 真无线降噪耳机
10. {brand} Galaxy Buds2 Pro 主动降噪耳机

#### 手机
1. {brand} iPhone 15 Pro Max 256GB 钛金属原色
2. {brand} Mate 60 Pro 512GB 雅丹黑 卫星通话
3. {brand} 14 Ultra 16GB+512GB 徕卡影像 专业旗舰
4. {brand} Find X7 Ultra 16GB+1TB 哈苏影像系统
5. {brand} X100 Pro 16GB+512GB 蔡司APO超级长焦
6. {brand} Galaxy S24 Ultra 1TB 骁龙8 Gen3 旗舰
7. {brand} Magic 6 Pro 鹰眼相机 第二代骁龙8
8. {brand} 12 16GB+1TB 性能旗舰 游戏手机
9. {brand} GT5 240W满级秒充 旗舰手机
10. {brand} Neo9S Pro+ 电竞旗舰 游戏手机

#### T恤
1. {brand} U系列 纯棉圆领T恤 多色可选
2. {brand} 运动速干T恤 透气排汗 跑步健身
3. {brand} 水洗棉T恤 基础款 舒适百搭
4. {brand} 美式复古印花T恤 宽松oversize
5. {brand} 国潮原创设计T恤 中国风印花 个性潮流
6. {brand} 重磅棉T恤 230g厚实不透 基础款
7. {brand} 联名款T恤 艺术家合作限量版
8. {brand} 情侣装T恤 夏季新款 宽松大码
9. {brand} 纯色打底T恤 内搭外穿 百搭神器
10. {brand} 卡通印花T恤 可爱减龄 学生款

#### 双肩包
1. {brand} 北面双肩包 户外旅行通勤
2. {brand} 极简都市双肩包 15.6英寸电脑包
3. {brand} 经典校园双肩包 学生书包
4. {brand} 多特户外登山包 大容量旅行背包
5. {brand} Everywhere 运动休闲双肩包
6. {brand} 运动双肩包 大容量训练包
7. {brand} 经典校园背包 复古潮流双肩包
8. {brand} 商务双肩包 通勤电脑包 防水
9. {brand} 国家地理摄影包 单反相机双肩包
10. {brand} 大容量旅行背包 短途出差行李包

#### 笔记本电脑
1. {brand} MacBook Pro 16英寸 M3 Max 芯片
2. {brand} ThinkPad X1 Carbon 2024 商务旗舰
3. {brand} MateBook X Pro 2024 轻薄本
4. {brand} XPS 15 9540 高性能创作本
5. {brand} 暗影精灵9 游戏本 RTX4090
6. {brand} 天选5 Pro 锐龙版 游戏笔记本
7. {brand} 雷蛇灵刃16 水银 电竞游戏本
8. {brand} RedmiBook Pro 15 2024 轻薄本
9. {brand} 机械革命旷世16 Super 水冷游戏本
10. {brand} 小新Pro16 2024 高性能轻薄本

#### 手表
1. {brand} Watch Series 9 智能手表 GPS版
2. {brand} Watch GT 4 运动智能手表 血氧监测
3. {brand} Watch S3 智能手表 独立通话
4. {brand} Watch X 全智能手表 旗舰运动版
5. {brand} Watch 3 Pro 智能手表 eSIM独立通话
6. {brand} Galaxy Watch 6 Classic 智能手表
7. {brand} G-Shock 经典运动电子手表
8. {brand} 力洛克系列 机械腕表 商务休闲
9. {brand} 名匠系列 自动机械手表 瑞士进口
10. {brand} 水鬼系列 潜航者型自动机械腕表

#### 护肤品
1. {brand} 小黑瓶精华肌底液 100ml 修护维稳
2. {brand} 小棕瓶特润修护精华液 50ml
3. {brand} 神仙水护肤精华露 230ml 补水保湿
4. {brand} 紫熨斗全脸眼霜 30ml 淡化细纹
5. {brand} 红腰子精华 50ml 增强肌肤免疫力
6. {brand} 红宝石面霜 50g 抗皱紧致
7. {brand} 三生花水乳套装 补水保湿
8. {brand} 凝时鲜颜肌活霜 50g 抗初老
9. {brand} 大红瓶面霜 80g 滋润紧致
10. {brand} 经典面霜 60ml 修护保湿

#### 家电
1. {brand} 1.5匹新一级能效变频冷暖空调挂机
2. {brand} 3匹立式柜机空调 新一级能效
3. {brand} 500L 对开门大容量冰箱 风冷无霜
4. {brand} 10kg 滚筒洗衣机 洗烘一体 除菌
5. {brand} 75英寸 4K超高清智能电视 全面屏
6. {brand} 20L 微波炉 家用小型 智能多功能
7. {brand} 65英寸 OLED 4K超清电视 自发光
8. {brand} 十字对开门冰箱 550L 智能变频
9. {brand} 波轮洗衣机 12kg 大容量 全自动
10. {brand} 85英寸 Mini LED 巨幕电视 120Hz

### 5.3 平台专属标签

**京东**：自营、京东物流、限时特惠、满减优惠、赠运费险、2年质保、次日达、官方授权

**拼多多**：百亿补贴、品牌黑标、万人团、限时秒杀、多多买菜、极速退款、假一赔十、正品保障

**淘宝**：天猫旗舰、88VIP、淘金币、限时特价、7天无理由、极速退款、退货运费险、正品保证、全球购、iFashion

### 5.4 生成字段

| 字段 | 说明 |
|------|------|
| `id` | `{platform}_{category}_{index}_{random}` |
| `name` | `{brand} {base_name}` |
| `price` | 分类区间内随机 |
| `original_price` | 价格 × 1.1~1.5 |
| `platform` | `"jd"` / `"pdd"` / `"taobao"` |
| `shop_name` | `{brand}官方旗舰店` |
| `shop_type` | jd: self_operated/official, taobao: tmall/taobao, pdd: official/third_party |
| `rating` | 京东 4.2~5.0 / 其他 None |
| `sales_count` | 100~500000 随机 |
| `image_url` | `https://picsum.photos/seed/{key}/300/400` |
| `is_mock` | 固定为 `True` |
| `attributes` | `{brand, category}` |
| `tags` | 平台专属标签列表（随机 2~4 个） |

---

## 6. MockProductLibrary（辅助关键词匹配库）

**文件**：[backend/app/clients/mock_product_library.py](../backend/app/clients/mock_product_library.py)

**触发条件**：内部使用，无直接触发入口

**数据规模**：7 分类（6 + 默认），每分类 5 条，总计约 **40 条硬编码商品**

### 6.1 全部商品明细

#### 运动鞋（6 个）
| # | 名称 | 价格 | 品牌 |
|---|------|------|------|
| 1 | Nike Air Max 270 男子气垫跑步鞋 透气缓震 | ¥599.00 | Nike |
| 2 | Adidas Ultraboost 22 男女同款运动休闲鞋 回弹舒适 | ¥799.00 | Adidas |
| 3 | 安踏 氢跑4.0 超轻透气跑步鞋 专业竞速 | ¥399.00 | 安踏 |
| 4 | 李宁 赤兔6 Pro 竞速训练跑鞋 高弹耐磨 | ¥459.00 | 李宁 |
| 5 | New Balance 574 经典复古休闲运动鞋 百搭潮流 | ¥499.00 | New Balance |
| 6 | 特步 动力巢T20 专业马拉松竞速鞋 轻便透气 | ¥299.00 | 特步 |

#### 连衣裙（5 个）
| # | 名称 | 价格 | 品牌 |
|---|------|------|------|
| 1 | 2024夏季新款碎花雪纺连衣裙 显瘦中长款 | ¥129.00 | 韩都衣舍 |
| 2 | 法式复古收腰气质连衣裙 温柔风长裙 | ¥199.00 | UR |
| 3 | 棉麻文艺范宽松连衣裙 森系小清新 | ¥89.00 | 茵曼 |
| 4 | 性感V领蕾丝连衣裙 晚宴派对小礼服 | ¥259.00 | ONLY |
| 5 | 运动风休闲连衣裙 减龄显瘦T恤裙 | ¥79.00 | 优衣库 |

#### 蓝牙耳机（5 个）
| # | 名称 | 价格 | 品牌 |
|---|------|------|------|
| 1 | Apple AirPods Pro 2 主动降噪无线蓝牙耳机 | ¥1,599.00 | Apple |
| 2 | Sony WF-1000XM5 旗舰级降噪豆 无线耳机 | ¥1,999.00 | Sony |
| 3 | 小米 Buds 5 半入耳降噪蓝牙耳机 长续航 | ¥299.00 | 小米 |
| 4 | 漫步者 LolliPods Pro 2 降噪蓝牙耳机 性价比之选 | ¥199.00 | 漫步者 |
| 5 | 华为 FreeBuds Pro 3 星闪技术 无线耳机 | ¥999.00 | 华为 |

#### 手机（5 个）
| # | 名称 | 价格 | 品牌 |
|---|------|------|------|
| 1 | Apple iPhone 15 Pro Max 256GB 钛金属原色 | ¥9,999.00 | Apple |
| 2 | 华为 Mate 60 Pro 512GB 雅丹黑 卫星通话 | ¥6,999.00 | 华为 |
| 3 | 小米14 Ultra 16GB+512GB 徕卡影像 专业旗舰 | ¥6,499.00 | 小米 |
| 4 | OPPO Find X7 Ultra 16GB+1TB 哈苏影像系统 | ¥5,999.00 | OPPO |
| 5 | vivo X100 Pro 16GB+512GB 蔡司APO超级长焦 | ¥5,299.00 | vivo |

#### T恤（5 个）
| # | 名称 | 价格 | 品牌 |
|---|------|------|------|
| 1 | 优衣库 U系列 纯棉圆领T恤 多色可选 | ¥79.00 | 优衣库 |
| 2 | Nike 运动速干T恤 透气排汗 跑步健身 | ¥149.00 | Nike |
| 3 | 无印良品 水洗棉T恤 基础款 舒适百搭 | ¥59.00 | MUJI |
| 4 | Gap 美式复古印花T恤 宽松oversize | ¥99.00 | Gap |
| 5 | 国潮原创设计T恤 中国风印花 个性潮流 | ¥129.00 | 中国李宁 |

#### 双肩包（5 个）
| # | 名称 | 价格 | 品牌 |
|---|------|------|------|
| 1 | The North Face 北面双肩包 户外旅行通勤 | ¥399.00 | The North Face |
| 2 | 小米 极简都市双肩包 15.6英寸电脑包 | ¥99.00 | 小米 |
| 3 | JanSport 经典校园双肩包 学生书包 | ¥259.00 | JanSport |
| 4 | Deuter 多特户外登山包 大容量旅行背包 | ¥599.00 | Deuter |
| 5 | Lululemon Everywhere 运动休闲双肩包 | ¥459.00 | Lululemon |

#### 默认兜底（5 个）
| # | 名称 | 价格 | 品牌 |
|---|------|------|------|
| 1 | 精选好物 高品质商品 限时特惠 | ¥99.00 | 精选 |
| 2 | 热销爆款 全网比价 超值推荐 | ¥199.00 | 热销 |
| 3 | 品质生活 精选好物 限时折扣 | ¥299.00 | 品质 |
| 4 | 人气爆款 万人好评 放心选购 | ¥59.00 | 人气 |
| 5 | 新品上市 首发特惠 抢先体验 | ¥159.00 | 新品 |

---

## 7. 第4层：Flutter 前端本地 Mock 库（最终兜底）

**文件**：[snapshop/lib/core/mock_products.dart](../snapshop/lib/core/mock_products.dart)

**触发条件**：后端 API 返回商品列表为空但 VLM 识别结果不为空时，Flutter 前端本地匹配分类商品

**匹配逻辑**：将 VLM 识别的分类名与库中分类做**双向子串匹配**（不区分大小写）

**数据规模**：6 个分类，总计约 **30 条硬编码商品**

### 7.1 全部商品明细

#### 运动鞋（6 个）
| # | 名称 | 价格 | 原价 | 品牌 | 店铺 | 评分 | 销量 | 平台 |
|---|------|------|------|------|------|------|------|------|
| 1 | Nike Air Max 270 男子气垫跑步鞋 透气缓震 | ¥599 | ¥799 | Nike | Nike官方旗舰店 | 4.9 | 12,580 | 拼多多 |
| 2 | Adidas Ultraboost 22 男女同款运动休闲鞋 | ¥799 | ¥1,099 | Adidas | Adidas官方旗舰店 | 4.8 | 8,920 | 京东 |
| 3 | 安踏 氢跑4.0 超轻透气跑步鞋 | ¥399 | ¥499 | 安踏 | 安踏官方旗舰店 | 4.7 | 34,500 | 淘宝 |
| 4 | 李宁 赤兔6 Pro 竞速训练跑鞋 高弹耐磨 | ¥459 | ¥599 | 李宁 | 李宁官方旗舰店 | 4.8 | 22,300 | 拼多多 |
| 5 | New Balance 574 经典复古休闲运动鞋 | ¥499 | ¥699 | New Balance | NB品牌店 | 4.6 | 15,600 | 京东 |
| 6 | 特步 动力巢T20 专业马拉松竞速鞋 | ¥299 | ¥399 | 特步 | 特步品牌店 | 4.5 | 45,600 | 淘宝 |

#### 连衣裙（4 个）
| # | 名称 | 价格 | 原价 | 品牌 | 店铺 | 评分 | 销量 | 平台 |
|---|------|------|------|------|------|------|------|------|
| 1 | 2024夏季新款碎花雪纺连衣裙 显瘦中长款 | ¥129 | ¥259 | 韩都衣舍 | 韩都衣舍旗舰店 | 4.7 | 32,100 | 拼多多 |
| 2 | 法式复古收腰气质连衣裙 温柔风长裙 | ¥199 | ¥399 | UR | UR官方旗舰店 | 4.8 | 18,900 | 京东 |
| 3 | 棉麻文艺范宽松连衣裙 森系小清新 | ¥89 | ¥179 | 茵曼 | 茵曼品牌店 | 4.6 | 15,800 | 淘宝 |
| 4 | 性感V领蕾丝连衣裙 晚宴派对小礼服 | ¥259 | ¥499 | ONLY | ONLY官方旗舰店 | 4.5 | 8,700 | 拼多多 |

#### 蓝牙耳机（5 个）
| # | 名称 | 价格 | 原价 | 品牌 | 店铺 | 评分 | 销量 | 平台 |
|---|------|------|------|------|------|------|------|------|
| 1 | Apple AirPods Pro 2 主动降噪无线蓝牙耳机 | ¥1,599 | ¥1,899 | Apple | Apple官方旗舰店 | 4.9 | 56,700 | 拼多多 |
| 2 | Sony WF-1000XM5 旗舰级降噪豆 | ¥1,999 | ¥2,499 | Sony | Sony官方旗舰店 | 4.8 | 23,400 | 京东 |
| 3 | 小米 Buds 5 半入耳降噪蓝牙耳机 长续航 | ¥299 | ¥399 | 小米 | 小米官方旗舰店 | 4.6 | 89,200 | 淘宝 |
| 4 | 漫步者 LolliPods Pro 2 降噪蓝牙耳机 | ¥199 | ¥299 | 漫步者 | 漫步者旗舰店 | 4.4 | 112,000 | 拼多多 |
| 5 | 华为 FreeBuds Pro 3 星闪技术无线耳机 | ¥999 | ¥1,299 | 华为 | 华为官方旗舰店 | 4.7 | 45,600 | 京东 |

#### 手机（4 个）
| # | 名称 | 价格 | 原价 | 品牌 | 店铺 | 评分 | 销量 | 平台 |
|---|------|------|------|------|------|------|------|------|
| 1 | Apple iPhone 15 Pro Max 256GB 钛金属原色 | ¥9,999 | ¥10,999 | Apple | Apple官方旗舰店 | 4.9 | 234,500 | 拼多多 |
| 2 | 华为 Mate 60 Pro 512GB 雅丹黑 | ¥6,999 | ¥7,499 | 华为 | 华为官方旗舰店 | 4.9 | 187,000 | 京东 |
| 3 | 小米14 Ultra 16GB+512GB 徕卡影像 | ¥6,499 | ¥6,999 | 小米 | 小米官方旗舰店 | 4.8 | 123,000 | 淘宝 |
| 4 | OPPO Find X7 Ultra 16GB+1TB | ¥5,999 | ¥6,499 | OPPO | OPPO官方旗舰店 | 4.7 | 89,000 | 拼多多 |

#### T恤（3 个）
| # | 名称 | 价格 | 原价 | 品牌 | 店铺 | 评分 | 销量 | 平台 |
|---|------|------|------|------|------|------|------|------|
| 1 | 优衣库 U系列 纯棉圆领T恤 多色可选 | ¥79 | ¥99 | 优衣库 | 优衣库官方旗舰店 | 4.8 | 89,000 | 拼多多 |
| 2 | Nike 运动速干T恤 透气排汗 | ¥149 | ¥199 | Nike | Nike官方旗舰店 | 4.7 | 45,600 | 京东 |
| 3 | 国潮原创设计T恤 中国风印花 | ¥129 | ¥169 | 中国李宁 | 李宁品牌店 | 4.5 | 12,800 | 淘宝 |

#### 双肩包（4 个）
| # | 名称 | 价格 | 原价 | 品牌 | 店铺 | 评分 | 销量 | 平台 |
|---|------|------|------|------|------|------|------|------|
| 1 | The North Face 北面双肩包 户外旅行通勤 | ¥399 | ¥599 | The North Face | 北面官方旗舰店 | 4.8 | 23,400 | 拼多多 |
| 2 | 小米 极简都市双肩包 15.6英寸电脑包 | ¥99 | ¥159 | 小米 | 小米官方旗舰店 | 4.7 | 56,000 | 京东 |
| 3 | JanSport 经典校园双肩包 学生书包 | ¥259 | ¥359 | JanSport | JanSport品牌店 | 4.6 | 34,500 | 淘宝 |
| 4 | Lululemon Everywhere 运动休闲双肩包 | ¥459 | ¥599 | Lululemon | Lululemon官方旗舰店 | 4.8 | 12,300 | 拼多多 |

---

## 8. Flutter 前端数据模型

**文件**：[snapshop/lib/core/mock_data.dart](../snapshop/lib/core/mock_data.dart)

定义了 4 个 Flutter 端可复用的数据模型：

| 模型 | 字段 |
|------|------|
| `MockProduct` | id, name, price, originalPrice, platform, shopName, shopType, rating, salesCount, imageUrl, productUrl, isMock, tags, attributes |
| `MockAttribute` | key, label, value |
| `MockSuggestion` | id, title, icon, action, type, params |
| `MockRecognitionResult` | category, attributes, suggestions |

---

## 9. 跨平台商品统一格式

所有 Mock 商品（无论来源）最终通过 [product_serializer.py](../backend/app/services/product_serializer.py) 序列化为统一格式：

| 字段 | 类型 | 必备 | 说明 |
|------|------|:--:|------|
| `id` | str | ✅ | 商品唯一ID |
| `name` | str | ✅ | 商品名称 |
| `price` | float | ✅ | 当前售价 |
| `original_price` | float | — | 划线价 |
| `platform` | str | ✅ | `"jd"` / `"pdd"` / `"taobao"` |
| `shop_name` | str | — | 店铺名称 |
| `shop_type` | str | — | `"official"` / `"self_operated"` / `"third_party"` / `"tmall"` |
| `rating` | float | — | 评分 0~5 |
| `sales_count` | int | — | 销量 |
| `image_url` | str | — | 商品缩略图URL |
| `product_url` | str | — | 商品链接URL |
| `is_mock` | bool | ✅ | Mock标记（所有Mock数据为 `true`） |
| `attributes` | dict | — | `{brand, category}` |
| `tags` | list[str] | — | 平台专属标签 |

---

## 10. 数据规模汇总

| 数据源 | 层级 | 规模 | 生成方式 |
|--------|:--:|------|----------|
| JDMockDatabase | 第1层 | 10类 × 50 = **500 条** | 15标题模板 + 10品牌 + 随机价格/销量/评分 |
| TaobaoMockDatabase | 第2层 | 10类 × 50 = **500 条** | 10标题模板 + 随机价格/销量/评分/佣金 |
| MockProductGenerator | 第3层 | 3平台 × 20 = **60 条** | 10类 × 10品牌 × 10名称模板动态组合 |
| MockProductLibrary | 辅助 | 7类 × 5 ≈ **40 条** | 完全硬编码，价格小幅随机波动 |
| mock_products.dart | 第4层 | 6类 × 2~6 ≈ **30 条** | 完全硬编码 + 指定销量/评分/平台 |

**总计可用 Mock 商品**：约 **1,130 条**（500 + 500 + 60 + 40 + 30）

---

## 11. 图片资源说明

Mock 商品图片使用以下外部占位图服务（均为公开合法服务）：

| 来源 | 服务商 | 用途 |
|------|--------|------|
| `https://picsum.photos/{w}/{h}` | Lorem Picsum | MockProductGenerator 随机风景图 |
| `https://via.placeholder.com/{w}x{h}` | Placeholder.com | MockProductLibrary 和 Flutter 本地库 |
| `https://img14.360buyimg.com/...` | 模拟京东域名 | JDMockDatabase 模拟京东商品图 |
| `https://img.alicdn.com/...` | 模拟阿里CDN | TaobaoMockDatabase 模拟淘宝商品图 |

> 以上图片 URL 均为模拟占位，不会实际发起对电商平台的图片请求。

---

## 12. 配置指南

所有 Mock 行为由 [config.py](../backend/app/config.py) 中的配置控制：

| 配置项 | 默认值 | 说明 |
|--------|--------|------|
| `use_mock_fallback` | `true` | Mock 总开关，关闭后所有层级 Mock 均失效 |
| `jd_app_key` | — | 京东联盟 API Key（有值时优先走真实API） |
| `jd_app_secret` | — | 京东联盟 API Secret |
| `pdd_client_id` | — | 拼多多开放平台 Client ID（有值时优先走真实API） |
| `pdd_client_secret` | — | 拼多多开放平台 Client Secret |
| `taobao_app_key` | — | 淘宝开放平台 App Key（有值时优先走真实API） |
| `taobao_app_secret` | — | 淘宝开放平台 App Secret |

---

## 13. 注意事项

1. **`is_mock` 标记**：所有 Mock 商品均携带 `is_mock: true`，可在前端或日志中区分真实/Mock 数据
2. **平台 Badge 显示**：Mock 商品在前端显示平台标识时，会在 Badge 中追加「模拟」提示（如「淘宝+模拟」），让用户明确知道当前看到的是模拟数据
3. **图片不持久化**：Mock 商品的图片 URL 指向外部占位图服务，不占用本地存储
4. **合规声明**：Mock 数据完全由程序生成，不涉及任何网络爬虫或对电商平台的未授权数据抓取

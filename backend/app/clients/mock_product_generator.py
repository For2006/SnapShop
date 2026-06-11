import random

from typing import Any


class MockProductGenerator:
    """强大的 Mock 商品生成器 - 京东、拼多多、淘宝各 500 条"""

    # 完整商品分类体系
    CATEGORIES = [
        {
            "name": "运动鞋",
            "keywords": ["运动鞋", "跑步鞋", "球鞋", "跑鞋", "篮球鞋", "休闲鞋"],
            "brands": ["Nike", "Adidas", "安踏", "李宁", "New Balance", "特步", "361°", "鸿星尔克", "Puma", "Asics"],
            "base_names": [
                "{brand} Air Max 气垫跑步鞋 透气缓震",
                "{brand} Ultraboost 回弹运动休闲鞋",
                "{brand} 氢跑4.0 超轻专业竞速鞋",
                "{brand} 赤兔6 Pro 高弹耐磨训练跑鞋",
                "{brand} 574 经典复古休闲运动鞋",
                "{brand} 动力巢T20 马拉松轻便透气鞋",
                "{brand} 飞燃2 碳板竞速专业跑鞋",
                "{brand} 星云9.0 缓震舒适运动鞋",
                "{brand} 篮球鞋 实战高帮耐磨战靴",
                "{brand} 老爹鞋 复古潮流增高休闲鞋",
            ],
            "price_range": (199, 1299),
        },
        {
            "name": "连衣裙",
            "keywords": ["连衣裙", "裙子", "长裙", "短裙", "礼服", "碎花裙"],
            "brands": ["韩都衣舍", "UR", "茵曼", "ONLY", "优衣库", "ZARA", "太平鸟", "乐町", "三彩", "红袖"],
            "base_names": [
                "{brand} 2024夏季新款碎花雪纺连衣裙 显瘦中长款",
                "{brand} 法式复古收腰气质连衣裙 温柔风长裙",
                "{brand} 棉麻文艺范宽松连衣裙 森系小清新",
                "{brand} 性感V领蕾丝连衣裙 晚宴派对小礼服",
                "{brand} 运动风休闲连衣裙 减龄显瘦T恤裙",
                "{brand} 吊带连衣裙 海边度假沙滩裙",
                "{brand} 衬衫连衣裙 通勤职业气质中长裙",
                "{brand} 牛仔连衣裙 复古减龄A字短裙",
                "{brand} 针织连衣裙 秋冬修身显瘦包臀裙",
                "{brand} 旗袍连衣裙 中国风改良年轻款",
            ],
            "price_range": (59, 499),
        },
        {
            "name": "蓝牙耳机",
            "keywords": ["蓝牙耳机", "耳机", "无线耳机", "耳塞", "耳麦", "降噪耳机"],
            "brands": ["Apple", "Sony", "小米", "漫步者", "华为", "Bose", "JBL", "OPPO", "vivo", "三星"],
            "base_names": [
                "{brand} AirPods Pro 2 主动降噪无线蓝牙耳机",
                "{brand} WF-1000XM5 旗舰级降噪豆 无线耳机",
                "{brand} Buds 5 半入耳降噪蓝牙耳机 长续航",
                "{brand} LolliPods Pro 2 降噪蓝牙耳机 性价比之选",
                "{brand} FreeBuds Pro 3 星闪技术 无线耳机",
                "{brand} QuietComfort Ultra 消噪耳塞",
                "{brand} Tune 230NC TWS 真无线降噪耳机",
                "{brand} Enco X2 双重降噪蓝牙耳机",
                "{brand} TWS 3 Pro 真无线降噪耳机",
                "{brand} Galaxy Buds2 Pro 主动降噪耳机",
            ],
            "price_range": (99, 2999),
        },
        {
            "name": "手机",
            "keywords": ["手机", "智能手机", "iPhone", "安卓手机", "旗舰手机", "5G手机"],
            "brands": ["Apple", "华为", "小米", "OPPO", "vivo", "Samsung", "荣耀", "一加", "realme", "iQOO"],
            "base_names": [
                "{brand} iPhone 15 Pro Max 256GB 钛金属原色",
                "{brand} Mate 60 Pro 512GB 雅丹黑 卫星通话",
                "{brand} 14 Ultra 16GB+512GB 徕卡影像 专业旗舰",
                "{brand} Find X7 Ultra 16GB+1TB 哈苏影像系统",
                "{brand} X100 Pro 16GB+512GB 蔡司APO超级长焦",
                "{brand} Galaxy S24 Ultra 1TB 骁龙8 Gen3 旗舰",
                "{brand} Magic 6 Pro 鹰眼相机 第二代骁龙8",
                "{brand} 12 16GB+1TB 性能旗舰 游戏手机",
                "{brand} GT5 240W满级秒充 旗舰手机",
                "{brand} Neo9S Pro+ 电竞旗舰 游戏手机",
            ],
            "price_range": (1299, 15999),
        },
        {
            "name": "T恤",
            "keywords": ["T恤", "短袖", "体恤", "半袖", "文化衫", "打底衫"],
            "brands": ["优衣库", "Nike", "MUJI", "Gap", "中国李宁", "Adidas", "HM", "森马", "美特斯邦威", "凡客诚品"],
            "base_names": [
                "{brand} U系列 纯棉圆领T恤 多色可选",
                "{brand} 运动速干T恤 透气排汗 跑步健身",
                "{brand} 水洗棉T恤 基础款 舒适百搭",
                "{brand} 美式复古印花T恤 宽松oversize",
                "{brand} 国潮原创设计T恤 中国风印花 个性潮流",
                "{brand} 重磅棉T恤 230g厚实不透 基础款",
                "{brand} 联名款T恤 艺术家合作限量版",
                "{brand} 情侣装T恤 夏季新款 宽松大码",
                "{brand} 纯色打底T恤 内搭外穿 百搭神器",
                "{brand} 卡通印花T恤 可爱减龄 学生款",
            ],
            "price_range": (29, 299),
        },
        {
            "name": "双肩包",
            "keywords": ["双肩包", "背包", "书包", "旅行包", "电脑包", "登山包"],
            "brands": ["The North Face", "小米", "JanSport", "Deuter", "Lululemon", "Nike", "Adidas", "新秀丽", "瑞士军刀", "国家地理"],
            "base_names": [
                "{brand} 北面双肩包 户外旅行通勤",
                "{brand} 极简都市双肩包 15.6英寸电脑包",
                "{brand} 经典校园双肩包 学生书包",
                "{brand} 多特户外登山包 大容量旅行背包",
                "{brand} Everywhere 运动休闲双肩包",
                "{brand} 运动双肩包 大容量训练包",
                "{brand} 经典校园背包 复古潮流双肩包",
                "{brand} 商务双肩包 通勤电脑包 防水",
                "{brand} 国家地理摄影包 单反相机双肩包",
                "{brand} 大容量旅行背包 短途出差行李包",
            ],
            "price_range": (79, 1299),
        },
        {
            "name": "笔记本电脑",
            "keywords": ["笔记本电脑", "电脑", "轻薄本", "游戏本", "办公本", "手提电脑"],
            "brands": ["Apple", "联想", "华为", "戴尔", "惠普", "华硕", "微星", "雷蛇", "小米", "机械革命"],
            "base_names": [
                "{brand} MacBook Pro 16英寸 M3 Max 芯片",
                "{brand} ThinkPad X1 Carbon 2024 商务旗舰",
                "{brand} MateBook X Pro 2024 轻薄本",
                "{brand} XPS 15 9540 高性能创作本",
                "{brand} 暗影精灵9 游戏本 RTX4090",
                "{brand} 天选5 Pro 锐龙版 游戏笔记本",
                "{brand} 雷蛇灵刃16 水银 电竞游戏本",
                "{brand} RedmiBook Pro 15 2024 轻薄本",
                "{brand} 机械革命旷世16 Super 水冷游戏本",
                "{brand} 小新Pro16 2024 高性能轻薄本",
            ],
            "price_range": (3999, 39999),
        },
        {
            "name": "手表",
            "keywords": ["手表", "智能手表", "机械表", "腕表", "运动手表", "电子表"],
            "brands": ["Apple", "华为", "小米", "OPPO", "vivo", "三星", "卡西欧", "天梭", "浪琴", "劳力士"],
            "base_names": [
                "{brand} Watch Series 9 智能手表 GPS版",
                "{brand} Watch GT 4 运动智能手表 血氧监测",
                "{brand} Watch S3 智能手表 独立通话",
                "{brand} Watch X 全智能手表 旗舰运动版",
                "{brand} Watch 3 Pro 智能手表 eSIM独立通话",
                "{brand} Galaxy Watch 6 Classic 智能手表",
                "{brand} G-Shock 经典运动电子手表",
                "{brand} 力洛克系列 机械腕表 商务休闲",
                "{brand} 名匠系列 自动机械手表 瑞士进口",
                "{brand} 水鬼系列 潜航者型自动机械腕表",
            ],
            "price_range": (199, 199999),
        },
        {
            "name": "护肤品",
            "keywords": ["护肤品", "化妆品", "面霜", "精华液", "水乳套装", "洗面奶"],
            "brands": ["兰蔻", "雅诗兰黛", "SK-II", "欧莱雅", "资生堂", "珀莱雅", "百雀羚", "自然堂", "玉兰油", "海蓝之谜"],
            "base_names": [
                "{brand} 小黑瓶精华肌底液 100ml 修护维稳",
                "{brand} 小棕瓶特润修护精华液 50ml",
                "{brand} 神仙水护肤精华露 230ml 补水保湿",
                "{brand} 紫熨斗全脸眼霜 30ml 淡化细纹",
                "{brand} 红腰子精华 50ml 增强肌肤免疫力",
                "{brand} 红宝石面霜 50g 抗皱紧致",
                "{brand} 三生花水乳套装 补水保湿",
                "{brand} 凝时鲜颜肌活霜 50g 抗初老",
                "{brand} 大红瓶面霜 80g 滋润紧致",
                "{brand} 经典面霜 60ml 修护保湿",
            ],
            "price_range": (89, 3999),
        },
        {
            "name": "家电",
            "keywords": ["家电", "空调", "冰箱", "洗衣机", "电视", "微波炉"],
            "brands": ["美的", "格力", "海尔", "小米", "海信", "TCL", "创维", "西门子", "松下", "索尼"],
            "base_names": [
                "{brand} 1.5匹新一级能效变频冷暖空调挂机",
                "{brand} 3匹立式柜机空调 新一级能效",
                "{brand} 500L 对开门大容量冰箱 风冷无霜",
                "{brand} 10kg 滚筒洗衣机 洗烘一体 除菌",
                "{brand} 75英寸 4K超高清智能电视 全面屏",
                "{brand} 20L 微波炉 家用小型 智能多功能",
                "{brand} 65英寸 OLED 4K超清电视 自发光",
                "{brand} 十字对开门冰箱 550L 智能变频",
                "{brand} 波轮洗衣机 12kg 大容量 全自动",
                "{brand} 85英寸 Mini LED 巨幕电视 120Hz",
            ],
            "price_range": (599, 29999),
        },
    ]

    # 京东专属标签
    JD_TAGS = ["自营", "京东物流", "限时特惠", "满减优惠", "赠运费险", "2年质保", "次日达", "官方授权"]

    # 拼多多专属标签
    PDD_TAGS = ["百亿补贴", "品牌黑标", "万人团", "限时秒杀", "多多买菜", "极速退款", "假一赔十", "正品保障"]

    # 淘宝专属标签
    TAOBAO_TAGS = ["天猫旗舰", "88VIP", "淘金币", "限时特价", "7天无理由", "极速退款", "退货运费险", "正品保证", "全球购", "iFashion"]

    @classmethod
    def _generate_product(cls, category: dict, platform: str, index: int) -> dict[str, Any]:
        """生成单个商品"""
        brand = random.choice(category["brands"])
        base_name = random.choice(category["base_names"])
        name = base_name.format(brand=brand)

        min_p, max_p = category["price_range"]
        base_price = random.uniform(min_p, max_p)

        if platform == "jd":
            product_id = f"100{random.randint(1000000000, 9999999999)}"
            product_url = f"https://item.jd.com/{product_id}.html"
            tags = random.sample(cls.JD_TAGS, random.randint(2, 4))
            shop_type = "self_operated" if random.random() > 0.6 else "official"
        elif platform == "taobao":
            product_id = f"{random.randint(100000000000, 999999999999)}"
            product_url = f"https://item.taobao.com/item.htm?id={product_id}"
            tags = random.sample(cls.TAOBAO_TAGS, random.randint(2, 4))
            shop_type = "tmall" if random.random() > 0.5 else "taobao"
        else:
            product_id = f"{random.randint(100000000000, 999999999999)}"
            product_url = f"https://mobile.yangkeduo.com/goods.html?goods_id={product_id}"
            tags = random.sample(cls.PDD_TAGS, random.randint(2, 4))
            shop_type = "official" if random.random() > 0.5 else "third_party"

        return {
            "id": f"{platform}_{category['name']}_{index}_{random.randint(100000, 999999)}",
            "name": name,
            "price": round(base_price, 2),
            "original_price": round(base_price * random.uniform(1.1, 1.5), 2),
            "platform": platform,
            "shop_name": f"{brand}官方旗舰店",
            "shop_type": shop_type,
            "rating": round(random.uniform(4.2, 5.0), 1) if platform == "jd" else None,
            "sales_count": random.randint(100, 500000),
            "image_url": f"https://picsum.photos/seed/{platform}{category['name']}{index}/300/400",
            "product_url": product_url,
            "is_mock": True,
            "attributes": {
                "brand": brand,
                "category": category["name"],
            },
            "tags": tags,
        }

    @classmethod
    def generate_jd_products(cls, count: int = 500) -> list[dict[str, Any]]:
        """生成京东 500 条商品"""
        products = []
        category_weights = [len(cat["keywords"]) for cat in cls.CATEGORIES]
        total_weight = sum(category_weights)

        for i in range(count):
            category = random.choices(cls.CATEGORIES, weights=category_weights, k=1)[0]
            products.append(cls._generate_product(category, "jd", i))

        return products

    @classmethod
    def generate_pdd_products(cls, count: int = 500) -> list[dict[str, Any]]:
        """生成拼多多 500 条商品"""
        products = []
        category_weights = [len(cat["keywords"]) for cat in cls.CATEGORIES]
        total_weight = sum(category_weights)

        for i in range(count):
            category = random.choices(cls.CATEGORIES, weights=category_weights, k=1)[0]
            products.append(cls._generate_product(category, "pdd", i))

        return products

    @classmethod
    def generate_taobao_products(cls, count: int = 500) -> list[dict[str, Any]]:
        """生成淘宝 500 条商品"""
        products = []
        category_weights = [len(cat["keywords"]) for cat in cls.CATEGORIES]
        total_weight = sum(category_weights)

        for i in range(count):
            category = random.choices(cls.CATEGORIES, weights=category_weights, k=1)[0]
            products.append(cls._generate_product(category, "taobao", i))

        return products

    @classmethod
    def get_products_by_keywords(cls, keywords: list[str], platform: str, count: int = 20) -> list[dict[str, Any]]:
        """根据关键词获取相关商品"""
        matched_category = None

        all_text = " ".join(keywords).lower()
        for category in cls.CATEGORIES:
            for kw in category["keywords"]:
                if kw.lower() in all_text:
                    matched_category = category
                    break
            if matched_category:
                break

        if not matched_category:
            matched_category = random.choice(cls.CATEGORIES)

        results = []
        for i in range(count):
            results.append(cls._generate_product(matched_category, platform, i))

        return results

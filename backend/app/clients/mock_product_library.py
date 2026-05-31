import random
from typing import Any


class MockProductLibrary:
    """智能 Mock 商品库，根据关键词动态返回相关商品"""
    
    CATEGORIES = {
        "运动鞋": {
            "keywords": ["运动鞋", "跑步鞋", "球鞋", "跑鞋", "篮球鞋"],
            "products": [
                {"name": "Nike Air Max 270 男子气垫跑步鞋 透气缓震", "price": 599.0, "brand": "Nike", "category": "运动鞋", "image": "https://via.placeholder.com/300x400?text=Nike+Air+Max", "url": "https://mobile.yangkeduo.com/goods.html?goods_id=532145678901"},
                {"name": "Adidas Ultraboost 22 男女同款运动休闲鞋 回弹舒适", "price": 799.0, "brand": "Adidas", "category": "运动鞋", "image": "https://via.placeholder.com/300x400?text=Adidas+Ultraboost", "url": "https://item.jd.com/100123456789.html"},
                {"name": "安踏 氢跑4.0 超轻透气跑步鞋 专业竞速", "price": 399.0, "brand": "安踏", "category": "运动鞋", "image": "https://via.placeholder.com/300x400?text=Anta+Running", "url": "https://mobile.yangkeduo.com/goods.html?goods_id=532145678902"},
                {"name": "李宁 赤兔6 Pro 竞速训练跑鞋 高弹耐磨", "price": 459.0, "brand": "李宁", "category": "运动鞋", "image": "https://via.placeholder.com/300x400?text=LiNing+Chitu", "url": "https://item.jd.com/100123456790.html"},
                {"name": "New Balance 574 经典复古休闲运动鞋 百搭潮流", "price": 499.0, "brand": "New Balance", "category": "运动鞋", "image": "https://via.placeholder.com/300x400?text=NB+574", "url": "https://mobile.yangkeduo.com/goods.html?goods_id=532145678903"},
                {"name": "特步 动力巢T20 专业马拉松竞速鞋 轻便透气", "price": 299.0, "brand": "特步", "category": "运动鞋", "image": "https://via.placeholder.com/300x400?text=Xtep+Power", "url": "https://item.jd.com/100123456791.html"},
            ]
        },
        "连衣裙": {
            "keywords": ["连衣裙", "裙子", "长裙", "短裙", "礼服"],
            "products": [
                {"name": "2024夏季新款碎花雪纺连衣裙 显瘦中长款", "price": 129.0, "brand": "韩都衣舍", "category": "连衣裙", "image": "https://via.placeholder.com/300x400?text=Floral+Dress", "url": "https://mobile.yangkeduo.com/goods.html?goods_id=532145678904"},
                {"name": "法式复古收腰气质连衣裙 温柔风长裙", "price": 199.0, "brand": "UR", "category": "连衣裙", "image": "https://via.placeholder.com/300x400?text=French+Dress", "url": "https://item.jd.com/100123456792.html"},
                {"name": "棉麻文艺范宽松连衣裙 森系小清新", "price": 89.0, "brand": "茵曼", "category": "连衣裙", "image": "https://via.placeholder.com/300x400?text=Cotton+Linen+Dress", "url": "https://mobile.yangkeduo.com/goods.html?goods_id=532145678905"},
                {"name": "性感V领蕾丝连衣裙 晚宴派对小礼服", "price": 259.0, "brand": "ONLY", "category": "连衣裙", "image": "https://via.placeholder.com/300x400?text=Lace+Dress", "url": "https://item.jd.com/100123456793.html"},
                {"name": "运动风休闲连衣裙 减龄显瘦T恤裙", "price": 79.0, "brand": "优衣库", "category": "连衣裙", "image": "https://via.placeholder.com/300x400?text=Sport+Dress", "url": "https://mobile.yangkeduo.com/goods.html?goods_id=532145678906"},
            ]
        },
        "蓝牙耳机": {
            "keywords": ["蓝牙耳机", "耳机", "无线耳机", "耳塞", "耳麦"],
            "products": [
                {"name": "Apple AirPods Pro 2 主动降噪无线蓝牙耳机", "price": 1599.0, "brand": "Apple", "category": "蓝牙耳机", "image": "https://via.placeholder.com/300x400?text=AirPods+Pro+2", "url": "https://mobile.yangkeduo.com/goods.html?goods_id=532145678907"},
                {"name": "Sony WF-1000XM5 旗舰级降噪豆 无线耳机", "price": 1999.0, "brand": "Sony", "category": "蓝牙耳机", "image": "https://via.placeholder.com/300x400?text=Sony+WF1000XM5", "url": "https://item.jd.com/100123456794.html"},
                {"name": "小米 Buds 5 半入耳降噪蓝牙耳机 长续航", "price": 299.0, "brand": "小米", "category": "蓝牙耳机", "image": "https://via.placeholder.com/300x400?text=Xiaomi+Buds+5", "url": "https://mobile.yangkeduo.com/goods.html?goods_id=532145678908"},
                {"name": "漫步者 LolliPods Pro 2 降噪蓝牙耳机 性价比之选", "price": 199.0, "brand": "漫步者", "category": "蓝牙耳机", "image": "https://via.placeholder.com/300x400?text=Edifier+LolliPods", "url": "https://item.jd.com/100123456795.html"},
                {"name": "华为 FreeBuds Pro 3 星闪技术 无线耳机", "price": 999.0, "brand": "华为", "category": "蓝牙耳机", "image": "https://via.placeholder.com/300x400?text=Huawei+FreeBuds", "url": "https://mobile.yangkeduo.com/goods.html?goods_id=532145678909"},
            ]
        },
        "手机": {
            "keywords": ["手机", "智能手机", "iPhone", "安卓手机", "旗舰手机"],
            "products": [
                {"name": "Apple iPhone 15 Pro Max 256GB 钛金属原色", "price": 9999.0, "brand": "Apple", "category": "手机", "image": "https://via.placeholder.com/300x400?text=iPhone+15+Pro+Max", "url": "https://mobile.yangkeduo.com/goods.html?goods_id=532145678910"},
                {"name": "华为 Mate 60 Pro 512GB 雅丹黑 卫星通话", "price": 6999.0, "brand": "华为", "category": "手机", "image": "https://via.placeholder.com/300x400?text=Huawei+Mate+60+Pro", "url": "https://item.jd.com/100123456796.html"},
                {"name": "小米14 Ultra 16GB+512GB 徕卡影像 专业旗舰", "price": 6499.0, "brand": "小米", "category": "手机", "image": "https://via.placeholder.com/300x400?text=Xiaomi+14+Ultra", "url": "https://mobile.yangkeduo.com/goods.html?goods_id=532145678911"},
                {"name": "OPPO Find X7 Ultra 16GB+1TB 哈苏影像系统", "price": 5999.0, "brand": "OPPO", "category": "手机", "image": "https://via.placeholder.com/300x400?text=OPPO+Find+X7", "url": "https://item.jd.com/100123456797.html"},
                {"name": "vivo X100 Pro 16GB+512GB 蔡司APO超级长焦", "price": 5299.0, "brand": "vivo", "category": "手机", "image": "https://via.placeholder.com/300x400?text=vivo+X100+Pro", "url": "https://mobile.yangkeduo.com/goods.html?goods_id=532145678912"},
            ]
        },
        "T恤": {
            "keywords": ["T恤", "短袖", "体恤", "半袖", "文化衫"],
            "products": [
                {"name": "优衣库 U系列 纯棉圆领T恤 多色可选", "price": 79.0, "brand": "优衣库", "category": "T恤", "image": "https://via.placeholder.com/300x400?text=Uniqlo+Tshirt", "url": "https://mobile.yangkeduo.com/goods.html?goods_id=532145678913"},
                {"name": "Nike 运动速干T恤 透气排汗 跑步健身", "price": 149.0, "brand": "Nike", "category": "T恤", "image": "https://via.placeholder.com/300x400?text=Nike+DriFit", "url": "https://item.jd.com/100123456798.html"},
                {"name": "无印良品 水洗棉T恤 基础款 舒适百搭", "price": 59.0, "brand": "MUJI", "category": "T恤", "image": "https://via.placeholder.com/300x400?text=MUJI+Tshirt", "url": "https://mobile.yangkeduo.com/goods.html?goods_id=532145678914"},
                {"name": "Gap 美式复古印花T恤 宽松oversize", "price": 99.0, "brand": "Gap", "category": "T恤", "image": "https://via.placeholder.com/300x400?text=Gap+Vintage", "url": "https://item.jd.com/100123456799.html"},
                {"name": "国潮原创设计T恤 中国风印花 个性潮流", "price": 129.0, "brand": "中国李宁", "category": "T恤", "image": "https://via.placeholder.com/300x400?text=China+Style+Tshirt", "url": "https://mobile.yangkeduo.com/goods.html?goods_id=532145678915"},
            ]
        },
        "双肩包": {
            "keywords": ["双肩包", "背包", "书包", "旅行包", "电脑包"],
            "products": [
                {"name": "The North Face 北面双肩包 户外旅行通勤", "price": 399.0, "brand": "The North Face", "category": "双肩包", "image": "https://via.placeholder.com/300x400?text=NorthFace+Backpack", "url": "https://mobile.yangkeduo.com/goods.html?goods_id=532145678916"},
                {"name": "小米 极简都市双肩包 15.6英寸电脑包", "price": 99.0, "brand": "小米", "category": "双肩包", "image": "https://via.placeholder.com/300x400?text=Xiaomi+Backpack", "url": "https://item.jd.com/100123456800.html"},
                {"name": "JanSport 经典校园双肩包 学生书包", "price": 259.0, "brand": "JanSport", "category": "双肩包", "image": "https://via.placeholder.com/300x400?text=JanSport+Backpack", "url": "https://mobile.yangkeduo.com/goods.html?goods_id=532145678917"},
                {"name": "Deuter 多特户外登山包 大容量旅行背包", "price": 599.0, "brand": "Deuter", "category": "双肩包", "image": "https://via.placeholder.com/300x400?text=Deuter+Outdoor", "url": "https://item.jd.com/100123456801.html"},
                {"name": "Lululemon Everywhere 运动休闲双肩包", "price": 459.0, "brand": "Lululemon", "category": "双肩包", "image": "https://via.placeholder.com/300x400?text=Lululemon+Backpack", "url": "https://mobile.yangkeduo.com/goods.html?goods_id=532145678918"},
            ]
        },
        "默认": {
            "keywords": [],
            "products": [
                {"name": "精选好物 高品质商品 限时特惠", "price": 99.0, "brand": "精选", "category": "商品", "image": "https://via.placeholder.com/300x400?text=Hot+Product+1", "url": "https://mobile.yangkeduo.com/goods.html?goods_id=532145678990"},
                {"name": "热销爆款 全网比价 超值推荐", "price": 199.0, "brand": "热销", "category": "商品", "image": "https://via.placeholder.com/300x400?text=Hot+Product+2", "url": "https://item.jd.com/100123456890.html"},
                {"name": "品质生活 精选好物 限时折扣", "price": 299.0, "brand": "品质", "category": "商品", "image": "https://via.placeholder.com/300x400?text=Hot+Product+3", "url": "https://mobile.yangkeduo.com/goods.html?goods_id=532145678991"},
                {"name": "人气爆款 万人好评 放心选购", "price": 59.0, "brand": "人气", "category": "商品", "image": "https://via.placeholder.com/300x400?text=Hot+Product+4", "url": "https://item.jd.com/100123456891.html"},
                {"name": "新品上市 首发特惠 抢先体验", "price": 159.0, "brand": "新品", "category": "商品", "image": "https://via.placeholder.com/300x400?text=Hot+Product+5", "url": "https://mobile.yangkeduo.com/goods.html?goods_id=532145678992"},
            ]
        }
    }

    @classmethod
    def get_products(cls, keywords: list[str], platform: str = "pdd", count: int = 20) -> list[dict[str, Any]]:
        """根据关键词获取相关商品"""
        matched_category = "默认"
        
        # 匹配最相关的分类
        all_text = " ".join(keywords).lower()
        for category_name, category_data in cls.CATEGORIES.items():
            if category_name == "默认":
                continue
            for kw in category_data["keywords"]:
                if kw.lower() in all_text:
                    matched_category = category_name
                    break
            if matched_category != "默认":
                break
        
        # 获取该分类的商品
        base_products = cls.CATEGORIES[matched_category]["products"]
        results = []
        
        # 生成足够数量的商品（通过随机变体）
        for i in range(count):
            base_p = base_products[i % len(base_products)]
            variant = {
                "id": f"{platform}_{matched_category}_{i}_{random.randint(10000, 99999)}",
                "name": base_p["name"],
                "price": round(base_p["price"] * (0.8 + random.random() * 0.6), 2),
                "original_price": round(base_p["price"] * 1.2, 2),
                "platform": platform,
                "shop_name": f"{base_p['brand']}官方旗舰店",
                "shop_type": "official" if random.random() > 0.5 else "third_party",
                "rating": round(4.0 + random.random(), 1) if platform != "pdd" else None,
                "sales_count": random.randint(100, 50000),
                "image_url": base_p["image"],
                "product_url": base_p["url"],
                "attributes": {
                    "brand": base_p["brand"],
                    "category": base_p["category"],
                },
                "tags": ["有优惠券", "百亿补贴"] if platform == "pdd" else ["自营", "限时特惠"],
            }
            results.append(variant)
        
        # 打乱顺序
        random.shuffle(results)
        return results[:count]

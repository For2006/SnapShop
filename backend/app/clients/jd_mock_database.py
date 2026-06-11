import random

from dataclasses import asdict, dataclass
from enum import Enum
from typing import Any


class JDCategory(Enum):
    SPORTS_SHOES = "运动鞋"
    DRESS = "连衣裙"
    BLUETOOTH_HEADPHONES = "蓝牙耳机"
    MOBILE_PHONE = "手机"
    T_SHIRT = "T恤"
    BACKPACK = "双肩包"
    LAPTOP = "笔记本电脑"
    WATCH = "手表"
    SKINCARE = "护肤品"
    HOME_APPLIANCES = "家电"


class JDTag(Enum):
    SELF_OPERATED = "京东自营"
    JD_LOGISTICS = "京东物流"
    QUALITY_GUARANTEE = "品质保障"
    NEW_ARRIVAL = "新品上市"
    HOT_SALE = "热销爆款"
    LIMITED_OFFER = "限时特惠"
    OFFICIAL_STORE = "官方旗舰店"
    H24_HOURS_DELIVERY = "24小时达"
    AFTER_SALE_GUARANTEE = "售后无忧"
    JD_PLUS = "PLUS会员"


@dataclass
class JDProduct:
    item_id: str
    title: str
    category: str
    sub_category: str
    price: float
    original_price: float
    sales_count: int
    shop_name: str
    shop_type: str
    product_url: str
    image_url: str
    tags: list[str]
    rating: float
    review_count: int
    brand: str
    coupon_amount: float
    is_self_operated: bool
    is_jd_logistics: bool
    is_mock: bool = True


class JDMockDatabase:
    def __init__(self):
        self.products: dict[str, JDProduct] = {}
        self._initialize_database()

    def _generate_product_titles(self) -> dict[str, list[str]]:
        return {
            JDCategory.SPORTS_SHOES.value: [
                "Nike Air Max 270 男子气垫跑步鞋", "Adidas Ultraboost 22 男女运动跑鞋",
                "李宁赤兔6 Pro 专业竞速跑步鞋", "安踏KT7 汤普森篮球鞋",
                "New Balance 574 复古休闲运动鞋", "Jordan Air Jordan 1 高帮篮球鞋",
                "特步动力巢 缓震跑步鞋", "361°飞燃 碳板竞速跑鞋",
                "Puma Suede Classic 复古休闲鞋", "Asics Gel-Kayano 30 支撑跑鞋",
                "Skechers Go Walk 舒适健步鞋", "Mizuno Wave Rider 26 慢跑鞋",
                "Under Armour HOVR 芯片跑步鞋", "Vans Old Skool 经典板鞋",
                "Converse Chuck Taylor All Star 帆布鞋"
            ],
            JDCategory.DRESS.value: [
                "2024夏季新款雪纺连衣裙女士", "韩版修身显瘦碎花中长裙",
                "优雅气质真丝连衣裙高端", "法式复古方领泡泡袖连衣裙",
                "波西米亚风海边度假沙滩裙", "通勤职业西装领连衣裙",
                "甜美可爱洛丽塔公主裙", "轻奢刺绣晚礼服宴会裙",
                "棉麻文艺森系连衣裙", "针织收腰显瘦包臀连衣裙",
                "A字大摆显瘦连衣裙", "吊带露背性感连衣裙",
                "旗袍改良版中国风连衣裙", "牛仔连衣裙减龄少女款",
                "运动休闲卫衣连衣裙"
            ],
            JDCategory.BLUETOOTH_HEADPHONES.value: [
                "Apple AirPods Pro 2 主动降噪耳机", "Sony WH-1000XM5 头戴式降噪耳机",
                "Bose QuietComfort 45 无线消噪耳机", "华为FreeBuds Pro 3 蓝牙耳机",
                "小米Buds 4 Pro 真无线降噪耳机", "漫步者NeoBuds Pro 圈铁耳机",
                "JBL Tune 760NC 头戴式蓝牙耳机", "Beats Studio Pro 无线耳机",
                "三星Galaxy Buds2 Pro 耳机", "OPPO Enco X2 丹拿联合调音耳机",
                "vivo TWS 3 Pro 真无线耳机", "荣耀Earbuds 3 Pro 测温耳机",
                "Skullcandy Crusher ANC 重低音耳机", "Sennheiser Momentum 4 耳机",
                "铁三角ATH-M50xBT2 专业监听耳机"
            ],
            JDCategory.MOBILE_PHONE.value: [
                "iPhone 15 Pro Max 256GB 钛金属", "华为Mate 60 Pro 5G手机",
                "小米14 Ultra 徕卡影像旗舰", "OPPO Find X7 Ultra 双潜望手机",
                "vivo X100 Pro 蔡司影像手机", "三星Galaxy S24 Ultra AI手机",
                "一加12 哈苏影像手机", "荣耀Magic6 Pro 鹰眼相机",
                "Redmi K70 Pro 骁龙8Gen3手机", "realme GT5 240W快充手机",
                "iQOO 12 Pro 电竞游戏手机", "魅族21 骁龙8Gen3手机",
                "努比亚Z60 Ultra 屏下摄像手机", "摩托罗拉X50 Ultra 折叠屏",
                "索尼Xperia 1 V 4K HDR手机"
            ],
            JDCategory.T_SHIRT.value: [
                "优衣库纯棉圆领短袖T恤", "Nike运动速干透气T恤",
                "Adidas三叶草经典logoT恤", "李宁国潮印花短袖T恤",
                "Gap重磅棉宽松T恤", "H&M基础款纯色T恤",
                "ZARA时尚设计感T恤", "无印良品新疆棉T恤",
                "Champion经典刺绣T恤", "Supreme街头潮流T恤",
                "Stussy世界巡游印花T恤", "Bape猿人头迷彩T恤",
                "北面户外速干T恤", "哥伦比亚防晒速干T恤",
                "Levi's牛仔印花T恤"
            ],
            JDCategory.BACKPACK.value: [
                "Nike Elite Pro 篮球双肩包", "Adidas Originals 三叶草背包",
                "The North Face 北面户外登山包", "JanSport经典校园双肩包",
                "Herschel Supply 休闲背包", "Doughnut Macaroon 甜甜圈背包",
                "TUMI Alpha 3 商务通勤背包", "Samsonite新秀丽电脑背包",
                "小米极简都市双肩包", "华为原装智能背包",
                "Lululemon运动健身背包", "Under Armour安德玛运动包",
                "Deuter多特户外徒步背包", "Osprey小鹰登山背包",
                "Fjallraven北极狐Kanken背包"
            ],
            JDCategory.LAPTOP.value: [
                "Apple MacBook Pro 16英寸 M3 Max", "华为MateBook X Pro 2024款",
                "联想ThinkPad X1 Carbon 商务本", "戴尔XPS 15 9540 轻薄本",
                "华硕ROG幻16 游戏本", "微星雷影17 满血游戏本",
                "惠普暗影精灵10 游戏笔记本", "拯救者Y9000P 2024款",
                "MacBook Air M3 15英寸轻薄本", "LG Gram 17 超轻薄笔记本",
                "雷蛇灵刃16 电竞游戏本", "技嘉AORUS 17X 旗舰游戏本",
                "宏碁非凡Go 青春轻薄本", "荣耀MagicBook Pro 16",
                "小米Redmi G 游戏本"
            ],
            JDCategory.WATCH.value: [
                "Apple Watch Series 9 智能手表", "华为Watch GT 4 运动手表",
                "小米Watch S3 eSIM版", "OPPO Watch 4 Pro 全智能手表",
                "三星Galaxy Watch 6 Classic", "Garmin佳明Forerunner 965",
                "Tissot天梭力洛克机械表", "Casio卡西欧G-Shock手表",
                "Rolex劳力士水鬼潜航者", "Omega欧米茄海马系列",
                "Longines浪琴名匠系列", "Swatch斯沃琪瑞士腕表",
                "Seiko精工5号机械表", "Citizen西铁城光动能表",
                "TAG Heuer泰格豪雅竞潜"
            ],
            JDCategory.SKINCARE.value: [
                "SK-II神仙水精华液230ml", "兰蔻小黑瓶肌底精华100ml",
                "雅诗兰黛小棕瓶眼霜15ml", "资生堂红腰子精华50ml",
                "欧莱雅紫熨斗眼霜", "珀莱雅双抗精华液",
                "薇诺娜特护霜敏感肌", "修丽可色修精华",
                "海蓝之谜经典面霜60ml", "娇兰帝皇蜂姿复原蜜",
                "香奈儿山茶花保湿乳", "迪奥花蜜活颜丝悦系列",
                "雅顿金胶精华胶囊", "科颜氏高保湿面霜",
                "倩碧黄油无油版"
            ],
            JDCategory.HOME_APPLIANCES.value: [
                "海尔500L对开门冰箱", "美的10kg滚筒洗衣机",
                "格力3匹立式空调柜机", "戴森V15无线吸尘器",
                "科沃斯T20 PRO扫地机器人", "小米空气净化器4 Pro H",
                "西门子嵌入式洗碗机", "方太抽油烟机燃气灶套装",
                "老板电器大吸力油烟机", "九阳破壁机家用多功能",
                "苏泊尔电饭煲4L球釜", "美的微波炉智能变频",
                "飞利浦电动牙刷钻石9系", "松下智能马桶盖",
                "索尼75英寸4K智能电视"
            ]
        }

    def _generate_shop_names(self) -> list[str]:
        return [
            "京东自营官方旗舰店", "品牌官方旗舰店", "京东家电专卖店",
            "京东运动户外店", "京东数码专营店", "京东美妆馆",
            "京东服饰内衣店", "京东手机通讯店", "京东电脑办公店",
            "京东家居日用店", "京东超市自营", "京东国际自营",
            "品牌授权专卖店", "京东品质生活馆", "京东新品首发店"
        ]

    def _generate_brands(self) -> dict[str, list[str]]:
        return {
            JDCategory.SPORTS_SHOES.value: ["Nike", "Adidas", "李宁", "安踏", "New Balance", "Jordan", "特步", "361°", "Puma", "Asics"],
            JDCategory.DRESS.value: ["优衣库", "ZARA", "H&M", "ONLY", "VERO MODA", "欧时力", "太平鸟", "乐町", "伊芙丽", "诗凡黎"],
            JDCategory.BLUETOOTH_HEADPHONES.value: ["Apple", "Sony", "Bose", "华为", "小米", "漫步者", "JBL", "Beats", "三星", "OPPO"],
            JDCategory.MOBILE_PHONE.value: ["Apple", "华为", "小米", "OPPO", "vivo", "三星", "一加", "荣耀", "Redmi", "realme"],
            JDCategory.T_SHIRT.value: ["优衣库", "Nike", "Adidas", "李宁", "Gap", "Champion", "北面", "哥伦比亚", "Levi's", "无印良品"],
            JDCategory.BACKPACK.value: ["Nike", "Adidas", "北面", "TUMI", "新秀丽", "小米", "Herschel", "Fjallraven", "Osprey", "Deuter"],
            JDCategory.LAPTOP.value: ["Apple", "华为", "联想", "戴尔", "华硕", "惠普", "拯救者", "LG", "雷蛇", "小米"],
            JDCategory.WATCH.value: ["Apple", "华为", "小米", "Garmin", "Tissot", "Casio", "Rolex", "Omega", "Longines", "Swatch"],
            JDCategory.SKINCARE.value: ["SK-II", "兰蔻", "雅诗兰黛", "资生堂", "欧莱雅", "珀莱雅", "薇诺娜", "修丽可", "海蓝之谜", "科颜氏"],
            JDCategory.HOME_APPLIANCES.value: ["海尔", "美的", "格力", "戴森", "科沃斯", "小米", "西门子", "方太", "老板", "索尼"]
        }

    def _initialize_database(self):
        titles_by_category = self._generate_product_titles()
        shop_names = self._generate_shop_names()
        brands_by_category = self._generate_brands()

        total_products = 500
        products_per_category = total_products // 10
        item_id_start = 100000000000

        for category_enum in JDCategory:
            category = category_enum.value
            titles = titles_by_category.get(category, [])
            brands = brands_by_category.get(category, [])

            for i in range(products_per_category):
                item_id = str(item_id_start)
                item_id_start += 1

                title_template = random.choice(titles)
                brand = random.choice(brands) if brands else "知名品牌"
                title = f"{brand} {title_template}"

                is_self_operated = random.random() < 0.6
                is_jd_logistics = random.random() < 0.75

                base_price_ranges = {
                    JDCategory.SPORTS_SHOES.value: (200, 1500),
                    JDCategory.DRESS.value: (100, 800),
                    JDCategory.BLUETOOTH_HEADPHONES.value: (200, 3000),
                    JDCategory.MOBILE_PHONE.value: (2000, 15000),
                    JDCategory.T_SHIRT.value: (50, 300),
                    JDCategory.BACKPACK.value: (100, 2000),
                    JDCategory.LAPTOP.value: (4000, 30000),
                    JDCategory.WATCH.value: (500, 100000),
                    JDCategory.SKINCARE.value: (200, 5000),
                    JDCategory.HOME_APPLIANCES.value: (500, 20000)
                }

                min_p, max_p = base_price_ranges.get(category, (100, 1000))
                original_price = round(random.uniform(min_p, max_p), 2)
                discount = random.uniform(0.7, 1.0)
                price = round(original_price * discount, 2)

                sales_count = random.randint(100, 50000)
                review_count = random.randint(50, sales_count)
                rating = round(random.uniform(4.2, 5.0), 1)

                shop_name = random.choice(shop_names)
                shop_type = "self_operated" if is_self_operated else "third_party"

                product_url = f"https://item.jd.com/{item_id}.html"
                image_url = f"https://img14.360buyimg.com/n1/jfs/t1/{random.randint(1, 99999)}/{random.randint(1, 99999)}/{random.randint(100, 999)}/{random.randint(100, 999)}/{item_id}.jpg"

                tags = []
                if is_self_operated:
                    tags.append(JDTag.SELF_OPERATED.value)
                if is_jd_logistics:
                    tags.append(JDTag.JD_LOGISTICS.value)
                if random.random() < 0.3:
                    tags.append(JDTag.HOT_SALE.value)
                if random.random() < 0.25:
                    tags.append(JDTag.NEW_ARRIVAL.value)
                if random.random() < 0.2:
                    tags.append(JDTag.LIMITED_OFFER.value)
                if random.random() < 0.15:
                    tags.append(JDTag.JD_PLUS.value)
                if random.random() < 0.3:
                    tags.append(JDTag.QUALITY_GUARANTEE.value)

                coupon_amount = round(random.uniform(0, 200), 2) if random.random() < 0.6 else 0.0

                product = JDProduct(
                    item_id=item_id,
                    title=title,
                    category=category,
                    sub_category=category,
                    price=price,
                    original_price=original_price,
                    sales_count=sales_count,
                    shop_name=shop_name,
                    shop_type=shop_type,
                    product_url=product_url,
                    image_url=image_url,
                    tags=tags,
                    rating=rating,
                    review_count=review_count,
                    brand=brand,
                    coupon_amount=coupon_amount,
                    is_self_operated=is_self_operated,
                    is_jd_logistics=is_jd_logistics
                )

                self.products[item_id] = product

    def search_by_keywords(self, keywords: list[str], limit: int = 20) -> list[dict[str, Any]]:
        results = []
        all_products = list(self.products.values())

        for product in all_products:
            search_text = f"{product.title} {product.category} {product.brand}"
            matched = any(kw.lower() in search_text.lower() for kw in keywords)
            if matched:
                results.append(asdict(product))

        results.sort(key=lambda x: (x["sales_count"], x["rating"]), reverse=True)
        return results[:limit]

    def get_all_products(self) -> list[dict[str, Any]]:
        return [asdict(p) for p in self.products.values()]

    def get_product_by_id(self, item_id: str) -> dict[str, Any] | None:
        product = self.products.get(item_id)
        return asdict(product) if product else None

    def get_products_by_category(self, category: str, limit: int = 100) -> list[dict[str, Any]]:
        results = [asdict(p) for p in self.products.values() if p.category == category]
        return results[:limit]

    def get_statistics(self) -> dict[str, Any]:
        category_counts = {}
        for p in self.products.values():
            cat = p.category
            category_counts[cat] = category_counts.get(cat, 0) + 1

        self_operated_count = sum(1 for p in self.products.values() if p.is_self_operated)
        jd_logistics_count = sum(1 for p in self.products.values() if p.is_jd_logistics)

        return {
            "total_products": len(self.products),
            "category_distribution": category_counts,
            "self_operated_count": self_operated_count,
            "jd_logistics_count": jd_logistics_count
        }

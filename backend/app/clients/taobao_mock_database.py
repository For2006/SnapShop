import random
import uuid
from typing import List, Dict, Any
from dataclasses import dataclass, asdict
from enum import Enum


class TaobaoCategory(Enum):
    FASHION = "时尚服饰"
    ELECTRONICS = "数码家电"
    HOME_LIVING = "家居生活"
    BEAUTY = "美妆个护"
    FOOD = "食品生鲜"
    SPORTS = "运动户外"
    MOTHER_BABY = "母婴用品"
    TOYS = "玩具乐器"
    OFFICE = "办公文具"
    PETS = "宠物用品"


class TaobaoTag(Enum):
    LIVE_STREAM = "淘宝直播"
    VIP_88 = "88VIP"
    TAO_COIN = "淘金币"
    FREE_SHIPPING = "包邮"
    SEVEN_DAY_RETURN = "7天无理由"
    TIANMAO = "天猫正品"
    NEW_ARRIVAL = "新品上市"
    HOT_SALE = "热销爆款"
    LIMITED_OFFER = "限时特惠"
    OFFICIAL_STORE = "官方旗舰店"


@dataclass
class TaobaoProduct:
    item_id: str
    title: str
    category: str
    sub_category: str
    price: float
    original_price: float
    sales_count: int
    shop_name: str
    shop_level: str
    product_url: str
    image_url: str
    tags: List[str]
    rating: float
    review_count: int
    coupon_amount: float
    commission_rate: float
    is_tianmao: bool
    is_hot: bool


class TaobaoMockDatabase:
    def __init__(self):
        self.products: Dict[str, TaobaoProduct] = {}
        self._initialize_database()

    def _generate_product_titles(self) -> Dict[str, List[str]]:
        return {
            TaobaoCategory.FASHION.value: [
                "2024新款夏季纯棉短袖T恤男士", "韩版修身显瘦连衣裙女装", "潮流运动休闲鞋老爹鞋",
                "轻薄透气防晒衣男女同款", "时尚牛仔外套夹克上衣", "百搭阔腿裤垂感长裤",
                "优雅气质真丝衬衫女士", "保暖加绒毛衣针织衫", "高端商务正装皮鞋",
                "时尚双肩包旅行背包"
            ],
            TaobaoCategory.ELECTRONICS.value: [
                "2024最新款智能手机旗舰版", "高清4K智能液晶电视", "无线蓝牙耳机降噪Pro",
                "超薄笔记本电脑轻薄款", "大容量移动电源快充", "智能手表运动健康监测",
                "家用空气净化器除甲醛", "全自动智能扫地机器人", "便携蓝牙音箱低音炮",
                "机械键盘电竞游戏专用"
            ],
            TaobaoCategory.HOME_LIVING.value: [
                "北欧风简约实木餐桌", "记忆棉护颈枕头枕芯", "全棉四件套床上用品",
                "智能恒温电热水壶", "大容量冰箱家用节能", "滚筒全自动洗衣机",
                "创意LED护眼台灯", "多功能厨房料理机", "防滑浴室地垫吸水",
                "轻奢风客厅装饰画"
            ],
            TaobaoCategory.BEAUTY.value: [
                "大牌正品口红持久不脱色", "深层补水保湿面膜套装", "美白精华液淡斑提亮",
                "氨基酸温和洗面奶洁面乳", "防晒喷雾SPF50+防水", "气垫BB霜遮瑕持久",
                "香水女士持久淡香", "男士护肤套装控油", "电动牙刷声波震动",
                "美容仪脸部按摩导入"
            ],
            TaobaoCategory.FOOD.value: [
                "进口零食大礼包组合装", "新鲜水果当季整箱包邮", "正宗四川麻辣火锅底料",
                "手工曲奇饼干礼盒装", "有机纯牛奶整箱24盒", "即食燕窝滋补营养品",
                "咖啡豆新鲜烘焙现磨", "网红奶茶粉袋装速溶", "东北大米10斤装五常",
                "香辣牛肉干特产零食"
            ],
            TaobaoCategory.SPORTS.value: [
                "专业跑步鞋减震透气", "瑜伽垫加厚防滑健身垫", "动感单车家用静音款",
                "羽毛球拍正品全碳素", "游泳衣女款显瘦连体", "登山包户外旅行大容量",
                "篮球标准7号耐磨", "运动手环心率监测", "哑铃男士健身器材",
                "滑板初学者专业双翘"
            ],
            TaobaoCategory.MOTHER_BABY.value: [
                "新生儿纯棉婴儿衣服套装", "进口奶粉婴幼儿配方", "宝宝安全座椅汽车用",
                "婴儿推车轻便折叠可坐躺", "纸尿裤超薄透气尿不湿", "儿童益智早教玩具",
                "孕妇护肤品专用套装", "奶瓶消毒器带烘干", "婴儿辅食机多功能",
                "宝宝学步鞋软底防滑"
            ],
            TaobaoCategory.TOYS.value: [
                "乐高积木拼装益智玩具", "遥控汽车高速漂移赛车", "芭比娃娃套装大礼盒",
                "无人机航拍高清专业", "拼图1000片成人减压", "魔方三阶顺滑比赛专用",
                "儿童电子琴多功能玩具", "手办模型动漫周边", "泡泡机全自动网红款",
                "桌游卡牌多人聚会游戏"
            ],
            TaobaoCategory.OFFICE.value: [
                "A4打印纸整箱500张", "人体工学办公椅护腰", "中性笔黑色签字笔12支",
                "文件资料袋透明档案袋", "桌面收纳盒文具整理", "订书机重型加厚省力",
                "笔记本子商务记事本", "标签打印机便携式", "白板支架式家用教学",
                "U盘64G高速正品"
            ],
            TaobaoCategory.PETS.value: [
                "猫粮成猫幼猫全价粮", "狗狗零食磨牙棒骨头", "猫砂豆腐砂除臭无尘",
                "宠物自动喂食器定时", "猫窝四季通用可拆洗", "狗狗牵引绳胸背带",
                "宠物沐浴露杀菌除臭", "猫爬架大型猫树一体", "宠物玩具逗猫棒套装",
                "航空箱宠物外出便携"
            ]
        }

    def _generate_sub_categories(self) -> Dict[str, List[str]]:
        return {
            TaobaoCategory.FASHION.value: ["男装", "女装", "鞋靴", "箱包", "配饰"],
            TaobaoCategory.ELECTRONICS.value: ["手机", "电脑", "耳机", "家电", "数码配件"],
            TaobaoCategory.HOME_LIVING.value: ["家具", "家纺", "厨具", "日用品", "装饰"],
            TaobaoCategory.BEAUTY.value: ["护肤", "彩妆", "香水", "个护", "美容仪器"],
            TaobaoCategory.FOOD.value: ["零食", "生鲜", "粮油", "饮料", "滋补"],
            TaobaoCategory.SPORTS.value: ["运动鞋服", "健身器材", "户外装备", "球类运动", "游泳用品"],
            TaobaoCategory.MOTHER_BABY.value: ["婴儿服饰", "奶粉辅食", "孕妈用品", "童车童床", "安全座椅"],
            TaobaoCategory.TOYS.value: ["积木", "遥控玩具", "娃娃", "模型", "益智玩具"],
            TaobaoCategory.OFFICE.value: ["办公纸品", "办公文具", "办公设备", "收纳用品", "桌面用品"],
            TaobaoCategory.PETS.value: ["主粮", "零食", "猫砂", "宠物用品", "宠物玩具"]
        }

    def _generate_shop_names(self) -> List[str]:
        return [
            "天猫官方旗舰店", "淘宝精选店铺", "品牌直营专卖店", "全球购海外店",
            "工厂直销批发店", "网红直播带货店", "88VIP专属店", "品质生活生活馆",
            "时尚潮流先锋店", "数码科技体验店", "家居好物优选店", "美妆护肤专柜",
            "美食特产专营店", "运动户外装备店", "母婴用品母婴坊", "玩具总动员乐园",
            "办公文具一站式", "萌宠之家宠物店", "时尚穿搭工作室", "数码家电大卖场"
        ]

    def _generate_shop_levels(self) -> List[str]:
        return ["红心1钻", "蓝冠3冠", "金冠5冠", "天猫旗舰店", "天猫超市", "企业店铺"]

    def _initialize_database(self):
        product_titles = self._generate_product_titles()
        sub_categories = self._generate_sub_categories()
        shop_names = self._generate_shop_names()
        shop_levels = self._generate_shop_levels()
        all_tags = [tag.value for tag in TaobaoTag]

        product_id_counter = 100000000000

        for category in TaobaoCategory:
            category_name = category.value
            titles = product_titles[category_name]
            subs = sub_categories[category_name]

            for i in range(50):
                product_id_counter += 1
                item_id = str(product_id_counter)

                title = random.choice(titles)
                sub_category = random.choice(subs)

                base_price = random.uniform(19.9, 2999.9)
                price = round(base_price, 2)
                original_price = round(price * random.uniform(1.2, 2.0), 2)

                sales_count = random.randint(10, 99999)
                shop_name = random.choice(shop_names)
                shop_level = random.choice(shop_levels)

                product_url = f"https://item.taobao.com/item.htm?id={item_id}"
                image_url = f"https://img.alicdn.com/imgextra/i{random.randint(1,10)}/{uuid.uuid4().hex.upper()}_O1.jpg"

                num_tags = random.randint(2, 6)
                tags = random.sample(all_tags, num_tags)

                rating = round(random.uniform(4.0, 5.0), 1)
                review_count = random.randint(50, 50000)

                coupon_amount = round(random.uniform(0, 100), 2) if random.random() > 0.3 else 0.0
                commission_rate = round(random.uniform(1, 50), 1)

                is_tianmao = random.random() > 0.5
                is_hot = sales_count > 5000

                product = TaobaoProduct(
                    item_id=item_id,
                    title=title,
                    category=category_name,
                    sub_category=sub_category,
                    price=price,
                    original_price=original_price,
                    sales_count=sales_count,
                    shop_name=shop_name,
                    shop_level=shop_level,
                    product_url=product_url,
                    image_url=image_url,
                    tags=tags,
                    rating=rating,
                    review_count=review_count,
                    coupon_amount=coupon_amount,
                    commission_rate=commission_rate,
                    is_tianmao=is_tianmao,
                    is_hot=is_hot
                )

                self.products[item_id] = product

    def get_all_products(self) -> List[Dict[str, Any]]:
        return [asdict(product) for product in self.products.values()]

    def get_product_by_id(self, item_id: str) -> Dict[str, Any]:
        product = self.products.get(item_id)
        return asdict(product) if product else None

    def search_products(self, keyword: str = "", category: str = "", 
                       min_price: float = 0, max_price: float = 99999,
                       page: int = 1, page_size: int = 20) -> Dict[str, Any]:
        results = []
        keyword_lower = keyword.lower()

        for product in self.products.values():
            match = True
            if keyword and keyword_lower not in product.title.lower():
                match = False
            if category and product.category != category:
                match = False
            if product.price < min_price or product.price > max_price:
                match = False
            if match:
                results.append(asdict(product))

        total = len(results)
        start_index = (page - 1) * page_size
        paginated_results = results[start_index:start_index + page_size]

        return {
            "total": total,
            "page": page,
            "page_size": page_size,
            "total_pages": (total + page_size - 1) // page_size,
            "data": paginated_results
        }

    def get_products_by_category(self, category: str, page: int = 1, page_size: int = 50) -> Dict[str, Any]:
        return self.search_products(category=category, page=page, page_size=page_size)

    def get_hot_products(self, limit: int = 50) -> List[Dict[str, Any]]:
        hot_products = [asdict(p) for p in self.products.values() if p.is_hot]
        hot_products.sort(key=lambda x: x["sales_count"], reverse=True)
        return hot_products[:limit]

    def get_products_by_tag(self, tag: str, page: int = 1, page_size: int = 50) -> Dict[str, Any]:
        results = []
        for product in self.products.values():
            if tag in product.tags:
                results.append(asdict(product))

        total = len(results)
        start_index = (page - 1) * page_size
        paginated_results = results[start_index:start_index + page_size]

        return {
            "total": total,
            "page": page,
            "page_size": page_size,
            "total_pages": (total + page_size - 1) // page_size,
            "data": paginated_results
        }

    def get_statistics(self) -> Dict[str, Any]:
        category_counts = {}
        for product in self.products.values():
            if product.category not in category_counts:
                category_counts[product.category] = 0
            category_counts[product.category] += 1

        return {
            "total_products": len(self.products),
            "total_categories": len(TaobaoCategory),
            "category_distribution": category_counts,
            "hot_products_count": sum(1 for p in self.products.values() if p.is_hot),
            "tianmao_products_count": sum(1 for p in self.products.values() if p.is_tianmao)
        }

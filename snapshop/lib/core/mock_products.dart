import 'mock_data.dart';

/// 本地 Mock 商品库，按分类组织，用于 API 无返回时的降级兜底
class MockProductData {
  static const Map<String, List<Map<String, dynamic>>> _categories = {
    '运动鞋': [
      {'name': 'Nike Air Max 270 男子气垫跑步鞋 透气缓震', 'price': 599.0, 'original_price': 799.0, 'brand': 'Nike', 'shop_name': 'Nike官方旗舰店', 'shop_type': 'official', 'rating': 4.9, 'sales_count': 12580, 'image_url': 'https://via.placeholder.com/300x400?text=Nike+Air+Max', 'product_url': 'https://mobile.yangkeduo.com/goods.html?goods_id=532145678901'},
      {'name': 'Adidas Ultraboost 22 男女同款运动休闲鞋', 'price': 799.0, 'original_price': 1099.0, 'brand': 'Adidas', 'shop_name': 'Adidas官方旗舰店', 'shop_type': 'official', 'rating': 4.8, 'sales_count': 8920, 'image_url': 'https://via.placeholder.com/300x400?text=Adidas+Ultraboost', 'product_url': 'https://item.jd.com/100123456789.html'},
      {'name': '安踏 氢跑4.0 超轻透气跑步鞋', 'price': 399.0, 'original_price': 499.0, 'brand': '安踏', 'shop_name': '安踏官方旗舰店', 'shop_type': 'official', 'rating': 4.7, 'sales_count': 34500, 'image_url': 'https://via.placeholder.com/300x400?text=Anta+Running', 'product_url': 'https://mobile.yangkeduo.com/goods.html?goods_id=532145678902'},
      {'name': '李宁 赤兔6 Pro 竞速训练跑鞋 高弹耐磨', 'price': 459.0, 'original_price': 599.0, 'brand': '李宁', 'shop_name': '李宁官方旗舰店', 'shop_type': 'official', 'rating': 4.8, 'sales_count': 22300, 'image_url': 'https://via.placeholder.com/300x400?text=LiNing+Chitu', 'product_url': 'https://item.jd.com/100123456790.html'},
      {'name': 'New Balance 574 经典复古休闲运动鞋', 'price': 499.0, 'original_price': 699.0, 'brand': 'New Balance', 'shop_name': 'NB品牌店', 'shop_type': 'third_party', 'rating': 4.6, 'sales_count': 15600, 'image_url': 'https://via.placeholder.com/300x400?text=NB+574', 'product_url': 'https://mobile.yangkeduo.com/goods.html?goods_id=532145678903'},
      {'name': '特步 动力巢T20 专业马拉松竞速鞋', 'price': 299.0, 'original_price': 399.0, 'brand': '特步', 'shop_name': '特步品牌店', 'shop_type': 'third_party', 'rating': 4.5, 'sales_count': 45600, 'image_url': 'https://via.placeholder.com/300x400?text=Xtep+Power', 'product_url': 'https://item.jd.com/100123456791.html'},
    ],
    '连衣裙': [
      {'name': '2024夏季新款碎花雪纺连衣裙 显瘦中长款', 'price': 129.0, 'original_price': 259.0, 'brand': '韩都衣舍', 'shop_name': '韩都衣舍旗舰店', 'shop_type': 'official', 'rating': 4.7, 'sales_count': 32100, 'image_url': 'https://via.placeholder.com/300x400?text=Floral+Dress', 'product_url': 'https://mobile.yangkeduo.com/goods.html?goods_id=532145678904'},
      {'name': '法式复古收腰气质连衣裙 温柔风长裙', 'price': 199.0, 'original_price': 399.0, 'brand': 'UR', 'shop_name': 'UR官方旗舰店', 'shop_type': 'official', 'rating': 4.8, 'sales_count': 18900, 'image_url': 'https://via.placeholder.com/300x400?text=French+Dress', 'product_url': 'https://item.jd.com/100123456792.html'},
      {'name': '棉麻文艺范宽松连衣裙 森系小清新', 'price': 89.0, 'original_price': 179.0, 'brand': '茵曼', 'shop_name': '茵曼品牌店', 'shop_type': 'third_party', 'rating': 4.6, 'sales_count': 15800, 'image_url': 'https://via.placeholder.com/300x400?text=Cotton+Linen+Dress', 'product_url': 'https://mobile.yangkeduo.com/goods.html?goods_id=532145678905'},
      {'name': '性感V领蕾丝连衣裙 晚宴派对小礼服', 'price': 259.0, 'original_price': 499.0, 'brand': 'ONLY', 'shop_name': 'ONLY官方旗舰店', 'shop_type': 'official', 'rating': 4.5, 'sales_count': 8700, 'image_url': 'https://via.placeholder.com/300x400?text=Lace+Dress', 'product_url': 'https://item.jd.com/100123456793.html'},
    ],
    '蓝牙耳机': [
      {'name': 'Apple AirPods Pro 2 主动降噪无线蓝牙耳机', 'price': 1599.0, 'original_price': 1899.0, 'brand': 'Apple', 'shop_name': 'Apple官方旗舰店', 'shop_type': 'official', 'rating': 4.9, 'sales_count': 56700, 'image_url': 'https://via.placeholder.com/300x400?text=AirPods+Pro+2', 'product_url': 'https://mobile.yangkeduo.com/goods.html?goods_id=532145678907'},
      {'name': 'Sony WF-1000XM5 旗舰级降噪豆', 'price': 1999.0, 'original_price': 2499.0, 'brand': 'Sony', 'shop_name': 'Sony官方旗舰店', 'shop_type': 'official', 'rating': 4.8, 'sales_count': 23400, 'image_url': 'https://via.placeholder.com/300x400?text=Sony+WF1000XM5', 'product_url': 'https://item.jd.com/100123456794.html'},
      {'name': '小米 Buds 5 半入耳降噪蓝牙耳机 长续航', 'price': 299.0, 'original_price': 399.0, 'brand': '小米', 'shop_name': '小米官方旗舰店', 'shop_type': 'official', 'rating': 4.6, 'sales_count': 89200, 'image_url': 'https://via.placeholder.com/300x400?text=Xiaomi+Buds+5', 'product_url': 'https://mobile.yangkeduo.com/goods.html?goods_id=532145678908'},
      {'name': '漫步者 LolliPods Pro 2 降噪蓝牙耳机', 'price': 199.0, 'original_price': 299.0, 'brand': '漫步者', 'shop_name': '漫步者旗舰店', 'shop_type': 'official', 'rating': 4.4, 'sales_count': 112000, 'image_url': 'https://via.placeholder.com/300x400?text=Edifier+LolliPods', 'product_url': 'https://item.jd.com/100123456795.html'},
      {'name': '华为 FreeBuds Pro 3 星闪技术无线耳机', 'price': 999.0, 'original_price': 1299.0, 'brand': '华为', 'shop_name': '华为官方旗舰店', 'shop_type': 'official', 'rating': 4.7, 'sales_count': 45600, 'image_url': 'https://via.placeholder.com/300x400?text=Huawei+FreeBuds', 'product_url': 'https://mobile.yangkeduo.com/goods.html?goods_id=532145678909'},
    ],
    '手机': [
      {'name': 'Apple iPhone 15 Pro Max 256GB 钛金属原色', 'price': 9999.0, 'original_price': 10999.0, 'brand': 'Apple', 'shop_name': 'Apple官方旗舰店', 'shop_type': 'official', 'rating': 4.9, 'sales_count': 234500, 'image_url': 'https://via.placeholder.com/300x400?text=iPhone+15+Pro+Max', 'product_url': 'https://mobile.yangkeduo.com/goods.html?goods_id=532145678910'},
      {'name': '华为 Mate 60 Pro 512GB 雅丹黑', 'price': 6999.0, 'original_price': 7499.0, 'brand': '华为', 'shop_name': '华为官方旗舰店', 'shop_type': 'official', 'rating': 4.9, 'sales_count': 187000, 'image_url': 'https://via.placeholder.com/300x400?text=Huawei+Mate+60+Pro', 'product_url': 'https://item.jd.com/100123456796.html'},
      {'name': '小米14 Ultra 16GB+512GB 徕卡影像', 'price': 6499.0, 'original_price': 6999.0, 'brand': '小米', 'shop_name': '小米官方旗舰店', 'shop_type': 'official', 'rating': 4.8, 'sales_count': 123000, 'image_url': 'https://via.placeholder.com/300x400?text=Xiaomi+14+Ultra', 'product_url': 'https://mobile.yangkeduo.com/goods.html?goods_id=532145678911'},
      {'name': 'OPPO Find X7 Ultra 16GB+1TB', 'price': 5999.0, 'original_price': 6499.0, 'brand': 'OPPO', 'shop_name': 'OPPO官方旗舰店', 'shop_type': 'official', 'rating': 4.7, 'sales_count': 89000, 'image_url': 'https://via.placeholder.com/300x400?text=OPPO+Find+X7', 'product_url': 'https://item.jd.com/100123456797.html'},
    ],
    'T恤': [
      {'name': '优衣库 U系列 纯棉圆领T恤 多色可选', 'price': 79.0, 'original_price': 99.0, 'brand': '优衣库', 'shop_name': '优衣库官方旗舰店', 'shop_type': 'official', 'rating': 4.8, 'sales_count': 89000, 'image_url': 'https://via.placeholder.com/300x400?text=Uniqlo+Tshirt', 'product_url': 'https://mobile.yangkeduo.com/goods.html?goods_id=532145678913'},
      {'name': 'Nike 运动速干T恤 透气排汗', 'price': 149.0, 'original_price': 199.0, 'brand': 'Nike', 'shop_name': 'Nike官方旗舰店', 'shop_type': 'official', 'rating': 4.7, 'sales_count': 45600, 'image_url': 'https://via.placeholder.com/300x400?text=Nike+DriFit', 'product_url': 'https://item.jd.com/100123456798.html'},
      {'name': '国潮原创设计T恤 中国风印花', 'price': 129.0, 'original_price': 169.0, 'brand': '中国李宁', 'shop_name': '李宁品牌店', 'shop_type': 'third_party', 'rating': 4.5, 'sales_count': 12800, 'image_url': 'https://via.placeholder.com/300x400?text=China+Style+Tshirt', 'product_url': 'https://mobile.yangkeduo.com/goods.html?goods_id=532145678915'},
    ],
    '双肩包': [
      {'name': 'The North Face 北面双肩包 户外旅行通勤', 'price': 399.0, 'original_price': 599.0, 'brand': 'The North Face', 'shop_name': '北面官方旗舰店', 'shop_type': 'official', 'rating': 4.8, 'sales_count': 23400, 'image_url': 'https://via.placeholder.com/300x400?text=NorthFace+Backpack', 'product_url': 'https://mobile.yangkeduo.com/goods.html?goods_id=532145678916'},
      {'name': '小米 极简都市双肩包 15.6英寸电脑包', 'price': 99.0, 'original_price': 159.0, 'brand': '小米', 'shop_name': '小米官方旗舰店', 'shop_type': 'official', 'rating': 4.7, 'sales_count': 56000, 'image_url': 'https://via.placeholder.com/300x400?text=Xiaomi+Backpack', 'product_url': 'https://item.jd.com/100123456800.html'},
      {'name': 'JanSport 经典校园双肩包 学生书包', 'price': 259.0, 'original_price': 359.0, 'brand': 'JanSport', 'shop_name': 'JanSport品牌店', 'shop_type': 'third_party', 'rating': 4.6, 'sales_count': 34500, 'image_url': 'https://via.placeholder.com/300x400?text=JanSport+Backpack', 'product_url': 'https://mobile.yangkeduo.com/goods.html?goods_id=532145678917'},
      {'name': 'Lululemon Everywhere 运动休闲双肩包', 'price': 459.0, 'original_price': 599.0, 'brand': 'Lululemon', 'shop_name': 'Lululemon官方旗舰店', 'shop_type': 'official', 'rating': 4.8, 'sales_count': 12300, 'image_url': 'https://via.placeholder.com/300x400?text=Lululemon+Backpack', 'product_url': 'https://mobile.yangkeduo.com/goods.html?goods_id=532145678918'},
    ],
  };

  /// 根据分类名称获取匹配的 Mock 商品
  static List<MockProduct> getByCategory(String category) {
    final categoryLower = category.trim();
    // 精确匹配
    for (final entry in _categories.entries) {
      if (categoryLower.contains(entry.key) || entry.key.contains(categoryLower)) {
        return _toProducts(entry.value, entry.key);
      }
    }
    return [];
  }

  static List<MockProduct> _toProducts(List<Map<String, dynamic>> list, String category) {
    final platforms = ['pdd', 'jd', 'taobao'];
    return list.asMap().entries.map((e) {
      final i = e.key;
      final p = e.value;
      return MockProduct(
        id: 'mock_${category}_$i',
        name: p['name'] as String,
        price: (p['price'] as num).toDouble(),
        originalPrice: (p['original_price'] as num).toDouble(),
        platform: platforms[i % platforms.length],
        shopName: p['shop_name'] as String,
        shopType: p['shop_type'] as String,
        rating: (p['rating'] as num).toDouble(),
        salesCount: p['sales_count'] as int,
        imageUrl: p['image_url'] as String,
        productUrl: p['product_url'] as String,
        isMock: true,
        tags: (p['platform'] ?? '') == 'pdd' ? ['百亿补贴'] : ['限时特惠'],
        attributes: {'brand': p['brand'], 'category': category},
      );
    }).toList();
  }
}

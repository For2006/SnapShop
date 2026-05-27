class MockProduct {
  final String id;
  final String name;
  final double price;
  final double originalPrice;
  final String platform;
  final String shopName;
  final String shopType;
  final double rating;
  final int salesCount;
  final String imageUrl;
  final List<String> tags;

  const MockProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.originalPrice,
    required this.platform,
    required this.shopName,
    required this.shopType,
    required this.rating,
    required this.salesCount,
    required this.imageUrl,
    required this.tags,
  });
}

class MockAttribute {
  final String key;
  final String label;
  String value;
  double confidence;

  MockAttribute({
    required this.key,
    required this.label,
    required this.value,
    required this.confidence,
  });

  MockAttribute copyWith({String? value, double? confidence}) {
    return MockAttribute(
      key: key,
      label: label,
      value: value ?? this.value,
      confidence: confidence ?? this.confidence,
    );
  }
}

class MockSuggestion {
  final String id;
  final String title;
  final String icon;
  final String action;
  final String type;

  const MockSuggestion({
    required this.id,
    required this.title,
    required this.icon,
    required this.action,
    required this.type,
  });
}

class MockRecognitionResult {
  final String category;
  final List<MockAttribute> attributes;
  final List<MockSuggestion> suggestions;

  const MockRecognitionResult({
    required this.category,
    required this.attributes,
    required this.suggestions,
  });
}

const List<MockProduct> mockProducts = [
  MockProduct(
    id: 'p1',
    name: 'Nike Air Max 270 男子气垫跑步鞋',
    price: 899.00,
    originalPrice: 1199.00,
    platform: 'taobao',
    shopName: 'Nike官方旗舰店',
    shopType: 'official',
    rating: 4.9,
    salesCount: 12580,
    imageUrl:
        'https://images.unsplash.com/photo-1542291026-7eec264c27ff?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxuaWtlJTIwc2hvZXMlMjBydW5uaW5nfGVufDF8fHx8MTc3OTU5OTg4Nnww&ixlib=rb-4.1.0&q=80&w=1080',
    tags: ['百亿补贴', '包邮'],
  ),
  MockProduct(
    id: 'p2',
    name: 'Nike Air Max 男子运动鞋 舒适透气',
    price: 859.00,
    originalPrice: 1099.00,
    platform: 'jd',
    shopName: '京东自营',
    shopType: 'self_operated',
    rating: 4.8,
    salesCount: 8900,
    imageUrl:
        'https://images.unsplash.com/photo-1600185365483-26d7a4cc7519?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxuaWtlJTIwYWlyJTIwbWF4fGVufDF8fHx8MTc3OTQ0MjAxMXww&ixlib=rb-4.1.0&q=80&w=1080',
    tags: ['自营', '次日达'],
  ),
  MockProduct(
    id: 'p3',
    name: '耐克男鞋跑步鞋 Air Max 蓝黑配色',
    price: 799.00,
    originalPrice: 1199.00,
    platform: 'pdd',
    shopName: '耐克品牌店',
    shopType: 'third_party',
    rating: 4.6,
    salesCount: 34000,
    imageUrl:
        'https://images.unsplash.com/photo-1660633777105-9521b3757393?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxuaWtlJTIwc2hvZXMlMjBydW5uaW5nJTIwYmx1ZXxlbnwxfHx8fDE3Nzk1OTk4OTF8MA&ixlib=rb-4.1.0&q=80&w=1080',
    tags: ['全网低价', '退货包运费'],
  ),
  MockProduct(
    id: 'p4',
    name: 'Nike官方 Air Max 透气休闲鞋',
    price: 929.00,
    originalPrice: 1299.00,
    platform: 'taobao',
    shopName: 'Nike官方旗舰店',
    shopType: 'official',
    rating: 4.9,
    salesCount: 5600,
    imageUrl:
        'https://images.unsplash.com/photo-1676041669566-fead69bd7007?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxzbmVha2VycyUyMHJ1bm5pbmclMjB3aGl0ZXxlbnwxfHx8fDE3Nzk1OTk4OTF8MA&ixlib=rb-4.1.0&q=80&w=1080',
    tags: [],
  ),
  MockProduct(
    id: 'p5',
    name: '耐克 Joyride 缓震跑步鞋',
    price: 699.00,
    originalPrice: 1099.00,
    platform: 'jd',
    shopName: '耐克授权专卖',
    shopType: 'third_party',
    rating: 4.7,
    salesCount: 12000,
    imageUrl:
        'https://images.unsplash.com/photo-1606107557195-0e29a4b5b4aa?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxuaWtlJTIwam95cmlkZXxlbnwxfHx8fDE3Nzk1OTk5OTN8MA&ixlib=rb-4.1.0&q=80&w=1080',
    tags: ['热销款'],
  ),
  MockProduct(
    id: 'p6',
    name: 'Nike React Infinity Run 男鞋',
    price: 1199.00,
    originalPrice: 1399.00,
    platform: 'taobao',
    shopName: 'Nike官方旗舰店',
    shopType: 'official',
    rating: 4.9,
    salesCount: 8000,
    imageUrl:
        'https://images.unsplash.com/photo-1491553895911-0055eca6402d?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxuaWtlJTIwcmVhY3R8ZW58MXx8fHwxNzc5NTk5OTkzfDA&ixlib=rb-4.1.0&q=80&w=1080',
    tags: ['官方正品', '新款'],
  ),
];

MockRecognitionResult get mockRecognitionResult {
  return MockRecognitionResult(
    category: '运动鞋',
    attributes: [
      MockAttribute(key: 'brand', label: '品牌', value: 'Nike', confidence: 0.95),
      MockAttribute(key: 'color', label: '颜色', value: '红色', confidence: 0.65),
      MockAttribute(key: 'style', label: '风格', value: '运动', confidence: 0.88),
      MockAttribute(key: 'material', label: '材质', value: '网面', confidence: 0.90),
    ],
    suggestions: const [
      MockSuggestion(
        id: 's1',
        title: '跨平台最低价在拼多多',
        icon: 'zap',
        action: 'filter_pdd',
        type: 'primary',
      ),
      MockSuggestion(
        id: 's2',
        title: '查看同款低价',
        icon: 'trending-down',
        action: 'sort_price',
        type: 'normal',
      ),
      MockSuggestion(
        id: 's3',
        title: '只看官方旗舰店',
        icon: 'shield-check',
        action: 'filter_official',
        type: 'normal',
      ),
      MockSuggestion(
        id: 's4',
        title: '相似风格推荐',
        icon: 'sparkles',
        action: 'similar',
        type: 'normal',
      ),
    ],
  );
}

const List<String> mockHistory = [
  '白色连衣裙',
  '索尼降噪耳机',
  '双肩包男',
  'Air Force 1',
];

const List<String> mockGalleryImages = [
  'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400&q=80',
  'https://images.unsplash.com/photo-1515372039744-b8f02a3ae446?w=400&q=80',
  'https://images.unsplash.com/photo-1581605405669-fcdf81165afa?w=400&q=80',
  'https://images.unsplash.com/photo-1572569511254-d8f925fe2cbb?w=400&q=80',
  'https://images.unsplash.com/photo-1460353581641-37baddab0fa2?w=400&q=80',
  'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=400&q=80',
  'https://images.unsplash.com/photo-1560343090-f0409e92791a?w=400&q=80',
  'https://images.unsplash.com/photo-1491553895911-0055eca6402d?w=400&q=80',
  'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?w=400&q=80',
  'https://images.unsplash.com/photo-1525966222134-fcfa99b8ae77?w=400&q=80',
  'https://images.unsplash.com/photo-1511556820780-d912e42b4980?w=400&q=80',
  'https://images.unsplash.com/photo-1584735175315-9d5df23860e6?w=400&q=80',
];

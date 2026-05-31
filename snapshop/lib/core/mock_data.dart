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
  final String productUrl;
  final bool isMock;
  final List<String> tags;
  final Map<String, dynamic> attributes;

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
    required this.productUrl,
    this.isMock = false,
    required this.tags,
    this.attributes = const {},
  });

  factory MockProduct.fromJson(Map<String, dynamic> json) {
    return MockProduct(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: (json['price'] ?? 0).toDouble(),
      originalPrice: (json['original_price'] ?? 0).toDouble(),
      platform: json['platform']?.toString() ?? '',
      shopName: json['shop_name']?.toString() ?? '',
      shopType: json['shop_type']?.toString() ?? 'third_party',
      rating: (json['rating'] ?? 0).toDouble(),
      salesCount: (json['sales_count'] ?? 0).toInt(),
      imageUrl: json['image_url']?.toString() ?? '',
      productUrl: json['product_url']?.toString() ?? '',
      isMock: json['is_mock'] == true,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      attributes: (json['attributes'] as Map<String, dynamic>?) ?? {},
    );
  }
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

  factory MockAttribute.fromJson(Map<String, dynamic> json) {
    return MockAttribute(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
      confidence: (json['confidence'] ?? 0).toDouble(),
    );
  }
}

class MockSuggestion {
  final String id;
  final String title;
  final String icon;
  final String action;
  final String type;
  final Map<String, dynamic> params;

  const MockSuggestion({
    required this.id,
    required this.title,
    required this.icon,
    required this.action,
    required this.type,
    this.params = const {},
  });

  factory MockSuggestion.fromJson(Map<String, dynamic> json) {
    return MockSuggestion(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      type: json['type']?.toString() ?? 'normal',
      params: (json['params'] as Map<String, dynamic>?) ?? {},
    );
  }
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

  factory MockRecognitionResult.fromJson(Map<String, dynamic> json) {
    final rec = json['recognition'] ?? json;
    return MockRecognitionResult(
      category: rec['category']?.toString() ?? '',
      attributes: (rec['attributes'] as List<dynamic>?)
              ?.map((e) => MockAttribute.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      suggestions: (rec['suggestions'] as List<dynamic>?)
              ?.map((e) => MockSuggestion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

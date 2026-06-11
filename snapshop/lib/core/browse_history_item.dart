import 'mock_data.dart';

class BrowseHistoryItem {
  final String id;
  final String productId;
  final String name;
  final double price;
  final String platform;
  final String imageUrl;
  final String? shopName;
  final String? viewedAt;
  final bool isMock;

  const BrowseHistoryItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    required this.platform,
    required this.imageUrl,
    this.shopName,
    this.viewedAt,
    this.isMock = false,
  });

  factory BrowseHistoryItem.fromJson(Map<String, dynamic> json) {
    final snap = json['product_snapshot'] as Map<String, dynamic>? ?? json;
    return BrowseHistoryItem(
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      name: snap['name']?.toString() ?? '',
      price: double.tryParse(snap['price']?.toString() ?? '0') ?? 0,
      platform: snap['platform']?.toString() ?? '',
      imageUrl: snap['image_url']?.toString() ?? '',
      shopName: snap['shop_name']?.toString(),
      viewedAt: json['viewed_at']?.toString(),
      isMock: snap['is_mock'] == true,
    );
  }

  MockProduct toMockProduct() {
    return MockProduct(
      id: productId,
      name: name,
      price: price,
      originalPrice: price,
      platform: platform,
      imageUrl: imageUrl,
      shopName: shopName ?? '',
      shopType: 'third_party',
      rating: 0,
      salesCount: 0,
      productUrl: '',
      isMock: isMock,
      tags: const [],
    );
  }
}

class HistoryItem {
  final String sessionId;
  final String? imageUrl;
  final String? category;
  final String? searchQuery;
  final String? searchType;
  final String? createdAt;

  const HistoryItem({
    required this.sessionId,
    this.imageUrl,
    this.category,
    this.searchQuery,
    this.searchType,
    this.createdAt,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      sessionId: json['session_id']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
      category: json['category']?.toString(),
      searchQuery: json['search_query']?.toString(),
      searchType: json['search_type']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  String get displayText {
    return searchQuery?.isNotEmpty == true
        ? searchQuery!
        : category?.isNotEmpty == true
            ? category!
            : '...';
  }
}

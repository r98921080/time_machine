enum ShopCategory {
  outfit,
  hairstyle,
  accessory,
  background,
  furniture,
  tattoo,
  faceDecal,
  special,
}

extension ShopCategoryExt on ShopCategory {
  String get label {
    switch (this) {
      case ShopCategory.outfit: return '服飾';
      case ShopCategory.hairstyle: return '髮型';
      case ShopCategory.accessory: return '配件';
      case ShopCategory.background: return '背景';
      case ShopCategory.furniture: return '裝潢';
      case ShopCategory.tattoo: return '刺青';
      case ShopCategory.faceDecal: return '臉部';
      case ShopCategory.special: return '限定';
    }
  }
}

class ShopItem {
  final String id;
  final String name;
  final ShopCategory category;
  final int price;
  final String description;
  final String emoji;
  final String? assetPath;
  final String? previewUrl;
  final bool isLimited;
  final String? unlockCondition;
  final DateTime? availableUntil;

  const ShopItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    this.emoji = '🎁',
    this.assetPath,
    this.previewUrl,
    this.isLimited = false,
    this.unlockCondition,
    this.availableUntil,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'category': category.name,
    'price': price,
    'description': description,
    'emoji': emoji,
    'assetPath': assetPath,
    'previewUrl': previewUrl,
    'isLimited': isLimited,
    'unlockCondition': unlockCondition,
    'availableUntil': availableUntil?.toIso8601String(),
  };

  factory ShopItem.fromMap(Map<String, dynamic> m) => ShopItem(
    id: m['id'] as String,
    name: m['name'] as String,
    category: ShopCategory.values.firstWhere((e) => e.name == m['category']),
    price: m['price'] as int,
    description: m['description'] as String,
    emoji: m['emoji'] as String? ?? '🎁',
    assetPath: m['assetPath'] as String?,
    previewUrl: m['previewUrl'] as String?,
    isLimited: m['isLimited'] as bool? ?? false,
    unlockCondition: m['unlockCondition'] as String?,
    availableUntil: m['availableUntil'] != null
        ? DateTime.tryParse(m['availableUntil'] as String)
        : null,
  );
}

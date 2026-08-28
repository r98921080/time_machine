import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/shop_item.dart';
import '../../providers/app_provider.dart';

// Sample shop data — in production, fetched from backend API
final _sampleItems = [
  // Outfits
  ShopItem(id: 'outfit_casual_01', name: '休閒帽T', category: ShopCategory.outfit,
      price: 50, description: '簡單舒適的百搭帽T'),
  ShopItem(id: 'outfit_sport_01', name: '運動套裝', category: ShopCategory.outfit,
      price: 80, description: '高機能排汗運動服'),
  ShopItem(id: 'outfit_formal_01', name: '西裝套裝', category: ShopCategory.outfit,
      price: 120, description: '帥氣正式的西裝'),
  ShopItem(id: 'outfit_kimono_01', name: '和服', category: ShopCategory.outfit,
      price: 150, description: '傳統日式和服', isLimited: true),
  ShopItem(id: 'outfit_mage_01', name: '魔法師袍', category: ShopCategory.outfit,
      price: 200, description: '中古世紀魔法師服裝', isLimited: true),

  // Hair
  ShopItem(id: 'hair_twin_01', name: '雙馬尾', category: ShopCategory.hairstyle,
      price: 30, description: '活潑可愛的雙馬尾'),
  ShopItem(id: 'hair_ahoge_01', name: '呆毛頭', category: ShopCategory.hairstyle,
      price: 40, description: '特徵明顯的呆毛'),
  ShopItem(id: 'hair_undercut_01', name: 'Undercut', category: ShopCategory.hairstyle,
      price: 60, description: '時髦的側剃髮型'),

  // Accessories
  ShopItem(id: 'acc_glasses_01', name: '圓框眼鏡', category: ShopCategory.accessory,
      price: 30, description: '文青必備圓框眼鏡'),
  ShopItem(id: 'acc_crown_01', name: '花冠', category: ShopCategory.accessory,
      price: 50, description: '清新浪漫的花冠'),
  ShopItem(id: 'acc_medal_01', name: '金牌', category: ShopCategory.accessory,
      price: 100, description: '達成100天連續打卡獎章',
      unlockCondition: '連續打卡100天'),

  // Backgrounds
  ShopItem(id: 'bg_beach_01', name: '海邊日落', category: ShopCategory.background,
      price: 60, description: '浪漫的海邊日落場景'),
  ShopItem(id: 'bg_forest_01', name: '魔法森林', category: ShopCategory.background,
      price: 80, description: '充滿魔力的奇幻森林'),
  ShopItem(id: 'bg_city_01', name: '霓虹城市', category: ShopCategory.background,
      price: 100, description: '繁華的夜間都市'),

  // Tattoos
  ShopItem(id: 'tat_rose_01', name: '玫瑰刺青', category: ShopCategory.tattoo,
      price: 40, description: '優雅的玫瑰花臂'),
  ShopItem(id: 'tat_dragon_01', name: '龍紋刺青', category: ShopCategory.tattoo,
      price: 80, description: '霸氣的龍紋圖騰'),

  // Face
  ShopItem(id: 'face_blush_01', name: '星星腮紅', category: ShopCategory.faceDecal,
      price: 20, description: '可愛的星星腮紅'),
  ShopItem(id: 'face_scar_01', name: '英雄疤痕', category: ShopCategory.faceDecal,
      price: 30, description: '充滿故事的臉部疤痕'),
];

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  Set<String> _owned = {};

  final _tabs = ShopCategory.values;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _loadOwned();
  }

  Future<void> _loadOwned() async {
    final provider = context.read<AppProvider>();
    if (provider.profile == null) return;
    // In production: load from DatabaseService
    setState(() => _owned = {});
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final points = provider.profile?.growthPoints ?? 0;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('裝備商店'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              avatar: const Icon(Icons.star, size: 16, color: Colors.amber),
              label: Text('$points 點',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.amber.shade50,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabs: _tabs.map((c) => Tab(text: c.label)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: _tabs.map((cat) {
          final items =
              _sampleItems.where((i) => i.category == cat).toList();
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              final owned = _owned.contains(item.id);
              return _ShopCard(
                item: item,
                owned: owned,
                canAfford: points >= item.price,
                theme: theme,
                onBuy: () => _buy(context, provider, item),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Future<void> _buy(
      BuildContext context, AppProvider provider, ShopItem item) async {
    if (_owned.contains(item.id)) {
      // Apply item to character
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.name} 已裝備！')));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('購買 ${item.name}'),
        content: Text('花費 ${item.price} 成長點數購買？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('確認購買')),
        ],
      ),
    );

    if (confirm == true) {
      final success = await provider.purchaseItem(item.id, item.price);
      if (context.mounted) {
        if (success) {
          setState(() => _owned.add(item.id));
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('🎉 成功購買 ${item.name}！'),
                  backgroundColor: Colors.green));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('成長點數不足'),
                  backgroundColor: Colors.red));
        }
      }
    }
  }
}

class _ShopCard extends StatelessWidget {
  final ShopItem item;
  final bool owned;
  final bool canAfford;
  final ThemeData theme;
  final VoidCallback onBuy;

  const _ShopCard({
    required this.item,
    required this.owned,
    required this.canAfford,
    required this.theme,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onBuy,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_categoryEmoji(item.category),
                          style: const TextStyle(fontSize: 40)),
                      if (item.isLimited)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('限定',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 10)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: theme.textTheme.labelLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(item.description,
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text('${item.price}',
                          style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: canAfford ? Colors.amber.shade700
                                  : Colors.grey)),
                      const Spacer(),
                      if (owned)
                        const Icon(Icons.check_circle,
                            size: 18, color: Colors.green)
                      else if (!canAfford)
                        const Icon(Icons.lock_outline,
                            size: 18, color: Colors.grey),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _categoryEmoji(ShopCategory cat) {
    switch (cat) {
      case ShopCategory.outfit: return '👕';
      case ShopCategory.hairstyle: return '💇';
      case ShopCategory.accessory: return '💍';
      case ShopCategory.background: return '🌅';
      case ShopCategory.furniture: return '🛋️';
      case ShopCategory.tattoo: return '🎨';
      case ShopCategory.faceDecal: return '✨';
      case ShopCategory.special: return '🌟';
    }
  }
}

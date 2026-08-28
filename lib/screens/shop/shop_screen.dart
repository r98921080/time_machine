import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/shop_item.dart';
import '../../models/character.dart';
import '../../providers/app_provider.dart';

// ── Catalog (120+ items) ───────────────────────────────────────────────────
final _catalog = <ShopItem>[
  // ── 服飾 ──
  ShopItem(id: 'outfit_tshirt_white', name: '白色T恤', category: ShopCategory.outfit,
      price: 30, description: '簡約百搭的白色基本款', emoji: '👕'),
  ShopItem(id: 'outfit_casual_hoodie', name: '連帽衫', category: ShopCategory.outfit,
      price: 50, description: '舒適保暖的帽T', emoji: '🧥'),
  ShopItem(id: 'outfit_sport_set', name: '運動套裝', category: ShopCategory.outfit,
      price: 80, description: '高機能排汗運動服', emoji: '🏃'),
  ShopItem(id: 'outfit_denim_jacket', name: '牛仔外套', category: ShopCategory.outfit,
      price: 90, description: '街頭感牛仔外套', emoji: '👔'),
  ShopItem(id: 'outfit_formal_suit', name: '西裝套裝', category: ShopCategory.outfit,
      price: 120, description: '帥氣正式的西裝', emoji: '🤵'),
  ShopItem(id: 'outfit_sundress', name: '碎花洋裝', category: ShopCategory.outfit,
      price: 100, description: '清新浪漫的夏日洋裝', emoji: '👗'),
  ShopItem(id: 'outfit_trench', name: '風衣', category: ShopCategory.outfit,
      price: 130, description: '歐系時尚風衣', emoji: '🧣'),
  ShopItem(id: 'outfit_tracksuit', name: '格紋西裝', category: ShopCategory.outfit,
      price: 140, description: '精緻格紋雙排扣', emoji: '🎩'),
  ShopItem(id: 'outfit_kimono', name: '和服', category: ShopCategory.outfit,
      price: 200, description: '傳統日式和服', emoji: '👘', isLimited: true),
  ShopItem(id: 'outfit_hanfu', name: '漢服', category: ShopCategory.outfit,
      price: 220, description: '典雅傳統漢服', emoji: '🀄', isLimited: true),
  ShopItem(id: 'outfit_mage_robe', name: '魔法師袍', category: ShopCategory.outfit,
      price: 250, description: '神秘中古魔法師長袍', emoji: '🪄', isLimited: true),
  ShopItem(id: 'outfit_knight_armor', name: '騎士盔甲', category: ShopCategory.outfit,
      price: 300, description: '中古世紀銀色全甲',  emoji: '⚔️',
      unlockCondition: '連續打卡30天', isLimited: true),
  ShopItem(id: 'outfit_cyberpunk', name: '賽博龐克裝', category: ShopCategory.outfit,
      price: 280, description: '未來感霓虹裝備', emoji: '🤖', isLimited: true),
  ShopItem(id: 'outfit_ninja', name: '忍者裝束', category: ShopCategory.outfit,
      price: 180, description: '黑色輕薄忍者服', emoji: '🥷'),
  ShopItem(id: 'outfit_lab_coat', name: '實驗室白袍', category: ShopCategory.outfit,
      price: 110, description: '科學家的驕傲', emoji: '🥼'),
  ShopItem(id: 'outfit_chef', name: '主廚服', category: ShopCategory.outfit,
      price: 100, description: '專業主廚白色制服', emoji: '👨‍🍳'),
  ShopItem(id: 'outfit_space_suit', name: '太空衣', category: ShopCategory.outfit,
      price: 350, description: 'NASA認證太空探索裝', emoji: '👨‍🚀',
      unlockCondition: '記錄滿100餐', isLimited: true),
  ShopItem(id: 'outfit_detective', name: '偵探大衣', category: ShopCategory.outfit,
      price: 160, description: '福爾摩斯風格長大衣', emoji: '🕵️'),
  ShopItem(id: 'outfit_shrine_maiden', name: '巫女服', category: ShopCategory.outfit,
      price: 200, description: '紅白相間的神社巫女裝', emoji: '⛩️', isLimited: true),
  ShopItem(id: 'outfit_pirate', name: '海盜裝', category: ShopCategory.outfit,
      price: 170, description: '揚帆七海的海盜服', emoji: '🏴‍☠️'),
  ShopItem(id: 'outfit_school_uniform', name: '制服', category: ShopCategory.outfit,
      price: 80, description: '青春校園制服', emoji: '🎒'),
  ShopItem(id: 'outfit_egyptian', name: '古埃及裝', category: ShopCategory.outfit,
      price: 260, description: '法老王的黃金裝束', emoji: '𓂀', isLimited: true),

  // ── 髮型 ──
  ShopItem(id: 'hair_bob', name: '鮑伯頭', category: ShopCategory.hairstyle,
      price: 30, description: '俐落的短髮鮑伯', emoji: '💇'),
  ShopItem(id: 'hair_twintail', name: '雙馬尾', category: ShopCategory.hairstyle,
      price: 35, description: '活潑可愛的雙馬尾', emoji: '👧'),
  ShopItem(id: 'hair_long_wave', name: '長波浪', category: ShopCategory.hairstyle,
      price: 40, description: '飄逸的長卷髮', emoji: '💃'),
  ShopItem(id: 'hair_ahoge', name: '呆毛', category: ShopCategory.hairstyle,
      price: 30, description: '萌度爆表的招牌呆毛', emoji: '🌀'),
  ShopItem(id: 'hair_undercut', name: 'Undercut', category: ShopCategory.hairstyle,
      price: 60, description: '時髦的側剃兩層髮型', emoji: '✂️'),
  ShopItem(id: 'hair_dreadlock', name: '雷鬼辮', category: ShopCategory.hairstyle,
      price: 70, description: '自由奔放的雷鬼辮', emoji: '🎵'),
  ShopItem(id: 'hair_braided_bun', name: '編髮盤髻', category: ShopCategory.hairstyle,
      price: 55, description: '優雅的古風編髮', emoji: '🪢'),
  ShopItem(id: 'hair_ponytail_high', name: '高馬尾', category: ShopCategory.hairstyle,
      price: 30, description: '清爽活力的高馬尾', emoji: '🐴'),
  ShopItem(id: 'hair_afro', name: '爆炸頭', category: ShopCategory.hairstyle,
      price: 65, description: '圓潤飽滿的爆炸頭', emoji: '⚡'),
  ShopItem(id: 'hair_mohawk', name: '莫西干', category: ShopCategory.hairstyle,
      price: 75, description: '龐克風格的莫西干髮型', emoji: '🤘'),
  ShopItem(id: 'hair_silver', name: '銀白長髮', category: ShopCategory.hairstyle,
      price: 120, description: '如月光般的銀白長髮', emoji: '🌙',
      unlockCondition: '連續打卡14天'),
  ShopItem(id: 'hair_galaxy', name: '星河漸層', category: ShopCategory.hairstyle,
      price: 200, description: '深藍到紫的星河漸層染', emoji: '🌌', isLimited: true),
  ShopItem(id: 'hair_side_shave', name: '側剃龐克', category: ShopCategory.hairstyle,
      price: 80, description: '一邊剃光的龐克造型', emoji: '🎸'),
  ShopItem(id: 'hair_bun_space', name: '丸子頭', category: ShopCategory.hairstyle,
      price: 25, description: '可愛軟萌的丸子頭', emoji: '🎀'),

  // ── 配件 ──
  ShopItem(id: 'acc_glasses_round', name: '圓框眼鏡', category: ShopCategory.accessory,
      price: 30, description: '文青必備圓框眼鏡', emoji: '🤓'),
  ShopItem(id: 'acc_glasses_sunglasses', name: '墨鏡', category: ShopCategory.accessory,
      price: 45, description: '酷感十足的方形墨鏡', emoji: '😎'),
  ShopItem(id: 'acc_flower_crown', name: '花冠', category: ShopCategory.accessory,
      price: 50, description: '清新浪漫的野花花冠', emoji: '🌸'),
  ShopItem(id: 'acc_earring_star', name: '星星耳環', category: ShopCategory.accessory,
      price: 35, description: '閃亮五芒星耳環', emoji: '⭐'),
  ShopItem(id: 'acc_necklace_moon', name: '月牙項鍊', category: ShopCategory.accessory,
      price: 55, description: '優雅月牙形項鍊', emoji: '🌙'),
  ShopItem(id: 'acc_bandana', name: '頭巾', category: ShopCategory.accessory,
      price: 25, description: '復古花紋頭巾', emoji: '🧣'),
  ShopItem(id: 'acc_hat_cap', name: '棒球帽', category: ShopCategory.accessory,
      price: 35, description: '街頭感棒球帽', emoji: '🧢'),
  ShopItem(id: 'acc_hat_tophat', name: '高禮帽', category: ShopCategory.accessory,
      price: 90, description: '紳士必備大禮帽', emoji: '🎩'),
  ShopItem(id: 'acc_crown_gold', name: '黃金王冠', category: ShopCategory.accessory,
      price: 500, description: '王者的象徵',  emoji: '👑',
      unlockCondition: '達成Elite等級30天', isLimited: true),
  ShopItem(id: 'acc_medal_100', name: '百日金牌', category: ShopCategory.accessory,
      price: 200, description: '連續打卡100天的象徵', emoji: '🥇',
      unlockCondition: '連續打卡100天'),
  ShopItem(id: 'acc_ribbon_pink', name: '粉色緞帶', category: ShopCategory.accessory,
      price: 30, description: '甜美粉色大蝴蝶結', emoji: '🎀'),
  ShopItem(id: 'acc_scarf_winter', name: '毛絨圍巾', category: ShopCategory.accessory,
      price: 40, description: '冬日暖心毛絨圍巾', emoji: '🧤'),
  ShopItem(id: 'acc_wings_angel', name: '天使翅膀', category: ShopCategory.accessory,
      price: 300, description: '潔白純淨的天使羽翼', emoji: '👼', isLimited: true),
  ShopItem(id: 'acc_wings_demon', name: '惡魔之翼', category: ShopCategory.accessory,
      price: 320, description: '黑色帥氣的惡魔翅膀', emoji: '🦇', isLimited: true),
  ShopItem(id: 'acc_headphones', name: '無線耳機', category: ShopCategory.accessory,
      price: 70, description: '潮流感頭戴耳機', emoji: '🎧'),
  ShopItem(id: 'acc_mask_kitsune', name: '狐狸面具', category: ShopCategory.accessory,
      price: 150, description: '神秘的日式狐狸半面具', emoji: '🦊', isLimited: true),

  // ── 背景 ──
  ShopItem(id: 'bg_beach_sunset', name: '海邊日落', category: ShopCategory.background,
      price: 60, description: '溫暖橙色的海邊日落', emoji: '🌅'),
  ShopItem(id: 'bg_magic_forest', name: '魔法森林', category: ShopCategory.background,
      price: 80, description: '充滿魔力的螢光森林', emoji: '🌿'),
  ShopItem(id: 'bg_neon_city', name: '霓虹城市', category: ShopCategory.background,
      price: 100, description: '繁華的賽博龐克都市夜景', emoji: '🌃'),
  ShopItem(id: 'bg_sakura_park', name: '櫻花公園', category: ShopCategory.background,
      price: 90, description: '漫天飛舞的粉色櫻花', emoji: '🌸'),
  ShopItem(id: 'bg_starry_sky', name: '星空曠野', category: ShopCategory.background,
      price: 110, description: '一望無際的銀河星空', emoji: '🌌'),
  ShopItem(id: 'bg_mountain_snow', name: '雪山日出', category: ShopCategory.background,
      price: 120, description: '壯麗的高山雪地日出', emoji: '🏔️'),
  ShopItem(id: 'bg_underwater', name: '深海世界', category: ShopCategory.background,
      price: 130, description: '神秘瑰麗的深海珊瑚', emoji: '🐠'),
  ShopItem(id: 'bg_desert_oasis', name: '沙漠綠洲', category: ShopCategory.background,
      price: 100, description: '無盡黃沙中的一片翠綠', emoji: '🌴'),
  ShopItem(id: 'bg_ancient_temple', name: '古代神廟', category: ShopCategory.background,
      price: 150, description: '遠古文明的宏偉神廟', emoji: '🏛️'),
  ShopItem(id: 'bg_space_station', name: '太空站', category: ShopCategory.background,
      price: 200, description: '俯瞰地球的太空站觀測窗', emoji: '🛸', isLimited: true),
  ShopItem(id: 'bg_autumn_river', name: '楓葉溪流', category: ShopCategory.background,
      price: 95, description: '紅橙楓葉與潺潺溪水', emoji: '🍁'),
  ShopItem(id: 'bg_cozy_cafe', name: '溫馨咖啡廳', category: ShopCategory.background,
      price: 80, description: '雨天窗邊的咖啡廳角落', emoji: '☕'),
  ShopItem(id: 'bg_festival', name: '祭典夜市', category: ShopCategory.background,
      price: 110, description: '日式夏日祭典燈籠', emoji: '🏮', isLimited: true),

  // ── 裝潢 ──
  ShopItem(id: 'furn_sofa_modern', name: '現代沙發', category: ShopCategory.furniture,
      price: 60, description: '簡約北歐風格灰色沙發', emoji: '🛋️'),
  ShopItem(id: 'furn_plant_monstera', name: '龜背芋', category: ShopCategory.furniture,
      price: 25, description: '網紅植物龜背芋盆栽', emoji: '🌿'),
  ShopItem(id: 'furn_bookshelf', name: '木質書架', category: ShopCategory.furniture,
      price: 55, description: '滿載書籍的原木書架', emoji: '📚'),
  ShopItem(id: 'furn_desk_setup', name: '電競桌面', category: ShopCategory.furniture,
      price: 120, description: 'RGB燈效的電競工作桌', emoji: '💻'),
  ShopItem(id: 'furn_cat_tree', name: '貓跳台', category: ShopCategory.furniture,
      price: 70, description: '豪華多層貓咪跳台', emoji: '🐱'),
  ShopItem(id: 'furn_aquarium', name: '水族箱', category: ShopCategory.furniture,
      price: 90, description: '五彩熱帶魚的玻璃水缸', emoji: '🐟'),
  ShopItem(id: 'furn_telescope', name: '天文望遠鏡', category: ShopCategory.furniture,
      price: 100, description: '探索星空的折射式望遠鏡', emoji: '🔭'),
  ShopItem(id: 'furn_record_player', name: '黑膠唱片機', category: ShopCategory.furniture,
      price: 110, description: '復古風格木質黑膠唱片機', emoji: '🎵'),
  ShopItem(id: 'furn_art_corner', name: '藝術角落', category: ShopCategory.furniture,
      price: 80, description: '畫架與調色盤的創作空間', emoji: '🎨'),
  ShopItem(id: 'furn_gym_corner', name: '健身角落', category: ShopCategory.furniture,
      price: 130, description: '啞鈴瑜珈墊的訓練空間', emoji: '💪',
      unlockCondition: '目標達成Advanced等級30天'),
  ShopItem(id: 'furn_piano', name: '立式鋼琴', category: ShopCategory.furniture,
      price: 200, description: '優雅黑色立式鋼琴', emoji: '🎹', isLimited: true),
  ShopItem(id: 'furn_herb_garden', name: '香草花園', category: ShopCategory.furniture,
      price: 65, description: '窗台上的迷你香草種植區', emoji: '🌱'),
  ShopItem(id: 'furn_neon_sign', name: '霓虹燈牌', category: ShopCategory.furniture,
      price: 85, description: '客製化霓虹燈裝飾', emoji: '💡'),
  ShopItem(id: 'furn_hammock', name: '吊床', category: ShopCategory.furniture,
      price: 75, description: '木頭支架條紋吊床', emoji: '🏖️'),
  ShopItem(id: 'furn_wall_clock', name: '設計師掛鐘', category: ShopCategory.furniture,
      price: 45, description: '金屬線條極簡掛鐘', emoji: '⏰'),
  ShopItem(id: 'furn_trophy_shelf', name: '獎盃展示架', category: ShopCategory.furniture,
      price: 150, description: '展示你成就的黃金獎盃架', emoji: '🏆',
      unlockCondition: '達成Elite等級10次'),

  // ── 刺青 ──
  ShopItem(id: 'tat_rose', name: '玫瑰花臂', category: ShopCategory.tattoo,
      price: 40, description: '精緻優雅的玫瑰花刺青', emoji: '🌹'),
  ShopItem(id: 'tat_dragon', name: '龍紋背刺', category: ShopCategory.tattoo,
      price: 80, description: '氣勢磅礴的東方龍紋', emoji: '🐉'),
  ShopItem(id: 'tat_wave', name: '海浪刺青', category: ShopCategory.tattoo,
      price: 60, description: '葛飾北齋風格海浪', emoji: '🌊'),
  ShopItem(id: 'tat_phoenix', name: '鳳凰刺青', category: ShopCategory.tattoo,
      price: 100, description: '浴火重生的鳳凰刺青', emoji: '🔥',
      unlockCondition: '連續打卡21天'),
  ShopItem(id: 'tat_koi', name: '錦鯉刺青', category: ShopCategory.tattoo,
      price: 90, description: '象徵好運的錦鯉游刺', emoji: '🐠'),
  ShopItem(id: 'tat_geometric', name: '幾何線條', category: ShopCategory.tattoo,
      price: 55, description: '精準的幾何圖案線條刺青', emoji: '🔷'),
  ShopItem(id: 'tat_wolf', name: '狼紋刺青', category: ShopCategory.tattoo,
      price: 85, description: '孤傲嗥叫狼的月夜刺青', emoji: '🐺'),
  ShopItem(id: 'tat_constellation', name: '星座刺青', category: ShopCategory.tattoo,
      price: 50, description: '細膩的十二星座點線刺青', emoji: '✨'),
  ShopItem(id: 'tat_sakura', name: '櫻花刺青', category: ShopCategory.tattoo,
      price: 65, description: '飄落的粉色櫻花刺青', emoji: '🌸'),
  ShopItem(id: 'tat_tribal', name: '部落紋身', category: ShopCategory.tattoo,
      price: 70, description: '原住民傳統部落幾何圖騰', emoji: '⚡'),
  ShopItem(id: 'tat_anchor', name: '船錨刺青', category: ShopCategory.tattoo,
      price: 45, description: '海洋風格船錨', emoji: '⚓'),
  ShopItem(id: 'tat_lion', name: '獅子頭刺青', category: ShopCategory.tattoo,
      price: 95, description: '霸氣的獅王頭像刺青', emoji: '🦁'),

  // ── 臉部 ──
  ShopItem(id: 'face_blush_star', name: '星星腮紅', category: ShopCategory.faceDecal,
      price: 20, description: '可愛的五芒星腮紅', emoji: '⭐'),
  ShopItem(id: 'face_blush_heart', name: '愛心腮紅', category: ShopCategory.faceDecal,
      price: 20, description: '粉嫩的愛心腮紅', emoji: '💗'),
  ShopItem(id: 'face_scar_hero', name: '英雄疤痕', category: ShopCategory.faceDecal,
      price: 30, description: '充滿戰鬥故事的臉部疤痕', emoji: '⚔️'),
  ShopItem(id: 'face_freckles', name: '雀斑', category: ShopCategory.faceDecal,
      price: 15, description: '陽光灑落的自然雀斑', emoji: '☀️'),
  ShopItem(id: 'face_eye_patch', name: '海盜眼罩', category: ShopCategory.faceDecal,
      price: 35, description: '神秘的黑色眼罩', emoji: '🏴‍☠️'),
  ShopItem(id: 'face_gem_forehead', name: '額頭寶石', category: ShopCategory.faceDecal,
      price: 60, description: '第三眼位置的藍寶石', emoji: '💎'),
  ShopItem(id: 'face_circuit_lines', name: '電路紋路', category: ShopCategory.faceDecal,
      price: 80, description: '賽博龐克風格的臉部電路', emoji: '🤖', isLimited: true),
  ShopItem(id: 'face_war_paint', name: '戰鬥彩繪', category: ShopCategory.faceDecal,
      price: 45, description: '原住民風格臉部彩繪', emoji: '🎭'),
  ShopItem(id: 'face_tear_gem', name: '寶石淚痣', category: ShopCategory.faceDecal,
      price: 25, description: '眼下的藍色淚痣', emoji: '💙'),
  ShopItem(id: 'face_cat_whiskers', name: '貓鬚', category: ShopCategory.faceDecal,
      price: 20, description: '可愛的貓咪鬍鬚紋', emoji: '🐱'),

  // ── 限定 ──
  ShopItem(id: 'special_xmas_outfit', name: '聖誕裝', category: ShopCategory.special,
      price: 0, description: '限定節慶聖誕服裝', emoji: '🎅', isLimited: true,
      unlockCondition: '12月達成目標7天'),
  ShopItem(id: 'special_newyear_outfit', name: '新年禮服', category: ShopCategory.special,
      price: 0, description: '閃耀的新年倒數禮服', emoji: '🎆', isLimited: true,
      unlockCondition: '1月份的限定獎勵'),
  ShopItem(id: 'special_champion_aura', name: '冠軍光環', category: ShopCategory.special,
      price: 0, description: '全身散發的金色冠軍光環', emoji: '🏅', isLimited: true,
      unlockCondition: '連續打卡50天'),
  ShopItem(id: 'special_rainbow_trail', name: '彩虹殘影', category: ShopCategory.special,
      price: 0, description: '角色移動時的彩虹特效', emoji: '🌈', isLimited: true,
      unlockCondition: '達成Elite等級20次'),
  ShopItem(id: 'special_pet_cat', name: '隨行貓咪', category: ShopCategory.special,
      price: 500, description: '一隻陪伴你的虛擬小貓', emoji: '🐈', isLimited: true),
  ShopItem(id: 'special_pet_dragon', name: '迷你火龍', category: ShopCategory.special,
      price: 1000, description: '坐在肩膀上的迷你火龍', emoji: '🐲', isLimited: true,
      unlockCondition: '連續打卡100天'),
  ShopItem(id: 'special_first_meal', name: '第一餐紀念章', category: ShopCategory.special,
      price: 0, description: '記錄第一餐的紀念徽章', emoji: '🍽️',
      unlockCondition: '記錄第一餐'),
  ShopItem(id: 'special_health_master', name: '健康達人勳章', category: ShopCategory.special,
      price: 0, description: '連續7天達成Elite', emoji: '💪', isLimited: true,
      unlockCondition: '連續7天達成Elite等級'),
];

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _tabs = ShopCategory.values;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  bool _isEquipped(CharacterAppearance? char, ShopItem item) {
    if (char == null) return false;
    final cat = item.id.split('_').first;
    switch (cat) {
      case 'outfit':
        return char.outfitId == item.id;
      case 'bg':
        return char.backgroundId == item.id;
      case 'acc':
      case 'face':
      case 'furn':
      case 'tat':
      case 'special':
        return char.accessories.contains(item.id);
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final points = provider.profile?.growthPoints ?? 0;
    final owned = provider.ownedItems;
    final character = provider.character;
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
          final items = _catalog.where((i) => i.category == cat).toList();
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🔜', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text('更多 ${cat.label} 即將上架',
                      style: theme.textTheme.titleMedium),
                ],
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              final isOwned = owned.contains(item.id);
              final isEquipped = _isEquipped(character, item);
              return _ShopCard(
                item: item,
                owned: isOwned,
                equipped: isEquipped,
                canAfford: points >= item.price || item.price == 0,
                theme: theme,
                onTap: () => _handleTap(context, provider, item, isOwned, isEquipped),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Future<void> _handleTap(BuildContext context, AppProvider provider,
      ShopItem item, bool owned, bool equipped) async {
    if (item.unlockCondition != null && !owned && item.price == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('解鎖條件：${item.unlockCondition}')),
      );
      return;
    }
    if (!owned) {
      await _buy(context, provider, item);
      return;
    }
    final cat = item.id.split('_').first;
    if (cat == 'hair') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.name} 將在下次生成角色圖片時套用')),
      );
      return;
    }
    if (equipped) {
      await provider.unequipItem(item.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已卸下 ${item.name}')),
        );
      }
    } else {
      await provider.equipItem(item.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ 已裝備 ${item.name}！'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    }
  }

  Future<void> _buy(BuildContext context, AppProvider provider, ShopItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(children: [
          Text(item.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 8),
          Expanded(child: Text(item.name)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.description),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.star, size: 16, color: Colors.amber),
              const SizedBox(width: 4),
              Text('花費 ${item.price} 成長點數',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
          ],
        ),
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

    if (confirm == true && context.mounted) {
      final success = await provider.purchaseItem(item.id, item.price);
      if (context.mounted) {
        if (success) {
          await provider.equipItem(item.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('🎉 購買並裝備 ${item.emoji} ${item.name}！'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('成長點數不足'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class _ShopCard extends StatelessWidget {
  final ShopItem item;
  final bool owned;
  final bool equipped;
  final bool canAfford;
  final ThemeData theme;
  final VoidCallback onTap;

  const _ShopCard({
    required this.item,
    required this.owned,
    required this.equipped,
    required this.canAfford,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: equipped ? 4 : 1,
      shape: equipped
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.primary, width: 2))
          : RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview area
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: equipped
                        ? [
                            theme.colorScheme.primaryContainer,
                            theme.colorScheme.primary.withOpacity(0.3),
                          ]
                        : [
                            theme.colorScheme.surfaceContainerHighest,
                            theme.colorScheme.surfaceContainerHigh,
                          ],
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(item.emoji, style: const TextStyle(fontSize: 52)),
                    if (item.isLimited)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('限定',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    if (item.unlockCondition != null && !owned)
                      Positioned(
                        bottom: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock, size: 10, color: Colors.white),
                              SizedBox(width: 3),
                              Text('解鎖任務',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 9)),
                            ],
                          ),
                        ),
                      ),
                    if (equipped)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check,
                              size: 12, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Info area
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
                      if (item.price > 0)
                        const Icon(Icons.star, size: 13, color: Colors.amber),
                      if (item.price > 0) const SizedBox(width: 2),
                      Text(
                        owned
                            ? '已擁有'
                            : item.price == 0
                                ? '任務解鎖'
                                : '${item.price}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: owned
                              ? Colors.green
                              : item.price == 0
                                  ? Colors.purple
                                  : canAfford
                                      ? Colors.amber.shade700
                                      : Colors.grey,
                        ),
                      ),
                      const Spacer(),
                      if (equipped)
                        Icon(Icons.check_circle,
                            size: 18, color: theme.colorScheme.primary)
                      else if (owned)
                        Icon(Icons.check_circle_outline,
                            size: 18, color: theme.colorScheme.primary)
                      else if (item.unlockCondition != null && item.price == 0)
                        const Icon(Icons.lock_outline,
                            size: 18, color: Colors.purple)
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
}

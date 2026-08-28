enum SkinTone { light, medium, tan, dark }
enum HairStyle { short, medium, long, bun, ponytail, curly }
enum HairColor { black, brown, blonde, red, gray, fantasy }
enum FaceShape { round, oval, sharp }
enum BodyType { slim, normal, athletic, chubby }

class CharacterAppearance {
  SkinTone skinTone;
  HairStyle hairStyle;
  HairColor hairColor;
  FaceShape faceShape;
  String? outfitId;
  String? backgroundId;
  List<String> accessories;
  List<String> tattoos;
  BodyType bodyType;
  double muscleLevel;  // 0.0–1.0, reflects actual progress
  double fatLevel;     // 0.0–1.0, reflects actual progress
  String? gender;

  CharacterAppearance({
    this.skinTone = SkinTone.medium,
    this.hairStyle = HairStyle.short,
    this.hairColor = HairColor.black,
    this.faceShape = FaceShape.oval,
    this.outfitId,
    this.backgroundId,
    List<String>? accessories,
    List<String>? tattoos,
    this.bodyType = BodyType.normal,
    this.muscleLevel = 0.0,
    this.fatLevel = 0.3,
    this.gender,
  }) : accessories = accessories ?? [],
       tattoos = tattoos ?? [];

  Map<String, dynamic> toMap() => {
    'skinTone': skinTone.name,
    'hairStyle': hairStyle.name,
    'hairColor': hairColor.name,
    'faceShape': faceShape.name,
    'outfitId': outfitId,
    'backgroundId': backgroundId,
    'accessories': accessories,
    'tattoos': tattoos,
    'bodyType': bodyType.name,
    'muscleLevel': muscleLevel,
    'fatLevel': fatLevel,
    'gender': gender,
  };

  factory CharacterAppearance.fromMap(Map<String, dynamic> m) => CharacterAppearance(
    skinTone: SkinTone.values.firstWhere((e) => e.name == m['skinTone'],
        orElse: () => SkinTone.medium),
    hairStyle: HairStyle.values.firstWhere((e) => e.name == m['hairStyle'],
        orElse: () => HairStyle.short),
    hairColor: HairColor.values.firstWhere((e) => e.name == m['hairColor'],
        orElse: () => HairColor.black),
    faceShape: FaceShape.values.firstWhere((e) => e.name == m['faceShape'],
        orElse: () => FaceShape.oval),
    outfitId: m['outfitId'] as String?,
    backgroundId: m['backgroundId'] as String?,
    accessories: List<String>.from(m['accessories'] as List? ?? []),
    tattoos: List<String>.from(m['tattoos'] as List? ?? []),
    bodyType: BodyType.values.firstWhere((e) => e.name == m['bodyType'],
        orElse: () => BodyType.normal),
    muscleLevel: (m['muscleLevel'] as num?)?.toDouble() ?? 0.0,
    fatLevel: (m['fatLevel'] as num?)?.toDouble() ?? 0.3,
    gender: m['gender'] as String?,
  );

  CharacterAppearance copyWith({
    SkinTone? skinTone,
    HairStyle? hairStyle,
    HairColor? hairColor,
    FaceShape? faceShape,
    String? outfitId,
    String? backgroundId,
    List<String>? accessories,
    List<String>? tattoos,
    BodyType? bodyType,
    double? muscleLevel,
    double? fatLevel,
    String? gender,
  }) => CharacterAppearance(
    skinTone: skinTone ?? this.skinTone,
    hairStyle: hairStyle ?? this.hairStyle,
    hairColor: hairColor ?? this.hairColor,
    faceShape: faceShape ?? this.faceShape,
    outfitId: outfitId ?? this.outfitId,
    backgroundId: backgroundId ?? this.backgroundId,
    accessories: accessories ?? this.accessories,
    tattoos: tattoos ?? this.tattoos,
    bodyType: bodyType ?? this.bodyType,
    muscleLevel: muscleLevel ?? this.muscleLevel,
    fatLevel: fatLevel ?? this.fatLevel,
    gender: gender ?? this.gender,
  );
}

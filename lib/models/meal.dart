import 'package:uuid/uuid.dart';

class Meal {
  final String id;
  final String profileId;
  final String mealType;
  final String description;
  final double totalCalories;
  final double caloriesMin;
  final double caloriesMax;
  final double protein;
  final double carbs;
  final double fat;
  final String? hiddenCaloriesNote;
  final String? mealTimingNote;
  final String? aiSummary;
  final String? imagePath;
  final DateTime timestamp;

  const Meal({
    required this.id,
    required this.profileId,
    required this.mealType,
    required this.description,
    required this.totalCalories,
    required this.caloriesMin,
    required this.caloriesMax,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.hiddenCaloriesNote,
    this.mealTimingNote,
    this.aiSummary,
    this.imagePath,
    required this.timestamp,
  });

  factory Meal.create({
    required String profileId,
    required String mealType,
    required String description,
    required double totalCalories,
    required double caloriesMin,
    required double caloriesMax,
    required double protein,
    required double carbs,
    required double fat,
    String? hiddenCaloriesNote,
    String? mealTimingNote,
    String? aiSummary,
    String? imagePath,
  }) => Meal(
    id: const Uuid().v4(),
    profileId: profileId,
    mealType: mealType,
    description: description,
    totalCalories: totalCalories,
    caloriesMin: caloriesMin,
    caloriesMax: caloriesMax,
    protein: protein,
    carbs: carbs,
    fat: fat,
    hiddenCaloriesNote: hiddenCaloriesNote,
    mealTimingNote: mealTimingNote,
    aiSummary: aiSummary,
    imagePath: imagePath,
    timestamp: DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'profileId': profileId,
    'mealType': mealType,
    'description': description,
    'totalCalories': totalCalories,
    'caloriesMin': caloriesMin,
    'caloriesMax': caloriesMax,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'hiddenCaloriesNote': hiddenCaloriesNote,
    'mealTimingNote': mealTimingNote,
    'aiSummary': aiSummary,
    'imagePath': imagePath,
    'timestamp': timestamp.toIso8601String(),
  };

  factory Meal.fromMap(Map<String, dynamic> m) => Meal(
    id: m['id'] as String,
    profileId: m['profileId'] as String,
    mealType: m['mealType'] as String,
    description: m['description'] as String,
    totalCalories: (m['totalCalories'] as num).toDouble(),
    caloriesMin: (m['caloriesMin'] as num).toDouble(),
    caloriesMax: (m['caloriesMax'] as num).toDouble(),
    protein: (m['protein'] as num).toDouble(),
    carbs: (m['carbs'] as num).toDouble(),
    fat: (m['fat'] as num).toDouble(),
    hiddenCaloriesNote: m['hiddenCaloriesNote'] as String?,
    mealTimingNote: m['mealTimingNote'] as String?,
    aiSummary: m['aiSummary'] as String?,
    imagePath: m['imagePath'] as String?,
    timestamp: DateTime.parse(m['timestamp'] as String),
  );
}

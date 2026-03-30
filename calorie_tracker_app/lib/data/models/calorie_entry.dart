class CalorieEntry {
  final int? id;
  final DateTime timestamp;
  final String? imagePath;
  final double prediction;
  final double? userAdjustment;

  CalorieEntry({
    this.id,
    required this.timestamp,
    this.imagePath,
    required this.prediction,
    this.userAdjustment,
  });

  double get finalCalories => userAdjustment ?? prediction;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'image_path': imagePath,
      'prediction': prediction,
      'user_adjustment': userAdjustment,
    };
  }

  factory CalorieEntry.fromMap(Map<String, dynamic> map) {
    return CalorieEntry(
      id: map['id'] as int?,
      timestamp: DateTime.parse(map['timestamp'] as String),
      imagePath: map['image_path'] as String?,
      prediction: (map['prediction'] as num).toDouble(),
      userAdjustment: map['user_adjustment'] != null
          ? (map['user_adjustment'] as num).toDouble()
          : null,
    );
  }

  CalorieEntry copyWith({
    int? id,
    DateTime? timestamp,
    String? imagePath,
    double? prediction,
    double? userAdjustment,
  }) {
    return CalorieEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      imagePath: imagePath ?? this.imagePath,
      prediction: prediction ?? this.prediction,
      userAdjustment: userAdjustment ?? this.userAdjustment,
    );
  }
}

class Vehicle {
  final String id;
  final String plate;
  final String type; // SEDAN | CROSSOVER | SUV | COUPE
  final String? nickname;

  const Vehicle({
    required this.id,
    required this.plate,
    required this.type,
    this.nickname,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id'] as String,
        plate: json['plate'] as String,
        type: json['type'] as String,
        nickname: json['nickname'] as String?,
      );

  String get displayName => (nickname != null && nickname!.isNotEmpty) ? nickname! : plate;
}

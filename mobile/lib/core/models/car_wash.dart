class CarWash {
  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String availabilityStatus; // GREEN | YELLOW | RED
  final int nextSlotMinutes;

  const CarWash({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.availabilityStatus,
    required this.nextSlotMinutes,
  });

  factory CarWash.fromJson(Map<String, dynamic> json) => CarWash(
        id: json['id'] as String,
        name: json['name'] as String,
        address: json['address'] as String,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        availabilityStatus: json['availabilityStatus'] as String? ?? 'RED',
        nextSlotMinutes: json['nextSlotMinutes'] as int? ?? 0,
      );
}

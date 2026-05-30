class Booking {
  final String id;
  final String bayId;
  final String status;
  final DateTime startsAt;
  final DateTime endsAt;

  const Booking({
    required this.id,
    required this.bayId,
    required this.status,
    required this.startsAt,
    required this.endsAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'] as String,
        bayId: json['bayId'] as String,
        status: json['status'] as String,
        startsAt: DateTime.parse(json['startsAt'] as String),
        endsAt: DateTime.parse(json['endsAt'] as String),
      );

  bool get isActive => !['COMPLETED', 'CANCELLED'].contains(status);
}

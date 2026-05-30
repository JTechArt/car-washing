class ModeratorBay {
  final String id;
  final String name;
  final String status; // IDLE | OCCUPIED | BLOCKED
  final String? activeBookingId;
  final String? activeBookingStatus; // PENDING | ARRIVED | WASHING | FINISHING

  const ModeratorBay({
    required this.id,
    required this.name,
    required this.status,
    this.activeBookingId,
    this.activeBookingStatus,
  });

  factory ModeratorBay.fromJson(Map<String, dynamic> json) => ModeratorBay(
        id: json['id'] as String,
        name: json['name'] as String,
        status: json['status'] as String,
        activeBookingId: json['activeBookingId'] as String?,
        activeBookingStatus: json['activeBookingStatus'] as String?,
      );

  bool get isIdle => status == 'IDLE';
  bool get isOccupied => status == 'OCCUPIED';
  bool get isBlocked => status == 'BLOCKED';
  bool get hasActiveBooking => activeBookingId != null;

  String? get nextActionLabel => switch (activeBookingStatus) {
        'PENDING' => 'Mark Arrived',
        'ARRIVED' => 'Start Washing',
        'WASHING' => 'Mark Finishing',
        'FINISHING' => 'Complete',
        _ => null,
      };

  String? get nextStatus => switch (activeBookingStatus) {
        'PENDING' => 'ARRIVED',
        'ARRIVED' => 'WASHING',
        'WASHING' => 'FINISHING',
        'FINISHING' => 'COMPLETED',
        _ => null,
      };
}

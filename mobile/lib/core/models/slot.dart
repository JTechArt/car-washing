class Slot {
  final DateTime startsAt;
  final int durationMinutes;
  final int amountAmd;

  const Slot({
    required this.startsAt,
    required this.durationMinutes,
    required this.amountAmd,
  });

  factory Slot.fromJson(Map<String, dynamic> json) => Slot(
        startsAt: DateTime.parse(json['startsAt'] as String),
        durationMinutes: json['durationMinutes'] as int,
        amountAmd: json['amountAmd'] as int,
      );
}

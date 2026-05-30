import 'package:flutter/material.dart';
import '../models/moderator_bay.dart';
import 'walk_in_dialog.dart';

class BayCard extends StatelessWidget {
  final ModeratorBay bay;
  final Future<bool> Function(String bookingId, String status) onUpdateStatus;
  final Future<bool> Function(String bayId, int minutes) onWalkIn;

  const BayCard({
    super.key,
    required this.bay,
    required this.onUpdateStatus,
    required this.onWalkIn,
  });

  Color get _borderColor => switch (bay.status) {
        'IDLE' => const Color(0xFF27AE60),
        'OCCUPIED' => const Color(0xFF1B4F72),
        _ => const Color(0xFFE74C3C),
      };

  Color get _badgeColor => switch (bay.status) {
        'IDLE' => Colors.green,
        'OCCUPIED' => const Color(0xFF1B4F72),
        _ => Colors.red,
      };

  String get _statusLabel => switch (bay.status) {
        'IDLE' => 'Available',
        'OCCUPIED' => bay.activeBookingStatus ?? 'Occupied',
        _ => 'Blocked',
      };

  Color get _actionColor => switch (bay.activeBookingStatus) {
        'PENDING' => Colors.green,
        'ARRIVED' => const Color(0xFF1B4F72),
        'WASHING' => Colors.orange,
        'FINISHING' => Colors.teal,
        _ => Colors.grey,
      };

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Text('$label: ',
                style:
                    const TextStyle(color: Colors.grey, fontSize: 12)),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 12),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: _borderColor, width: 2.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Expanded(
                  child: Text(bay.name,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: _badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_statusLabel,
                      style: TextStyle(
                          color: _badgeColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Body
            if (bay.isIdle && !bay.hasActiveBooking) ...[
              // IDLE with no booking — show walk-in button
              const Expanded(
                child: Center(
                  child: Text('Ready for next vehicle',
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => WalkInDialog(
                    bayName: bay.name,
                    onConfirm: (min) => onWalkIn(bay.id, min),
                  ),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Walk-In'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ] else if (bay.hasActiveBooking) ...[
              // OCCUPIED with booking — show booking info and action
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow(
                        'Booking',
                        '#${bay.activeBookingId!.length >= 8 ? bay.activeBookingId!.substring(0, 8).toUpperCase() : bay.activeBookingId!.toUpperCase()}'),
                    if (bay.activeBookingStatus != null)
                      _infoRow('Status', bay.activeBookingStatus!),
                  ],
                ),
              ),
              const Spacer(),
              if (bay.nextActionLabel != null)
                _ActionButton(
                  label: bay.nextActionLabel!,
                  color: _actionColor,
                  onPressed: () async {
                    await onUpdateStatus(
                        bay.activeBookingId!, bay.nextStatus!);
                  },
                ),
            ] else ...[
              // BLOCKED (walk-in, no booking entity)
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Walk-in customer',
                        style: TextStyle(color: Colors.grey, fontSize: 14)),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () async => onWalkIn(bay.id, 0),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44)),
                child: const Text('Release Bay'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final Future<void> Function() onPressed;
  final Color color;

  const _ActionButton({
    required this.label,
    required this.onPressed,
    required this.color,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: _loading
          ? null
          : () async {
              setState(() => _loading = true);
              try {
                await widget.onPressed();
              } finally {
                if (mounted) setState(() => _loading = false);
              }
            },
      style: FilledButton.styleFrom(
        backgroundColor: widget.color,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
      ),
      child: _loading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : Text(widget.label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15)),
    );
  }
}

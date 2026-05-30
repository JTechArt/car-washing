import 'package:flutter/material.dart';

class WalkInDialog extends StatefulWidget {
  final String bayName;
  final Future<bool> Function(int minutes) onConfirm;

  const WalkInDialog({
    super.key,
    required this.bayName,
    required this.onConfirm,
  });

  @override
  State<WalkInDialog> createState() => _WalkInDialogState();
}

class _WalkInDialogState extends State<WalkInDialog> {
  int _selectedMinutes = 25;
  bool _loading = false;

  static const _options = [15, 25, 45, 60];

  Future<void> _confirm() async {
    setState(() => _loading = true);
    try {
      await widget.onConfirm(_selectedMinutes);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Walk-In — ${widget.bayName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Estimated duration:',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            children: _options
                .map((min) => ChoiceChip(
                      label: Text('$min min'),
                      selected: _selectedMinutes == min,
                      onSelected: (_) =>
                          setState(() => _selectedMinutes = min),
                      selectedColor:
                          const Color(0xFF1B4F72).withValues(alpha: 0.15),
                      checkmarkColor: const Color(0xFF1B4F72),
                    ))
                .toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _loading ? null : _confirm,
          style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1B4F72)),
          child: _loading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Block Bay'),
        ),
      ],
    );
  }
}

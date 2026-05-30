import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'garage_provider.dart';

const _vehicleTypes = ['SEDAN', 'CROSSOVER', 'SUV', 'COUPE'];

class AddVehicleScreen extends ConsumerStatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  ConsumerState<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends ConsumerState<AddVehicleScreen> {
  final _plateCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  String _selectedType = 'SEDAN';
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _plateCtrl.dispose();
    _nicknameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_plateCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Plate number is required');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(garageProvider.notifier).addVehicle(
            _plateCtrl.text.trim(),
            _selectedType,
            _nicknameCtrl.text.trim().isEmpty
                ? null
                : _nicknameCtrl.text.trim(),
          );
      if (mounted) context.pop();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Vehicle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Vehicle Type',
                style:
                    TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: _vehicleTypes
                  .map((type) => FilterChip(
                        label: Text(type),
                        selected: _selectedType == type,
                        onSelected: (_) =>
                            setState(() => _selectedType = type),
                        selectedColor:
                            const Color(0xFF1B4F72).withValues(alpha: 0.15),
                        checkmarkColor: const Color(0xFF1B4F72),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _plateCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Plate Number *',
                hintText: 'AM 1234 AB',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nicknameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nickname (optional)',
                hintText: 'My Sedan',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: TextStyle(color: Colors.red.shade700)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1B4F72),
                minimumSize: const Size.fromHeight(52),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Add to Garage',
                      style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

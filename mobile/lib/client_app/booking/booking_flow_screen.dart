import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../garage/garage_provider.dart';
import '../../core/models/vehicle.dart';
import '../../core/models/slot.dart';
import 'booking_provider.dart';

const _serviceTypes = ['EXTERIOR', 'INTERIOR', 'FULL', 'PREMIUM'];
const _serviceLabels = {
  'EXTERIOR': 'Exterior Wash',
  'INTERIOR': 'Interior Clean',
  'FULL': 'Full Wash',
  'PREMIUM': 'Premium Detail',
};

class BookingFlowScreen extends ConsumerStatefulWidget {
  final String carWashId;
  const BookingFlowScreen({super.key, required this.carWashId});

  @override
  ConsumerState<BookingFlowScreen> createState() =>
      _BookingFlowScreenState();
}

class _BookingFlowScreenState extends ConsumerState<BookingFlowScreen> {
  Vehicle? _selectedVehicle;
  String _selectedService = 'EXTERIOR';
  Slot? _selectedSlot;

  SlotQuery get _slotQuery => SlotQuery(
        carWashId: widget.carWashId,
        vehicleType: _selectedVehicle?.type ?? 'SEDAN',
        serviceType: _selectedService,
      );

  Future<void> _confirm() async {
    if (_selectedVehicle == null || _selectedSlot == null) return;
    try {
      final booking =
          await ref.read(bookingNotifierProvider.notifier).createBooking(
                carWashId: widget.carWashId,
                vehicleId: _selectedVehicle!.id,
                serviceType: _selectedService,
                slotStartsAt: _selectedSlot!.startsAt,
              );
      if (mounted) {
        context.go('/confirmed?bookingId=${booking.id}&name=Car+Wash');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Booking failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(garageProvider);
    final slotsAsync = ref.watch(slotsProvider(_slotQuery));
    final bookingState = ref.watch(bookingNotifierProvider);
    final fmt = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Book a Wash')),
      body: vehiclesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('Error loading vehicles: $e')),
        data: (vehicles) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('1. Select your vehicle',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              if (vehicles.isEmpty)
                OutlinedButton.icon(
                  onPressed: () => context.push('/garage/add'),
                  icon: const Icon(Icons.add),
                  label: const Text('Add a vehicle first'),
                )
              else
                RadioGroup<Vehicle>(
                  groupValue: _selectedVehicle,
                  onChanged: (val) => setState(() {
                    _selectedVehicle = val;
                    _selectedSlot = null;
                  }),
                  child: Column(
                    children: vehicles
                        .map((v) => RadioListTile<Vehicle>(
                              value: v,
                              title: Text(v.displayName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text('${v.plate} · ${v.type}'),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ))
                        .toList(),
                  ),
                ),
              const Divider(height: 32),
              const Text('2. Select service',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: _serviceTypes
                    .map((s) => ChoiceChip(
                          label: Text(_serviceLabels[s] ?? s),
                          selected: _selectedService == s,
                          onSelected: (_) => setState(() {
                            _selectedService = s;
                            _selectedSlot = null;
                          }),
                        ))
                    .toList(),
              ),
              const Divider(height: 32),
              const Text('3. Pick a time slot',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              if (_selectedVehicle == null)
                const Text('Select a vehicle first',
                    style: TextStyle(color: Colors.grey))
              else
                slotsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                  data: (slots) {
                    if (slots.isEmpty) {
                      return const Text('No slots available',
                          style: TextStyle(color: Colors.grey));
                    }
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: slots.take(6).map((slot) {
                        final selected = _selectedSlot?.startsAt ==
                            slot.startsAt;
                        return ChoiceChip(
                          label: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                  fmt.format(
                                      slot.startsAt.toLocal()),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              Text('${slot.durationMinutes} min',
                                  style:
                                      const TextStyle(fontSize: 11)),
                              Text('${slot.amountAmd} ֏',
                                  style:
                                      const TextStyle(fontSize: 11)),
                            ],
                          ),
                          selected: selected,
                          onSelected: (_) =>
                              setState(() => _selectedSlot = slot),
                        );
                      }).toList(),
                    );
                  },
                ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: (_selectedVehicle != null &&
                        _selectedSlot != null &&
                        !bookingState.isLoading)
                    ? _confirm
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4F72),
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: bookingState.isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(
                        _selectedSlot != null
                            ? 'Confirm — ${fmt.format(_selectedSlot!.startsAt.toLocal())}'
                            : 'Confirm Booking',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

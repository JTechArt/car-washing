import 'package:flutter_test/flutter_test.dart';
import 'package:lva_mobile/core/models/vehicle.dart';

void main() {
  test('Vehicle displayName prefers nickname', () {
    const v = Vehicle(id: '1', plate: 'AM1234', type: 'SEDAN', nickname: 'Work Car');
    expect(v.displayName, 'Work Car');
  });

  test('Vehicle displayName uses plate when nickname is null', () {
    const v = Vehicle(id: '2', plate: 'AM9999', type: 'SUV');
    expect(v.displayName, 'AM9999');
  });

  test('Vehicle displayName uses plate when nickname is empty', () {
    const v = Vehicle(id: '3', plate: 'AM8888', type: 'COUPE', nickname: '');
    expect(v.displayName, 'AM8888');
  });
}

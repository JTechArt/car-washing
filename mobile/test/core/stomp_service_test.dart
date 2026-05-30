import 'package:flutter_test/flutter_test.dart';
import 'package:lva_mobile/core/websocket/stomp_service.dart';

void main() {
  test('stompService returns same singleton instance', () {
    expect(identical(stompService, stompService), isTrue);
  });

  test('disconnect can be called safely when not connected', () {
    expect(() => stompService.disconnect(), returnsNormally);
  });
}

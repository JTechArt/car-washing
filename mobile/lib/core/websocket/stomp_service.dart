import 'dart:convert';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_handler.dart';
import '../config.dart';
import '../storage/auth_storage.dart';

typedef BayStatusCallback = void Function(String bayId, String status);

class StompService {
  StompClient? _client;
  final Map<String, StompUnsubscribe> _subscriptions = {};

  Future<void> connect() async {
    if (_client?.connected == true) return;
    final token = await AuthStorage.getToken();
    _client = StompClient(
      config: StompConfig(
        url: AppConfig.wsUrl,
        stompConnectHeaders:
            token != null ? {'Authorization': 'Bearer $token'} : {},
        webSocketConnectHeaders:
            token != null ? {'Authorization': 'Bearer $token'} : {},
        reconnectDelay: const Duration(seconds: 5),
        onConnect: (_) {},
        onDisconnect: (_) {},
        onStompError: (frame) {},
        onWebSocketError: (_) {},
      ),
    );
    _client!.activate();
  }

  void subscribeToBayUpdates(String carWashId, BayStatusCallback onUpdate) {
    final topic = '/topic/carwash/$carWashId/bays';
    if (_subscriptions.containsKey(topic)) return;
    _client?.subscribe(
      destination: topic,
      callback: (frame) {
        if (frame.body == null) return;
        final data = jsonDecode(frame.body!) as Map<String, dynamic>;
        onUpdate(data['bayId'] as String, data['status'] as String);
      },
    );
  }

  void unsubscribeFromCarWash(String carWashId) {
    final topic = '/topic/carwash/$carWashId/bays';
    _subscriptions.remove(topic)?.call();
  }

  void disconnect() {
    _subscriptions.clear();
    _client?.deactivate();
    _client = null;
  }
}

final _stompSingleton = StompService();
StompService get stompService => _stompSingleton;

class AppConfig {
  static const String apiBaseUrl = 'http://localhost:9080';
  // Raw WebSocket endpoint (bypasses SockJS negotiation)
  static const String wsUrl = 'ws://localhost:9080/ws/websocket';
  static const String tokenKey = 'lva_jwt';
}

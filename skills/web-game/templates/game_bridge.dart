import 'dart:convert';
import 'dart:developer';

/// Routes messages from the web game (game/src/bridge.ts) to the app.
/// Kept apart from the WebView so it can be tested without one.
class GameBridge {
  const new({required this.onHaptic});

  final void Function() onHaptic;

  /// JavaScript channel: the game calls window.logspace.postMessage(json).
  static const channelName = 'logspace';

  void handle(Object? raw) {
    final Object? message;
    try {
      message = raw is String ? jsonDecode(raw) : null;
    } on FormatException {
      log('invalid json from game', name: 'GameBridge');
      return;
    }
    if (message is! Map<String, Object?>) return;
    switch (message['type']) {
      case 'haptic':
        onHaptic();
      case 'ready':
        break;
      default:
        log('unknown message ${message['type']}', name: 'GameBridge');
    }
  }

  /// JavaScript that delivers [message] to the game.
  static String deliver(Map<String, Object?> message) =>
      'window.logspaceBridge && '
      'window.logspaceBridge.receive(${jsonEncode(message)})';
}

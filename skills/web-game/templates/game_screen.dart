import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Routes messages coming from the game to the app services.
/// Kept separate from the widget so it can be tested without a WebView.
class GameBridge {
  GameBridge({required this.onAnalytics, required this.onRewarded, required this.onInterstitial});

  final void Function(String name, Map<String, Object?> params) onAnalytics;
  final Future<bool> Function(String placement) onRewarded;
  final void Function(String placement) onInterstitial;

  /// Returns the reply to send to the game, or null.
  Future<Map<String, Object?>?> handle(String raw) async {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      log('game bridge: invalid json', name: 'GameBridge');
      return null;
    }
    if (decoded is! Map<String, Object?>) return null;
    switch (decoded['type']) {
      case 'analytics':
        onAnalytics(
          decoded['name']! as String,
          (decoded['params'] as Map<String, Object?>?) ?? const {},
        );
      case 'showRewarded':
        final placement = decoded['placement']! as String;
        final rewarded = await onRewarded(placement);
        return {'type': 'rewardResult', 'placement': placement, 'rewarded': rewarded};
      case 'showInterstitial':
        onInterstitial(decoded['placement']! as String);
      case 'ready':
      case 'haptic':
        break;
      default:
        log('game bridge: unknown message ${decoded['type']}', name: 'GameBridge');
    }
    return null;
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({required this.bridge, required this.locale, super.key});

  final GameBridge bridge;
  final String locale;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static final _server = InAppLocalhostServer(documentRoot: 'assets/game', port: 8642);
  InAppWebViewController? _controller;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onPause: () => _send({'type': 'pause'}),
      onResume: () => _send({'type': 'resume'}),
    );
    if (!_server.isRunning()) _server.start();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _send(Map<String, Object?> message) async {
    await _controller?.evaluateJavascript(
      source: 'window.logspaceBridge && window.logspaceBridge.receive(${jsonEncode(message)})',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri('http://localhost:8642/index.html')),
        initialSettings: InAppWebViewSettings(
          mediaPlaybackRequiresUserGesture: false,
          supportZoom: false,
          disableContextMenu: true,
          transparentBackground: true,
        ),
        onWebViewCreated: (controller) {
          _controller = controller
            ..addJavaScriptHandler(
              handlerName: 'logspace',
              callback: (args) async {
                final reply = await widget.bridge.handle(args.first as String);
                if (reply != null) await _send(reply);
              },
            );
        },
        onLoadStop: (_, _) => _send({'type': 'setLocale', 'locale': widget.locale}),
      ),
    );
  }
}

import 'package:<idSegment>/features/game/asset_server.dart';
import 'package:<idSegment>/features/game/game_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Hosts the Phaser game (built into assets/game by scripts/build-game.sh)
/// in the official webview_flutter, served by [AssetServer].
class GameScreen extends StatefulWidget {
  const new({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const _bridge = GameBridge(onHaptic: HapticFeedback.lightImpact);
  static const _background = Color(0xFF0B1026);

  final _server = AssetServer();
  late final AppLifecycleListener _lifecycle;
  late final WebViewController _controller = WebViewController()
    ..setBackgroundColor(_background)
    ..addJavaScriptChannel(
      GameBridge.channelName,
      onMessageReceived: (message) => _bridge.handle(message.message),
    );
  Future<void>? _ready;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onPause: () => _send({'type': 'pause'}),
      onResume: () => _send({'type': 'resume'}),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Loaded once, with the app's language (not the WebView's).
    _ready ??= _load(Localizations.localeOf(context).toLanguageTag());
  }

  Future<void> _load(String locale) async {
    final url = await _server.start();
    await _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await _controller.loadRequest(
      url.replace(queryParameters: {'lang': locale}),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _server.stop().ignore();
    super.dispose();
  }

  Future<void> _send(Map<String, Object?> message) =>
      _controller.runJavaScript(GameBridge.deliver(message));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(backgroundColor: Colors.transparent),
      extendBodyBehindAppBar: true,
      body: FutureBuilder<void>(
        future: _ready,
        builder: (context, snapshot) =>
            snapshot.connectionState == ConnectionState.done
            ? WebViewWidget(controller: _controller)
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

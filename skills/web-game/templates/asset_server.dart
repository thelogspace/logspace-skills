import 'dart:io';

import 'package:flutter/services.dart';

/// Lists the bundled asset keys (injectable for tests).
typedef ListAssets = Future<Set<String>> Function();

Future<Set<String>> _bundledAssets() async =>
    (await AssetManifest.loadFromAssetBundle(rootBundle)).listAssets().toSet();

/// Serves the bundled web game (assets/game) on localhost. ES modules and
/// fetch don't work over file://, so the WebView loads it over HTTP.
/// Loopback only, random free port, and only files listed in the asset
/// manifest are served (a whitelist: nothing outside assets/game leaks).
class AssetServer {
  new({
    this.root = 'assets/game',
    AssetBundle? bundle,
    this.listAssets = _bundledAssets,
  }) : _bundle = bundle ?? rootBundle;

  final String root;
  final AssetBundle _bundle;
  final ListAssets listAssets;
  HttpServer? _server;
  Set<String> _files = const {};

  static const _types = <String, String>{
    'html': 'text/html; charset=utf-8',
    'js': 'text/javascript; charset=utf-8',
    'mjs': 'text/javascript; charset=utf-8',
    'css': 'text/css; charset=utf-8',
    'json': 'application/json',
    'svg': 'image/svg+xml',
    'png': 'image/png',
    'jpg': 'image/jpeg',
    'webp': 'image/webp',
    'mp3': 'audio/mpeg',
    'm4a': 'audio/mp4',
    'ogg': 'audio/ogg',
    'wav': 'audio/wav',
    'woff2': 'font/woff2',
    'wasm': 'application/wasm',
  };

  /// Starts once and returns the game's URL.
  Future<Uri> start() async {
    var server = _server;
    if (server == null) {
      _files = (await listAssets()).where((k) => k.startsWith(root)).toSet();
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _server = server;
      server.listen(_handle);
    }
    return Uri.parse('http://127.0.0.1:${server.port}/index.html');
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  Future<void> _handle(HttpRequest request) async {
    final response = request.response;
    final path = request.uri.path == '/' ? '/index.html' : request.uri.path;
    final key = '$root$path';
    if (_files.contains(key)) {
      final data = await _bundle.load(key);
      final type = _types[path.split('.').last] ?? 'application/octet-stream';
      response.headers.set(HttpHeaders.contentTypeHeader, type);
      response.add(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
    } else {
      response.statusCode = HttpStatus.notFound;
    }
    await response.close();
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:<idSegment>/features/game/asset_server.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeBundle extends CachingAssetBundle {
  new(this.files);

  final Map<String, String> files;

  @override
  Future<ByteData> load(String key) async {
    final content = files[key];
    if (content == null) throw StateError('test asked for $key');
    return ByteData.sublistView(utf8.encode(content));
  }
}

void main() {
  late AssetServer server;
  late Uri url;
  final client = HttpClient();

  setUp(() async {
    final files = {
      'assets/game/index.html': '<html></html>',
      'assets/game/assets/app.js': 'console.log(1)',
      'assets/brand.json': '{}', // bundled, but outside the game root
    };
    server = AssetServer(
      bundle: FakeBundle(files),
      listAssets: () async => files.keys.toSet(),
    );
    url = await server.start();
  });

  tearDown(() => server.stop());
  tearDownAll(() => client.close(force: true));

  Future<HttpClientResponse> get(String path) async {
    final request = await client.getUrl(url.resolve(path));
    final response = await request.close();
    return response;
  }

  test('listens on loopback only, on a free port', () {
    expect(url.host, '127.0.0.1');
    expect(url.port, isNonZero);
    expect(url.path, '/index.html');
  });

  test('start twice returns the same server', () async {
    expect(await server.start(), url);
  });

  test('serves files with their content type', () async {
    final html = await get('/index.html');
    expect(html.statusCode, HttpStatus.ok);
    expect(html.headers.contentType?.mimeType, 'text/html');
    expect(await html.transform(utf8.decoder).join(), '<html></html>');

    final js = await get('/assets/app.js');
    expect(js.headers.contentType?.mimeType, 'text/javascript');
    await js.drain<void>();
  });

  test('missing files are 404', () async {
    final response = await get('/nope.png');
    expect(response.statusCode, HttpStatus.notFound);
    await response.drain<void>();
  });

  test('other bundled assets are not served', () async {
    final response = await get('/../brand.json');
    expect(response.statusCode, HttpStatus.notFound);
    await response.drain<void>();
  });

  test('a path outside the game folder is never served', () async {
    // Encoded dots survive client-side normalization and reach the server.
    final response = await get('/%2E%2E/pubspec.yaml');
    expect(response.statusCode, isNot(HttpStatus.ok));
    await response.drain<void>();
  });
}

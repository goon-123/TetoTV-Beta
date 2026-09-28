import 'dart:io';

import 'package:anime_tv/core/platform/android_tv_bridge.dart';
import 'package:anime_tv/features/marketplace/data/typescript_compiler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_js/quickjs/quickjs_runtime2.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('iOS native storage, version and extension runtime', (
    tester,
  ) async {
    expect(
      Platform.isIOS,
      isTrue,
      reason: 'Run this test on an iOS simulator.',
    );
    final version = await AndroidTvBridge.instance.getAppVersion();
    expect(version.name, isNot('unknown'));

    const storage = FlutterSecureStorage();
    const key = 'tetotv_ios_port_smoke_test';
    try {
      await storage.write(key: key, value: 'round-trip');
      expect(await storage.read(key: key), 'round-trip');
    } finally {
      await storage.delete(key: key);
    }

    final directory = await getApplicationSupportDirectory();
    expect(await directory.exists(), isTrue);
    final database = await openDatabase(inMemoryDatabasePath);
    try {
      await database.execute('CREATE TABLE smoke (value TEXT)');
      await database.insert('smoke', {'value': 'round-trip'});
      expect((await database.query('smoke')).single['value'], 'round-trip');
    } finally {
      await database.close();
    }

    final runtime = QuickJsRuntime2(timeout: 100, memoryLimit: 8 * 1024 * 1024);
    try {
      expect(runtime.evaluate('21 * 2').stringResult, '42');
      expect(runtime.evaluate('while (true) {}').isError, isTrue);
    } finally {
      runtime.dispose();
    }
    // Exercise the real bundled Sucrase transformer, not just a toy JS eval.
    final compiled = await AddonTypescriptCompiler().compile(
      'const episode: number = 3; class Provider { search() { return episode; } }',
    );
    expect(compiled, contains('Provider'));
    expect(compiled, isNot(contains(': number')));
  });

  testWidgets(
    'bundled MPV decodes the local fixture',
    (tester) async {
      MediaKit.ensureInitialized();
      final player = Player();
      final controller = VideoController(player);
      final errors = <String>[];
      final subscription = player.stream.error.listen(errors.add);
      try {
        // Hosted simulators have no audio output device. Decode audio into the
        // null sink only for CI; normal simulator/device runs still use audio.
        // Audible output must also be checked on a physical iPhone.
        if (const bool.fromEnvironment('TETOTV_TEST_HEADLESS_AUDIO')) {
          final platform = player.platform;
          expect(platform, isA<NativePlayer>());
          await (platform as NativePlayer).setProperty('ao', 'null');
        }
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: Video(controller: controller)),
          ),
        );
        final hasDuration = player.stream.duration
            .firstWhere((duration) => duration > Duration.zero)
            .timeout(const Duration(seconds: 30));
        await player.open(
          Media('asset:///assets/videos/mpv_smoke.mp4'),
          play: false,
        );
        await hasDuration;
        final advances = player.stream.position
            .firstWhere(
              (position) => position > const Duration(milliseconds: 100),
            )
            .timeout(const Duration(seconds: 30));
        await player.play();
        await advances;
        expect(errors, isEmpty);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await subscription.cancel();
        await player.dispose();
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

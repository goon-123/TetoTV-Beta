import 'package:anime_tv/features/settings/application/settings_preferences_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'iOS starts with MPV and rejects saved Android native preferences',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        'player_preferred_engine': 'external',
        'player_external_handoff_enabled': 'true',
        'player_external_default_package': 'org.videolan.vlc',
        'player_external_default_label': 'VLC',
        'streaming_direct_torrent_enabled': 'true',
      });
      final controller = SettingsPreferencesController(
        const FlutterSecureStorage(),
        platform: TargetPlatform.iOS,
      );
      addTearDown(controller.dispose);
      expect(controller.state.preferredPlayer, PreferredPlayer.mpv);
      await controller.load();
      expect(controller.state.preferredPlayer, PreferredPlayer.mpv);
      expect(controller.state.externalPlayerEnabled, isFalse);
      expect(controller.state.selectedExternalPlayerPackage, isNull);
      expect(controller.state.directTorrentStreamingEnabled, isFalse);

      await controller.setMedia3SurfaceViewEnabled(true);
      await controller.setPreferredPlayer(PreferredPlayer.media3);
      await controller.resetAppearance();
      expect(controller.state.preferredPlayer, PreferredPlayer.mpv);
      expect(controller.state.media3SurfaceViewEnabled, isFalse);
    },
  );

  test('Android keeps its existing player choices', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final controller = SettingsPreferencesController(
      const FlutterSecureStorage(),
      platform: TargetPlatform.android,
    );
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.state.preferredPlayer, PreferredPlayer.media3);
    await controller.setPreferredPlayer(PreferredPlayer.mpv);
    expect(controller.state.preferredPlayer, PreferredPlayer.mpv);
  });
}

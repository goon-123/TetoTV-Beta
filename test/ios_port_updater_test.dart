import 'dart:io';

import 'package:anime_tv/features/settings/application/app_update_controller.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _ForbiddenApkSource extends AppReleaseSource {
  @override
  Future<AppReleaseInfo> latest({required List<String> deviceAbis}) async =>
      throw StateError('An iOS build must never request Android releases.');

  @override
  Future<void> download({
    required AppReleaseInfo release,
    required String destination,
    required void Function(int, int) onProgress,
  }) async => throw StateError('An iOS build must never download an APK.');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('iOS does not check, download or install Android updates', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final controller = AppUpdateController(
      const FlutterSecureStorage(),
      _ForbiddenApkSource(),
      () async => '0.1.0+1',
      () async => throw StateError('Android ABI lookup on iOS'),
      () async => Directory.systemTemp,
      (_) async => throw StateError('Android installer on iOS'),
      canInstallUpdates: false,
    );
    addTearDown(controller.dispose);
    await controller.checkForUpdates(automatic: true);
    await controller.checkForUpdates();
    await controller.enableDeveloperMode();
    await controller.refreshReleaseHistory();
    await controller.downloadUpdate();
    await controller.installDownloadedUpdate();
    expect(controller.state.phase, AppUpdatePhase.idle);
    expect(controller.state.automaticUpdates, isFalse);
    expect(controller.state.releaseHistory, isEmpty);
    expect(controller.state.message, contains('sideloading'));
  });
}

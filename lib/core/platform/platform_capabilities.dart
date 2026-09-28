import 'package:flutter/foundation.dart';

/// Device capabilities for the first iPhone/iPad port.
///
/// Android native integrations remain unavailable until they have an iOS
/// implementation. A saved Android preference cannot make them available.
bool get isIosPort => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

bool get supportsApkUpdates =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

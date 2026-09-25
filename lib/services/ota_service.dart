import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

class OtaVersionInfo {
  final String currentVersion;
  final String latestVersion;
  final bool updateAvailable;
  final String releaseNotes;
  final String downloadUrl;

  OtaVersionInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.updateAvailable,
    required this.releaseNotes,
    required this.downloadUrl,
  });
}

class OtaService extends ChangeNotifier {
  OtaVersionInfo _versionInfo = OtaVersionInfo(
    currentVersion: AppConfig.version,
    latestVersion: 'v1.1.0',
    updateAvailable: true,
    releaseNotes: '• Enhanced FEFO Batch Auto-Selection\n• Schedule H1 Narcotics PIN Security Lock\n• 1-Click Direct WhatsApp Share Integration',
    downloadUrl: 'https://billsprout.online/updates/v1.1.0.apk',
  );

  OtaVersionInfo get versionInfo => _versionInfo;

  void applyUpdate() {
    _versionInfo = OtaVersionInfo(
      currentVersion: 'v1.1.0',
      latestVersion: 'v1.1.0',
      updateAvailable: false,
      releaseNotes: 'Up to date',
      downloadUrl: '',
    );
    notifyListeners();
  }
}

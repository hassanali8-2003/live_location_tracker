import 'dart:io';

class TrackingIdentity {
  const TrackingIdentity({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
  });

  final String deviceId;
  final String deviceName;
  final String platform;

  static Future<TrackingIdentity> current() async {
    final platform = Platform.operatingSystem;
    final hostname = _sanitize(Platform.localHostname);
    final versionHash = Platform.operatingSystemVersion.hashCode
        .abs()
        .toRadixString(16)
        .padLeft(6, '0');

    final deviceName = hostname.isEmpty ? '${platform}_device' : hostname;
    final deviceId = '${platform}_${deviceName}_$versionHash';

    return TrackingIdentity(
      deviceId: deviceId,
      deviceName: deviceName,
      platform: platform,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'platform': platform,
    };
  }

  static String _sanitize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}

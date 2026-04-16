import 'dart:async';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'tracking_identity.dart';

class TrackedDevice {
  const TrackedDevice({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.position,
    required this.timestamp,
    required this.isOnline,
    this.socketId,
    this.accuracy,
    this.speed,
  });

  final String deviceId;
  final String deviceName;
  final String platform;
  final LatLng position;
  final DateTime timestamp;
  final bool isOnline;
  final String? socketId;
  final double? accuracy;
  final double? speed;

  factory TrackedDevice.fromMap(Map<String, dynamic> map) {
    return TrackedDevice(
      deviceId: (map['deviceId'] ?? map['userId'] ?? 'unknown').toString(),
      deviceName: (map['deviceName'] ?? map['userId'] ?? 'Unknown Device')
          .toString(),
      platform: (map['platform'] ?? 'unknown').toString(),
      position: LatLng(
        (map['lat'] as num?)?.toDouble() ?? 0,
        (map['lng'] as num?)?.toDouble() ?? 0,
      ),
      timestamp:
          DateTime.tryParse((map['timestamp'] ?? '').toString()) ??
          DateTime.now(),
      isOnline: map['isOnline'] != false,
      socketId: map['socketId']?.toString(),
      accuracy: (map['accuracy'] as num?)?.toDouble(),
      speed: (map['speed'] as num?)?.toDouble(),
    );
  }
}

class SocketService {
  SocketService._internal();

  static final SocketService _instance = SocketService._internal();

  factory SocketService() => _instance;

  io.Socket? _socket;
  final StreamController<Map<String, TrackedDevice>> _devicesController =
      StreamController<Map<String, TrackedDevice>>.broadcast();
  final Map<String, TrackedDevice> _devices = {};

  Stream<Map<String, TrackedDevice>> get devicesStream =>
      _devicesController.stream;

  Map<String, TrackedDevice> get devices => Map.unmodifiable(_devices);

  bool get isConnected => _socket?.connected ?? false;

  void connect(String serverUrl, TrackingIdentity identity) {
    _socket?.dispose();
    _socket = io.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'reconnection': true,
      'reconnectionAttempts': 999999,
      'reconnectionDelay': 2000,
    });

    _socket!.onConnect((_) {
      _socket!.emit('register', identity.toMap());
    });

    _socket!.on('devicesSnapshot', _handleSnapshot);
    _socket!.on('allLocations', _handleLegacyAllLocations);
    _socket!.on('locationChanged', _handleSingleDeviceUpdate);
    _socket!.onDisconnect((_) {});

    _socket!.connect();
  }

  void sendLocation(
    TrackingIdentity identity,
    LatLng position, {
    double? accuracy,
    double? speed,
  }) {
    if (!isConnected) {
      return;
    }

    _socket!.emit('updateLocation', {
      ...identity.toMap(),
      'lat': position.latitude,
      'lng': position.longitude,
      'accuracy': accuracy,
      'speed': speed,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
  }

  void _handleSnapshot(dynamic data) {
    if (data is! List) {
      return;
    }

    _devices
      ..clear()
      ..addEntries(
        data.whereType<Map>().map((item) {
          final device = TrackedDevice.fromMap(Map<String, dynamic>.from(item));
          return MapEntry(device.deviceId, device);
        }),
      );

    _devicesController.add(Map.unmodifiable(_devices));
  }

  void _handleLegacyAllLocations(dynamic data) {
    if (data is! Map) {
      return;
    }

    final parsed = <String, TrackedDevice>{};
    for (final entry in data.entries) {
      if (entry.value is Map) {
        final payload = Map<String, dynamic>.from(entry.value);
        payload.putIfAbsent('deviceId', () => entry.key.toString());
        parsed[entry.key.toString()] = TrackedDevice.fromMap(payload);
      }
    }

    _devices
      ..clear()
      ..addAll(parsed);
    _devicesController.add(Map.unmodifiable(_devices));
  }

  void _handleSingleDeviceUpdate(dynamic data) {
    if (data is! Map) {
      return;
    }

    final device = TrackedDevice.fromMap(Map<String, dynamic>.from(data));
    _devices[device.deviceId] = device;
    _devicesController.add(Map.unmodifiable(_devices));
  }

  void dispose() {
    _socket?.dispose();
    _socket = null;
  }
}

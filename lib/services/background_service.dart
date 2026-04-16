import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'app_config.dart';
import 'socket_service.dart';
import 'tracking_identity.dart';

class BackgroundTrackingService {
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'geotrack_foreground',
      'GeoTrack Live Tracking',
      description: 'This channel is used for real-time tracking.',
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'geotrack_foreground',
        initialNotificationTitle: 'GeoTrack Active',
        initialNotificationContent: 'Sending location to supervisor...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    service.startService();
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    final socketService = SocketService();
    final identity = await TrackingIdentity.current();
    socketService.connect(AppConfig.socketServerUrl, identity);

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // Tracking loop: Send location every 60 seconds (Heartbeat)
    Timer.periodic(const Duration(seconds: 60), (timer) async {
      await _sendCurrentLocation(socketService, identity, service);
    });

    // Live Movement: Send location immediately when moving (Distance filter: 10m)
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
      socketService.sendLocation(
        identity,
        LatLng(position.latitude, position.longitude),
        accuracy: position.accuracy,
        speed: position.speed,
      );
      
      _updateNotification(service, "Moving | Live Update");
    });
  }

  static Future<void> _sendCurrentLocation(
    SocketService socketService,
    TrackingIdentity identity,
    ServiceInstance service,
  ) async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      socketService.sendLocation(
        identity,
        LatLng(position.latitude, position.longitude),
        accuracy: position.accuracy,
        speed: position.speed,
      );

      _updateNotification(service, "Last Sync: ${DateTime.now().hour}:${DateTime.now().minute}");
    } catch (e) {
      print("Error in background tracking: $e");
    }
  }

  static void _updateNotification(ServiceInstance service, String status) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: "GeoTrack Live",
          content: status,
        );
      }
    }
  }
}

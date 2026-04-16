import 'dart:async';
import 'dart:ui';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../home_screen.dart';

class MockDataService {
  static final List<UserTracker> _initialUsers = [
    UserTracker(
      id: "1",
      name: "Marcus Wright",
      position: const LatLng(37.7849, -122.4094),
      isOnline: true,
      lastUpdated: "Just now",
      avatar: "https://i.pravatar.cc/150?u=marcus",
      color: const Color(0xFF6C63FF),
    ),
    UserTracker(
      id: "2",
      name: "Sarah Chen",
      position: const LatLng(37.7749, -122.4294),
      isOnline: true,
      lastUpdated: "2m ago",
      avatar: "https://i.pravatar.cc/150?u=sarah",
      color: const Color(0xFF00D1FF),
    ),
    UserTracker(
      id: "3",
      name: "Alex Rivera",
      position: const LatLng(37.7649, -122.4194),
      isOnline: false,
      lastUpdated: "1h ago",
      avatar: "https://i.pravatar.cc/150?u=alex",
      color: const Color(0xFFFF9F1C),
    ),
  ];

  final StreamController<List<UserTracker>> _userController = StreamController<List<UserTracker>>.broadcast();

  Stream<List<UserTracker>> get userStream => _userController.stream;

  void startMocking() {
    List<UserTracker> currentUsers = List.from(_initialUsers);
    
    Timer.periodic(const Duration(seconds: 5), (timer) {
      currentUsers = currentUsers.map((user) {
        if (!user.isOnline) return user;
        
        // Slightly move the online users
        return UserTracker(
          id: user.id,
          name: user.name,
          position: LatLng(
            user.position.latitude + 0.0001,
            user.position.longitude + 0.0001,
          ),
          isOnline: user.isOnline,
          lastUpdated: "Just now",
          avatar: user.avatar,
          color: user.color,
        );
      }).toList();
      
      _userController.add(currentUsers);
    });
  }

  void dispose() {
    _userController.close();
  }
}

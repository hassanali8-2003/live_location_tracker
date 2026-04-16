import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import 'friends_screen.dart';
import 'services/app_config.dart';
import 'services/location_service.dart';
import 'services/socket_service.dart';
import 'services/tracking_identity.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  final LocationService _locationService = LocationService();
  final SocketService _socketService = SocketService();

  bool _isSharing = true;
  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<Map<String, TrackedDevice>>? _devicesSubscription;
  LatLng? _currentUserLocation;
  TrackingIdentity? _identity;
  List<UserTracker> _users = [];

  static const CameraPosition _kInitialPosition = CameraPosition(
    target: LatLng(37.7749, -122.4194),
    zoom: 13.5,
  );

  final String _darkMapStyle = '''
[
  { "elementType": "geometry", "stylers": [ { "color": "#121212" } ] },
  { "elementType": "labels.icon", "stylers": [ { "visibility": "off" } ] },
  { "elementType": "labels.text.fill", "stylers": [ { "color": "#616161" } ] },
  { "elementType": "labels.text.stroke", "stylers": [ { "color": "#121212" } ] },
  { "featureType": "administrative", "elementType": "geometry", "stylers": [ { "color": "#757575" } ] },
  { "featureType": "poi", "elementType": "geometry", "stylers": [ { "color": "#181818" } ] },
  { "featureType": "road", "elementType": "geometry.fill", "stylers": [ { "color": "#2c2c2c" } ] },
  { "featureType": "water", "elementType": "geometry", "stylers": [ { "color": "#000000" } ] }
]
''';

  @override
  void initState() {
    super.initState();
    _bindSocketEvents();
    _initLocation();
    _initSocket();
  }

  void _bindSocketEvents() {
    _devicesSubscription = _socketService.devicesStream.listen((devices) {
      if (!mounted) {
        return;
      }

      final users = devices.values.map(_toUserTracker).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      setState(() {
        _users = users;
      });
    });
  }

  Future<void> _initSocket() async {
    final identity = await TrackingIdentity.current();
    _identity = identity;
    _socketService.connect(AppConfig.socketServerUrl, identity);
  }

  void _initLocation() async {
    final hasPermission = await _locationService.handleLocationPermission();
    if (!hasPermission) {
      return;
    }

    final pos = await _locationService.getCurrentPosition();
    if (pos != null) {
      setState(() {
        _currentUserLocation = LatLng(pos.latitude, pos.longitude);
      });
      _moveToUser(_currentUserLocation!);

      final identity = _identity ?? await TrackingIdentity.current();
      _identity = identity;
      _socketService.sendLocation(
        identity,
        _currentUserLocation!,
        accuracy: pos.accuracy,
        speed: pos.speed,
      );
    }

    _locationSubscription = _locationService.getLocationStream().listen((
      Position position,
    ) async {
      if (!_isSharing) {
        return;
      }

      final newLatLng = LatLng(position.latitude, position.longitude);
      final identity = _identity ?? await TrackingIdentity.current();
      _identity = identity;

      _socketService.sendLocation(
        identity,
        newLatLng,
        accuracy: position.accuracy,
        speed: position.speed,
      );

      if (mounted) {
        setState(() {
          _currentUserLocation = newLatLng;
        });
      }
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _devicesSubscription?.cancel();
    _socketService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0B10),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _kInitialPosition,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
              controller.setMapStyle(_darkMapStyle);
            },
            markers: _buildMarkers(),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
          ),
          _buildPremiumHeader(),
          _buildSideActions(),
          _buildModernDraggableSheet(),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1D24).withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: const [
                  Icon(Icons.radar_rounded, color: Color(0xFF6C63FF), size: 24),
                  SizedBox(width: 10),
                  Text(
                    'GEOTRACK',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF6C63FF).withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const CircleAvatar(
                radius: 22,
                backgroundImage: NetworkImage(
                  'https://i.pravatar.cc/150?u=current_user',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideActions() {
    return Positioned(
      right: 20,
      top: 150,
      child: Column(
        children: [
          _buildSideBtn(
            icon: Icons.sos_rounded,
            color: const Color(0xFFFF4B4B),
            onTap: () {},
            isLarge: true,
          ),
          const SizedBox(height: 16),
          _buildSideBtn(
            icon: Icons.people_alt_rounded,
            color: const Color(0xFF1C1D24),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FriendsScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildSideBtn(
            icon: _isSharing
                ? Icons.location_on_rounded
                : Icons.location_off_rounded,
            color: _isSharing
                ? const Color(0xFF6C63FF)
                : const Color(0xFF1C1D24),
            onTap: () => setState(() => _isSharing = !_isSharing),
            glow: _isSharing,
          ),
          const SizedBox(height: 16),
          _buildSideBtn(
            icon: Icons.layers_rounded,
            color: const Color(0xFF1C1D24),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSideBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isLarge = false,
    bool glow = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isLarge ? 18 : 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.9),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            if (glow)
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 4,
              ),
            const BoxShadow(
              color: Colors.black45,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: isLarge ? 28 : 22),
      ),
    );
  }

  Widget _buildModernDraggableSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.15,
      minChildSize: 0.15,
      maxChildSize: 0.7,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF14151B).withOpacity(0.98),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Live Activity',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00FF94).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_users.where((u) => u.isOnline).length} ONLINE',
                        style: const TextStyle(
                          color: Color(0xFF00FF94),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_users.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'No tracked devices have reported a location yet.',
                      style: TextStyle(color: Colors.white54),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ..._users.map((user) => _buildModernUserTile(user)),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernUserTile(UserTracker user) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _moveToUser(user.position),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: user.color.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundImage: NetworkImage(user.avatar),
                    ),
                  ),
                  if (user.isOnline)
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00FF94),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF14151B),
                            width: 2.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.isOnline
                          ? 'Moving | Active now'
                          : 'Offline | ${user.lastUpdated}',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withOpacity(0.1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    return _users.map((user) {
      return Marker(
        markerId: MarkerId(user.id),
        position: user.position,
        onTap: () => _showPremiumUserSheet(user),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          user.isOnline ? BitmapDescriptor.hueAzure : BitmapDescriptor.hueCyan,
        ),
      );
    }).toSet();
  }

  void _moveToUser(LatLng pos) async {
    final controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(pos, 15));
  }

  void _showPremiumUserSheet(UserTracker user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Color(0xFF1C1D24),
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 32),
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(user.avatar),
            ),
            const SizedBox(height: 20),
            Text(
              user.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              user.isOnline ? 'Live Tracking Active' : 'Currently Offline',
              style: TextStyle(
                color: user.isOnline ? const Color(0xFF00FF94) : Colors.white24,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionCircle(
                  Icons.message_rounded,
                  'Chat',
                  const Color(0xFF6C63FF),
                ),
                _buildActionCircle(
                  Icons.call_rounded,
                  'Call',
                  const Color(0xFF00D1FF),
                ),
                _buildActionCircle(
                  Icons.directions_rounded,
                  'Route',
                  const Color(0xFF00FF94),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCircle(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class UserTracker {
  final String id;
  final String name;
  final LatLng position;
  final bool isOnline;
  final String lastUpdated;
  final String avatar;
  final Color color;

  UserTracker({
    required this.id,
    required this.name,
    required this.position,
    required this.isOnline,
    required this.lastUpdated,
    required this.avatar,
    required this.color,
  });
}

UserTracker _toUserTracker(TrackedDevice device) {
  return UserTracker(
    id: device.deviceId,
    name: device.deviceName,
    position: device.position,
    isOnline: device.isOnline,
    lastUpdated: DateFormat('hh:mm a').format(device.timestamp.toLocal()),
    avatar:
        'https://i.pravatar.cc/150?u=${Uri.encodeComponent(device.deviceId)}',
    color: device.isOnline ? const Color(0xFF6C63FF) : const Color(0xFF00D1FF),
  );
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LiveTrackingScreen extends StatefulWidget {
  final String userName;
  final String avatarUrl;
  final LatLng initialPosition;

  const LiveTrackingScreen({
    super.key,
    required this.userName,
    required this.avatarUrl,
    required this.initialPosition,
  });

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  
  late LatLng _currentPos;
  final List<LatLng> _polylineCoordinates = [];
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  
  bool _isFollowing = true;
  double _currentSpeed = 42.5; // Mock speed in km/h

  // Dark Map Style JSON (matching HomeScreen)
  final String _darkMapStyle = '''
[
  { "elementType": "geometry", "stylers": [ { "color": "#212121" } ] },
  { "elementType": "labels.icon", "stylers": [ { "visibility": "off" } ] },
  { "elementType": "labels.text.fill", "stylers": [ { "color": "#757575" } ] },
  { "elementType": "labels.text.stroke", "stylers": [ { "color": "#212121" } ] },
  { "featureType": "administrative", "elementType": "geometry", "stylers": [ { "color": "#757575" } ] },
  { "featureType": "poi", "elementType": "geometry", "stylers": [ { "color": "#181818" } ] },
  { "featureType": "road", "elementType": "geometry.fill", "stylers": [ { "color": "#2c2c2c" } ] },
  { "featureType": "water", "elementType": "geometry", "stylers": [ { "color": "#000000" } ] }
]
''';

  @override
  void initState() {
    super.initState();
    _currentPos = widget.initialPosition;
    _polylineCoordinates.add(_currentPos);
    _updateMarkers();
    _startMockMovement();
  }

  void _updateMarkers() {
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('trackedUser'),
          position: _currentPos,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(title: widget.userName),
        ),
      );
    });
  }

  void _startMockMovement() {
    // Simulate movement for the "Live" feel
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _currentPos = LatLng(
          _currentPos.latitude + 0.0005,
          _currentPos.longitude + 0.0005,
        );
        _polylineCoordinates.add(_currentPos);
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: _polylineCoordinates,
            color: Colors.blueAccent,
            width: 5,
            jointType: JointType.round,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ),
        );
        _updateMarkers();
        
        if (_isFollowing) {
          _moveCamera(_currentPos);
        }
      });
    });
  }

  Future<void> _moveCamera(LatLng pos) async {
    final controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLng(pos));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0B10),
      body: Stack(
        children: [
          // 1. Full Screen Map
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _currentPos, zoom: 15),
            onMapCreated: (controller) {
              _controller.complete(controller);
              controller.setMapStyle(_darkMapStyle);
            },
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
          ),

          // 2. Top Section (User Info Card)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildCircularBtn(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      _buildCircularBtn(
                        icon: _isFollowing ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                        color: _isFollowing ? Colors.blueAccent : Colors.white10,
                        onTap: () => setState(() => _isFollowing = !_isFollowing),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildGlassInfoCard(),
                ],
              ),
            ),
          ),

          // 3. Bottom Panel
          _buildBottomActionPanel(),
        ],
      ),
    );
  }

  Widget _buildGlassInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1D24).withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(widget.avatarUrl),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF1C1D24), width: 3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.userName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Live • 1.2 km away",
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
          _buildTag("42 km/h"),
        ],
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildBottomActionPanel() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        decoration: const BoxDecoration(
          color: Color(0xFF14151B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(color: Colors.black54, blurRadius: 30, spreadRadius: 10),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Last updated", style: TextStyle(color: Colors.white38, fontSize: 12)),
                    SizedBox(height: 4),
                    Text("Just now", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                _buildTag("ETA: 8 mins"),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildActionBtn(Icons.call_rounded, "Call", Colors.greenAccent),
                const SizedBox(width: 12),
                _buildActionBtn(Icons.chat_bubble_rounded, "Message", Colors.blueAccent),
                const SizedBox(width: 12),
                _buildActionBtn(Icons.stop_rounded, "Stop", Colors.redAccent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularBtn({required IconData icon, required VoidCallback onTap, Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color ?? const Color(0xFF1C1D24).withOpacity(0.8),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

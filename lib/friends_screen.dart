import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'live_tracking_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final List<Friend> _friends = [
    Friend(
      name: 'Alex Johnson',
      status: FriendStatus.sharing,
      lastSeen: 'Live Now',
      distance: '0.8 km',
      avatarUrl: 'https://i.pravatar.cc/150?u=alex',
      position: const LatLng(37.779, -122.418),
    ),
    Friend(
      name: 'Sarah Williams',
      status: FriendStatus.online,
      lastSeen: 'Active 5m ago',
      distance: '2.4 km',
      avatarUrl: 'https://i.pravatar.cc/150?u=sarah',
      position: const LatLng(37.771, -122.422),
    ),
    Friend(
      name: 'Michael Chen',
      status: FriendStatus.offline,
      lastSeen: 'Seen 2h ago',
      distance: '5.1 km',
      avatarUrl: 'https://i.pravatar.cc/150?u=michael',
      position: const LatLng(37.782, -122.412),
    ),
    Friend(
      name: 'Emma Davis',
      status: FriendStatus.sharing,
      lastSeen: 'Live Now',
      distance: '1.2 km',
      avatarUrl: 'https://i.pravatar.cc/150?u=emma',
      position: const LatLng(37.775, -122.415),
    ),
    Friend(
      name: 'James Wilson',
      status: FriendStatus.offline,
      lastSeen: 'Seen yesterday',
      distance: '12 km',
      avatarUrl: 'https://i.pravatar.cc/150?u=james',
      position: const LatLng(37.768, -122.425),
    ),
  ];

  List<Friend> _filteredFriends = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredFriends = _friends;
  }

  void _filterFriends(String query) {
    setState(() {
      _filteredFriends = _friends
          .where((friend) =>
              friend.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0B10),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Premium Header
          _buildSliverAppBar(),

          // 2. Search & Stats Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  _buildSearchBar(),
                  const SizedBox(height: 24),
                  _buildStatsRow(),
                  const SizedBox(height: 32),
                  const Text(
                    "All Contacts",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // 3. Friends List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final friend = _filteredFriends[index];
                  return _buildFriendCard(friend);
                },
                childCount: _filteredFriends.length,
              ),
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: _buildPremiumFAB(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      backgroundColor: Colors.transparent,
      elevation: 0,
      floating: true,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        title: const Text(
          "Friends",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 24,
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF6C63FF), size: 22),
            ),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1D24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _filterFriends,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "Search your inner circle...",
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6C63FF)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    int sharingCount = _friends.where((f) => f.status == FriendStatus.sharing).length;
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            "Active Now",
            "$sharingCount",
            const Color(0xFF6C63FF),
            Icons.sensors_rounded,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            "Total Friends",
            "${_friends.length}",
            const Color(0xFF00D1FF),
            Icons.people_alt_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1D24),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendCard(Friend friend) {
    bool isLive = friend.status == FriendStatus.sharing;
    Color statusColor = _getStatusColor(friend.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF14151B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => LiveTrackingScreen(
                  userName: friend.name,
                  avatarUrl: friend.avatarUrl,
                  initialPosition: friend.position,
                ),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar with Status Glow
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isLive ? statusColor.withOpacity(0.5) : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage(friend.avatarUrl),
                      ),
                    ),
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF14151B), width: 3),
                          boxShadow: [
                            if (friend.status != FriendStatus.offline)
                              BoxShadow(
                                color: statusColor.withOpacity(0.5),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            isLive ? Icons.location_on_rounded : Icons.access_time_rounded,
                            size: 14,
                            color: isLive ? const Color(0xFF6C63FF) : Colors.white38,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            friend.lastSeen,
                            style: TextStyle(
                              color: isLive ? const Color(0xFF6C63FF) : Colors.white38,
                              fontSize: 13,
                              fontWeight: isLive ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Trailing Info (Distance)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      friend.distance,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: Colors.white24,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumFAB() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: const Color(0xFF6C63FF),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        label: const Text(
          "Radar View",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        icon: const Icon(Icons.radar_rounded),
      ),
    );
  }

  Color _getStatusColor(FriendStatus status) {
    switch (status) {
      case FriendStatus.online:
        return const Color(0xFF00FF94); // Neon Green
      case FriendStatus.offline:
        return Colors.white24;
      case FriendStatus.sharing:
        return const Color(0xFF6C63FF); // Primary Indigo
    }
  }
}

enum FriendStatus { online, offline, sharing }

class Friend {
  final String name;
  final FriendStatus status;
  final String lastSeen;
  final String distance;
  final String avatarUrl;
  final LatLng position;

  Friend({
    required this.name,
    required this.status,
    required this.lastSeen,
    required this.distance,
    required this.avatarUrl,
    required this.position,
  });
}

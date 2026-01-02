import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();
  List<UserModel> _xpLeaderboard = [];
  List<UserModel> _streakLeaderboard = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLeaderboards();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaderboards() async {
    setState(() => _isLoading = true);

    try {
      _xpLeaderboard = await _firestoreService.getLeaderboard(limit: 50);
      _streakLeaderboard =
          await _firestoreService.getLeaderboardByStreak(limit: 50);
    } catch (e) {
      // Handle error
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'XP Points', icon: Icon(Icons.star)),
            Tab(text: 'Streaks', icon: Icon(Icons.local_fire_department)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLeaderboardList(_xpLeaderboard, 'xp'),
                _buildLeaderboardList(_streakLeaderboard, 'streak'),
              ],
            ),
    );
  }

  Widget _buildLeaderboardList(List<UserModel> users, String type) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.leaderboard_outlined,
                size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No data available',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLeaderboards,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return _buildLeaderboardItem(user, index + 1, type);
        },
      ),
    );
  }

  Widget _buildLeaderboardItem(UserModel user, int rank, String type) {
    Color? backgroundColor;
    Widget? rankWidget;

    if (rank == 1) {
      backgroundColor = Colors.amber.shade50;
      rankWidget = const Icon(Icons.emoji_events, color: Colors.amber, size: 28);
    } else if (rank == 2) {
      backgroundColor = Colors.grey.shade100;
      rankWidget = Icon(Icons.emoji_events, color: Colors.grey.shade400, size: 28);
    } else if (rank == 3) {
      backgroundColor = Colors.orange.shade50;
      rankWidget = Icon(Icons.emoji_events, color: Colors.orange.shade300, size: 28);
    } else {
      rankWidget = Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade200,
        ),
        child: Center(
          child: Text(
            '$rank',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          rankWidget,
          const SizedBox(width: 12),
          CircleAvatar(
            backgroundColor: const Color(0xFF00796B),
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Level ${user.currentLevel}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(
                    type == 'xp' ? Icons.star : Icons.local_fire_department,
                    color: type == 'xp' ? Colors.amber : Colors.orange,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    type == 'xp' ? '${user.xp}' : '${user.streak}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Text(
                type == 'xp' ? 'XP' : 'days',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

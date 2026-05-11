import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../models/weekly_leaderboard_entry.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../widgets/bmoris_back_button.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  static const String _bootstrapWeekId = '2026-05-11';

  final FirestoreService _firestoreService = FirestoreService();
  List<WeeklyLeaderboardEntry> _weeklyEntries = [];
  WeeklyLeaderboardEntry? _currentUserEntry;
  int? _currentUserRank;
  int? _currentUserGap;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);

    final userId =
        Provider.of<AuthProvider>(context, listen: false).user?.uid ?? '';

    try {
      final useBootstrapLifetime =
          FirestoreService.getWeekId() == _bootstrapWeekId;
      final weeklyEntries =
          useBootstrapLifetime
              ? _mapUsersToWeeklyEntries(
                await _firestoreService.getLeaderboard(limit: 50),
              )
              : await _firestoreService.getWeeklyLeaderboard(limit: 50);

      WeeklyLeaderboardEntry? currentUserEntry;
      int? currentUserRank;
      int? currentUserGap;

      if (userId.isNotEmpty) {
        final visibleIndex = weeklyEntries.indexWhere(
          (entry) => entry.userId == userId,
        );
        if (visibleIndex >= 0) {
          currentUserEntry = weeklyEntries[visibleIndex];
          currentUserRank = visibleIndex + 1;
          currentUserGap =
              visibleIndex == 0
                  ? 0
                  : weeklyEntries[visibleIndex - 1].xp - currentUserEntry.xp;
        } else if (useBootstrapLifetime) {
          final user = await _firestoreService.getUserById(userId);
          if (user != null && user.role == 'user') {
            currentUserEntry = _mapUserToWeeklyEntry(user);
            currentUserRank = await _firestoreService
                .getLifetimeLeaderboardRank(userId);
            currentUserGap = await _firestoreService
                .getLifetimeLeaderboardGapToNextRank(userId);
          }
        } else {
          currentUserEntry = await _firestoreService.getWeeklyLeaderboardEntry(
            userId,
          );
          currentUserRank = await _firestoreService.getWeeklyLeaderboardRank(
            userId,
          );
          currentUserGap = await _firestoreService
              .getWeeklyLeaderboardGapToNextRank(userId);
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _weeklyEntries = weeklyEntries;
        _currentUserEntry = currentUserEntry;
        _currentUserRank = currentUserRank;
        _currentUserGap = currentUserGap;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _weeklyEntries = [];
        _currentUserEntry = null;
        _currentUserRank = null;
        _currentUserGap = null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthProvider>().user?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                  onRefresh: _loadLeaderboard,
                  color: const Color(0xFF00897B),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      if (_weeklyEntries.isEmpty)
                        _buildEmptyState()
                      else ...[
                        _buildPodium(currentUserId),
                        const SizedBox(height: 20),
                        _buildLeaderboardList(currentUserId),
                        if (_shouldShowPinnedCurrentUser(currentUserId)) ...[
                          const SizedBox(height: 14),
                          _buildLeaderboardRow(
                            entry: _currentUserEntry!,
                            rank: _currentUserRank!,
                            isCurrentUser: true,
                            emphasize: true,
                          ),
                        ],
                        const SizedBox(height: 22),
                        _buildFooterMessage(),
                      ],
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: 8,
            child: Opacity(
              opacity: 0.18,
              child: Image.asset(
                'assets/bmorisbird3.png',
                width: 118,
                height: 118,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  const BMorisBackButton(),
                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Weekly Chart',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _buildCountdownLabel(),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF7B7B7B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Image.asset('assets/dodo.png', width: 120, height: 120),
          const SizedBox(height: 18),
          Text(
            'No weekly scores yet',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Earn XP from lessons, quizzes, and pronunciation to enter this week\'s chart.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF727272),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(String currentUserId) {
    final first = _weeklyEntries.length > 0 ? _weeklyEntries[0] : null;
    final second = _weeklyEntries.length > 1 ? _weeklyEntries[1] : null;
    final third = _weeklyEntries.length > 2 ? _weeklyEntries[2] : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _buildPodiumSlot(
              entry: second,
              rank: 2,
              height: 122,
              accent: const Color(0xFFD9DCE3),
              isCurrentUser: second?.userId == currentUserId,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildPodiumSlot(
              entry: first,
              rank: 1,
              height: 154,
              accent: const Color(0xFFF2D27A),
              isCurrentUser: first?.userId == currentUserId,
              highlight: true,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildPodiumSlot(
              entry: third,
              rank: 3,
              height: 108,
              accent: const Color(0xFFE9BF80),
              isCurrentUser: third?.userId == currentUserId,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumSlot({
    required WeeklyLeaderboardEntry? entry,
    required int rank,
    required double height,
    required Color accent,
    required bool isCurrentUser,
    bool highlight = false,
  }) {
    if (entry == null) {
      return Container(
        height: height + 56,
        alignment: Alignment.bottomCenter,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      );
    }

    return SizedBox(
      height: height + (highlight ? 88 : 76),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildAvatar(entry, radius: highlight ? 34 : 28, podium: true),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            height: height,
            padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  accent.withValues(alpha: 0.55),
                  accent.withValues(alpha: 0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border:
                  isCurrentUser
                      ? Border.all(color: const Color(0xFF00897B), width: 2)
                      : null,
            ),
            child: Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$rank',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF7A5D1B),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  isCurrentUser ? 'You' : entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: highlight ? 13 : 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2A2A2A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.xp} XP',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4E4E4E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList(String currentUserId) {
    final remainingEntries =
        _weeklyEntries.length > 3
            ? _weeklyEntries.sublist(3)
            : <WeeklyLeaderboardEntry>[];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          for (var index = 0; index < remainingEntries.length; index++) ...[
            _buildLeaderboardRow(
              entry: remainingEntries[index],
              rank: index + 4,
              isCurrentUser: remainingEntries[index].userId == currentUserId,
            ),
            if (index != remainingEntries.length - 1)
              Divider(height: 20, thickness: 1, color: const Color(0xFFF0EAE0)),
          ],
        ],
      ),
    );
  }

  Widget _buildLeaderboardRow({
    required WeeklyLeaderboardEntry entry,
    required int rank,
    required bool isCurrentUser,
    bool emphasize = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrentUser ? const Color(0xFFEAF8F3) : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        border:
            isCurrentUser
                ? Border.all(color: const Color(0xFFA7DCC9), width: 1.5)
                : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              style: GoogleFonts.poppins(
                fontSize: emphasize ? 16 : 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF474747),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _buildAvatar(entry, radius: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isCurrentUser ? 'You' : entry.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: emphasize ? 16 : 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E1E1E),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${entry.xp} XP',
            style: GoogleFonts.poppins(
              fontSize: emphasize ? 16 : 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3C3C3C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(
    WeeklyLeaderboardEntry entry, {
    required double radius,
    bool podium = false,
  }) {
    final hasPhoto = entry.photoUrl != null && entry.photoUrl!.isNotEmpty;
    final initial = entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?';

    return Container(
      padding: EdgeInsets.all(podium ? 4 : 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFFF7E8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFF00897B),
        backgroundImage: hasPhoto ? NetworkImage(entry.photoUrl!) : null,
        child:
            hasPhoto
                ? null
                : Text(
                  initial,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: radius * 0.8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
      ),
    );
  }

  Widget _buildFooterMessage() {
    final message = switch ((
      _currentUserRank,
      _currentUserGap,
      _currentUserEntry,
    )) {
      (_, _, null) => 'Earn XP this week to enter the chart.',
      (1, _, _) => 'You\'re in first place this week.',
      (_, final gap?, _) when gap > 0 => '$gap XP to climb one place.',
      _ => 'Keep earning XP this week.',
    };

    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF4E4E4E),
        ),
      ),
    );
  }

  bool _shouldShowPinnedCurrentUser(String currentUserId) {
    if (_currentUserEntry == null || _currentUserRank == null) {
      return false;
    }
    return _currentUserRank! > 50 ||
        _weeklyEntries.every((entry) => entry.userId != currentUserId);
  }

  String _buildCountdownLabel() {
    final now = DateTime.now();
    final nextWeekStart = FirestoreService.getNextWeekStart(now);
    final difference = nextWeekStart.difference(now);
    final days = difference.inDays;
    final hours = difference.inHours.remainder(24);

    if (days > 0) {
      return '${days}d ${hours}h left';
    }
    return '${difference.inHours}h left';
  }

  List<WeeklyLeaderboardEntry> _mapUsersToWeeklyEntries(List<UserModel> users) {
    return users.map(_mapUserToWeeklyEntry).toList();
  }

  WeeklyLeaderboardEntry _mapUserToWeeklyEntry(UserModel user) {
    final now = DateTime.now();
    return WeeklyLeaderboardEntry(
      userId: user.uid,
      name: user.name,
      photoUrl: user.photoUrl,
      xp: user.xp,
      streak: user.streak,
      currentLevel: user.currentLevel,
      updatedAt: now,
    );
  }
}

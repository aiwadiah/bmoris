import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/announcement_model.dart';
import '../services/firestore_service.dart';
import '../widgets/bmoris_back_button.dart';

enum _NotificationFilter { all, unread, announcements }

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const String _readStorageKey = 'bmoris_read_announcement_ids';
  static const Color _teal = Color(0xFF00796B);
  static const Color _ink = Color(0xFF21413B);

  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  List<AnnouncementModel> _announcements = [];
  Set<String> _readAnnouncementIds = {};
  _NotificationFilter _selectedFilter = _NotificationFilter.all;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final announcements = await _firestoreService.getActiveAnnouncements();

      if (!mounted) return;
      setState(() {
        _announcements = announcements;
        _readAnnouncementIds =
            prefs.getStringList(_readStorageKey)?.toSet() ?? {};
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _announcements = [];
        _readAnnouncementIds = {};
        _isLoading = false;
      });
    }
  }

  List<AnnouncementModel> get _filteredAnnouncements {
    switch (_selectedFilter) {
      case _NotificationFilter.unread:
        return _announcements
            .where((announcement) => !_isRead(announcement))
            .toList();
      case _NotificationFilter.announcements:
      case _NotificationFilter.all:
        return _announcements;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFCFB),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator(color: _teal))
                : RefreshIndicator(
                  color: _teal,
                  onRefresh: _loadNotifications,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 14),
                      _buildFilterChips(),
                      const SizedBox(height: 12),
                      _buildNotificationList(),
                      const SizedBox(height: 14),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedFilter = _NotificationFilter.all;
                            });
                          },
                          child: Text(
                            'View all',
                            style: GoogleFonts.poppins(
                              color: _teal,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        if (Navigator.canPop(context)) const BMorisBackButton(),
        if (Navigator.canPop(context)) const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Notifications',
            style: GoogleFonts.poppins(
              color: _teal,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFilterChip('All', _NotificationFilter.all),
        _buildFilterChip('Unread', _NotificationFilter.unread),
        _buildFilterChip('Announcements', _NotificationFilter.announcements),
      ],
    );
  }

  Widget _buildFilterChip(String label, _NotificationFilter filter) {
    final isSelected = _selectedFilter == filter;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = filter),
      showCheckmark: false,
      selectedColor: _teal,
      backgroundColor: const Color(0xFFF0F2F1),
      side: BorderSide(color: isSelected ? _teal : const Color(0xFFE1E7E5)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      labelStyle: GoogleFonts.poppins(
        color: isSelected ? Colors.white : const Color(0xFF526B65),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    );
  }

  Widget _buildNotificationList() {
    final announcements = _filteredAnnouncements;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E8E5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child:
          announcements.isEmpty
              ? _buildEmptyState()
              : Column(
                children: [
                  for (
                    var index = 0;
                    index < announcements.length;
                    index++
                  ) ...[
                    _buildNotificationRow(announcements[index]),
                    if (index < announcements.length - 1)
                      const Divider(height: 1, color: Color(0xFFE9EFEC)),
                  ],
                ],
              ),
    );
  }

  Widget _buildEmptyState() {
    final message = switch (_selectedFilter) {
      _NotificationFilter.unread => 'No unread notifications',
      _NotificationFilter.announcements => 'No announcements yet',
      _NotificationFilter.all => 'No notifications yet',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 44),
      child: Column(
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 52,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: _ink,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Admin announcements will appear here when published.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: const Color(0xFF78908A),
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationRow(AnnouncementModel announcement) {
    final isRead = _isRead(announcement);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openAnnouncement(announcement),
        child: IntrinsicHeight(
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 4,
                decoration: BoxDecoration(
                  color: isRead ? Colors.transparent : _teal,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(12),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 13, 12, 13),
                  child: Row(
                    children: [
                      _buildAnnouncementIcon(announcement),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              announcement.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: _ink,
                                fontSize: 12,
                                fontWeight:
                                    isRead ? FontWeight.w700 : FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              announcement.content,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF677D78),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 64,
                        child: Text(
                          _relativeTime(announcement.createdAt),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF78908A),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _buildReadIndicator(isRead),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncementIcon(AnnouncementModel announcement) {
    final icon = _iconForAnnouncement(announcement);
    final color = _colorForAnnouncement(announcement);

    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 16),
    );
  }

  Widget _buildReadIndicator(bool isRead) {
    if (!isRead) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(color: _teal, shape: BoxShape.circle),
            child: SizedBox(width: 9, height: 9),
          ),
        ),
      );
    }

    return Container(
      width: 13,
      height: 13,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFB8C6C2), width: 1.6),
      ),
    );
  }

  Future<void> _openAnnouncement(AnnouncementModel announcement) async {
    await _markAsRead(announcement.id);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildAnnouncementIcon(announcement),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      announcement.title,
                      style: GoogleFonts.poppins(
                        color: _ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                announcement.content,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF526B65),
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _fullTimeLabel(announcement.createdAt),
                style: GoogleFonts.poppins(
                  color: const Color(0xFF78908A),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _markAsRead(String announcementId) async {
    if (_readAnnouncementIds.contains(announcementId)) return;

    final updatedIds = {..._readAnnouncementIds, announcementId};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_readStorageKey, updatedIds.toList());

    if (!mounted) return;
    setState(() {
      _readAnnouncementIds = updatedIds;
    });
  }

  bool _isRead(AnnouncementModel announcement) {
    return _readAnnouncementIds.contains(announcement.id);
  }

  IconData _iconForAnnouncement(AnnouncementModel announcement) {
    final text = '${announcement.title} ${announcement.content}'.toLowerCase();
    if (text.contains('level') || text.contains('rank')) {
      return Icons.workspace_premium_rounded;
    }
    if (text.contains('ai') || text.contains('tutor')) {
      return Icons.auto_awesome_rounded;
    }
    if (text.contains('practice') || text.contains('lesson')) {
      return Icons.school_rounded;
    }
    if (text.contains('warning') || text.contains('important')) {
      return Icons.warning_amber_rounded;
    }
    return Icons.campaign_rounded;
  }

  Color _colorForAnnouncement(AnnouncementModel announcement) {
    final text = '${announcement.title} ${announcement.content}'.toLowerCase();
    if (text.contains('warning') || text.contains('important')) {
      return const Color(0xFFE45D50);
    }
    if (text.contains('level') || text.contains('rank')) {
      return const Color(0xFF91A600);
    }
    if (text.contains('ai') || text.contains('tutor')) {
      return const Color(0xFFE4B032);
    }
    return _teal;
  }

  String _relativeTime(DateTime createdAt) {
    final difference = DateTime.now().difference(createdAt);

    if (difference.inMinutes < 1) return 'Now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  String _fullTimeLabel(DateTime createdAt) {
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '${createdAt.day}/${createdAt.month}/${createdAt.year} at $hour:$minute';
  }
}

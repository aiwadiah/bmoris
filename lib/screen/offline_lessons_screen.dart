import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/lesson_model.dart';
import '../providers/lesson_provider.dart';
import '../widgets/bmoris_back_button.dart';
import 'lesson_screen.dart';

class OfflineLessonsScreen extends StatefulWidget {
  const OfflineLessonsScreen({super.key});

  @override
  State<OfflineLessonsScreen> createState() => _OfflineLessonsScreenState();
}

class _OfflineLessonsScreenState extends State<OfflineLessonsScreen> {
  static const int _storageLimitBytes = 500 * 1024 * 1024;
  static const Color _green = Color(0xFF00897B);
  static const Color _mint = Color(0xFFE8F6F2);
  static const Color _ink = Color(0xFF24413D);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<LessonProvider>(context, listen: false);
      await provider.loadOfflineLessons();
      if (provider.lessons.isEmpty) {
        await provider.loadLessons();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFCFB),
      body: SafeArea(
        child: Consumer<LessonProvider>(
          builder: (context, lessonProvider, _) {
            final offlineLessons = lessonProvider.offlineLessons;
            final offlineIds =
                offlineLessons.map((lesson) => lesson.id).toSet();
            final suggestedLessons =
                lessonProvider.lessons
                    .where((lesson) => !offlineIds.contains(lesson.id))
                    .take(3)
                    .toList();

            return RefreshIndicator(
              color: _green,
              onRefresh: () async {
                await lessonProvider.loadOfflineLessons();
                await lessonProvider.loadLessons();
              },
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 16),
                  _buildStorageCard(lessonProvider.offlineStorageUsageBytes),
                  const SizedBox(height: 22),
                  _buildSectionTitle('Downloaded'),
                  const SizedBox(height: 10),
                  if (offlineLessons.isEmpty)
                    _buildEmptyDownloadedCard(context)
                  else
                    ...offlineLessons.map(
                      (lesson) =>
                          _buildDownloadedCard(context, lesson, lessonProvider),
                    ),
                  if (suggestedLessons.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildSectionTitle('Suggested Downloads'),
                    const SizedBox(height: 10),
                    ...suggestedLessons.map(
                      (lesson) =>
                          _buildSuggestedCard(context, lesson, lessonProvider),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        if (Navigator.canPop(context)) const BMorisBackButton.plain(),
        if (Navigator.canPop(context)) const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Offline Lessons',
            style: GoogleFonts.poppins(
              color: _green,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStorageCard(int usedBytes) {
    final progress = (usedBytes / _storageLimitBytes).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EFEC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Used: ${_formatBytes(usedBytes)} / 500MB',
            style: GoogleFonts.poppins(
              color: const Color(0xFF60706C),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E9E6),
              valueColor: const AlwaysStoppedAnimation<Color>(_green),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: _ink,
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildDownloadedCard(
    BuildContext context,
    LessonModel lesson,
    LessonProvider provider,
  ) {
    final metadata = provider.offlineMetadata[lesson.id];

    return _OfflineCard(
      icon: Icons.menu_book_rounded,
      iconBackground: _mint,
      title: lesson.title,
      subtitle:
          '${_formatBytes(metadata?.sizeBytes ?? 0)}  •  ${_formatAccessLabel(metadata?.lastAccessed)}',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton.filled(
            tooltip: 'Open lesson',
            onPressed: () => _openLesson(context, lesson, provider),
            icon: const Icon(Icons.play_arrow_rounded),
            color: Colors.white,
            style: IconButton.styleFrom(
              backgroundColor: _green,
              fixedSize: const Size(34, 34),
              padding: EdgeInsets.zero,
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'More options',
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF79908B)),
            onSelected: (value) {
              if (value == 'remove') {
                _confirmDelete(context, lesson, provider);
              }
            },
            itemBuilder:
                (context) => const [
                  PopupMenuItem(
                    value: 'remove',
                    child: Text('Remove download'),
                  ),
                ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedCard(
    BuildContext context,
    LessonModel lesson,
    LessonProvider provider,
  ) {
    return _OfflineCard(
      icon: Icons.landscape_rounded,
      iconBackground: const Color(0xFFE4F5FA),
      title: lesson.title,
      subtitle: '${lesson.contents.length} items',
      trailing: IconButton(
        tooltip: 'Download lesson',
        onPressed: () => _downloadLesson(context, lesson, provider),
        icon: const Icon(Icons.download_rounded, color: _green),
      ),
    );
  }

  Widget _buildEmptyDownloadedCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EFEC)),
      ),
      child: Column(
        children: [
          const Icon(Icons.download_done_rounded, color: _green, size: 36),
          const SizedBox(height: 10),
          Text(
            'No downloaded lessons yet',
            style: GoogleFonts.poppins(
              color: _ink,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Save a lesson to learn without internet.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/lessons'),
            icon: const Icon(Icons.explore_rounded),
            label: const Text('Browse Lessons'),
          ),
        ],
      ),
    );
  }

  Future<void> _openLesson(
    BuildContext context,
    LessonModel lesson,
    LessonProvider provider,
  ) async {
    await provider.recordOfflineLessonAccess(lesson.id);
    provider.setCurrentLesson(lesson);
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LessonDetailSheet(lesson: lesson),
    );
  }

  Future<void> _downloadLesson(
    BuildContext context,
    LessonModel lesson,
    LessonProvider provider,
  ) async {
    await provider.downloadLesson(lesson);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${lesson.title} saved for offline access')),
    );
  }

  void _confirmDelete(
    BuildContext context,
    LessonModel lesson,
    LessonProvider provider,
  ) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Remove Offline Lesson'),
            content: Text('Remove "${lesson.title}" from offline storage?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  await provider.removeOfflineLesson(lesson.id);
                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lesson removed from offline'),
                    ),
                  );
                },
                child: const Text(
                  'Remove',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0MB';
    final kilobytes = bytes / 1024;
    if (kilobytes < 1024) {
      return '${kilobytes.ceil()}KB';
    }

    final megabytes = kilobytes / 1024;
    if (megabytes < 10) {
      return '${megabytes.toStringAsFixed(1)}MB';
    }
    return '${megabytes.round()}MB';
  }

  String _formatAccessLabel(DateTime? lastAccessed) {
    if (lastAccessed == null) return 'Downloaded recently';

    final days = DateTime.now().difference(lastAccessed).inDays;
    if (days <= 0) return 'Opened today';
    if (days == 1) return 'Opened 1 day ago';
    return 'Opened $days days ago';
  }
}

class _OfflineCard extends StatelessWidget {
  final IconData icon;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _OfflineCard({
    required this.icon,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EFEC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _OfflineLessonsScreenState._green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: _OfflineLessonsScreenState._ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF6F827D),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

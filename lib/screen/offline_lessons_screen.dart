import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/lesson_provider.dart';
import '../models/lesson_model.dart';

class OfflineLessonsScreen extends StatefulWidget {
  const OfflineLessonsScreen({super.key});

  @override
  State<OfflineLessonsScreen> createState() => _OfflineLessonsScreenState();
}

class _OfflineLessonsScreenState extends State<OfflineLessonsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LessonProvider>(context, listen: false).loadOfflineLessons();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Lessons'),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
      ),
      body: Consumer<LessonProvider>(
        builder: (context, lessonProvider, _) {
          final offlineLessons = lessonProvider.offlineLessons;

          if (offlineLessons.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: offlineLessons.length,
            itemBuilder: (context, index) {
              final lesson = offlineLessons[index];
              return _buildLessonCard(context, lesson, lessonProvider);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.download_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No offline lessons',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Download lessons to access them offline',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/lessons');
            },
            icon: const Icon(Icons.book),
            label: const Text('Browse Lessons'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00796B),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonCard(
      BuildContext context, LessonModel lesson, LessonProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF00796B).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.book, color: Color(0xFF00796B)),
        ),
        title: Text(lesson.title),
        subtitle: Text(lesson.titleMalay),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _confirmDelete(context, lesson, provider),
        ),
        onTap: () {
          provider.setCurrentLesson(lesson);
          // Open lesson detail
        },
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, LessonModel lesson, LessonProvider provider) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Offline Lesson'),
        content: Text(
            'Are you sure you want to remove "${lesson.title}" from offline storage?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              provider.removeOfflineLesson(lesson.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Lesson removed from offline')),
              );
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

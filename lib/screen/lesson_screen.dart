import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/lesson_provider.dart';
import '../providers/auth_provider.dart';
import '../models/lesson_model.dart';

class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LessonProvider>(context, listen: false).loadLessons();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Lessons',
          style: GoogleFonts.poppins(
            color: const Color(0xFF00897B),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF00897B),
        elevation: 0,
        centerTitle: false,
      ),
      body: Consumer<LessonProvider>(
        builder: (context, lessonProvider, _) {
          if (lessonProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (lessonProvider.lessons.isEmpty) {
            return _buildEmptyState();
          }

          final categories = ['All', ...lessonProvider.getCategories()];
          final filteredLessons =
              _selectedCategory == 'All'
                  ? lessonProvider.lessons
                  : lessonProvider.lessons
                      .where((l) => l.category == _selectedCategory)
                      .toList();

          return Column(
            children: [
              // Category Filter
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = _selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          }
                        },
                        selectedColor: const Color(0xFF00897B),
                        labelStyle: GoogleFonts.poppins(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 13,
                        ),
                        backgroundColor: Colors.grey.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color:
                              isSelected
                                  ? const Color(0xFF00897B)
                                  : Colors.grey.shade200,
                        ),
                        showCheckmark: false,
                      ),
                    );
                  },
                ),
              ),

              // Lessons List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredLessons.length,
                  itemBuilder: (context, index) {
                    final lesson = filteredLessons[index];
                    return _buildLessonCard(context, lesson);
                  },
                ),
              ),
            ],
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
          Image.asset('assets/dodo.png', width: 100, height: 100),
          const SizedBox(height: 16),
          const Text(
            'No lessons available',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check back later for new content',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonCard(BuildContext context, LessonModel lesson) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openLesson(context, lesson),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00897B).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.book_rounded,
                        color: Color(0xFF00897B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lesson.title,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            lesson.titleMalay,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        _buildDifficultyBadge(lesson.difficulty),
                        const SizedBox(height: 4),
                        Text(
                          '+${lesson.xpReward} XP',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  lesson.description,
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        lesson.category,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    FutureBuilder<bool>(
                      future: Provider.of<LessonProvider>(
                        context,
                        listen: false,
                      ).isLessonOffline(lesson.id),
                      builder: (context, snapshot) {
                        if (snapshot.data == true) {
                          return const Icon(
                            Icons.cloud_done_rounded,
                            color: Color(0xFF00897B),
                            size: 20,
                          );
                        }
                        return Icon(
                          Icons.download_rounded,
                          color: Colors.grey.shade400,
                          size: 20,
                        );
                      },
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

  Widget _buildDifficultyBadge(int difficulty) {
    Color color;
    String label;

    switch (difficulty) {
      case 1:
        color = Colors.green;
        label = 'Easy';
        break;
      case 2:
        color = Colors.lightGreen;
        label = 'Basic';
        break;
      case 3:
        color = Colors.orange;
        label = 'Medium';
        break;
      case 4:
        color = Colors.deepOrange;
        label = 'Hard';
        break;
      case 5:
        color = Colors.red;
        label = 'Expert';
        break;
      default:
        color = Colors.grey;
        label = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _openLesson(BuildContext context, LessonModel lesson) {
    Provider.of<LessonProvider>(
      context,
      listen: false,
    ).setCurrentLesson(lesson);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LessonDetailSheet(lesson: lesson),
    );
  }
}

class LessonDetailSheet extends StatefulWidget {
  final LessonModel lesson;

  const LessonDetailSheet({super.key, required this.lesson});

  @override
  State<LessonDetailSheet> createState() => _LessonDetailSheetState();
}

class _LessonDetailSheetState extends State<LessonDetailSheet> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.lesson.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.lesson.titleMalay,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              LinearProgressIndicator(
                value:
                    widget.lesson.contents.isEmpty
                        ? 0
                        : (_currentIndex + 1) / widget.lesson.contents.length,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF00796B),
                ),
              ),
              Expanded(
                child:
                    widget.lesson.contents.isEmpty
                        ? const Center(child: Text('No content available'))
                        : _buildContentView(),
              ),
              _buildNavigationButtons(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContentView() {
    final content = widget.lesson.contents[_currentIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF00796B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  content.malay,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00796B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  content.english,
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          if (content.phonemes != null && content.phonemes!.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Key Phonemes',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children:
                  content.phonemes!.map((phoneme) {
                    return Chip(
                      label: Text(phoneme),
                      backgroundColor: Colors.amber.shade50,
                    );
                  }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_currentIndex > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentIndex--;
                  });
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  side: const BorderSide(color: Color(0xFF00897B)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Previous',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF00897B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (_currentIndex > 0) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (_currentIndex < widget.lesson.contents.length - 1) {
                  setState(() {
                    _currentIndex++;
                  });
                } else {
                  _completeLesson();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00897B),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                _currentIndex < widget.lesson.contents.length - 1
                    ? 'Next'
                    : 'Complete',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _completeLesson() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.addXp(widget.lesson.xpReward);
    await authProvider.incrementActivityCount();

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lesson completed! +${widget.lesson.xpReward} XP'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

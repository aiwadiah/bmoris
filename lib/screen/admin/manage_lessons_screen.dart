import 'package:flutter/material.dart';
import '../../models/lesson_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/bmoris_back_button.dart';

class ManageLessonsScreen extends StatefulWidget {
  const ManageLessonsScreen({super.key});

  @override
  State<ManageLessonsScreen> createState() => _ManageLessonsScreenState();
}

class _ManageLessonsScreenState extends State<ManageLessonsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<LessonModel> _lessons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    setState(() => _isLoading = true);
    try {
      _lessons = await _firestoreService.getLessons();
    } catch (e) {
      // Handle error
    }
    setState(() => _isLoading = false);
  }

  Future<void> _deleteLesson(LessonModel lesson) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Lesson'),
            content: Text('Are you sure you want to delete "${lesson.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await _firestoreService.firestore
            .collection('lessons')
            .doc(lesson.id)
            .delete();
        _loadLessons();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lesson deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting lesson: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _addOrEditLesson([LessonModel? lesson]) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => _LessonFormScreen(lesson: lesson),
        fullscreenDialog: true,
      ),
    );

    if (result != null) {
      try {
        if (lesson == null) {
          // Add new lesson
          await _firestoreService.firestore.collection('lessons').add(result);
        } else {
          // Update existing lesson
          await _firestoreService.firestore
              .collection('lessons')
              .doc(lesson.id)
              .update(result);
        }
        _loadLessons();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(lesson == null ? 'Lesson added' : 'Lesson updated'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BMorisBackButton(),
        title: const Text('Manage Lessons'),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _lessons.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                onRefresh: _loadLessons,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _lessons.length,
                  itemBuilder: (context, index) {
                    final lesson = _lessons[index];
                    return _buildLessonCard(lesson);
                  },
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditLesson(),
        backgroundColor: const Color(0xFF00796B),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.book_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No lessons yet',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _addOrEditLesson(),
            icon: const Icon(Icons.add),
            label: const Text('Add First Lesson'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00796B),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonCard(LessonModel lesson) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF00796B),
          child: Text(
            '${lesson.difficulty}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(lesson.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lesson.titleMalay),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(lesson.category),
                  backgroundColor: Colors.blue.shade50,
                  labelStyle: const TextStyle(fontSize: 10),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
                Text(
                  '${lesson.contents.length} contents',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 8),
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
        trailing: PopupMenuButton(
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
          onSelected: (value) {
            if (value == 'edit') {
              _addOrEditLesson(lesson);
            } else if (value == 'delete') {
              _deleteLesson(lesson);
            }
          },
        ),
      ),
    );
  }
}

class _LessonFormScreen extends StatefulWidget {
  final LessonModel? lesson;

  const _LessonFormScreen({this.lesson});

  @override
  State<_LessonFormScreen> createState() => _LessonFormScreenState();
}

class _LessonFormScreenState extends State<_LessonFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _titleMalayController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _xpRewardController = TextEditingController();
  int _difficulty = 1;
  List<LessonContent> _contents = [];

  @override
  void initState() {
    super.initState();
    if (widget.lesson != null) {
      _titleController.text = widget.lesson!.title;
      _titleMalayController.text = widget.lesson!.titleMalay;
      _descriptionController.text = widget.lesson!.description;
      _categoryController.text = widget.lesson!.category;
      _xpRewardController.text = widget.lesson!.xpReward.toString();
      _difficulty = widget.lesson!.difficulty;
      _contents = List.from(widget.lesson!.contents);
    } else {
      _xpRewardController.text = '10';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleMalayController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _xpRewardController.dispose();
    super.dispose();
  }

  void _addContent() async {
    final result = await showDialog<LessonContent>(
      context: context,
      builder: (context) => _ContentFormDialog(),
    );

    if (result != null) {
      setState(() {
        _contents.add(result);
      });
    }
  }

  void _editContent(int index) async {
    final result = await showDialog<LessonContent>(
      context: context,
      builder: (context) => _ContentFormDialog(content: _contents[index]),
    );

    if (result != null) {
      setState(() {
        _contents[index] = result;
      });
    }
  }

  void _deleteContent(int index) {
    setState(() {
      _contents.removeAt(index);
    });
  }

  void _saveLesson() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, {
        'title': _titleController.text.trim(),
        'titleMalay': _titleMalayController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _categoryController.text.trim(),
        'difficulty': _difficulty,
        'xpReward': int.parse(_xpRewardController.text.trim()),
        'contents': _contents.map((c) => c.toMap()).toList(),
        'createdAt':
            widget.lesson?.createdAt.toIso8601String() ??
            DateTime.now().toIso8601String(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BMorisBackButton(),
        title: Text(widget.lesson == null ? 'Add Lesson' : 'Edit Lesson'),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveLesson),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basic Info Section
            const Text(
              'Basic Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title (English)',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleMalayController,
              decoration: const InputDecoration(
                labelText: 'Title (Malay)',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _difficulty,
              decoration: const InputDecoration(
                labelText: 'Difficulty',
                border: OutlineInputBorder(),
              ),
              items:
                  List.generate(5, (i) => i + 1)
                      .map(
                        (level) => DropdownMenuItem(
                          value: level,
                          child: Text('Level $level'),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                setState(() {
                  _difficulty = value!;
                });
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _xpRewardController,
              decoration: const InputDecoration(
                labelText: 'XP Reward',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 24),

            // Lesson Contents Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Lesson Contents',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _addContent,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Content'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00796B),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_contents.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.content_paste,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No contents yet',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...List.generate(_contents.length, (index) {
                final content = _contents[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF00796B),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(content.malay),
                    subtitle: Text('${content.english}\nType: ${content.type}'),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _editContent(index),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: () => _deleteContent(index),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

// Content Form Dialog
class _ContentFormDialog extends StatefulWidget {
  final LessonContent? content;

  const _ContentFormDialog({this.content});

  @override
  State<_ContentFormDialog> createState() => _ContentFormDialogState();
}

class _ContentFormDialogState extends State<_ContentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _malayController = TextEditingController();
  final _englishController = TextEditingController();
  final _audioUrlController = TextEditingController();
  String _type = 'text';

  @override
  void initState() {
    super.initState();
    if (widget.content != null) {
      _malayController.text = widget.content!.malay;
      _englishController.text = widget.content!.english;
      _audioUrlController.text = widget.content!.audioUrl ?? '';
      _type = widget.content!.type;
    }
  }

  @override
  void dispose() {
    _malayController.dispose();
    _englishController.dispose();
    _audioUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.content == null ? 'Add Content' : 'Edit Content'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(
                  labelText: 'Content Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'text', child: Text('Text')),
                  DropdownMenuItem(value: 'audio', child: Text('Audio')),
                  DropdownMenuItem(
                    value: 'pronunciation',
                    child: Text('Pronunciation'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _type = value!;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _malayController,
                decoration: const InputDecoration(
                  labelText: 'Malay Text',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _englishController,
                decoration: const InputDecoration(
                  labelText: 'English Translation',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              if (_type == 'audio' || _type == 'pronunciation')
                TextFormField(
                  controller: _audioUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Audio URL (optional)',
                    border: OutlineInputBorder(),
                    hintText: 'https://...',
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(
                context,
                LessonContent(
                  type: _type,
                  malay: _malayController.text.trim(),
                  english: _englishController.text.trim(),
                  audioUrl:
                      _audioUrlController.text.trim().isEmpty
                          ? null
                          : _audioUrlController.text.trim(),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00796B),
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../models/lesson_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/admin_ui.dart';
import '../../widgets/bmoris_back_button.dart';

class ManageLessonsScreen extends StatefulWidget {
  const ManageLessonsScreen({super.key});

  @override
  State<ManageLessonsScreen> createState() => _ManageLessonsScreenState();
}

class _ManageLessonsScreenState extends State<ManageLessonsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  List<LessonModel> _lessons = [];
  bool _isLoading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _loadLessons();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLessons() async {
    setState(() => _isLoading = true);
    try {
      _lessons = await _firestoreService.getLessons();
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  List<LessonModel> get _visibleLessons {
    final query = _searchController.text.trim().toLowerCase();
    return _lessons.where((lesson) {
      if (_filter == 'beginner' && lesson.difficulty > 2) return false;
      if (_filter == 'advanced' && lesson.difficulty < 3) return false;
      if (query.isEmpty) return true;
      return lesson.title.toLowerCase().contains(query) ||
          lesson.titleMalay.toLowerCase().contains(query) ||
          lesson.category.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _deleteLesson(LessonModel lesson) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Lesson', style: AdminUi.title()),
        content: Text('Are you sure you want to delete "${lesson.title}"?', style: AdminUi.body()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
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
        await _firestoreService.firestore.collection('lessons').doc(lesson.id).delete();
        await _loadLessons();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting lesson: $e')));
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
          await _firestoreService.firestore.collection('lessons').add(result);
        } else {
          await _firestoreService.firestore.collection('lessons').doc(lesson.id).update(result);
        }
        await _loadLessons();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lessons = _visibleLessons;
    return AdminPage(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditLesson(),
        backgroundColor: AdminUi.teal,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      child:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : AdminShell(
                title: 'Manage Lessons',
                subtitle: 'Organize learning modules, levels, and lesson content.',
                leading: const BMorisBackButton(),
                trailing: AdminActionButton.primary(label: 'Add', icon: Icons.add_rounded, onPressed: () => _addOrEditLesson()),
                child: Column(
                  children: [
                    AdminSearchField(controller: _searchController, hintText: 'Search lesson title or category'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        AdminPill(label: 'All', selected: _filter == 'all', onTap: () => setState(() => _filter = 'all')),
                        AdminPill(label: 'Beginner', selected: _filter == 'beginner', onTap: () => setState(() => _filter = 'beginner')),
                        AdminPill(label: 'Advanced', selected: _filter == 'advanced', onTap: () => setState(() => _filter = 'advanced')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (lessons.isEmpty)
                      AdminEmptyState(
                        icon: Icons.menu_book_outlined,
                        title: 'No lessons available',
                        subtitle: 'Create a new lesson to populate the library.',
                        action: AdminActionButton.primary(label: 'Add Lesson', onPressed: () => _addOrEditLesson()),
                      )
                    else
                      ...lessons.map((lesson) => AdminCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: AdminUi.mint,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(Icons.auto_stories_rounded, color: AdminUi.teal.withValues(alpha: .9)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          lesson.title,
                                          style: AdminUi.body(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      AdminPill(label: lesson.category),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    lesson.titleMalay,
                                    style: AdminUi.caption(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text('${lesson.contents.length} items', style: AdminUi.caption()),
                                      const SizedBox(width: 10),
                                      Text('Level ${lesson.difficulty}', style: AdminUi.caption()),
                                      const SizedBox(width: 10),
                                      Text('+${lesson.xpReward} XP', style: AdminUi.caption(const Color(0xFFE59B2F))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') _addOrEditLesson(lesson);
                                if (value == 'delete') _deleteLesson(lesson);
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(value: 'edit', child: Text('Edit')),
                                PopupMenuItem(value: 'delete', child: Text('Delete')),
                              ],
                            ),
                          ],
                        ),
                      )),
                  ],
                ),
              ),
    );
  }
}

class _LessonFormScreen extends StatefulWidget {
  const _LessonFormScreen({this.lesson});

  final LessonModel? lesson;

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
    final result = await showDialog<LessonContent>(context: context, builder: (context) => const _ContentFormDialog());
    if (result != null) {
      setState(() => _contents.add(result));
    }
  }

  void _editContent(int index) async {
    final result = await showDialog<LessonContent>(
      context: context,
      builder: (context) => _ContentFormDialog(content: _contents[index]),
    );
    if (result != null) {
      setState(() => _contents[index] = result);
    }
  }

  void _deleteContent(int index) => setState(() => _contents.removeAt(index));

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
        'createdAt': widget.lesson?.createdAt.toIso8601String() ?? DateTime.now().toIso8601String(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: AdminShell(
        title: widget.lesson == null ? 'Add Lesson' : 'Edit Lesson',
        subtitle: 'Structure lesson details, difficulty, and content blocks.',
        leading: const BMorisBackButton(),
        trailing: AdminActionButton.primary(label: 'Save', icon: Icons.check_rounded, onPressed: _saveLesson),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: const [
                  AdminPill(label: '1. Details', selected: true),
                  SizedBox(width: 8),
                  AdminPill(label: '2. Content'),
                  SizedBox(width: 8),
                  AdminPill(label: '3. Publish'),
                ],
              ),
              const SizedBox(height: 16),
              AdminCard(
                child: Column(
                  children: [
                    TextFormField(controller: _titleController, decoration: adminInputDecoration(label: 'Title (English)'), validator: _required),
                    const SizedBox(height: 12),
                    TextFormField(controller: _titleMalayController, decoration: adminInputDecoration(label: 'Title (Malay)'), validator: _required),
                    const SizedBox(height: 12),
                    TextFormField(controller: _descriptionController, decoration: adminInputDecoration(label: 'Description'), maxLines: 2, validator: _required),
                    const SizedBox(height: 12),
                    TextFormField(controller: _categoryController, decoration: adminInputDecoration(label: 'Category'), validator: _required),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: _difficulty,
                      decoration: adminInputDecoration(label: 'Difficulty'),
                      items: List.generate(5, (i) => i + 1).map((level) => DropdownMenuItem(value: level, child: Text('Level $level'))).toList(),
                      onChanged: (value) => setState(() => _difficulty = value!),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _xpRewardController,
                      decoration: adminInputDecoration(label: 'XP Reward'),
                      keyboardType: TextInputType.number,
                      validator: _required,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AdminCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AdminSectionTitle(
                      'Lesson Content',
                      trailing: AdminActionButton.primary(label: 'Add Item', icon: Icons.add_rounded, onPressed: _addContent),
                    ),
                    const SizedBox(height: 12),
                    if (_contents.isEmpty)
                      const AdminEmptyState(
                        icon: Icons.library_books_outlined,
                        title: 'No content items yet',
                        subtitle: 'Add vocabulary, audio, or pronunciation blocks for this lesson.',
                      )
                    else
                      ...List.generate(_contents.length, (index) {
                        final content = _contents[index];
                        return AdminCard(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AdminUi.mint,
                                child: Text('${index + 1}', style: AdminUi.caption(AdminUi.teal)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(content.malay, style: AdminUi.body(), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    Text(content.english, style: AdminUi.caption(), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              AdminPill(label: content.type),
                              IconButton(onPressed: () => _editContent(index), icon: const Icon(Icons.edit_outlined, color: AdminUi.teal)),
                              IconButton(onPressed: () => _deleteContent(index), icon: const Icon(Icons.delete_outline_rounded, color: AdminUi.danger)),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _required(String? value) => value == null || value.isEmpty ? 'Required' : null;
}

class _ContentFormDialog extends StatefulWidget {
  const _ContentFormDialog({this.content});

  final LessonContent? content;

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
      title: Text(widget.content == null ? 'Add Content Item' : 'Edit Content Item', style: AdminUi.title()),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _type,
                decoration: adminInputDecoration(label: 'Content Type'),
                items: const [
                  DropdownMenuItem(value: 'text', child: Text('Text')),
                  DropdownMenuItem(value: 'audio', child: Text('Audio')),
                  DropdownMenuItem(value: 'pronunciation', child: Text('Pronunciation')),
                ],
                onChanged: (value) => setState(() => _type = value!),
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _malayController, decoration: adminInputDecoration(label: 'Malay Text'), validator: _required),
              const SizedBox(height: 12),
              TextFormField(controller: _englishController, decoration: adminInputDecoration(label: 'English Translation'), validator: _required),
              if (_type == 'audio' || _type == 'pronunciation') ...[
                const SizedBox(height: 12),
                TextFormField(controller: _audioUrlController, decoration: adminInputDecoration(label: 'Audio URL')),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(
                context,
                LessonContent(
                  type: _type,
                  malay: _malayController.text.trim(),
                  english: _englishController.text.trim(),
                  audioUrl: _audioUrlController.text.trim().isEmpty ? null : _audioUrlController.text.trim(),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AdminUi.teal, foregroundColor: Colors.white),
          child: const Text('Save'),
        ),
      ],
    );
  }

  String? _required(String? value) => value == null || value.isEmpty ? 'Required' : null;
}

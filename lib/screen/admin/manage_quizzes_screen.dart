import 'package:flutter/material.dart';

import '../../models/quiz_model.dart';
import '../../services/ai_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/admin_ui.dart';
import '../../widgets/bmoris_back_button.dart';

class ManageQuizzesScreen extends StatefulWidget {
  const ManageQuizzesScreen({super.key});

  @override
  State<ManageQuizzesScreen> createState() => _ManageQuizzesScreenState();
}

class _ManageQuizzesScreenState extends State<ManageQuizzesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AIService _aiService = AIService();
  final TextEditingController _searchController = TextEditingController();
  List<QuizModel> _quizzes = [];
  bool _isLoading = true;
  bool _isGenerating = false;
  int? _selectedDifficulty;
  String? _selectedCategory;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadQuizzes() async {
    setState(() => _isLoading = true);
    try {
      _quizzes = await _firestoreService.getQuizzes();
      final categorySet = <String>{};
      for (final quiz in _quizzes) {
        categorySet.add(quiz.category);
      }
      _categories = categorySet.toList()..sort();
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  List<QuizModel> get _filteredQuizzes {
    final query = _searchController.text.trim().toLowerCase();
    return _quizzes.where((quiz) {
      if (_selectedDifficulty != null && quiz.difficulty != _selectedDifficulty) return false;
      if (_selectedCategory != null && quiz.category != _selectedCategory) return false;
      if (query.isEmpty) return true;
      return quiz.question.toLowerCase().contains(query) ||
          quiz.questionMalay.toLowerCase().contains(query) ||
          quiz.category.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _deleteQuiz(QuizModel quiz) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Quiz', style: AdminUi.title()),
        content: Text('Are you sure you want to delete this quiz?', style: AdminUi.body()),
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
        await _firestoreService.firestore.collection('quizzes').doc(quiz.id).delete();
        await _loadQuizzes();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting quiz: $e')));
        }
      }
    }
  }

  Future<void> _generateQuizWithAI() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _AIQuizGeneratorDialog(),
    );
    if (result == null) return;
    setState(() => _isGenerating = true);
    try {
      final quizData = await _aiService.generateQuiz(
        topic: result['topic']!,
        difficulty: result['difficulty']!,
        category: result['category']!,
      );
      if (quizData != null) {
        await _firestoreService.firestore.collection('quizzes').add(quizData);
        await _loadQuizzes();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    if (mounted) setState(() => _isGenerating = false);
  }

  Future<void> _addOrEditQuiz([QuizModel? quiz]) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => _QuizEditorScreen(quiz: quiz),
        fullscreenDialog: true,
      ),
    );
    if (result != null) {
      try {
        if (quiz == null) {
          await _firestoreService.firestore.collection('quizzes').add(result);
        } else {
          await _firestoreService.firestore.collection('quizzes').doc(quiz.id).update(result);
        }
        await _loadQuizzes();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizzes = _filteredQuizzes;
    return AdminPage(
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: _isGenerating ? null : _generateQuizWithAI,
            heroTag: 'ai_quiz',
            backgroundColor: const Color(0xFFE1B647),
            child:
                _isGenerating
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.auto_awesome_rounded, color: Colors.white),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () => _addOrEditQuiz(),
            heroTag: 'manual_quiz',
            backgroundColor: AdminUi.teal,
            child: const Icon(Icons.add_rounded, color: Colors.white),
          ),
        ],
      ),
      child:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : AdminShell(
                title: 'Manage Quizzes',
                subtitle: 'Curate quiz banks, filters, and AI-generated question sets.',
                leading: const BMorisBackButton(),
                child: Column(
                  children: [
                    AdminSearchField(controller: _searchController, hintText: 'Search quiz question or category'),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          AdminPill(
                            label: 'All Levels',
                            selected: _selectedDifficulty == null,
                            onTap: () => setState(() => _selectedDifficulty = null),
                          ),
                          const SizedBox(width: 8),
                          ...List.generate(5, (i) => i + 1).map(
                            (level) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: AdminPill(
                                label: 'Level $level',
                                selected: _selectedDifficulty == level,
                                onTap: () => setState(() => _selectedDifficulty = level),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_categories.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            AdminPill(
                              label: 'All Categories',
                              selected: _selectedCategory == null,
                              onTap: () => setState(() => _selectedCategory = null),
                            ),
                            const SizedBox(width: 8),
                            ..._categories.map(
                              (category) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: AdminPill(
                                  label: category,
                                  selected: _selectedCategory == category,
                                  onTap: () => setState(() => _selectedCategory = category),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (quizzes.isEmpty)
                      AdminEmptyState(
                        icon: Icons.quiz_outlined,
                        title: 'No quizzes available',
                        subtitle: 'Add a manual quiz or generate one with AI.',
                        action: AdminActionButton.primary(label: 'Add Quiz', onPressed: () => _addOrEditQuiz()),
                      )
                    else
                      ...quizzes.map((quiz) => AdminCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: _difficultyColor(quiz.difficulty).withValues(alpha: .14),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Text(
                                  '${quiz.difficulty}',
                                  style: AdminUi.title(_difficultyColor(quiz.difficulty)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(quiz.question, style: AdminUi.body(), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Text(quiz.questionMalay, style: AdminUi.caption(), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      AdminPill(label: quiz.category),
                                      const SizedBox(width: 8),
                                      Text('${quiz.options.length} options', style: AdminUi.caption()),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') _addOrEditQuiz(quiz);
                                if (value == 'delete') _deleteQuiz(quiz);
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

  Color _difficultyColor(int difficulty) {
    switch (difficulty) {
      case 1:
        return const Color(0xFF3DA96B);
      case 2:
        return const Color(0xFF58B77B);
      case 3:
        return const Color(0xFFE1B647);
      case 4:
        return const Color(0xFFEB8D4B);
      case 5:
        return const Color(0xFFE06363);
      default:
        return AdminUi.muted;
    }
  }
}

class _AIQuizGeneratorDialog extends StatefulWidget {
  const _AIQuizGeneratorDialog();

  @override
  State<_AIQuizGeneratorDialog> createState() => _AIQuizGeneratorDialogState();
}

class _AIQuizGeneratorDialogState extends State<_AIQuizGeneratorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _topicController = TextEditingController();
  final _categoryController = TextEditingController();
  int _difficulty = 1;

  @override
  void dispose() {
    _topicController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Generate Quiz with AI', style: AdminUi.title()),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(controller: _topicController, decoration: adminInputDecoration(label: 'Topic'), validator: _required),
            const SizedBox(height: 12),
            TextFormField(controller: _categoryController, decoration: adminInputDecoration(label: 'Category'), validator: _required),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _difficulty,
              decoration: adminInputDecoration(label: 'Difficulty'),
              items: List.generate(5, (i) => i + 1).map((level) => DropdownMenuItem(value: level, child: Text('Level $level'))).toList(),
              onChanged: (value) => setState(() => _difficulty = value!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'topic': _topicController.text.trim(),
                'category': _categoryController.text.trim(),
                'difficulty': _difficulty,
              });
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE1B647), foregroundColor: Colors.white),
          child: const Text('Generate'),
        ),
      ],
    );
  }

  String? _required(String? value) => value == null || value.isEmpty ? 'Required' : null;
}

class _QuizEditorScreen extends StatefulWidget {
  const _QuizEditorScreen({this.quiz});

  final QuizModel? quiz;

  @override
  State<_QuizEditorScreen> createState() => _QuizEditorScreenState();
}

class _QuizEditorScreenState extends State<_QuizEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _questionMalayController = TextEditingController();
  final _categoryController = TextEditingController();
  final List<TextEditingController> _optionControllers = [];
  int _difficulty = 1;
  int _correctIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.quiz != null) {
      _questionController.text = widget.quiz!.question;
      _questionMalayController.text = widget.quiz!.questionMalay;
      _categoryController.text = widget.quiz!.category;
      _difficulty = widget.quiz!.difficulty;
      _correctIndex = widget.quiz!.correctIndex;
      for (final option in widget.quiz!.options) {
        _optionControllers.add(TextEditingController(text: option));
      }
    } else {
      for (int i = 0; i < 4; i++) {
        _optionControllers.add(TextEditingController());
      }
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _questionMalayController.dispose();
    _categoryController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveQuiz() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, {
        'question': _questionController.text.trim(),
        'questionMalay': _questionMalayController.text.trim(),
        'category': _categoryController.text.trim(),
        'difficulty': _difficulty,
        'correctIndex': _correctIndex,
        'options': _optionControllers.map((c) => c.text.trim()).toList(),
        'lessonId': widget.quiz?.lessonId ?? '',
        'type': widget.quiz?.type ?? 'multiple_choice',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: AdminShell(
        title: widget.quiz == null ? 'Add Quiz' : 'Edit Quiz',
        subtitle: 'Build a question set and mark the correct answer.',
        leading: const BMorisBackButton(),
        trailing: AdminActionButton.primary(label: 'Save', icon: Icons.check_rounded, onPressed: _saveQuiz),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: const [
                  AdminPill(label: '1. Question', selected: true),
                  SizedBox(width: 8),
                  AdminPill(label: '2. Answers'),
                  SizedBox(width: 8),
                  AdminPill(label: '3. Publish'),
                ],
              ),
              const SizedBox(height: 16),
              AdminCard(
                child: Column(
                  children: [
                    TextFormField(controller: _questionController, decoration: adminInputDecoration(label: 'Question (English)'), maxLines: 2, validator: _required),
                    const SizedBox(height: 12),
                    TextFormField(controller: _questionMalayController, decoration: adminInputDecoration(label: 'Question (Malay)'), maxLines: 2, validator: _required),
                    const SizedBox(height: 12),
                    TextFormField(controller: _categoryController, decoration: adminInputDecoration(label: 'Category'), validator: _required),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: _difficulty,
                      decoration: adminInputDecoration(label: 'Difficulty'),
                      items: List.generate(5, (i) => i + 1).map((level) => DropdownMenuItem(value: level, child: Text('Level $level'))).toList(),
                      onChanged: (value) => setState(() => _difficulty = value!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AdminCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AdminSectionTitle('Answer Options'),
                    const SizedBox(height: 8),
                    Text('Select the correct answer using the radio button.', style: AdminUi.caption()),
                    const SizedBox(height: 12),
                    ...List.generate(_optionControllers.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Radio<int>(
                              value: index,
                              groupValue: _correctIndex,
                              onChanged: (value) => setState(() => _correctIndex = value!),
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: _optionControllers[index],
                                decoration: adminInputDecoration(label: 'Option ${String.fromCharCode(65 + index)}'),
                                validator: _required,
                              ),
                            ),
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

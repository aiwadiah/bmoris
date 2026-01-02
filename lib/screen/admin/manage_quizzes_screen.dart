import 'package:flutter/material.dart';
import '../../models/quiz_model.dart';
import '../../services/firestore_service.dart';
import '../../services/ai_service.dart';

class ManageQuizzesScreen extends StatefulWidget {
  const ManageQuizzesScreen({super.key});

  @override
  State<ManageQuizzesScreen> createState() => _ManageQuizzesScreenState();
}

class _ManageQuizzesScreenState extends State<ManageQuizzesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AIService _aiService = AIService();
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
  }

  Future<void> _loadQuizzes() async {
    setState(() => _isLoading = true);
    try {
      _quizzes = await _firestoreService.getQuizzes();
      _extractCategories();
    } catch (e) {
      // Handle error
    }
    setState(() => _isLoading = false);
  }

  void _extractCategories() {
    final categorySet = <String>{};
    for (var quiz in _quizzes) {
      categorySet.add(quiz.category);
    }
    _categories = categorySet.toList()..sort();
  }

  List<QuizModel> get _filteredQuizzes {
    return _quizzes.where((quiz) {
      if (_selectedDifficulty != null && quiz.difficulty != _selectedDifficulty) {
        return false;
      }
      if (_selectedCategory != null && quiz.category != _selectedCategory) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> _deleteQuiz(QuizModel quiz) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quiz'),
        content: Text('Are you sure you want to delete this quiz?'),
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
            .collection('quizzes')
            .doc(quiz.id)
            .delete();
        _loadQuizzes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Quiz deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting quiz: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _generateQuizWithAI() async {
    // Show dialog to get topic, difficulty, category
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AIQuizGeneratorDialog(),
    );

    if (result == null) return;

    setState(() => _isGenerating = true);

    try {
      final quizData = await _aiService.generateQuiz(
        topic: result['topic']!,
        difficulty: result['difficulty']!,
        category: result['category']!,
      );

      setState(() => _isGenerating = false);

      if (quizData != null) {
        // Save to Firestore
        await _firestoreService.firestore.collection('quizzes').add(quizData);
        _loadQuizzes();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('AI-generated quiz added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to generate quiz. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addOrEditQuiz([QuizModel? quiz]) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _QuizFormDialog(quiz: quiz),
    );

    if (result != null) {
      try {
        if (quiz == null) {
          // Add new quiz
          await _firestoreService.firestore.collection('quizzes').add(result);
        } else {
          // Update existing quiz
          await _firestoreService.firestore
              .collection('quizzes')
              .doc(quiz.id)
              .update(result);
        }
        _loadQuizzes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(quiz == null ? 'Quiz added' : 'Quiz updated'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredQuizzes = _filteredQuizzes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Quizzes'),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter Section
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey.shade100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Difficulty Filter
                          Expanded(
                            child: DropdownButtonFormField<int?>(
                              value: _selectedDifficulty,
                              decoration: const InputDecoration(
                                labelText: 'Difficulty',
                                prefixIcon: Icon(Icons.signal_cellular_alt),
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('All'),
                                ),
                                ...List.generate(5, (i) => i + 1).map((level) {
                                  return DropdownMenuItem<int?>(
                                    value: level,
                                    child: Text('Level $level'),
                                  );
                                }),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedDifficulty = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Category Filter
                          Expanded(
                            child: DropdownButtonFormField<String?>(
                              value: _selectedCategory,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                prefixIcon: Icon(Icons.category),
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('All'),
                                ),
                                ..._categories.map((category) {
                                  return DropdownMenuItem<String?>(
                                    value: category,
                                    child: Text(category),
                                  );
                                }),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      if (_selectedDifficulty != null || _selectedCategory != null) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedDifficulty = null;
                              _selectedCategory = null;
                            });
                          },
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear Filters'),
                        ),
                      ],
                    ],
                  ),
                ),
                // Quiz List
                Expanded(
                  child: _quizzes.isEmpty
                      ? _buildEmptyState()
                      : filteredQuizzes.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off, size: 80, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No quizzes match your filters',
                                    style: TextStyle(fontSize: 18, color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadQuizzes,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: filteredQuizzes.length,
                                itemBuilder: (context, index) {
                                  final quiz = filteredQuizzes[index];
                                  return _buildQuizCard(quiz);
                                },
                              ),
                            ),
                ),
              ],
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: _isGenerating ? null : _generateQuizWithAI,
            backgroundColor: _isGenerating ? Colors.grey : Colors.purple,
            heroTag: 'ai_quiz',
            child: _isGenerating
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.auto_awesome, color: Colors.white),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            onPressed: () => _addOrEditQuiz(),
            backgroundColor: const Color(0xFF00796B),
            heroTag: 'manual_quiz',
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No quizzes yet',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _addOrEditQuiz(),
            icon: const Icon(Icons.add),
            label: const Text('Add First Quiz'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00796B),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizCard(QuizModel quiz) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getDifficultyColor(quiz.difficulty),
          child: Text(
            '${quiz.difficulty}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(quiz.question, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(quiz.questionMalay, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(quiz.category),
                  backgroundColor: Colors.blue.shade50,
                  labelStyle: const TextStyle(fontSize: 10),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
                Text(
                  '${quiz.options.length} options',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
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
              _addOrEditQuiz(quiz);
            } else if (value == 'delete') {
              _deleteQuiz(quiz);
            }
          },
        ),
      ),
    );
  }

  Color _getDifficultyColor(int difficulty) {
    switch (difficulty) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.deepOrange;
      case 5:
        return Colors.red;
      default:
        return Colors.grey;
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
      title: Row(
        children: const [
          Icon(Icons.auto_awesome, color: Colors.purple),
          SizedBox(width: 8),
          Text('Generate Quiz with AI'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _topicController,
              decoration: const InputDecoration(
                labelText: 'Topic',
                border: OutlineInputBorder(),
                hintText: 'e.g., Greetings, Numbers, Family',
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                hintText: 'e.g., Vocabulary, Grammar',
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
              items: List.generate(5, (i) => i + 1)
                  .map((level) => DropdownMenuItem(
                        value: level,
                        child: Text('Level $level'),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _difficulty = value!;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'topic': _topicController.text.trim(),
                'category': _categoryController.text.trim(),
                'difficulty': _difficulty,
              });
            }
          },
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Generate'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _QuizFormDialog extends StatefulWidget {
  final QuizModel? quiz;

  const _QuizFormDialog({this.quiz});

  @override
  State<_QuizFormDialog> createState() => _QuizFormDialogState();
}

class _QuizFormDialogState extends State<_QuizFormDialog> {
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

      for (var option in widget.quiz!.options) {
        final controller = TextEditingController(text: option);
        _optionControllers.add(controller);
      }
    } else {
      // Default 4 options
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
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.quiz == null ? 'Add Quiz' : 'Edit Quiz'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _questionController,
                decoration: const InputDecoration(
                  labelText: 'Question (English)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _questionMalayController,
                decoration: const InputDecoration(
                  labelText: 'Question (Malay)',
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
                items: List.generate(5, (i) => i + 1)
                    .map((level) => DropdownMenuItem(
                          value: level,
                          child: Text('Level $level'),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _difficulty = value!;
                  });
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'Options (Select correct answer):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...List.generate(_optionControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Radio<int>(
                        value: index,
                        groupValue: _correctIndex,
                        onChanged: (value) {
                          setState(() {
                            _correctIndex = value!;
                          });
                        },
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _optionControllers[index],
                          decoration: InputDecoration(
                            labelText: 'Option ${String.fromCharCode(65 + index)}',
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                );
              }),
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

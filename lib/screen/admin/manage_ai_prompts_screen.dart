import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../widgets/admin_ui.dart';
import '../../widgets/bmoris_back_button.dart';
import '../../services/firestore_service.dart';

class ManageAIPromptsScreen extends StatefulWidget {
  const ManageAIPromptsScreen({super.key});

  @override
  State<ManageAIPromptsScreen> createState() => _ManageAIPromptsScreenState();
}

class _ManageAIPromptsScreenState extends State<ManageAIPromptsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  Map<String, AIPrompt> _prompts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrompts();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPrompts() async {
    setState(() => _isLoading = true);
    try {
      final doc = await _firestoreService.firestore.collection('settings').doc('ai_prompts').get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _prompts = {
          'pronunciation': AIPrompt(
            id: 'pronunciation',
            name: 'Tutor Feedback',
            description: 'Prompt used to analyze spoken pronunciation.',
            prompt: data['pronunciation'] ?? _defaultPronunciationPrompt,
          ),
          'feedback': AIPrompt(
            id: 'feedback',
            name: 'Feedback Replies',
            description: 'Prompt used to produce structured learner feedback.',
            prompt: data['feedback'] ?? _defaultFeedbackPrompt,
          ),
          'quiz_generation': AIPrompt(
            id: 'quiz_generation',
            name: 'Quiz Builder',
            description: 'Prompt used to generate new multiple-choice quizzes.',
            prompt: data['quiz_generation'] ?? _defaultQuizPrompt,
          ),
        };
      } else {
        _prompts = {
          'pronunciation': AIPrompt(id: 'pronunciation', name: 'Tutor Feedback', description: 'Prompt used to analyze spoken pronunciation.', prompt: _defaultPronunciationPrompt),
          'feedback': AIPrompt(id: 'feedback', name: 'Feedback Replies', description: 'Prompt used to produce structured learner feedback.', prompt: _defaultFeedbackPrompt),
          'quiz_generation': AIPrompt(id: 'quiz_generation', name: 'Quiz Builder', description: 'Prompt used to generate new multiple-choice quizzes.', prompt: _defaultQuizPrompt),
        };
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  List<AIPrompt> get _visiblePrompts {
    final query = _searchController.text.trim().toLowerCase();
    final prompts = _prompts.values.toList();
    if (query.isEmpty) return prompts;
    return prompts.where((prompt) {
      return prompt.name.toLowerCase().contains(query) ||
          prompt.description.toLowerCase().contains(query) ||
          prompt.prompt.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _savePrompt(AIPrompt prompt) async {
    try {
      await _firestoreService.firestore.collection('settings').doc('ai_prompts').set({
        prompt.id: prompt.prompt,
      }, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prompt saved successfully'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving prompt: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _editPrompt(AIPrompt prompt) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => _PromptEditorScreen(prompt: prompt), fullscreenDialog: true),
    );
    if (result != null) {
      setState(() {
        _prompts[prompt.id] = AIPrompt(
          id: prompt.id,
          name: prompt.name,
          description: prompt.description,
          prompt: result,
        );
      });
      await _savePrompt(_prompts[prompt.id]!);
    }
  }

  Future<void> _resetToDefault(AIPrompt prompt) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset to Default', style: AdminUi.title()),
        content: Text('Reset "${prompt.name}" to its default prompt?', style: AdminUi.body()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reset')),
        ],
      ),
    );
    if (confirm == true) {
      String defaultPrompt;
      switch (prompt.id) {
        case 'pronunciation':
          defaultPrompt = _defaultPronunciationPrompt;
          break;
        case 'feedback':
          defaultPrompt = _defaultFeedbackPrompt;
          break;
        case 'quiz_generation':
          defaultPrompt = _defaultQuizPrompt;
          break;
        default:
          return;
      }
      setState(() {
        _prompts[prompt.id] = AIPrompt(
          id: prompt.id,
          name: prompt.name,
          description: prompt.description,
          prompt: defaultPrompt,
        );
      });
      await _savePrompt(_prompts[prompt.id]!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prompts = _visiblePrompts;
    return AdminPage(
      child:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : AdminShell(
                title: 'AI Prompt Library',
                subtitle: 'Tune how the assistant analyzes, replies, and builds content.',
                leading: const BMorisBackButton(),
                child: Column(
                  children: [
                    AdminSearchField(controller: _searchController, hintText: 'Search prompts'),
                    const SizedBox(height: 16),
                    ...prompts.map((prompt) => AdminCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AdminUi.mint,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(_getPromptIcon(prompt.id), color: AdminUi.teal),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(prompt.name, style: AdminUi.title()),
                                    Text(prompt.description, style: AdminUi.caption()),
                                  ],
                                ),
                              ),
                              const AdminPill(label: 'Published', selected: true),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F8FA),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AdminUi.border),
                            ),
                            child: Text(
                              prompt.prompt.length > 180 ? '${prompt.prompt.substring(0, 180)}...' : prompt.prompt,
                              style: AdminUi.caption(AdminUi.text),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: AdminActionButton.outlined(
                                  label: 'Reset',
                                  icon: Icons.restart_alt_rounded,
                                  onPressed: () => _resetToDefault(prompt),
                                  expanded: true,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: AdminActionButton.primary(
                                  label: 'Edit Prompt',
                                  icon: Icons.edit_outlined,
                                  onPressed: () => _editPrompt(prompt),
                                  expanded: true,
                                ),
                              ),
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

  IconData _getPromptIcon(String id) {
    switch (id) {
      case 'pronunciation':
        return Icons.record_voice_over_rounded;
      case 'feedback':
        return Icons.forum_outlined;
      case 'quiz_generation':
        return Icons.quiz_rounded;
      default:
        return Icons.settings_outlined;
    }
  }

  String get _defaultPronunciationPrompt => '''
You are a Bahasa Melayu pronunciation expert. Analyze the user's pronunciation and provide detailed feedback.

Target text: {target_text}
User's spoken text: {spoken_text}

Provide:
1. Overall accuracy score (0-100)
2. Phoneme-by-phoneme analysis
3. Specific suggestions for improvement
4. Encouraging feedback

Be constructive and helpful. Focus on the most important improvements first.
''';

  String get _defaultFeedbackPrompt => '''
You are a helpful language learning assistant for Bahasa Melayu.

Generate encouraging and constructive feedback for the user based on their performance.

Performance data: {performance_data}

Provide:
1. Positive reinforcement
2. Areas for improvement
3. Specific actionable tips
4. Motivation to continue learning

Keep feedback brief, encouraging, and actionable.
''';

  String get _defaultQuizPrompt => '''
You are a Bahasa Melayu language expert creating educational quiz questions.

Generate a multiple-choice quiz question for:
Topic: {topic}
Difficulty level: {difficulty}

Requirements:
1. Question in both English and Bahasa Melayu
2. 4 answer options
3. One correct answer
4. Educational and engaging
5. Appropriate for the difficulty level

Return as JSON: {"question": "", "questionMalay": "", "options": [], "correctIndex": 0}
''';
}

class AIPrompt {
  final String id;
  final String name;
  final String description;
  final String prompt;

  AIPrompt({required this.id, required this.name, required this.description, required this.prompt});
}

class _PromptEditorScreen extends StatefulWidget {
  const _PromptEditorScreen({required this.prompt});

  final AIPrompt prompt;

  @override
  State<_PromptEditorScreen> createState() => _PromptEditorScreenState();
}

class _PromptEditorScreenState extends State<_PromptEditorScreen> {
  late final TextEditingController _controller;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.prompt.prompt);
    _controller.addListener(() {
      if (!_hasChanges) setState(() => _hasChanges = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unsaved Changes', style: AdminUi.title()),
        content: Text('You have unsaved changes. Discard them?', style: AdminUi.body()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) Navigator.pop(context);
      },
      child: AdminPage(
        child: AdminShell(
          title: 'Edit AI Prompt',
          subtitle: widget.prompt.name,
          leading: const BMorisBackButton(),
          trailing: AdminActionButton.primary(label: 'Save', icon: Icons.check_rounded, onPressed: () => Navigator.pop(context, _controller.text)),
          child: Column(
            children: [
              AdminCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Available variables', style: AdminUi.title()),
                    const SizedBox(height: 10),
                    _variable('{target_text}', 'The text the user should pronounce'),
                    _variable('{spoken_text}', 'The text transcribed from user speech'),
                    _variable('{performance_data}', 'User performance metrics'),
                    _variable('{topic}', 'Quiz topic'),
                    _variable('{difficulty}', 'Difficulty level'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AdminCard(
                child: SizedBox(
                  height: 420,
                  child: TextField(
                    controller: _controller,
                    expands: true,
                    maxLines: null,
                    decoration: adminInputDecoration(label: 'Prompt body'),
                    style: AdminUi.body(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _variable(String variable, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F3F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(variable, style: AdminUi.caption(AdminUi.text)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(description, style: AdminUi.caption())),
        ],
      ),
    );
  }
}

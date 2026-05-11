import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../widgets/bmoris_back_button.dart';

class ManageAIPromptsScreen extends StatefulWidget {
  const ManageAIPromptsScreen({super.key});

  @override
  State<ManageAIPromptsScreen> createState() => _ManageAIPromptsScreenState();
}

class _ManageAIPromptsScreenState extends State<ManageAIPromptsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  Map<String, AIPrompt> _prompts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrompts();
  }

  Future<void> _loadPrompts() async {
    setState(() => _isLoading = true);
    try {
      final doc =
          await _firestoreService.firestore
              .collection('settings')
              .doc('ai_prompts')
              .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _prompts = {
          'pronunciation': AIPrompt(
            id: 'pronunciation',
            name: 'Pronunciation Analysis',
            description: 'Prompt for analyzing user pronunciation',
            prompt: data['pronunciation'] ?? _defaultPronunciationPrompt,
          ),
          'feedback': AIPrompt(
            id: 'feedback',
            name: 'Feedback Generation',
            description: 'Prompt for generating helpful feedback',
            prompt: data['feedback'] ?? _defaultFeedbackPrompt,
          ),
          'quiz_generation': AIPrompt(
            id: 'quiz_generation',
            name: 'Quiz Generation',
            description: 'Prompt for generating quiz questions',
            prompt: data['quiz_generation'] ?? _defaultQuizPrompt,
          ),
        };
      } else {
        // Initialize with defaults
        _prompts = {
          'pronunciation': AIPrompt(
            id: 'pronunciation',
            name: 'Pronunciation Analysis',
            description: 'Prompt for analyzing user pronunciation',
            prompt: _defaultPronunciationPrompt,
          ),
          'feedback': AIPrompt(
            id: 'feedback',
            name: 'Feedback Generation',
            description: 'Prompt for generating helpful feedback',
            prompt: _defaultFeedbackPrompt,
          ),
          'quiz_generation': AIPrompt(
            id: 'quiz_generation',
            name: 'Quiz Generation',
            description: 'Prompt for generating quiz questions',
            prompt: _defaultQuizPrompt,
          ),
        };
      }
    } catch (e) {
      // Handle error
    }
    setState(() => _isLoading = false);
  }

  Future<void> _savePrompt(AIPrompt prompt) async {
    try {
      await _firestoreService.firestore
          .collection('settings')
          .doc('ai_prompts')
          .set({prompt.id: prompt.prompt}, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prompt saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving prompt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editPrompt(AIPrompt prompt) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => _PromptEditorScreen(prompt: prompt),
        fullscreenDialog: true,
      ),
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
      builder:
          (context) => AlertDialog(
            title: const Text('Reset to Default'),
            content: Text('Reset "${prompt.name}" to default prompt?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.orange),
                child: const Text('Reset'),
              ),
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prompt reset to default'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BMorisBackButton(),
        title: const Text('Manage AI Prompts'),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadPrompts,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'AI Training Prompts',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Configure the prompts used by the AI to analyze pronunciation, generate feedback, and create quiz questions.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ..._prompts.values.map(
                      (prompt) => _buildPromptCard(prompt),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildPromptCard(AIPrompt prompt) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getPromptIcon(prompt.id), color: const Color(0xFF00796B)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prompt.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        prompt.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                prompt.prompt.length > 200
                    ? '${prompt.prompt.substring(0, 200)}...'
                    : prompt.prompt,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _resetToDefault(prompt),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Reset'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _editPrompt(prompt),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit Prompt'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00796B),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPromptIcon(String id) {
    switch (id) {
      case 'pronunciation':
        return Icons.record_voice_over;
      case 'feedback':
        return Icons.feedback;
      case 'quiz_generation':
        return Icons.quiz;
      default:
        return Icons.settings;
    }
  }

  // Default prompts
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

  AIPrompt({
    required this.id,
    required this.name,
    required this.description,
    required this.prompt,
  });
}

class _PromptEditorScreen extends StatefulWidget {
  final AIPrompt prompt;

  const _PromptEditorScreen({required this.prompt});

  @override
  State<_PromptEditorScreen> createState() => _PromptEditorScreenState();
}

class _PromptEditorScreenState extends State<_PromptEditorScreen> {
  late TextEditingController _controller;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.prompt.prompt);
    _controller.addListener(() {
      if (!_hasChanges) {
        setState(() {
          _hasChanges = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.pop(context, _controller.text);
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Unsaved Changes'),
            content: const Text('You have unsaved changes. Discard them?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
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
        if (shouldPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: const BMorisBackButton(),
          title: Text('Edit ${widget.prompt.name}'),
          backgroundColor: const Color(0xFF00796B),
          foregroundColor: Colors.white,
          actions: [
            IconButton(icon: const Icon(Icons.check), onPressed: _save),
          ],
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available Variables:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildVariableChip(
                    '{target_text}',
                    'The text the user should pronounce',
                  ),
                  _buildVariableChip(
                    '{spoken_text}',
                    'The text transcribed from user speech',
                  ),
                  _buildVariableChip(
                    '{performance_data}',
                    'User performance metrics',
                  ),
                  _buildVariableChip('{topic}', 'Quiz topic'),
                  _buildVariableChip('{difficulty}', 'Difficulty level (1-5)'),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  decoration: const InputDecoration(
                    hintText: 'Enter your AI prompt here...',
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariableChip(String variable, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              variable,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(description, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

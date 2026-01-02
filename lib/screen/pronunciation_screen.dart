import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/auth_provider.dart';
import '../services/speech_service.dart';
import '../services/firestore_service.dart';
import '../models/pronunciation_model.dart';

class PronunciationScreen extends StatefulWidget {
  const PronunciationScreen({super.key});

  @override
  State<PronunciationScreen> createState() => _PronunciationScreenState();
}

class _PronunciationScreenState extends State<PronunciationScreen> {
  final SpeechService _speechService = SpeechService();
  final FirestoreService _firestoreService = FirestoreService();

  bool _isRecording = false;
  bool _isInitialized = false;
  String _spokenText = '';
  String _feedbackText = 'Press the mic to start speaking.';
  double _accuracyScore = 0.0;
  List<PhonemeAnalysis> _phonemeAnalysis = [];

  int _currentPhraseIndex = 0;
  final List<Map<String, String>> _phrases = [
    {'malay': 'Apa khabar?', 'english': 'How are you?'},
    {'malay': 'Selamat pagi', 'english': 'Good morning'},
    {'malay': 'Terima kasih', 'english': 'Thank you'},
    {'malay': 'Sama-sama', 'english': "You're welcome"},
    {'malay': 'Saya suka belajar', 'english': 'I like to learn'},
    {'malay': 'Apa nama awak?', 'english': 'What is your name?'},
    {'malay': 'Saya dari Malaysia', 'english': 'I am from Malaysia'},
    {'malay': 'Selamat malam', 'english': 'Good night'},
  ];

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      _isInitialized = await _speechService.initialize();
      if (!_isInitialized && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Speech recognition is not available on this device. '
              'Please make sure Google app is installed and updated.',
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }
      setState(() {});
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Microphone permission is required for pronunciation practice.',
            ),
          ),
        );
      }
    }
  }

  void _toggleRecording() async {
    if (!_isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
      return;
    }

    if (_isRecording) {
      await _speechService.stopListening();
      _analyzePronunciation();
    } else {
      setState(() {
        _isRecording = true;
        _feedbackText = 'Listening...';
        _spokenText = '';
        _accuracyScore = 0.0;
        _phonemeAnalysis = [];
      });

      await _speechService.startListening(
        onResult: (text) {
          setState(() {
            _spokenText = text;
          });
        },
        onComplete: () {
          setState(() {
            _isRecording = false;
          });
          _analyzePronunciation();
        },
      );
    }
  }

  void _analyzePronunciation() async {
    if (_spokenText.isEmpty) {
      setState(() {
        _feedbackText = 'No speech detected. Please try again.';
        _isRecording = false;
      });
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid ?? '';
    final targetText = _phrases[_currentPhraseIndex]['malay']!;

    // Show analyzing state
    setState(() {
      _feedbackText = 'Analyzing with AI...';
    });

    // Call the async AI analysis
    final attempt = await _speechService.analyzePronunciation(
      userId: userId,
      targetText: targetText,
      spokenText: _spokenText,
    );

    setState(() {
      _accuracyScore = attempt.accuracyScore;
      _feedbackText = attempt.feedback;
      _phonemeAnalysis = attempt.phonemeAnalysis;
      _isRecording = false;
    });

    // Save to Firestore
    if (userId.isNotEmpty) {
      await _firestoreService.savePronunciationAttempt(attempt);

      // Award XP based on score
      if (_accuracyScore >= 0.8) {
        await authProvider.addXp(10);
      } else if (_accuracyScore >= 0.5) {
        await authProvider.addXp(5);
      }
    }
  }

  void _nextPhrase() {
    setState(() {
      _currentPhraseIndex = (_currentPhraseIndex + 1) % _phrases.length;
      _feedbackText = 'Press the mic to start speaking.';
      _spokenText = '';
      _accuracyScore = 0.0;
      _phonemeAnalysis = [];
    });
  }

  void _previousPhrase() {
    setState(() {
      _currentPhraseIndex =
          (_currentPhraseIndex - 1 + _phrases.length) % _phrases.length;
      _feedbackText = 'Press the mic to start speaking.';
      _spokenText = '';
      _accuracyScore = 0.0;
      _phonemeAnalysis = [];
    });
  }

  void _speakPhrase() async {
    await _speechService.speak(_phrases[_currentPhraseIndex]['malay']!);
  }

  @override
  Widget build(BuildContext context) {
    final currentPhrase = _phrases[_currentPhraseIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pronunciation Practice'),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.pushNamed(context, '/pronunciation-history'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Progress Indicator
              Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_phrases.length, (index) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == _currentPhraseIndex
                        ? const Color(0xFF00796B)
                        : Colors.grey.shade300,
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            // Navigation Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _previousPhrase,
                  icon: const Icon(Icons.arrow_back_ios),
                  color: const Color(0xFF00796B),
                ),
                Text(
                  '${_currentPhraseIndex + 1} / ${_phrases.length}',
                  style: const TextStyle(color: Colors.grey),
                ),
                IconButton(
                  onPressed: _nextPhrase,
                  icon: const Icon(Icons.arrow_forward_ios),
                  color: const Color(0xFF00796B),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Target Phrase
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF00796B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    currentPhrase['malay']!,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00796B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentPhrase['english']!,
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _speakPhrase,
                    icon: const Icon(Icons.volume_up),
                    label: const Text('Listen'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Spoken Text
            if (_spokenText.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mic, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You said: "$_spokenText"',
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),

            // AI Feedback Section with Mascot
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              constraints: const BoxConstraints(
                maxHeight: 300, // Limit max height
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Show mascot based on accuracy
                    if (_accuracyScore > 0)
                      Image.asset(
                        _accuracyScore >= 0.7
                            ? 'assets/dodoHappy.png'
                            : 'assets/dodoSad.png',
                        width: 60,
                        height: 60,
                      ),
                    if (_accuracyScore > 0) const SizedBox(height: 8),
                    Text(
                      'AI Feedback:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _feedbackText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                  const SizedBox(height: 10),
                  if (_accuracyScore > 0)
                    Column(
                      children: [
                        const Text('Accuracy Score'),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: _accuracyScore,
                          minHeight: 10,
                          backgroundColor: Colors.grey.shade300,
                          color:
                              _accuracyScore > 0.8 ? Colors.green : Colors.orange,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(_accuracyScore * 100).toInt()}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _accuracyScore > 0.8
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  if (_phonemeAnalysis.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _phonemeAnalysis.map((p) {
                        return Chip(
                          avatar: Icon(
                            p.isCorrect ? Icons.check : Icons.close,
                            color: p.isCorrect ? Colors.green : Colors.red,
                            size: 16,
                          ),
                          label: Text(p.phoneme),
                          backgroundColor: p.isCorrect
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                        );
                      }).toList(),
                    ),
                  ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Recording Button
            GestureDetector(
              onTap: _toggleRecording,
              child: Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: _isRecording ? Colors.red : const Color(0xFF00796B),
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  _isRecording ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isRecording ? 'Tap to Stop' : 'Tap to Record',
              style: const TextStyle(color: Colors.grey),
            ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

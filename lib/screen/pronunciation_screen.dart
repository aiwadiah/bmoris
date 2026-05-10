import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final TextEditingController _customPhraseController = TextEditingController();

  bool _isRecording = false;
  bool _isInitialized = false;
  bool _isUsingCustomPhrase = false;
  String _spokenText = '';
  String _feedbackText = 'Press the mic to start speaking.';
  double _accuracyScore = 0.0;
  String _resultLabel = '';
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

  @override
  void dispose() {
    _customPhraseController.dispose();
    super.dispose();
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
    final targetText = _currentMalayPhrase;

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
      _resultLabel = _speechService.getPronunciationLabel(_accuracyScore);
      _isRecording = false;
    });

    try {
      await _speechService.speakPronunciationLabel(_accuracyScore);
    } catch (_) {
      // Ignore TTS failures; the visual result still matters.
    }

    // Save to Firestore
    if (userId.isNotEmpty) {
      await _firestoreService.savePronunciationAttempt(attempt);
      await authProvider.incrementActivityCount();

      // Award XP based on score
      if (_accuracyScore >= 0.8) {
        await authProvider.addXp(10);
      } else if (_accuracyScore >= 0.5) {
        await authProvider.addXp(5);
      }
    }
  }

  void _nextPhrase() {
    if (_isUsingCustomPhrase) {
      _resetPhrase();
      return;
    }
    setState(() {
      _currentPhraseIndex = (_currentPhraseIndex + 1) % _phrases.length;
      _feedbackText = 'Press the mic to start speaking.';
      _spokenText = '';
      _accuracyScore = 0.0;
      _resultLabel = '';
      _phonemeAnalysis = [];
    });
  }

  void _speakPhrase() async {
    await _speechService.speak(_currentMalayPhrase);
  }

  void _resetPhrase() {
    setState(() {
      _feedbackText = 'Press the mic to start speaking.';
      _spokenText = '';
      _accuracyScore = 0.0;
      _resultLabel = '';
      _phonemeAnalysis = [];
    });
  }

  String get _currentMalayPhrase {
    if (_isUsingCustomPhrase) {
      return _customPhraseController.text.trim();
    }
    return _phrases[_currentPhraseIndex]['malay']!;
  }

  String? get _currentEnglishPhrase {
    if (_isUsingCustomPhrase) {
      return 'Custom phrase';
    }
    return _phrases[_currentPhraseIndex]['english'];
  }

  void _applyCustomPhrase() {
    final phrase = _customPhraseController.text.trim();
    if (phrase.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a word or short phrase first.')),
      );
      return;
    }

    setState(() {
      _isUsingCustomPhrase = true;
      _feedbackText = 'Press the mic to start speaking.';
      _spokenText = '';
      _accuracyScore = 0.0;
      _resultLabel = '';
      _phonemeAnalysis = [];
    });
  }

  void _clearCustomPhrase() {
    setState(() {
      _isUsingCustomPhrase = false;
      _customPhraseController.clear();
      _feedbackText = 'Press the mic to start speaking.';
      _spokenText = '';
      _accuracyScore = 0.0;
      _resultLabel = '';
      _phonemeAnalysis = [];
    });
  }

  Widget _buildWaveform({bool isLeft = true}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(6, (index) {
        // Create a pattern of heights: 10, 20, 15, 25, 12, 18
        final heights =
            isLeft
                ? [8.0, 16.0, 12.0, 24.0, 10.0, 14.0]
                : [14.0, 10.0, 24.0, 12.0, 16.0, 8.0];

        return Container(
          width: 3,
          height: heights[index % heights.length],
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: const Color(
              0xFF00897B,
            ).withValues(alpha: _isRecording ? 0.6 : 0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentMalay = _currentMalayPhrase;
    final currentEnglish = _currentEnglishPhrase;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Pronunciation Practice',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed:
                () => Navigator.pushNamed(context, '/pronunciation-history'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Practice your own phrase',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _customPhraseController,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            hintText: 'Type a Malay word or short phrase',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            suffixIcon:
                                _customPhraseController.text.isEmpty
                                    ? null
                                    : IconButton(
                                      onPressed: _clearCustomPhrase,
                                      icon: const Icon(Icons.close),
                                    ),
                          ),
                          onChanged: (_) {
                            setState(() {});
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed:
                                    _isUsingCustomPhrase
                                        ? _clearCustomPhrase
                                        : null,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                child: const Text('Use Preset List'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _applyCustomPhrase,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00897B),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                child: const Text(
                                  'Use Custom',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
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
                          color:
                              index == _currentPhraseIndex
                                  ? Colors.blue
                                  : Colors.grey.shade300,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),

                  // Blue Container (Practice Area)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 48,
                      horizontal: 32,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(
                        alpha: 0.03,
                      ), // even lighter blue
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.blue.shade50, width: 2),
                    ),
                    child: Column(
                      children: [
                        Text(
                          currentMalay,
                          style: GoogleFonts.poppins(
                            fontSize: 36, // even bigger
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        if (currentEnglish != null)
                          Text(
                            currentEnglish,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        const SizedBox(height: 12),
                        IconButton(
                          onPressed: _speakPhrase,
                          icon: const Icon(
                            Icons.volume_up,
                            color: Color(0xFF00897B),
                          ),
                          tooltip: 'Listen',
                        ),
                        const SizedBox(height: 24),
                        // Mic Button with Waveforms
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildWaveform(isLeft: true),
                            const SizedBox(width: 20),
                            GestureDetector(
                              onTap: _toggleRecording,
                              child: Container(
                                height: 90,
                                width: 90,
                                decoration: BoxDecoration(
                                  color:
                                      _isRecording
                                          ? Colors.red
                                          : const Color(0xFF00897B),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF00897B,
                                      ).withValues(alpha: 0.2),
                                      blurRadius: 15,
                                      spreadRadius: 5,
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
                            const SizedBox(width: 20),
                            _buildWaveform(isLeft: false),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isRecording ? 'Listening...' : 'Tap to speak',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF00897B),
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // AI Feedback Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        if (_accuracyScore > 0)
                          Image.asset(
                            _accuracyScore >= 0.8
                                ? 'assets/dodoHappy.png'
                                : 'assets/dodoSad.png',
                            width: 70,
                            height: 70,
                          ),
                        if (_accuracyScore > 0) const SizedBox(height: 16),
                        Text(
                          'AI Feedback',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _feedbackText,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        if (_accuracyScore > 0) ...[
                          const SizedBox(height: 20),
                          LinearProgressIndicator(
                            value: _accuracyScore,
                            minHeight: 12,
                            backgroundColor: Colors.grey.shade100,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _accuracyScore >= 0.8
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(_accuracyScore * 100).toInt()}% Accuracy',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color:
                                  _accuracyScore >= 0.8
                                      ? Colors.green
                                      : Colors.orange,
                            ),
                          ),
                          if (_resultLabel.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    _accuracyScore >= 0.8
                                        ? Colors.green.shade50
                                        : _accuracyScore >= 0.5
                                        ? Colors.orange.shade50
                                        : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Sounds like $_resultLabel',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      _accuracyScore >= 0.8
                                          ? Colors.green.shade800
                                          : _accuracyScore >= 0.5
                                          ? Colors.orange.shade800
                                          : Colors.red.shade800,
                                ),
                              ),
                            ),
                          ],
                          if (_phonemeAnalysis.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children:
                                  _phonemeAnalysis.map((phoneme) {
                                    return Chip(
                                      avatar: Icon(
                                        phoneme.isCorrect
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        size: 16,
                                        color:
                                            phoneme.isCorrect
                                                ? Colors.green
                                                : Colors.red,
                                      ),
                                      label: Text(phoneme.phoneme),
                                      backgroundColor:
                                          phoneme.isCorrect
                                              ? Colors.green.shade50
                                              : Colors.red.shade50,
                                    );
                                  }).toList(),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          // Bottom Navigation Buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: const BoxDecoration(color: Colors.white),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetPhrase,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Try Again',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _nextPhrase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00897B),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _isUsingCustomPhrase ? 'Reset' : 'Next',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

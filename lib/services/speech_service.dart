import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:developer' as developer;
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pronunciation_model.dart';
import 'firestore_service.dart';

class SpeechService {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isInitialized = false;

  static const String _apiKey = 'AIzaSyC_CDAIBJTBWUpD8JJt60lN1qyyXB6025M';
  static const String _modelName = 'gemini-2.5-flash';

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    _isInitialized = await _speechToText.initialize(
      onError: (error) => developer.log('Speech error: $error'),
      onStatus: (status) => developer.log('Speech status: $status'),
    );

    // Configure TTS for Malay
    await _flutterTts.setLanguage('ms-MY'); // Malay
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    // Set handlers to debug audio playback
    _flutterTts.setStartHandler(() {
      developer.log('TTS: Started speaking');
    });

    _flutterTts.setCompletionHandler(() {
      developer.log('TTS: Completed speaking');
    });

    _flutterTts.setErrorHandler((msg) {
      developer.log('TTS Error: $msg');
    });

    return _isInitialized;
  }

  bool get isAvailable => _speechToText.isAvailable;
  bool get isListening => _speechToText.isListening;

  String getPronunciationLabel(double accuracyScore) {
    if (accuracyScore >= 0.8) return 'Great';
    if (accuracyScore >= 0.5) return 'Good';
    return 'Bad';
  }

  Future<void> speakPronunciationLabel(double accuracyScore) async {
    await speak(getPronunciationLabel(accuracyScore));
  }

  Future<void> startListening({
    required Function(String) onResult,
    required Function() onComplete,
    String localeId = 'ms_MY',
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    await _speechToText.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
        if (result.finalResult) {
          onComplete();
        }
      },
      localeId: localeId,
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        cancelOnError: true,
        partialResults: true,
      ),
    );
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
  }

  Future<void> speak(String text) async {
    developer.log('TTS: Attempting to speak: $text');

    // Ensure language is set before speaking
    await _flutterTts.setLanguage('ms-MY');
    await _flutterTts.setVolume(1.0);

    // Check if language is available
    final languages = await _flutterTts.getLanguages;
    developer.log('TTS: Available languages: $languages');

    final result = await _flutterTts.speak(text);
    developer.log('TTS: Speak result: $result');
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  Future<PronunciationAttempt> analyzePronunciation({
    required String userId,
    required String targetText,
    required String spokenText,
  }) async {
    try {
      // Fetch AI prompt from Firestore
      final doc = await _firestoreService.firestore
          .collection('settings')
          .doc('ai_prompts')
          .get();

      String prompt;
      if (doc.exists && doc.data()?['pronunciation'] != null) {
        // Use custom prompt from Firestore
        prompt = doc.data()!['pronunciation'] as String;
      } else {
        // Use default prompt
        prompt = _getDefaultPronunciationPrompt();
      }

      // Replace variables in the prompt
      prompt = prompt
          .replaceAll('{target_text}', targetText)
          .replaceAll('{spoken_text}', spokenText);

      // Call Gemini AI
      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1/models/$_modelName:generateContent?key=$_apiKey');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 1024,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = data['candidates'][0]['content']['parts'][0]['text'] as String;

        // Parse AI response for accuracy score and phoneme analysis
        return _parseAIResponse(
          userId: userId,
          targetText: targetText,
          spokenText: spokenText,
          aiResponse: aiResponse,
        );
      } else {
        // Fallback to rule-based analysis if AI fails
        developer.log('AI API failed: ${response.statusCode}, falling back to rule-based');
        return _fallbackAnalysis(userId, targetText, spokenText);
      }
    } catch (e) {
      developer.log('Error in AI pronunciation analysis: $e');
      // Fallback to rule-based analysis
      return _fallbackAnalysis(userId, targetText, spokenText);
    }
  }

  PronunciationAttempt _parseAIResponse({
    required String userId,
    required String targetText,
    required String spokenText,
    required String aiResponse,
  }) {
    // Try to extract accuracy score from AI response
    double accuracyScore = 0.0;
    final scoreRegex = RegExp(r'(\d+)(?:/100|%|\s*out of 100)');
    final match = scoreRegex.firstMatch(aiResponse);
    if (match != null) {
      accuracyScore = int.parse(match.group(1)!) / 100.0;
    } else {
      // Estimate based on similarity
      final targetWords = targetText.toLowerCase().split(' ');
      final spokenWords = spokenText.toLowerCase().split(' ');
      int correctWords = 0;
      for (int i = 0; i < targetWords.length && i < spokenWords.length; i++) {
        if (targetWords[i] == spokenWords[i]) correctWords++;
      }
      accuracyScore = targetWords.isNotEmpty ? correctWords / targetWords.length : 0.0;
    }

    // Extract phoneme feedback
    List<PhonemeAnalysis> phonemeAnalysis = [];
    final malayPhonemes = ['ng', 'ny', 'kh', 'sy', 'gh'];
    final targetWords = targetText.toLowerCase().split(' ');
    final spokenWords = spokenText.toLowerCase().split(' ');

    for (int i = 0; i < targetWords.length; i++) {
      final targetWord = targetWords[i];
      final spokenWord = i < spokenWords.length ? spokenWords[i] : '';

      for (final phoneme in malayPhonemes) {
        if (targetWord.contains(phoneme)) {
          final isCorrect = spokenWord.contains(phoneme);
          phonemeAnalysis.add(PhonemeAnalysis(
            phoneme: phoneme,
            isCorrect: isCorrect,
            score: isCorrect ? 1.0 : 0.0,
            suggestion: isCorrect
                ? 'Good pronunciation of "$phoneme"'
                : 'Practice the "$phoneme" sound',
          ));
        }
      }
    }

    return PronunciationAttempt(
      id: '',
      userId: userId,
      targetText: targetText,
      spokenText: spokenText,
      accuracyScore: accuracyScore,
      phonemeAnalysis: phonemeAnalysis,
      feedback: aiResponse,
      attemptedAt: DateTime.now(),
    );
  }

  PronunciationAttempt _fallbackAnalysis(
    String userId,
    String targetText,
    String spokenText,
  ) {
    final targetWords = targetText.toLowerCase().split(' ');
    final spokenWords = spokenText.toLowerCase().split(' ');

    int correctWords = 0;
    List<PhonemeAnalysis> phonemeAnalysis = [];

    final malayPhonemes = ['ng', 'ny', 'kh', 'sy', 'gh'];

    for (int i = 0; i < targetWords.length; i++) {
      final targetWord = targetWords[i];
      final spokenWord = i < spokenWords.length ? spokenWords[i] : '';

      if (targetWord == spokenWord) {
        correctWords++;
      }

      for (final phoneme in malayPhonemes) {
        if (targetWord.contains(phoneme)) {
          final isCorrect = spokenWord.contains(phoneme);
          phonemeAnalysis.add(PhonemeAnalysis(
            phoneme: phoneme,
            isCorrect: isCorrect,
            score: isCorrect ? 1.0 : 0.0,
            suggestion: isCorrect
                ? 'Good pronunciation of "$phoneme"'
                : 'Practice the "$phoneme" sound in "$targetWord"',
          ));
        }
      }
    }

    final accuracyScore = targetWords.isNotEmpty
        ? correctWords / targetWords.length
        : 0.0;

    String feedback;
    if (accuracyScore >= 0.9) {
      feedback = 'Excellent! Your pronunciation is very accurate.';
    } else if (accuracyScore >= 0.7) {
      feedback = 'Good job! Keep practicing to improve.';
    } else if (accuracyScore >= 0.5) {
      feedback = 'Nice try! Focus on the highlighted sounds.';
    } else {
      feedback = 'Keep practicing! Try speaking more slowly.';
    }

    final incorrectPhonemes = phonemeAnalysis.where((p) => !p.isCorrect).toList();
    if (incorrectPhonemes.isNotEmpty) {
      feedback += ' Pay attention to: ${incorrectPhonemes.map((p) => p.phoneme).join(", ")}';
    }

    return PronunciationAttempt(
      id: '',
      userId: userId,
      targetText: targetText,
      spokenText: spokenText,
      accuracyScore: accuracyScore,
      phonemeAnalysis: phonemeAnalysis,
      feedback: feedback,
      attemptedAt: DateTime.now(),
    );
  }

  String _getDefaultPronunciationPrompt() {
    return '''You are a Bahasa Melayu pronunciation expert. Analyze the user's pronunciation and provide detailed feedback.

Target text: {target_text}
User's spoken text: {spoken_text}

Provide:
1. Overall accuracy score (0-100)
2. Phoneme-by-phoneme analysis
3. Specific suggestions for improvement
4. Encouraging feedback

Be constructive and helpful. Focus on the most important improvements first.''';
  }
}

import 'package:cloud_functions/cloud_functions.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:developer' as developer;
import '../models/pronunciation_model.dart';

class SpeechService {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  bool _isInitialized = false;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    _isInitialized = await _speechToText.initialize(
      onError: (error) => developer.log('Speech error: $error'),
      onStatus: (status) => developer.log('Speech status: $status'),
    );

    await _flutterTts.setLanguage('ms-MY');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

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
    await _flutterTts.setLanguage('ms-MY');
    await _flutterTts.setVolume(1.0);
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
      final callable = _functions.httpsCallable('analyzePronunciation');
      final response = await callable.call({
        'userId': userId,
        'targetText': targetText,
        'spokenText': spokenText,
      });

      return PronunciationAttempt.fromMap(
        Map<String, dynamic>.from(response.data as Map),
        '',
      );
    } catch (e) {
      developer.log('Error in AI pronunciation analysis: $e');
      return _fallbackAnalysis(userId, targetText, spokenText);
    }
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
          phonemeAnalysis.add(
            PhonemeAnalysis(
              phoneme: phoneme,
              isCorrect: isCorrect,
              score: isCorrect ? 1.0 : 0.0,
              suggestion:
                  isCorrect
                      ? 'Good pronunciation of "$phoneme"'
                      : 'Practice the "$phoneme" sound in "$targetWord"',
            ),
          );
        }
      }
    }

    final accuracyScore =
        targetWords.isNotEmpty ? correctWords / targetWords.length : 0.0;

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

    final incorrectPhonemes =
        phonemeAnalysis.where((p) => !p.isCorrect).toList();
    if (incorrectPhonemes.isNotEmpty) {
      feedback +=
          ' Pay attention to: ${incorrectPhonemes.map((p) => p.phoneme).join(", ")}';
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
}

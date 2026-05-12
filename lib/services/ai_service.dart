import 'dart:convert';
import 'package:http/http.dart' as http;
import 'firestore_service.dart';

class AIService {
  static const String _apiKey = 'AIzaSyDEPb1ddtXdoUpWrfFyauCUaPxY9jZHxlY';
  static const String _modelName = 'gemini-2.5-flash';

  final FirestoreService _firestoreService = FirestoreService();
  final List<Map<String, dynamic>> _chatHistory = [];
  String? _cachedPrompt;

  // List available models for debugging
  Future<void> listAvailableModels() async {
    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1/models?key=$_apiKey',
      );
      final response = await http.get(url);
      print('=== AVAILABLE MODELS ===');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');
    } catch (e) {
      print('Error listing models: $e');
    }
  }

  Future<String> getConversationResponse({
    required String userMessage,
    required List<Map<String, String>> conversationHistory,
  }) async {
    try {
      // List available models on first call
      if (_chatHistory.isEmpty) {
        await listAvailableModels();
      }

      // Fetch chatbot prompt from Firestore (cache it)
      if (_cachedPrompt == null) {
        final doc =
            await _firestoreService.firestore
                .collection('settings')
                .doc('ai_prompts')
                .get();

        if (doc.exists && doc.data()?['feedback'] != null) {
          _cachedPrompt = doc.data()!['feedback'] as String;
        } else {
          _cachedPrompt = _getDefaultChatbotPrompt();
        }
      }

      // Build the chat history for the API
      final contents = <Map<String, dynamic>>[];

      // Add chat history
      for (var msg in _chatHistory) {
        contents.add(msg);
      }

      // Replace {user_message} in the prompt
      final promptWithMessage = _cachedPrompt!
          .replaceAll('{user_message}', userMessage)
          .replaceAll('{performance_data}', 'N/A');

      // Add current user message
      final userContent = {
        'role': 'user',
        'parts': [
          {'text': promptWithMessage},
        ],
      };
      contents.add(userContent);

      // Use v1 API endpoint
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1/models/$_modelName:generateContent?key=$_apiKey',
      );

      print('Sending to Gemini API v1 with model: $_modelName');
      print('URL: $url');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': contents,
          'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 1024},
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'];

        // Add to chat history
        _chatHistory.add(userContent);
        _chatHistory.add({
          'role': 'model',
          'parts': [
            {'text': text},
          ],
        });

        return text ?? 'Maaf, saya tidak faham. (Sorry, I did not understand.)';
      } else {
        return 'Error: ${response.statusCode} - ${response.body}';
      }
    } catch (e, stackTrace) {
      print('=== AI ERROR ===');
      print('Error Type: ${e.runtimeType}');
      print('Error Message: $e');
      print('Stack Trace: $stackTrace');
      print('Model: $_modelName');
      print('API Key (first 10 chars): ${_apiKey.substring(0, 10)}...');
      return '''ERROR DETAILS:
Type: ${e.runtimeType}
Message: $e

Please check console for full details.''';
    }
  }

  Future<String> translateText({
    required String text,
    required String fromLanguage,
    required String toLanguage,
  }) async {
    const translationModels = [
      _modelName,
      'gemini-2.0-flash-lite',
      'gemini-2.0-flash',
    ];

    final prompt =
        'Translate from $fromLanguage to $toLanguage. Only provide the translation, no explanations: "$text"';

    for (final model in translationModels) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1/models/$model:generateContent?key=$_apiKey',
        );

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt},
                ],
              },
            ],
            'generationConfig': {'temperature': 0.2, 'maxOutputTokens': 256},
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final translated =
              data['candidates']?[0]?['content']?['parts']?[0]?['text'];
          return translated ?? 'Translation failed.';
        }

        // 503 means the model/service is temporarily overloaded. Try fallback.
        if (response.statusCode == 503 || response.statusCode == 429) {
          continue;
        }

        return 'Translation error (${response.statusCode}). Please try again.';
      } catch (_) {
        continue;
      }
    }

    return 'Translation service is busy. Please try again in a moment.';
  }

  void resetChat() {
    _chatHistory.clear();
    _cachedPrompt = null; // Clear cached prompt to reload on next chat
  }

  Future<Map<String, dynamic>?> generateQuiz({
    required String topic,
    required int difficulty,
    required String category,
  }) async {
    try {
      // Fetch quiz generation prompt from Firestore
      final doc =
          await _firestoreService.firestore
              .collection('settings')
              .doc('ai_prompts')
              .get();

      String prompt;
      if (doc.exists && doc.data()?['quiz_generation'] != null) {
        prompt = doc.data()!['quiz_generation'] as String;
      } else {
        prompt = _getDefaultQuizPrompt();
      }

      // Replace variables
      prompt = prompt
          .replaceAll('{topic}', topic)
          .replaceAll('{difficulty}', difficulty.toString())
          .replaceAll('{category}', category);

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1/models/$_modelName:generateContent?key=$_apiKey',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 512},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse =
            data['candidates'][0]['content']['parts'][0]['text'] as String;

        // Try to parse JSON from the response
        try {
          // Remove markdown code blocks if present
          String cleanedResponse =
              aiResponse.replaceAll('```json', '').replaceAll('```', '').trim();

          final quizData = jsonDecode(cleanedResponse) as Map<String, dynamic>;

          // Validate required fields
          if (quizData.containsKey('question') &&
              quizData.containsKey('options') &&
              quizData.containsKey('correctIndex')) {
            return {
              'question': quizData['question'] ?? '',
              'questionMalay':
                  quizData['questionMalay'] ?? quizData['question'],
              'options': List<String>.from(quizData['options'] ?? []),
              'correctIndex': quizData['correctIndex'] ?? 0,
              'difficulty': difficulty,
              'category': category,
              'type': 'multiple_choice',
              'lessonId': '',
            };
          }
        } catch (e) {
          print('Error parsing quiz JSON: $e');
        }
      }

      return null;
    } catch (e) {
      print('Error generating quiz: $e');
      return null;
    }
  }

  String _getDefaultChatbotPrompt() {
    return '''You are BMoris, a helpful and friendly Bahasa Melayu language tutor.

User message: {user_message}

Respond to the user in a helpful and encouraging way. Always provide responses in both Malay and English to help them learn. Be patient and supportive.''';
  }

  String _getDefaultQuizPrompt() {
    return '''You are a Bahasa Melayu language expert creating educational quiz questions.

Generate a multiple-choice quiz question for:
Topic: {topic}
Difficulty level: {difficulty}
Category: {category}

Requirements:
1. Question in both English and Bahasa Melayu
2. 4 answer options
3. One correct answer
4. Educational and engaging
5. Appropriate for the difficulty level

Return as JSON: {"question": "", "questionMalay": "", "options": [], "correctIndex": 0}''';
  }
}

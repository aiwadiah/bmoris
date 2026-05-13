import 'package:cloud_functions/cloud_functions.dart';

class AIService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final List<Map<String, dynamic>> _chatHistory = [];

  Future<String> getConversationResponse({
    required String userMessage,
    required List<Map<String, String>> conversationHistory,
  }) async {
    try {
      final callable = _functions.httpsCallable('chat');
      final response = await callable.call({
        'message': userMessage,
        'history': _chatHistory.isNotEmpty ? _chatHistory : conversationHistory,
      });

      final data = Map<String, dynamic>.from(response.data as Map);
      final reply = (data['reply'] as String?)?.trim();
      if (reply == null || reply.isEmpty) {
        return 'Maaf, saya tidak faham. (Sorry, I did not understand.)';
      }

      _chatHistory.add({
        'role': 'user',
        'parts': [
          {'text': userMessage},
        ],
      });
      _chatHistory.add({
        'role': 'model',
        'parts': [
          {'text': reply},
        ],
      });

      return reply;
    } on FirebaseFunctionsException catch (e) {
      return 'Error: ${e.code} - ${e.message ?? 'Unable to contact AI service.'}';
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String> translateText({
    required String text,
    required String fromLanguage,
    required String toLanguage,
  }) async {
    try {
      final callable = _functions.httpsCallable('translate');
      final response = await callable.call({
        'text': text,
        'fromLanguage': fromLanguage,
        'toLanguage': toLanguage,
      });

      final data = Map<String, dynamic>.from(response.data as Map);
      return (data['translation'] as String?)?.trim().isNotEmpty == true
          ? (data['translation'] as String).trim()
          : 'Translation failed.';
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'resource-exhausted') {
        return 'Translation service is busy. Please try again in a moment.';
      }
      return 'Translation error (${e.code}). Please try again.';
    } catch (_) {
      return 'Translation service is busy. Please try again in a moment.';
    }
  }

  void resetChat() {
    _chatHistory.clear();
  }

  Future<Map<String, dynamic>?> generateQuiz({
    required String topic,
    required int difficulty,
    required String category,
  }) async {
    try {
      final callable = _functions.httpsCallable('generateQuiz');
      final response = await callable.call({
        'topic': topic,
        'difficulty': difficulty,
        'category': category,
      });

      return Map<String, dynamic>.from(response.data as Map);
    } catch (_) {
      return null;
    }
  }
}

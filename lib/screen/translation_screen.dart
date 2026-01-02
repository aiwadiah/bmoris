import 'package:flutter/material.dart';
import '../services/ai_service.dart';

class TranslationScreen extends StatefulWidget {
  const TranslationScreen({super.key});

  @override
  State<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> {
  final TextEditingController _textController = TextEditingController();
  final AIService _aiService = AIService();
  String _translatedText = '';
  bool _isLoading = false;
  String _fromLanguage = 'English';
  String _toLanguage = 'Malay';

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _swapLanguages() {
    setState(() {
      final temp = _fromLanguage;
      _fromLanguage = _toLanguage;
      _toLanguage = temp;
      _translatedText = '';
    });
  }

  Future<void> _translate() async {
    if (_textController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _aiService.translateText(
        text: _textController.text,
        fromLanguage: _fromLanguage,
        toLanguage: _toLanguage,
      );

      setState(() {
        _translatedText = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _translatedText = 'Translation failed. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Translation'),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Language Selector
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'From',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        Text(
                          _fromLanguage,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _swapLanguages,
                    icon: const Icon(Icons.swap_horiz),
                    color: const Color(0xFF00796B),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'To',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        Text(
                          _toLanguage,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Input Field
            TextField(
              controller: _textController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Enter text to translate...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Translate Button
            ElevatedButton(
              onPressed: _isLoading ? null : _translate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00796B),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Translate',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
            ),
            const SizedBox(height: 24),

            // Translation Result
            if (_translatedText.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF00796B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00796B).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.translate,
                          color: Color(0xFF00796B),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Translation ($_toLanguage)',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00796B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _translatedText,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Quick Phrases
            const Text(
              'Common Phrases',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickPhrase('Hello', 'Halo'),
                _buildQuickPhrase('Thank you', 'Terima kasih'),
                _buildQuickPhrase('Good morning', 'Selamat pagi'),
                _buildQuickPhrase('How are you?', 'Apa khabar?'),
                _buildQuickPhrase('Goodbye', 'Selamat tinggal'),
                _buildQuickPhrase('Please', 'Tolong'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickPhrase(String english, String malay) {
    return ActionChip(
      label: Text(_fromLanguage == 'English' ? english : malay),
      onPressed: () {
        _textController.text = _fromLanguage == 'English' ? english : malay;
        _translate();
      },
      backgroundColor: Colors.grey.shade100,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/feedback_model.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../widgets/bmoris_back_button.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  static const Color _green = Color(0xFF00A676);
  static const Color _darkGreen = Color(0xFF00796B);
  static const Color _ink = Color(0xFF1F3D38);
  static const List<String> _categories = [
    'Bug',
    'Suggestion',
    'Content',
    'AI Tutor',
    'Pronunciation',
  ];

  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;
  bool _isSubmitted = false;
  int _rating = 4;
  String _selectedCategory = _categories.first;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      if (user == null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to submit feedback.')),
        );
        return;
      }

      final feedback = FeedbackModel(
        id: '',
        oderId: user.uid,
        userName: user.name,
        subject: _selectedCategory,
        category: _selectedCategory,
        message: _messageController.text.trim(),
        rating: _rating,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await _firestoreService.sendFeedback(feedback);

      setState(() {
        _isLoading = false;
        _isSubmitted = true;
        _rating = 4;
        _selectedCategory = _categories.first;
        _messageController.clear();
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit feedback. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFCFB),
      body: SafeArea(
        child: _isSubmitted ? _buildSuccessView() : _buildFormView(),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFE7F8F1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 78,
              color: _green,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Thank You!',
            style: GoogleFonts.poppins(
              color: _ink,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your feedback has been submitted successfully.',
            style: GoogleFonts.poppins(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'We appreciate your input and will review it soon.',
            style: GoogleFonts.poppins(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                'Done',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTopBar(),
            const SizedBox(height: 10),
            _buildHeader(),
            const SizedBox(height: 24),
            _buildRatingSelector(),
            const SizedBox(height: 22),
            _buildCategorySelector(),
            const SizedBox(height: 18),
            _buildMessageField(),
            const SizedBox(height: 22),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(children: [const BMorisBackButton.plain()]);
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 118,
          height: 118,
          child: Image.asset(
            'assets/bmorisbird.png',
            fit: BoxFit.contain,
            errorBuilder:
                (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFE7F8F1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.feedback_rounded,
                    color: _darkGreen,
                    size: 54,
                  ),
                ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Feedback',
                style: GoogleFonts.poppins(
                  color: _ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Help BMoris become even better.',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF49635E),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRatingSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(5, (index) {
        final star = index + 1;
        final isFilled = star <= _rating;
        return IconButton(
          tooltip: '$star star rating',
          onPressed: () => setState(() => _rating = star),
          icon: Icon(
            isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
            color: const Color(0xFFFFC542),
            size: 42,
          ),
          style: IconButton.styleFrom(
            fixedSize: const Size(48, 48),
            padding: EdgeInsets.zero,
          ),
        );
      }),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: GoogleFonts.poppins(
            color: _ink,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              _categories.map((category) {
                final isSelected = category == _selectedCategory;
                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected:
                      (_) => setState(() => _selectedCategory = category),
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  selectedColor: const Color(0xFFE7F8F1),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: isSelected ? _green : const Color(0xFFE2E8E5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  labelStyle: GoogleFonts.poppins(
                    color: isSelected ? _darkGreen : const Color(0xFF6D817B),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildMessageField() {
    return TextFormField(
      controller: _messageController,
      maxLines: 6,
      maxLength: 300,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Write your feedback...',
        hintStyle: GoogleFonts.poppins(color: const Color(0xFF9AA8A4)),
        filled: true,
        fillColor: Colors.white,
        counterText: '${_messageController.text.length}/300',
        counterStyle: GoogleFonts.poppins(
          color: const Color(0xFF9AA8A4),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8E5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8E5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _green, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
      validator: (value) {
        final message = value?.trim() ?? '';
        if (message.isEmpty) return 'Please enter your feedback';
        if (message.length < 10) {
          return 'Feedback must be at least 10 characters';
        }
        return null;
      },
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitFeedback,
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkGreen,
          disabledBackgroundColor: _darkGreen.withValues(alpha: 0.55),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child:
            _isLoading
                ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : Text(
                  'Submit Feedback',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
      ),
    );
  }
}

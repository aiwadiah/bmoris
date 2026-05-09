import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../models/pronunciation_model.dart';
import '../services/firestore_service.dart';

class PronunciationHistoryScreen extends StatefulWidget {
  const PronunciationHistoryScreen({super.key});

  @override
  State<PronunciationHistoryScreen> createState() =>
      _PronunciationHistoryScreenState();
}

class _PronunciationHistoryScreenState
    extends State<PronunciationHistoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<PronunciationAttempt> _attempts = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';

  List<PronunciationAttempt> get _filteredAttempts {
    if (_selectedFilter == 'All') return _attempts;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    if (_selectedFilter == 'Today') {
      return _attempts.where((a) => a.attemptedAt.isAfter(todayStart)).toList();
    }

    if (_selectedFilter == 'Last 7 Days') {
      final weekStart = todayStart.subtract(const Duration(days: 7));
      return _attempts.where((a) => a.attemptedAt.isAfter(weekStart)).toList();
    }

    if (_selectedFilter == 'Last 30 Days') {
      final monthStart = todayStart.subtract(const Duration(days: 30));
      return _attempts.where((a) => a.attemptedAt.isAfter(monthStart)).toList();
    }

    return _attempts;
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      if (user != null) {
        _attempts =
            await _firestoreService.getUserPronunciationHistory(user.uid);
      }
    } catch (e) {
      // Handle error
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Pronunciation History',
          style: GoogleFonts.poppins(
            color: const Color(0xFF00897B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF00897B),
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredAttempts.isEmpty
                    ? _buildEmptyState()
                    : _buildHistoryList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final filters = ['All', 'Today', 'Last 7 Days', 'Last 30 Days'];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedFilter = filter);
                  }
                },
                selectedColor: const Color(0xFF00897B),
                labelStyle: GoogleFonts.poppins(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
                backgroundColor: Colors.grey.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF00897B) : Colors.grey.shade200,
                  width: 1,
                ),
                showCheckmark: false,
                elevation: isSelected ? 2 : 0,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No pronunciation history',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start practicing to see your progress',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/practice');
            },
            icon: const Icon(Icons.mic),
            label: const Text('Start Practice'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00796B),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    // Group by date
    final groupedAttempts = <String, List<PronunciationAttempt>>{};
    for (var attempt in _filteredAttempts) {
      final dateKey = DateFormat('MMM d, yyyy').format(attempt.attemptedAt);
      groupedAttempts.putIfAbsent(dateKey, () => []).add(attempt);
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: groupedAttempts.length,
        itemBuilder: (context, index) {
          final date = groupedAttempts.keys.elementAt(index);
          final attempts = groupedAttempts[date]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  date,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              ...attempts.map((attempt) => _buildAttemptCard(attempt)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAttemptCard(PronunciationAttempt attempt) {
    final scoreColor = attempt.accuracyScore >= 0.8
        ? Colors.green
        : attempt.accuracyScore >= 0.5
            ? Colors.orange
            : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAttemptDetail(attempt),
          borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          attempt.targetText,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You said: "${attempt.spokenText}"',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${(attempt.accuracyScore * 100).toInt()}%',
                      style: TextStyle(
                        color: scoreColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('h:mm a').format(attempt.attemptedAt),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  void _showAttemptDetail(PronunciationAttempt attempt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Pronunciation Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Target vs Spoken
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Target:',
                    style: TextStyle(color: Colors.grey),
                  ),
                  Text(
                    attempt.targetText,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00796B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'You said:',
                    style: TextStyle(color: Colors.grey),
                  ),
                  Text(
                    attempt.spokenText,
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Score
            Row(
              children: [
                const Text('Accuracy: '),
                Text(
                  '${(attempt.accuracyScore * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: attempt.accuracyScore >= 0.8
                        ? Colors.green
                        : attempt.accuracyScore >= 0.5
                            ? Colors.orange
                            : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Feedback
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      attempt.feedback,
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Phoneme Analysis
            if (attempt.phonemeAnalysis.isNotEmpty) ...[
              const Text(
                'Phoneme Analysis:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: attempt.phonemeAnalysis.map((phoneme) {
                  return Chip(
                    avatar: Icon(
                      phoneme.isCorrect ? Icons.check_circle : Icons.cancel,
                      color: phoneme.isCorrect ? Colors.green : Colors.red,
                      size: 18,
                    ),
                    label: Text(phoneme.phoneme),
                    backgroundColor: phoneme.isCorrect
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00796B),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child:
                    const Text('Close', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

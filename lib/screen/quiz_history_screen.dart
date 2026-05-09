import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../models/quiz_model.dart';

class QuizHistoryScreen extends StatefulWidget {
  const QuizHistoryScreen({super.key});

  @override
  State<QuizHistoryScreen> createState() => _QuizHistoryScreenState();
}

class _QuizHistoryScreenState extends State<QuizHistoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<QuizAttempt> _attempts = [];
  List<QuizAttempt> _filteredAttempts = [];
  bool _isLoading = true;
  int? _levelFilter;
  String? _categoryFilter;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;
    
    if (userId != null) {
      try {
        final snapshot = await _firestoreService.firestore.collection('quiz_attempts').get();
        final allAttempts = snapshot.docs
            .map((doc) => QuizAttempt.fromMap(doc.data(), doc.id))
            .toList();
        
        final myAttempts = allAttempts.where((a) => a.userId == userId).toList();
        
        myAttempts.sort((a, b) => b.attemptedAt.compareTo(a.attemptedAt));
        
        setState(() {
          _attempts = myAttempts;
          _filteredAttempts = myAttempts;
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredAttempts = _attempts.where((attempt) {
        final matchesLevel = _levelFilter == null || attempt.difficulty == _levelFilter;
        final matchesCategory = _categoryFilter == null || attempt.category == _categoryFilter;
        return matchesLevel && matchesCategory;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Quiz History',
          style: GoogleFonts.poppins(
            color: const Color(0xFF00897B),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF00897B),
        elevation: 0,
        centerTitle: true,
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
    final categories = _attempts.map((a) => a.category).toSet().toList()..sort();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              value: _levelFilter,
              decoration: InputDecoration(
                labelText: 'Level',
                labelStyle: GoogleFonts.poppins(fontSize: 12),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Levels')),
                ...List.generate(5, (i) => i + 1).map((l) => 
                  DropdownMenuItem(value: l, child: Text('Level $l'))
                ),
              ],
              onChanged: (val) {
                setState(() => _levelFilter = val);
                _applyFilters();
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _categoryFilter,
              decoration: InputDecoration(
                labelText: 'Content',
                labelStyle: GoogleFonts.poppins(fontSize: 12),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Content')),
                ...categories.map((c) => 
                  DropdownMenuItem(value: c, child: Text(c))
                ),
              ],
              onChanged: (val) {
                setState(() => _categoryFilter = val);
                _applyFilters();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredAttempts.length,
      itemBuilder: (context, index) {
        final attempt = _filteredAttempts[index];
        final dateStr = DateFormat('MMM dd, hh:mm a').format(attempt.attemptedAt);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: attempt.isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                attempt.isCorrect ? Icons.check_circle : Icons.cancel,
                color: attempt.isCorrect ? Colors.green : Colors.red,
                size: 24,
              ),
            ),
            title: Text(
              attempt.category,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Level ${attempt.difficulty} • $dateStr',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: attempt.isCorrect ? Colors.green.shade100 : Colors.red.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                attempt.isCorrect ? 'Correct' : 'Incorrect',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: attempt.isCorrect ? Colors.green.shade800 : Colors.red.shade800,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.history, size: 64, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 24),
          Text(
            'No quiz history found',
            style: GoogleFonts.poppins(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a quiz to see your progress here!',
            style: GoogleFonts.poppins(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Consumer<AuthProvider>(
            builder: (context, auth, _) => Text(
              'User: ${auth.user?.name ?? "Unknown"} (${_attempts.length} records found)',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

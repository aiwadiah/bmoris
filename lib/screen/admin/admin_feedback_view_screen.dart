import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/feedback_model.dart';
import '../../services/firestore_service.dart';
import 'admin_feedback_detail_screen.dart';

class AdminFeedbackViewScreen extends StatefulWidget {
  const AdminFeedbackViewScreen({super.key});

  @override
  State<AdminFeedbackViewScreen> createState() =>
      _AdminFeedbackViewScreenState();
}

class _AdminFeedbackViewScreenState extends State<AdminFeedbackViewScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<FeedbackModel> _feedbacks = [];
  bool _isLoading = true;
  int? _ratingFilter;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _loadFeedback();
  }

  Future<void> _loadFeedback() async {
    setState(() => _isLoading = true);
    try {
      final feedbacks = await _firestoreService.getAllFeedback();
      setState(() => _feedbacks = feedbacks);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading feedback: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<FeedbackModel> get _filteredFeedbacks {
    return _feedbacks.where((feedback) {
      final matchesRating =
          _ratingFilter == null || feedback.rating == _ratingFilter;
      final matchesStart =
          _dateRange == null || !feedback.createdAt.isBefore(_dateRange!.start);
      final matchesEnd =
          _dateRange == null ||
          !feedback.createdAt.isAfter(
            _dateRange!.end.add(const Duration(days: 1)),
          );
      return matchesRating && matchesStart && matchesEnd;
    }).toList();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  void _clearFilters() {
    setState(() {
      _ratingFilter = null;
      _dateRange = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final feedbacks = _filteredFeedbacks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback View'),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadFeedback),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'User Feedback',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text('${feedbacks.length} feedbacks'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<int?>(
                    initialValue: _ratingFilter,
                    decoration: const InputDecoration(
                      labelText: 'Rating',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem<int?>(value: null, child: Text('All')),
                      DropdownMenuItem(value: 5, child: Text('5 stars')),
                      DropdownMenuItem(value: 4, child: Text('4 stars')),
                      DropdownMenuItem(value: 3, child: Text('3 stars')),
                      DropdownMenuItem(value: 2, child: Text('2 stars')),
                      DropdownMenuItem(value: 1, child: Text('1 star')),
                    ],
                    onChanged: (value) => setState(() => _ratingFilter = value),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    _dateRange == null
                        ? 'Date range'
                        : '${DateFormat('MMM d').format(_dateRange!.start)} - ${DateFormat('MMM d').format(_dateRange!.end)}',
                  ),
                ),
                TextButton(
                  onPressed:
                      (_ratingFilter == null && _dateRange == null)
                          ? null
                          : _clearFilters,
                  child: const Text('Clear'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : feedbacks.isEmpty
                    ? const Center(child: Text('No feedback found'))
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: feedbacks.length,
                      itemBuilder: (context, index) {
                        final feedback = feedbacks[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(feedback.status),
                              child: Icon(
                                _getStatusIcon(feedback.status),
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            title: Text(feedback.subject),
                            subtitle: Text(
                              'From: ${feedback.userName} | ${DateFormat('MMM d, yyyy').format(feedback.createdAt)}',
                            ),
                            trailing: Chip(label: Text('${feedback.rating}/5')),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => AdminFeedbackDetailScreen(
                                        feedback: feedback,
                                      ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'reviewed':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending;
      case 'reviewed':
        return Icons.visibility;
      case 'resolved':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }
}

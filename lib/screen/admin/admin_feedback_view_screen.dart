import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/feedback_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/admin_ui.dart';
import '../../widgets/bmoris_back_button.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading feedback: $e')),
        );
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
    final hasFilters = _ratingFilter != null || _dateRange != null;

    return AdminPage(
      child:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : AdminShell(
                title: 'Feedback View',
                subtitle: '${feedbacks.length} feedbacks match the current view.',
                leading: const BMorisBackButton(),
                trailing: IconButton(
                  onPressed: _loadFeedback,
                  icon: const Icon(Icons.refresh_rounded, color: AdminUi.teal),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AdminCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AdminSectionTitle(
                            'User Feedback',
                            trailing: Text(
                              '${feedbacks.length} shown',
                              style: AdminUi.caption(),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              SizedBox(
                                width: 150,
                                child: DropdownButtonFormField<int?>(
                                  value: _ratingFilter,
                                  decoration: adminInputDecoration(
                                    label: 'Rating',
                                  ),
                                  items: const [
                                    DropdownMenuItem<int?>(
                                      value: null,
                                      child: Text('All'),
                                    ),
                                    DropdownMenuItem(
                                      value: 5,
                                      child: Text('5 stars'),
                                    ),
                                    DropdownMenuItem(
                                      value: 4,
                                      child: Text('4 stars'),
                                    ),
                                    DropdownMenuItem(
                                      value: 3,
                                      child: Text('3 stars'),
                                    ),
                                    DropdownMenuItem(
                                      value: 2,
                                      child: Text('2 stars'),
                                    ),
                                    DropdownMenuItem(
                                      value: 1,
                                      child: Text('1 star'),
                                    ),
                                  ],
                                  onChanged:
                                      (value) =>
                                          setState(() => _ratingFilter = value),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: _pickDateRange,
                                icon: const Icon(
                                  Icons.date_range_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  _dateRange == null
                                      ? 'Date range'
                                      : '${DateFormat('MMM d').format(_dateRange!.start)} - ${DateFormat('MMM d').format(_dateRange!.end)}',
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AdminUi.teal,
                                  side: const BorderSide(color: AdminUi.border),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: hasFilters ? _clearFilters : null,
                                child: const Text('Clear'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (feedbacks.isEmpty)
                      const AdminEmptyState(
                        icon: Icons.rate_review_outlined,
                        title: 'No feedback found',
                        subtitle:
                            'Try clearing filters or refreshing the feedback list.',
                      )
                    else
                      ...feedbacks.map(
                        (feedback) => _FeedbackListCard(
                          feedback: feedback,
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
                      ),
                  ],
                ),
              ),
    );
  }
}

class _FeedbackListCard extends StatelessWidget {
  const _FeedbackListCard({required this.feedback, this.onTap});

  final FeedbackModel feedback;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AdminUi.radius),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _statusColor(feedback.status).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _statusIcon(feedback.status),
                  color: _statusColor(feedback.status),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feedback.subject.isEmpty
                          ? feedback.category
                          : feedback.subject,
                      style: AdminUi.body(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'From: ${feedback.userName} | ${DateFormat('MMM d, yyyy').format(feedback.createdAt)}',
                      style: AdminUi.caption(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AdminPill(label: '${feedback.rating}/5'),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFE59B2F);
      case 'reviewed':
        return const Color(0xFF2D9BF0);
      case 'resolved':
        return const Color(0xFF3DA96B);
      default:
        return AdminUi.muted;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.more_horiz_rounded;
      case 'reviewed':
        return Icons.visibility_rounded;
      case 'resolved':
        return Icons.check_circle_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
}

import 'package:flutter/material.dart';

import '../../models/feedback_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/admin_ui.dart';
import '../../widgets/bmoris_back_button.dart';

class AdminFeedbackManagementScreen extends StatefulWidget {
  const AdminFeedbackManagementScreen({super.key});

  @override
  State<AdminFeedbackManagementScreen> createState() =>
      _AdminFeedbackManagementScreenState();
}

class _AdminFeedbackManagementScreenState
    extends State<AdminFeedbackManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<FeedbackModel> _feedbacks = [];
  bool _isLoading = true;

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

  Future<Map<String, String>?> _showResponseDialog(
    FeedbackModel feedback,
  ) async {
    final responseController = TextEditingController(
      text: feedback.adminResponse ?? '',
    );
    String selectedStatus =
        feedback.status == 'resolved' ? 'resolved' : 'reviewed';

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text('Respond to Feedback', style: AdminUi.title()),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: responseController,
                      maxLines: 4,
                      decoration: adminInputDecoration(label: 'Response'),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: selectedStatus,
                      decoration: adminInputDecoration(label: 'Status'),
                      items: const [
                        DropdownMenuItem(
                          value: 'reviewed',
                          child: Text('Reviewed'),
                        ),
                        DropdownMenuItem(
                          value: 'resolved',
                          child: Text('Resolved'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() => selectedStatus = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      'status': selectedStatus,
                      'response': responseController.text.trim(),
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminUi.teal,
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    responseController.dispose();
    return result;
  }

  Future<void> _respondToFeedback(FeedbackModel feedback) async {
    final result = await _showResponseDialog(feedback);
    if (result == null) return;

    try {
      await _firestoreService.respondToFeedback(
        feedback.id,
        status: result['status'] ?? 'reviewed',
        response: result['response'] ?? '',
      );
      await _loadFeedback();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error responding to feedback: $e')),
        );
      }
    }
  }

  Future<void> _deleteFeedback(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete Feedback', style: AdminUi.title()),
            content: Text(
              'Are you sure you want to delete this feedback?',
              style: AdminUi.body(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      await _firestoreService.deleteFeedback(id);
      await _loadFeedback();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting feedback: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount =
        _feedbacks.where((feedback) => feedback.status == 'pending').length;

    return AdminPage(
      child:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : AdminShell(
                title: 'Feedback Management',
                subtitle: '$pendingCount pending items need admin review.',
                leading: const BMorisBackButton(),
                trailing: IconButton(
                  onPressed: _loadFeedback,
                  icon: const Icon(Icons.refresh_rounded, color: AdminUi.teal),
                ),
                child:
                    _feedbacks.isEmpty
                        ? const AdminEmptyState(
                          icon: Icons.forum_outlined,
                          title: 'No feedback yet',
                          subtitle:
                              'Submitted feedback will appear here for review.',
                        )
                        : Column(
                          children:
                              _feedbacks
                                  .map(
                                    (feedback) => _ManagementFeedbackCard(
                                      feedback: feedback,
                                      onRespond:
                                          () => _respondToFeedback(feedback),
                                      onDelete:
                                          () => _deleteFeedback(feedback.id),
                                    ),
                                  )
                                  .toList(),
                        ),
              ),
    );
  }
}

class _ManagementFeedbackCard extends StatelessWidget {
  const _ManagementFeedbackCard({
    required this.feedback,
    required this.onRespond,
    required this.onDelete,
  });

  final FeedbackModel feedback;
  final VoidCallback onRespond;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final hasResponse =
        feedback.adminResponse != null &&
        feedback.adminResponse!.trim().isNotEmpty;

    return AdminCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AdminUi.radius),
        ),
        leading: Container(
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
        title: Text(
          feedback.subject.isEmpty ? feedback.category : feedback.subject,
          style: AdminUi.body(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'From: ${feedback.userName} | ${feedback.rating}/5',
          style: AdminUi.caption(),
        ),
        trailing: AdminPill(label: feedback.status),
        children: [
          const Divider(height: 22, color: AdminUi.border),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Message', style: AdminUi.title()),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(feedback.message, style: AdminUi.body()),
          ),
          if (hasResponse) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AdminUi.mint,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AdminUi.border),
              ),
              child: Text(
                'Response: ${feedback.adminResponse}',
                style: AdminUi.body(AdminUi.tealDark),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: AdminActionButton.primary(
                  label:
                      feedback.status == 'pending'
                          ? 'Respond'
                          : 'Edit Response',
                  icon: Icons.reply_rounded,
                  onPressed: onRespond,
                  expanded: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AdminActionButton.danger(
                  label: 'Delete',
                  icon: Icons.delete_outline_rounded,
                  onPressed: onDelete,
                  expanded: true,
                ),
              ),
            ],
          ),
        ],
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

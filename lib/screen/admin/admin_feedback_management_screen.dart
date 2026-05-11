import 'package:flutter/material.dart';
import '../../models/feedback_model.dart';
import '../../services/firestore_service.dart';
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
              title: const Text('Respond to Feedback'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: responseController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Response',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
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
                    backgroundColor: const Color(0xFF00796B),
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
    if (result == null) {
      return;
    }

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
            title: const Text('Delete Feedback'),
            content: const Text(
              'Are you sure you want to delete this feedback?',
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

    if (confirm != true) {
      return;
    }

    try {
      await _firestoreService.deleteFeedback(id);
      await _loadFeedback();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting feedback: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BMorisBackButton(),
        title: const Text('Feedback Management'),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadFeedback),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _feedbacks.isEmpty
              ? const Center(child: Text('No feedback yet'))
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _feedbacks.length,
                itemBuilder: (context, index) {
                  final feedback = _feedbacks[index];
                  return Card(
                    child: ExpansionTile(
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
                        'From: ${feedback.userName} | ${feedback.rating}/5',
                      ),
                      trailing: Chip(
                        label: Text(
                          feedback.status,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Message:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(feedback.message),
                              const SizedBox(height: 12),
                              if (feedback.adminResponse != null &&
                                  feedback.adminResponse!.trim().isNotEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Response: ${feedback.adminResponse}',
                                  ),
                                ),
                              if (feedback.adminResponse != null &&
                                  feedback.adminResponse!.trim().isNotEmpty)
                                const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed:
                                          () => _respondToFeedback(feedback),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                      ),
                                      child: Text(
                                        feedback.status == 'pending'
                                            ? 'Respond'
                                            : 'Edit Response',
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed:
                                          () => _deleteFeedback(feedback.id),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      child: const Text('Delete'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
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

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/feedback_model.dart';
import '../../widgets/bmoris_back_button.dart';

class AdminFeedbackDetailScreen extends StatelessWidget {
  const AdminFeedbackDetailScreen({super.key, required this.feedback});

  final FeedbackModel feedback;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BMorisBackButton(),
        title: const Text('Feedback Detail'),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Message',
              child: Text(
                feedback.message,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ),
            const SizedBox(height: 16),
            if (feedback.adminResponse != null &&
                feedback.adminResponse!.trim().isNotEmpty)
              _buildSection(
                title: 'Admin Response',
                child: Text(
                  feedback.adminResponse!,
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
              ),
            if (feedback.adminResponse != null &&
                feedback.adminResponse!.trim().isNotEmpty)
              const SizedBox(height: 16),
            _buildSection(
              title: 'Timeline',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Submitted: ${DateFormat('MMM d, yyyy h:mm a').format(feedback.createdAt)}',
                  ),
                  if (feedback.respondedAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Responded: ${DateFormat('MMM d, yyyy h:mm a').format(feedback.respondedAt!)}',
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              feedback.subject,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('From: ${feedback.userName}'),
            const SizedBox(height: 8),
            Chip(label: Text(feedback.category)),
            const SizedBox(height: 8),
            Row(
              children: [
                ...List.generate(
                  5,
                  (index) => Icon(
                    index < feedback.rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Chip(label: Text(feedback.status)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

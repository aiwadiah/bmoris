import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/feedback_model.dart';
import '../../widgets/admin_ui.dart';
import '../../widgets/bmoris_back_button.dart';

class AdminFeedbackDetailScreen extends StatelessWidget {
  const AdminFeedbackDetailScreen({super.key, required this.feedback});

  final FeedbackModel feedback;

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: AdminShell(
        title: 'Feedback Detail',
        subtitle: 'Read-only feedback record and response timeline.',
        leading: const BMorisBackButton(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 14),
            _buildSection(
              title: 'Message',
              icon: Icons.chat_bubble_outline_rounded,
              child: Text(feedback.message, style: AdminUi.body()),
            ),
            if (feedback.adminResponse != null &&
                feedback.adminResponse!.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              _buildSection(
                title: 'Admin Response',
                icon: Icons.reply_rounded,
                child: Text(feedback.adminResponse!, style: AdminUi.body()),
              ),
            ],
            const SizedBox(height: 14),
            _buildSection(
              title: 'Timeline',
              icon: Icons.schedule_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _timelineRow(
                    'Submitted',
                    DateFormat('MMM d, yyyy h:mm a').format(
                      feedback.createdAt,
                    ),
                  ),
                  if (feedback.respondedAt != null)
                    _timelineRow(
                      'Responded',
                      DateFormat('MMM d, yyyy h:mm a').format(
                        feedback.respondedAt!,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _statusColor(feedback.status).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _statusIcon(feedback.status),
                  color: _statusColor(feedback.status),
                  size: 22,
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
                      style: AdminUi.title(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text('From: ${feedback.userName}', style: AdminUi.caption()),
                  ],
                ),
              ),
              AdminPill(label: feedback.status),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AdminPill(label: feedback.category),
              AdminPill(label: '${feedback.rating}/5'),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < feedback.rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: const Color(0xFFE1B647),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AdminUi.teal),
              const SizedBox(width: 8),
              Text(title, style: AdminUi.title()),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _timelineRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 88, child: Text(label, style: AdminUi.caption())),
          Expanded(child: Text(value, style: AdminUi.body())),
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

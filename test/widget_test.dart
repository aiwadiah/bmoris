import 'package:bmoris/models/feedback_model.dart';
import 'package:bmoris/screen/admin/admin_feedback_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FeedbackModel buildFeedback({String? adminResponse, DateTime? respondedAt}) {
    return FeedbackModel(
      id: 'feedback-1',
      oderId: 'user-1',
      userName: 'Aisyah',
      subject: 'Quiz feedback',
      message: 'The history page works well.',
      rating: 4,
      status: adminResponse == null ? 'pending' : 'reviewed',
      adminResponse: adminResponse,
      createdAt: DateTime(2026, 5, 10, 9, 30),
      respondedAt: respondedAt,
    );
  }

  Future<void> pumpFeedbackDetail(
    WidgetTester tester,
    FeedbackModel feedback,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: AdminFeedbackDetailScreen(feedback: feedback)),
    );
  }

  testWidgets('feedback detail shows submitted feedback content', (
    WidgetTester tester,
  ) async {
    await pumpFeedbackDetail(tester, buildFeedback());

    expect(find.text('Feedback Detail'), findsOneWidget);
    expect(find.text('Quiz feedback'), findsOneWidget);
    expect(find.text('From: Aisyah'), findsOneWidget);
    expect(find.text('Message'), findsOneWidget);
    expect(find.text('The history page works well.'), findsOneWidget);
    expect(find.text('Timeline'), findsOneWidget);
    expect(find.textContaining('Submitted:'), findsOneWidget);
    expect(find.text('Admin Response'), findsNothing);
  });

  testWidgets('feedback detail shows admin response when present', (
    WidgetTester tester,
  ) async {
    await pumpFeedbackDetail(
      tester,
      buildFeedback(
        adminResponse: 'Thanks. We will keep monitoring this flow.',
        respondedAt: DateTime(2026, 5, 10, 10, 15),
      ),
    );

    expect(find.text('Admin Response'), findsOneWidget);
    expect(
      find.text('Thanks. We will keep monitoring this flow.'),
      findsOneWidget,
    );
    expect(find.textContaining('Responded:'), findsOneWidget);
  });
}

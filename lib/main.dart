import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/lesson_provider.dart';
import 'providers/quiz_provider.dart';
import 'screen/splash_screen.dart';
import 'screen/login_screen.dart';
import 'screen/register_screen.dart';
import 'screen/home_screen.dart';
import 'screen/profile_screen.dart';
import 'screen/pronunciation_screen.dart';
import 'screen/chatbot_screen.dart';
import 'screen/lesson_screen.dart';
import 'screen/quiz_screen.dart';
import 'screen/leaderboard_screen.dart';
import 'screen/offline_lessons_screen.dart';
import 'screen/translation_screen.dart';
import 'screen/feedback_screen.dart';
import 'screen/pronunciation_history_screen.dart';
import 'screen/admin/admin_dashboard_screen.dart';
import 'screen/admin/admin_register_screen.dart';
import 'screen/admin/admin_profile_screen.dart';
import 'screen/admin/manage_phonemes_screen.dart';
import 'screen/admin/manage_announcements_screen.dart';
import 'screen/admin/data_management_screen.dart';
import 'screen/admin/manage_lessons_screen.dart';
import 'screen/admin/manage_quizzes_screen.dart';
import 'screen/admin/manage_users_screen.dart';
import 'screen/admin/manage_ai_prompts_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const BMorisApp());
}

class BMorisApp extends StatelessWidget {
  const BMorisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LessonProvider()),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
      ],
      child: MaterialApp(
        title: 'BMoris',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00796B)),
          useMaterial3: true,
          textTheme: GoogleFonts.poppinsTextTheme(),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/practice': (context) => const PronunciationScreen(),
          '/chat': (context) => const ChatbotScreen(),
          '/lessons': (context) => const LessonScreen(),
          '/quiz': (context) => const QuizScreen(),
          '/leaderboard': (context) => const LeaderboardScreen(),
          '/offline-lessons': (context) => const OfflineLessonsScreen(),
          '/translate': (context) => const TranslationScreen(),
          '/feedback': (context) => const FeedbackScreen(),
          '/pronunciation-history': (context) => const PronunciationHistoryScreen(),
          '/admin-register': (context) => const AdminRegisterScreen(),
          '/admin': (context) => const AdminDashboardScreen(),
          '/admin/profile': (context) => const AdminProfileScreen(),
          '/admin/phonemes': (context) => const ManagePhonemesScreen(),
          '/admin/announcements': (context) => const ManageAnnouncementsScreen(),
          '/admin/data': (context) => const DataManagementScreen(),
          '/admin/lessons': (context) => const ManageLessonsScreen(),
          '/admin/quizzes': (context) => const ManageQuizzesScreen(),
          '/admin/users': (context) => const ManageUsersScreen(),
          '/admin/ai-prompts': (context) => const ManageAIPromptsScreen(),
        },
      ),
    );
  }
}

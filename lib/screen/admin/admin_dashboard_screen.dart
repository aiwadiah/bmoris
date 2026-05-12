import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/feedback_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/admin_ui.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  int _selectedIndex = 0;
  Map<String, dynamic> _analytics = {};
  List<UserModel> _users = [];
  List<FeedbackModel> _feedbacks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _analytics = await _firestoreService.getUserAnalytics();
      _users = await _firestoreService.getAllUsers();
      _feedbacks = await _firestoreService.getAllFeedback();
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        height: 68,
        backgroundColor: Colors.white,
        indicatorColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => AdminUi.caption(
            states.contains(WidgetState.selected) ? AdminUi.teal : AdminUi.muted,
          ),
        ),
        destinations: [
          NavigationDestination(
            icon: Icon(
              Icons.home_rounded,
              color: _selectedIndex == 0 ? AdminUi.teal : AdminUi.muted,
            ),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.people_alt_rounded,
              color: _selectedIndex == 1 ? AdminUi.teal : AdminUi.muted,
            ),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.library_books_rounded,
              color: _selectedIndex == 2 ? AdminUi.teal : AdminUi.muted,
            ),
            label: 'Content',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.campaign_rounded,
              color: _selectedIndex == 3 ? AdminUi.teal : AdminUi.muted,
            ),
            label: 'Alerts',
          ),
        ],
      ),
      child:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : IndexedStack(
                index: _selectedIndex,
                children: [
                  _buildOverview(),
                  _buildUsersView(),
                  _buildContentView(),
                  _buildAnnouncementView(),
                ],
              ),
    );
  }

  Widget _buildOverview() {
    final pendingCount =
        _feedbacks.where((feedback) => feedback.status == 'pending').length;
    final userCount = (_analytics['totalUsers'] ?? _users.length).toString();
    final pronunciationCount =
        '${_analytics['totalPronunciationAttempts'] ?? 0}';
    final quizCount = '${_analytics['totalQuizAttempts'] ?? 0}';
    final averageXp = '${_analytics['averageXp'] ?? 0}';

    return SingleChildScrollView(
      child: Column(
        children: [
          // Green Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 130), // Reduced from 150 to tighten gap
            decoration: const BoxDecoration(
              color: AdminUi.teal,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Admin Dashboard',
                        style: AdminUi.headline(Colors.white),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _loadData,
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pushNamed(context, '/admin/profile'),
                          icon: const Icon(Icons.person_outline_rounded, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'A quick view of activity, users, and content health.',
                  style: AdminUi.body(Colors.white.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),

          // Overlapping Content
          Transform.translate(
            offset: const Offset(0, -110), // Adjusted offset to keep stat cards fully on green
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: .9,
                    children: [
                      AdminStatCard(label: 'Users', value: userCount, icon: Icons.people_alt_rounded),
                      AdminStatCard(label: 'Practice', value: pronunciationCount, icon: Icons.mic_none_rounded),
                      AdminStatCard(label: 'Quizzes', value: quizCount, icon: Icons.quiz_outlined),
                      AdminStatCard(label: 'Avg XP', value: averageXp, icon: Icons.bolt_rounded),
                    ],
                  ),
                  const SizedBox(height: 32), // Increased gap before Admin Tools
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: AdminSectionTitle(
                      'Admin Tools',
                      trailing: Text('$pendingCount pending', style: AdminUi.caption()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AdminCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _overviewAction(
                          icon: Icons.campaign_rounded,
                          title: 'Manage announcements',
                          subtitle: 'Create updates and make them visible to learners.',
                          onTap: () => Navigator.pushNamed(context, '/admin/announcements'),
                        ),
                        _overviewAction(
                          icon: Icons.book_rounded,
                          title: 'Manage lessons',
                          subtitle: 'Edit lesson cards, content, and publish status.',
                          onTap: () => Navigator.pushNamed(context, '/admin/lessons'),
                        ),
                        _overviewAction(
                          icon: Icons.quiz_rounded,
                          title: 'Manage quizzes',
                          subtitle: 'Update quiz sets or create new practice content.',
                          onTap: () => Navigator.pushNamed(context, '/admin/quizzes'),
                        ),
                        _overviewAction(
                          icon: Icons.psychology_alt_rounded,
                          title: 'AI prompt library',
                          subtitle: 'Tune prompt behavior for tutor and content tools.',
                          onTap: () => Navigator.pushNamed(context, '/admin/ai-prompts'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: AdminSectionTitle('Recent Activity'),
                  ),
                  const SizedBox(height: 12),
                  AdminCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_feedbacks.isEmpty)
                          Text('No recent feedback yet.', style: AdminUi.body(AdminUi.muted))
                        else
                          ..._feedbacks.take(4).map(
                                (feedback) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: _statusColor(feedback.status).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          _statusIcon(feedback.status),
                                          size: 18,
                                          color: _statusColor(feedback.status),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              feedback.subject.isEmpty ? 'General feedback' : feedback.subject,
                                              style: AdminUi.body(),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              feedback.userName,
                                              style: AdminUi.caption(),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(feedback.status, style: AdminUi.caption(_statusColor(feedback.status))),
                                    ],
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersView() {
    return AdminShell(
      title: 'Users',
      subtitle: '${_users.length} total accounts',
      trailing: IconButton(
        onPressed: () => Navigator.pushNamed(context, '/admin/users'),
        icon: const Icon(Icons.open_in_new_rounded, color: AdminUi.teal),
      ),
      child: Column(
        children: [
          ..._users.take(8).map(
            (user) => AdminCard(
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: user.isAdmin ? const Color(0xFFEAD8A7) : AdminUi.teal,
                    child: Text(
                      user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                      style: TextStyle(
                        color: user.isAdmin ? AdminUi.text : Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name, style: AdminUi.body()),
                        Text(user.email, style: AdminUi.caption()),
                      ],
                    ),
                  ),
                  AdminPill(label: user.role == 'admin' ? 'Admin' : 'Learner'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentView() {
    return AdminShell(
      title: 'Content',
      subtitle: 'Manage learning assets and supporting tools.',
      child: Column(
        children: [
          _navigationCard('Manage Lessons', 'Review lesson visibility and lesson flow.', Icons.menu_book_rounded, '/admin/lessons'),
          _navigationCard('Manage Quizzes', 'Keep practice banks current and levelled.', Icons.quiz_rounded, '/admin/quizzes'),
          _navigationCard('Phoneme Library', 'Update phoneme examples and labels.', Icons.record_voice_over_rounded, '/admin/phonemes'),
          _navigationCard('Data Management', 'Import and refresh bundled source data.', Icons.storage_rounded, '/admin/data'),
        ],
      ),
    );
  }

  Widget _buildAnnouncementView() {
    final pendingFeedback =
        _feedbacks.where((feedback) => feedback.status == 'pending').length;
    return AdminShell(
      title: 'Announcements',
      subtitle: '$pendingFeedback feedback items still need review.',
      child: Column(
        children: [
          _navigationCard('Manage Announcements', 'Publish notices and toggle visibility.', Icons.campaign_rounded, '/admin/announcements'),
          _navigationCard('Feedback View', 'Open the filtered feedback inbox.', Icons.rate_review_rounded, '/admin/feedback/view'),
          _navigationCard('Feedback Management', 'Respond and resolve submitted feedback.', Icons.forum_rounded, '/admin/feedback/manage'),
          _navigationCard('AI Prompt Library', 'Fine-tune prompt behavior for admin tools.', Icons.psychology_alt_rounded, '/admin/ai-prompts'),
        ],
      ),
    );
  }

  Widget _overviewAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AdminUi.mint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AdminUi.teal, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AdminUi.body()),
                  Text(subtitle, style: AdminUi.caption()),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AdminUi.muted),
          ],
        ),
      ),
    );
  }

  Widget _navigationCard(String title, String subtitle, IconData icon, String route) {
    return AdminCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(AdminUi.radius),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AdminUi.mint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AdminUi.teal, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AdminUi.body()),
                  Text(subtitle, style: AdminUi.caption()),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AdminUi.muted),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFE59B2F);
      case 'reviewed':
        return const Color(0xFF4E8DF5);
      case 'resolved':
        return const Color(0xFF3DA96B);
      default:
        return AdminUi.muted;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule_rounded;
      case 'reviewed':
        return Icons.remove_red_eye_outlined;
      case 'resolved':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
}

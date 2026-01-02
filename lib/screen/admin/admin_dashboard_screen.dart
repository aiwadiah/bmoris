import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../models/feedback_model.dart';

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
    } catch (e) {
      // Handle error
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, '/admin/profile');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false).signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _selectedIndex,
              children: [
                _buildOverview(),
                _buildUserManagement(),
                _buildFeedbackManagement(),
                _buildContentManagement(),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF00796B),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.feedback),
            label: 'Feedback',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Content',
          ),
        ],
      ),
    );
  }

  Widget _buildOverview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analytics Overview',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Stats Grid
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatCard(
                'Total Users',
                '${_analytics['totalUsers'] ?? 0}',
                Icons.people,
                Colors.blue,
              ),
              _buildStatCard(
                'Pronunciations',
                '${_analytics['totalPronunciationAttempts'] ?? 0}',
                Icons.mic,
                Colors.green,
              ),
              _buildStatCard(
                'Quiz Attempts',
                '${_analytics['totalQuizAttempts'] ?? 0}',
                Icons.quiz,
                Colors.orange,
              ),
              _buildStatCard(
                'Average XP',
                '${_analytics['averageXp'] ?? 0}',
                Icons.star,
                Colors.amber,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recent Feedback
          const Text(
            'Recent Feedback',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (_feedbacks.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('No feedback yet')),
              ),
            )
          else
            ..._feedbacks.take(5).map((feedback) => Card(
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
                    subtitle: Text(feedback.userName),
                    trailing: Text(feedback.status),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserManagement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text(
                'User Management',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text('${_users.length} users'),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _users.length,
            itemBuilder: (context, index) {
              final user = _users[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF00796B),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(user.name),
                  subtitle: Text(user.email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Chip(
                        label: Text(
                          user.role,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: user.isAdmin
                            ? Colors.red.shade100
                            : Colors.blue.shade100,
                      ),
                      const SizedBox(width: 8),
                      Text('${user.xp} XP'),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackManagement() {
    return Column(
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
              Text('${_feedbacks.length} feedbacks'),
            ],
          ),
        ),
        Expanded(
          child: _feedbacks.isEmpty
              ? const Center(child: Text('No feedback yet'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                        subtitle: Text('From: ${feedback.userName}'),
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
                                const SizedBox(height: 16),
                                if (feedback.status == 'pending')
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => _respondToFeedback(
                                              feedback, 'reviewed'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                          ),
                                          child: const Text('Reviewed',
                                              style: TextStyle(color: Colors.white)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => _respondToFeedback(
                                              feedback, 'resolved'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                          ),
                                          child: const Text('Resolved',
                                              style: TextStyle(color: Colors.white)),
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
        ),
      ],
    );
  }

  Widget _buildContentManagement() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Content Management',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Management Cards
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildManagementCard(
                'Manage Lessons',
                'Add, edit, or remove lessons',
                Icons.book,
                Colors.blue,
                () {
                  Navigator.pushNamed(context, '/admin/lessons');
                },
              ),
              _buildManagementCard(
                'Manage Quizzes',
                'Create and manage quizzes',
                Icons.quiz,
                Colors.orange,
                () {
                  Navigator.pushNamed(context, '/admin/quizzes');
                },
              ),
              _buildManagementCard(
                'Phoneme Library',
                'Manage phoneme definitions',
                Icons.record_voice_over,
                Colors.green,
                () {
                  Navigator.pushNamed(context, '/admin/phonemes');
                },
              ),
              _buildManagementCard(
                'Announcements',
                'Create announcements',
                Icons.announcement,
                Colors.purple,
                () {
                  Navigator.pushNamed(context, '/admin/announcements');
                },
              ),
              _buildManagementCard(
                'Seed Data',
                'Import lessons & quizzes',
                Icons.upload_file,
                Colors.teal,
                () {
                  Navigator.pushNamed(context, '/admin/data');
                },
              ),
              _buildManagementCard(
                'Manage Users',
                'View and manage users',
                Icons.people,
                Colors.indigo,
                () {
                  Navigator.pushNamed(context, '/admin/users');
                },
              ),
              _buildManagementCard(
                'AI Prompts',
                'Configure AI training prompts',
                Icons.psychology,
                Colors.pink,
                () {
                  Navigator.pushNamed(context, '/admin/ai-prompts');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManagementCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 40),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
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

  Future<void> _respondToFeedback(FeedbackModel feedback, String status) async {
    await _firestoreService.respondToFeedback(
        feedback.id, 'Status updated to $status');
    _loadData();
  }
}

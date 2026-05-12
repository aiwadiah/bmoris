import 'package:flutter/material.dart';

import '../../services/data_seeder.dart';
import '../../widgets/admin_ui.dart';
import '../../widgets/bmoris_back_button.dart';

class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({super.key});

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  final DataSeeder _dataSeeder = DataSeeder();
  bool _isLoading = false;

  Future<void> _seedData() async {
    setState(() => _isLoading = true);
    try {
      await _dataSeeder.seedAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data seeded successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error seeding data: $e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _clearData() async {
    final confirm = await _confirmAction(
      title: 'Clear All Data',
      message: 'Delete all lessons and quizzes? This cannot be undone.',
      confirmLabel: 'Delete',
      confirmColor: AdminUi.danger,
    );
    if (confirm != true) return;
    setState(() => _isLoading = true);
    try {
      await _dataSeeder.clearAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data cleared successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing data: $e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _reseedData() async {
    final confirm = await _confirmAction(
      title: 'Reseed Data',
      message: 'Replace all lessons and quizzes with the bundled JSON source files?',
      confirmLabel: 'Reseed',
      confirmColor: const Color(0xFFE59B2F),
    );
    if (confirm != true) return;
    setState(() => _isLoading = true);
    try {
      await _dataSeeder.reseedAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data reseeded successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error reseeding data: $e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<bool?> _confirmAction({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: AdminUi.title()),
        content: Text(message, style: AdminUi.body()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: confirmColor),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      child: AdminShell(
        title: 'Data Management',
        subtitle: 'Import, reset, and maintain bundled BMoris content.',
        leading: const BMorisBackButton(),
        child: Stack(
          children: [
            Column(
              children: [
                AdminCard(
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AdminUi.mint,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.storage_rounded, color: AdminUi.teal),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Workspace Actions', style: AdminUi.title()),
                            Text('Use these tools when content needs to be imported or reset.', style: AdminUi.caption()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _actionCard(
                  title: 'Import Lessons and Quizzes',
                  subtitle: 'Load bundled JSON content into Firestore without replacing existing records.',
                  icon: Icons.upload_file_rounded,
                  accent: const Color(0xFF3DA96B),
                  action: AdminActionButton.primary(label: 'Import Data', onPressed: _seedData, expanded: true),
                ),
                const SizedBox(height: 12),
                _actionCard(
                  title: 'Export Refresh',
                  subtitle: 'Clear current learning content and reload the latest bundled source.',
                  icon: Icons.sync_rounded,
                  accent: const Color(0xFFE59B2F),
                  action: AdminActionButton.outlined(label: 'Reseed Data', onPressed: _reseedData, expanded: true),
                ),
                const SizedBox(height: 12),
                _actionCard(
                  title: 'Danger Zone',
                  subtitle: 'Permanently remove all lesson and quiz documents from Firestore.',
                  icon: Icons.delete_forever_rounded,
                  accent: AdminUi.danger,
                  action: AdminActionButton.danger(label: 'Clear All Data', onPressed: _clearData, expanded: true),
                ),
                const SizedBox(height: 16),
                AdminCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Source Files', style: AdminUi.title()),
                      const SizedBox(height: 10),
                      Text('assets/data/lessons.json', style: AdminUi.body()),
                      const SizedBox(height: 4),
                      Text('assets/data/quizzes.json', style: AdminUi.body()),
                    ],
                  ),
                ),
              ],
            ),
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.white.withValues(alpha: 0.6),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _actionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required Widget action,
  }) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AdminUi.title()),
                    Text(subtitle, style: AdminUi.caption()),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          action,
        ],
      ),
    );
  }
}

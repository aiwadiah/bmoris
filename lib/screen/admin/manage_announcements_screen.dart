import 'package:flutter/material.dart';

import '../../models/announcement_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/admin_ui.dart';
import '../../widgets/bmoris_back_button.dart';

class ManageAnnouncementsScreen extends StatefulWidget {
  const ManageAnnouncementsScreen({super.key});

  @override
  State<ManageAnnouncementsScreen> createState() => _ManageAnnouncementsScreenState();
}

class _ManageAnnouncementsScreenState extends State<ManageAnnouncementsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  List<AnnouncementModel> _announcements = [];
  bool _isLoading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAnnouncements() async {
    setState(() => _isLoading = true);
    try {
      _announcements = await _firestoreService.getAnnouncements();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading announcements: $e')));
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  List<AnnouncementModel> get _visibleAnnouncements {
    final query = _searchController.text.trim().toLowerCase();
    return _announcements.where((announcement) {
      if (_filter == 'active' && !announcement.isActive) return false;
      if (_filter == 'draft' && announcement.isActive) return false;
      if (query.isEmpty) return true;
      return announcement.title.toLowerCase().contains(query) ||
          announcement.content.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _addAnnouncement() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _AnnouncementDialog(),
    );
    if (result != null) {
      try {
        final announcement = AnnouncementModel(
          id: '',
          title: result['title'],
          content: result['content'],
          createdBy: 'Admin',
          createdAt: DateTime.now(),
          isActive: true,
        );
        await _firestoreService.createAnnouncement(announcement);
        await _loadAnnouncements();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error creating announcement: $e')));
        }
      }
    }
  }

  Future<void> _editAnnouncement(AnnouncementModel announcement) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AnnouncementDialog(title: announcement.title, content: announcement.content),
    );
    if (result != null) {
      try {
        await _firestoreService.firestore.collection('announcements').doc(announcement.id).update({
          'title': result['title'],
          'content': result['content'],
        });
        await _loadAnnouncements();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating announcement: $e')));
        }
      }
    }
  }

  Future<void> _toggleActive(AnnouncementModel announcement) async {
    try {
      await _firestoreService.firestore.collection('announcements').doc(announcement.id).update({
        'isActive': !announcement.isActive,
      });
      await _loadAnnouncements();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error toggling announcement: $e')));
      }
    }
  }

  Future<void> _deleteAnnouncement(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Announcement', style: AdminUi.title()),
        content: Text('Are you sure you want to delete this announcement?', style: AdminUi.body()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _firestoreService.firestore.collection('announcements').doc(id).delete();
        await _loadAnnouncements();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting announcement: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final announcements = _visibleAnnouncements;
    return AdminPage(
      floatingActionButton: FloatingActionButton(
        onPressed: _addAnnouncement,
        backgroundColor: AdminUi.teal,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      child:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : AdminShell(
                title: 'Announcements',
                subtitle: 'Publish updates, control visibility, and keep the feed tidy.',
                leading: const BMorisBackButton(),
                trailing: AdminActionButton.primary(label: 'Add', icon: Icons.add_rounded, onPressed: _addAnnouncement),
                child: Column(
                  children: [
                    AdminSearchField(controller: _searchController, hintText: 'Search announcements'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        AdminPill(label: 'All', selected: _filter == 'all', onTap: () => setState(() => _filter = 'all')),
                        const SizedBox(width: 8),
                        AdminPill(label: 'Published', selected: _filter == 'active', onTap: () => setState(() => _filter = 'active')),
                        const SizedBox(width: 8),
                        AdminPill(label: 'Draft', selected: _filter == 'draft', onTap: () => setState(() => _filter = 'draft')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (announcements.isEmpty)
                      const AdminEmptyState(
                        icon: Icons.campaign_outlined,
                        title: 'No announcements found',
                        subtitle: 'Create a new announcement or widen the active filters.',
                      )
                    else
                      ...announcements.map((announcement) => AdminCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AdminUi.mint,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.campaign_rounded, color: AdminUi.teal),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          announcement.title,
                                          style: AdminUi.body(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      AdminPill(
                                        label: announcement.isActive ? 'Published' : 'Draft',
                                        selected: announcement.isActive,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    announcement.content,
                                    style: AdminUi.caption(),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          announcement.createdAt.toString().substring(0, 16),
                                          style: AdminUi.caption(),
                                        ),
                                      ),
                                      Switch(
                                        value: announcement.isActive,
                                        onChanged: (_) => _toggleActive(announcement),
                                        activeThumbColor: AdminUi.teal,
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == 'edit') _editAnnouncement(announcement);
                                          if (value == 'delete') _deleteAnnouncement(announcement.id);
                                        },
                                        itemBuilder: (context) => const [
                                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                  ],
                ),
              ),
    );
  }
}

class _AnnouncementDialog extends StatefulWidget {
  const _AnnouncementDialog({this.title, this.content});

  final String? title;
  final String? content;

  @override
  State<_AnnouncementDialog> createState() => _AnnouncementDialogState();
}

class _AnnouncementDialogState extends State<_AnnouncementDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    _contentController = TextEditingController(text: widget.content);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title == null ? 'New Announcement' : 'Edit Announcement', style: AdminUi.title()),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: adminInputDecoration(label: 'Title'),
              validator: (value) => value == null || value.isEmpty ? 'Please enter title' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contentController,
              decoration: adminInputDecoration(label: 'Content'),
              maxLines: 4,
              validator: (value) => value == null || value.isEmpty ? 'Please enter content' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'title': _titleController.text.trim(),
                'content': _contentController.text.trim(),
              });
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AdminUi.teal),
          child: Text(widget.title == null ? 'Create' : 'Save', style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

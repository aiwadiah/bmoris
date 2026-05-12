import 'package:flutter/material.dart';

import '../../services/firestore_service.dart';
import '../../widgets/admin_ui.dart';
import '../../widgets/bmoris_back_button.dart';

class ManagePhonemesScreen extends StatefulWidget {
  const ManagePhonemesScreen({super.key});

  @override
  State<ManagePhonemesScreen> createState() => _ManagePhonemesScreenState();
}

class _ManagePhonemesScreenState extends State<ManagePhonemesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _phonemes = [];
  bool _isLoading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _loadPhonemes();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPhonemes() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _firestoreService.firestore.collection('phonemes').get();
      _phonemes = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading phonemes: $e')));
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> get _visiblePhonemes {
    final query = _searchController.text.trim().toLowerCase();
    return _phonemes.where((phoneme) {
      final symbol = (phoneme['symbol'] ?? '').toString();
      final description = (phoneme['description'] ?? '').toString();
      final example = (phoneme['exampleWord'] ?? '').toString();
      if (_filter == 'popular' && example.isEmpty) return false;
      if (query.isEmpty) return true;
      return symbol.toLowerCase().contains(query) ||
          description.toLowerCase().contains(query) ||
          example.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _addPhoneme() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const _PhonemeDialog(),
    );
    if (result != null) {
      try {
        await _firestoreService.firestore.collection('phonemes').add({
          'symbol': result['symbol'],
          'description': result['description'],
          'exampleWord': result['exampleWord'],
          'createdAt': DateTime.now().toIso8601String(),
        });
        await _loadPhonemes();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding phoneme: $e')));
        }
      }
    }
  }

  Future<void> _editPhoneme(Map<String, dynamic> phoneme) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _PhonemeDialog(
        symbol: phoneme['symbol'],
        description: phoneme['description'],
        exampleWord: phoneme['exampleWord'],
      ),
    );
    if (result != null) {
      try {
        await _firestoreService.firestore.collection('phonemes').doc(phoneme['id']).update({
          'symbol': result['symbol'],
          'description': result['description'],
          'exampleWord': result['exampleWord'],
          'updatedAt': DateTime.now().toIso8601String(),
        });
        await _loadPhonemes();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating phoneme: $e')));
        }
      }
    }
  }

  Future<void> _deletePhoneme(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Phoneme', style: AdminUi.title()),
        content: Text('Delete this phoneme from the library?', style: AdminUi.body()),
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
        await _firestoreService.firestore.collection('phonemes').doc(id).delete();
        await _loadPhonemes();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting phoneme: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final phonemes = _visiblePhonemes;
    return AdminPage(
      floatingActionButton: FloatingActionButton(
        onPressed: _addPhoneme,
        backgroundColor: AdminUi.teal,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      child:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : AdminShell(
                title: 'Phoneme Library',
                subtitle: 'Keep symbols, notes, and examples clean for the tutor.',
                leading: const BMorisBackButton(),
                trailing: AdminActionButton.primary(label: 'Add', icon: Icons.add_rounded, onPressed: _addPhoneme),
                child: Column(
                  children: [
                    AdminSearchField(controller: _searchController, hintText: 'Search phonemes'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        AdminPill(label: 'All', selected: _filter == 'all', onTap: () => setState(() => _filter = 'all')),
                        const SizedBox(width: 8),
                        AdminPill(label: 'Popular', selected: _filter == 'popular', onTap: () => setState(() => _filter = 'popular')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (phonemes.isEmpty)
                      const AdminEmptyState(
                        icon: Icons.record_voice_over_outlined,
                        title: 'No phonemes found',
                        subtitle: 'Add a phoneme or clear the current search term.',
                      )
                    else
                      ...phonemes.map((phoneme) => AdminCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: AdminUi.mint,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Text(
                                  (phoneme['symbol'] ?? '').toString(),
                                  style: AdminUi.title(AdminUi.teal),
                                ),
                              ),
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
                                          (phoneme['description'] ?? '').toString(),
                                          style: AdminUi.body(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == 'edit') _editPhoneme(phoneme);
                                          if (value == 'delete') _deletePhoneme(phoneme['id']);
                                        },
                                        itemBuilder: (context) => const [
                                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Example: ${(phoneme['exampleWord'] ?? '').toString()}',
                                    style: AdminUi.caption(),
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

class _PhonemeDialog extends StatefulWidget {
  const _PhonemeDialog({this.symbol, this.description, this.exampleWord});

  final String? symbol;
  final String? description;
  final String? exampleWord;

  @override
  State<_PhonemeDialog> createState() => _PhonemeDialogState();
}

class _PhonemeDialogState extends State<_PhonemeDialog> {
  late final TextEditingController _symbolController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _exampleWordController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _symbolController = TextEditingController(text: widget.symbol);
    _descriptionController = TextEditingController(text: widget.description);
    _exampleWordController = TextEditingController(text: widget.exampleWord);
  }

  @override
  void dispose() {
    _symbolController.dispose();
    _descriptionController.dispose();
    _exampleWordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.symbol == null ? 'Add Phoneme' : 'Edit Phoneme', style: AdminUi.title()),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _symbolController,
              decoration: adminInputDecoration(label: 'Phoneme symbol', hint: 'e.g. /a/'),
              validator: (value) => value == null || value.isEmpty ? 'Please enter phoneme symbol' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: adminInputDecoration(label: 'Description'),
              validator: (value) => value == null || value.isEmpty ? 'Please enter description' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _exampleWordController,
              decoration: adminInputDecoration(label: 'Example word'),
              validator: (value) => value == null || value.isEmpty ? 'Please enter example word' : null,
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
                'symbol': _symbolController.text.trim(),
                'description': _descriptionController.text.trim(),
                'exampleWord': _exampleWordController.text.trim(),
              });
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AdminUi.teal),
          child: Text(widget.symbol == null ? 'Add' : 'Save', style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../widgets/bmoris_back_button.dart';

class ManagePhonemesScreen extends StatefulWidget {
  const ManagePhonemesScreen({super.key});

  @override
  State<ManagePhonemesScreen> createState() => _ManagePhonemesScreenState();
}

class _ManagePhonemesScreenState extends State<ManagePhonemesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _phonemes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPhonemes();
  }

  Future<void> _loadPhonemes() async {
    setState(() => _isLoading = true);
    try {
      final snapshot =
          await _firestoreService.firestore.collection('phonemes').get();
      _phonemes =
          snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading phonemes: $e')));
    }
    setState(() => _isLoading = false);
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
        _loadPhonemes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Phoneme added successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error adding phoneme: $e')));
        }
      }
    }
  }

  Future<void> _editPhoneme(Map<String, dynamic> phoneme) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder:
          (context) => _PhonemeDialog(
            symbol: phoneme['symbol'],
            description: phoneme['description'],
            exampleWord: phoneme['exampleWord'],
          ),
    );

    if (result != null) {
      try {
        await _firestoreService.firestore
            .collection('phonemes')
            .doc(phoneme['id'])
            .update({
              'symbol': result['symbol'],
              'description': result['description'],
              'exampleWord': result['exampleWord'],
              'updatedAt': DateTime.now().toIso8601String(),
            });
        _loadPhonemes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Phoneme updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error updating phoneme: $e')));
        }
      }
    }
  }

  Future<void> _deletePhoneme(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Phoneme'),
            content: const Text(
              'Are you sure you want to delete this phoneme?',
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

    if (confirm == true) {
      try {
        await _firestoreService.firestore
            .collection('phonemes')
            .doc(id)
            .delete();
        _loadPhonemes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Phoneme deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting phoneme: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BMorisBackButton(),
        title: const Text('Manage Phoneme Library'),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _phonemes.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.record_voice_over,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No phonemes yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add your first phoneme',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _phonemes.length,
                itemBuilder: (context, index) {
                  final phoneme = _phonemes[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF00796B),
                        child: Text(
                          phoneme['symbol'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        phoneme['symbol'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(phoneme['description'] ?? ''),
                          const SizedBox(height: 4),
                          Text(
                            'Example: ${phoneme['exampleWord'] ?? ''}',
                            style: const TextStyle(
                              fontStyle: FontStyle.italic,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: PopupMenuButton(
                        itemBuilder:
                            (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                        onSelected: (value) {
                          if (value == 'edit') {
                            _editPhoneme(phoneme);
                          } else if (value == 'delete') {
                            _deletePhoneme(phoneme['id']);
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPhoneme,
        backgroundColor: const Color(0xFF00796B),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _PhonemeDialog extends StatefulWidget {
  final String? symbol;
  final String? description;
  final String? exampleWord;

  const _PhonemeDialog({this.symbol, this.description, this.exampleWord});

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
      title: Text(widget.symbol == null ? 'Add Phoneme' : 'Edit Phoneme'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _symbolController,
                decoration: const InputDecoration(
                  labelText: 'Phoneme Symbol',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., /a/',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phoneme symbol';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  hintText: 'Describe the phoneme',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _exampleWordController,
                decoration: const InputDecoration(
                  labelText: 'Example Word',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., apa',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter example word';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
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
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00796B),
          ),
          child: Text(
            widget.symbol == null ? 'Add' : 'Update',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

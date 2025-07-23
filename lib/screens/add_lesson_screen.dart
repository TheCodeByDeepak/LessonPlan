import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddLessonScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const AddLessonScreen({super.key, this.initialData});

  @override
  State<AddLessonScreen> createState() => _AddLessonScreenState();
}

class _AddLessonScreenState extends State<AddLessonScreen> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> _lesson;
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _lesson = {
      'className': widget.initialData?['className'] ?? '',
      'subject': widget.initialData?['subject'] ?? '',
      'topic': widget.initialData?['topic'] ?? '',
      'date': widget.initialData != null
          ? DateTime.tryParse(widget.initialData!['date']) ?? DateTime.now()
          : DateTime.now(),
      'customSections': widget.initialData?['customSections'] != null
          ? (widget.initialData!['customSections'] as List)
          .map<Map<String, List<String>>>((section) {
        final map = Map<String, dynamic>.from(section);
        final key = map.keys.first;
        final value = List<String>.from(map[key]);
        return {key: value};
      }).toList()
          : <Map<String, List<String>>>[],
    };
  }

  void _addCustomSection() {
    _showCustomSectionDialog(onSave: (title, points) {
      setState(() {
        (_lesson['customSections'] as List).add({title: points});
      });
    });
  }

  void _editCustomSection(int index, String initialTitle, List<String> initialPoints) {
    _showCustomSectionDialog(
      title: initialTitle,
      initialPoints: initialPoints,
      onSave: (updatedTitle, updatedPoints) {
        setState(() {
          (_lesson['customSections'] as List)[index] = {updatedTitle: updatedPoints};
        });
      },
    );
  }

  void _showCustomSectionDialog({
    String title = '',
    List<String> initialPoints = const [],
    required void Function(String, List<String>) onSave,
  }) {
    List<String> subpoints = List.from(initialPoints);
    String sectionTitle = title;
    final titleController = TextEditingController(text: sectionTitle);

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Section Title',
                        prefixIcon: Icon(Icons.title),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) => sectionTitle = val,
                    ),
                    const SizedBox(height: 10),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: subpoints.length,
                      itemBuilder: (context, i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: subpoints[i],
                                  onChanged: (val) => subpoints[i] = val,
                                  decoration: InputDecoration(
                                    labelText: 'Point ${i + 1}',
                                    prefixIcon: const Icon(Icons.circle, size: 10),
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () => setModalState(() => subpoints.removeAt(i)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => setModalState(() => subpoints.add('')),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Point'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            if (sectionTitle.isNotEmpty && subpoints.isNotEmpty) {
                              onSave(sectionTitle, subpoints);
                              Navigator.pop(context);
                            }
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _saveForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        await FirebaseFirestore.instance.collection('lessons').add({
          'className': _lesson['className'],
          'subject': _lesson['subject'],
          'topic': _lesson['topic'],
          'date': (_lesson['date'] as DateTime).toIso8601String(),
          'customSections': _lesson['customSections'],
          'createdBy': currentUser?.uid,
        });

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildField(String label, String fieldKey, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        initialValue: _lesson[fieldKey],
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, color: Colors.blue) : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        validator: (value) => value!.isEmpty ? 'Required' : null,
        onSaved: (val) => _lesson[fieldKey] = val ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: const Text('Add Lesson Plan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Card(
                color: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildField('Class Name', 'className', icon: Icons.class_),
                      _buildField('Subject', 'subject', icon: Icons.book),
                      _buildField('Topic', 'topic', icon: Icons.topic),
                      GestureDetector(
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: _lesson['date'],
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              _lesson['date'] = pickedDate;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Date:', style: TextStyle(fontWeight: FontWeight.bold)),
                              Row(
                                children: [
                                  Text(
                                    DateFormat('dd MMM yyyy').format(_lesson['date']),
                                    style: const TextStyle(color: Colors.blue),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.edit_calendar, color: Colors.blue),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _addCustomSection,
                icon: const Icon(Icons.add),
                label: const Text('Add Custom Section'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 16),
              ...(_lesson['customSections'] as List<Map<String, List<String>>>)
                  .asMap()
                  .entries
                  .map((entry) {
                final index = entry.key;
                final section = entry.value;
                final title = section.keys.first;
                final points = section[title]!;

                return Card(
                  color: Colors.white,
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black87)),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editCustomSection(index, title, points),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () => _confirmDeleteCustomSection(index),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ...points.map((e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text('• $e', style: const TextStyle(fontSize: 15)),
                        )),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _saveForm,
                icon: const Icon(Icons.check),
                label: const Text('Save Lesson Plan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteCustomSection(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Section'),
        content: const Text('Are you sure you want to delete this section?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                (_lesson['customSections'] as List).removeAt(index);
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EditLessonScreen extends StatefulWidget {
  final Map<String, dynamic> lessonData;
  final String? docId;

  const EditLessonScreen({super.key, required this.lessonData, this.docId});

  @override
  State<EditLessonScreen> createState() => _EditLessonScreenState();
}

class _EditLessonScreenState extends State<EditLessonScreen> {
  final _formKey = GlobalKey<FormState>();
  late String className;
  late String subject;
  late String topic;
  late DateTime date;
  late List<Map<String, List<String>>> customSections;

  @override
  void initState() {
    super.initState();
    className = widget.lessonData['className'] ?? '';
    subject = widget.lessonData['subject'] ?? '';
    topic = widget.lessonData['topic'] ?? '';
    date = DateTime.tryParse(widget.lessonData['date'] ?? '') ?? DateTime.now();
    customSections = (widget.lessonData['customSections'] as List)
        .map<Map<String, List<String>>>((section) {
      final key = section.keys.first.toString();
      final values = List<String>.from(section[section.keys.first]);
      return {key: values};
    }).toList();
  }

  void _addOrEditSection({int? index}) {
    String title = index != null ? customSections[index].keys.first : '';
    List<String> subpoints = index != null ? List.from(customSections[index][title]!) : [];

    final titleController = TextEditingController(text: title);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(index != null ? Icons.edit : Icons.add, color: Colors.blue),
            const SizedBox(width: 8),
            Text(index != null ? 'Edit Section' : 'Add Section'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
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
                      onChanged: (val) => title = val,
                    ),
                    const SizedBox(height: 10),
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: subpoints.length,
                      itemBuilder: (context, i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12), // Add gap between points
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
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => setModalState(() => subpoints.removeAt(i)),
                              )
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Point'),
                      onPressed: () => setModalState(() => subpoints.add('')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (title.isNotEmpty && subpoints.isNotEmpty) {
                setState(() {
                  if (index != null) {
                    customSections[index] = {title: subpoints};
                  } else {
                    customSections.add({title: subpoints});
                  }
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSection(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Section'),
        content: const Text('Are you sure you want to delete this section?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete, color: Colors.white, size: 18),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              setState(() => customSections.removeAt(index));
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _updateLesson() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        await FirebaseFirestore.instance.collection('lessons').doc(widget.docId).update({
          'className': className,
          'subject': subject,
          'topic': topic,
          'date': date.toIso8601String(),
          'customSections': customSections,
        });
        if (context.mounted) Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd MMM yyyy').format(date);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Edit Lesson'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField('Class', className, (val) => className = val!, icon: Icons.class_),
              const SizedBox(height: 12),
              _buildTextField('Subject', subject, (val) => subject = val!, icon: Icons.book),
              const SizedBox(height: 12),
              _buildTextField('Topic', topic, (val) => topic = val!, icon: Icons.topic),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.date_range, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text('Date:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Text(formattedDate),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => date = picked);
                    },
                    child: const Text('Change'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: const [
                  Icon(Icons.list_alt, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Custom Sections',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => _addOrEditSection(),
                icon: const Icon(Icons.add),
                label: const Text('Add Section'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 16),
              ...customSections.asMap().entries.map((entry) {
                final index = entry.key;
                final title = entry.value.keys.first;
                final points = entry.value[title]!;
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _addOrEditSection(index: index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDeleteSection(index),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ...points.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(fontSize: 18)),
                              Expanded(child: Text(e)),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _updateLesson,
                icon: const Icon(Icons.save),
                label: const Text('Update Lesson'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, String initial, FormFieldSetter<String> onSaved, {IconData? icon}) {
    return TextFormField(
      initialValue: initial,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: Colors.blue) : null,
        border: const OutlineInputBorder(),
      ),
      validator: (val) => val!.isEmpty ? 'Required' : null,
      onSaved: onSaved,
    );
  }
}
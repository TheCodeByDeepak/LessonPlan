import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'edit_lesson_screen.dart';
import 'add_lesson_screen.dart';
import 'share_lesson_pdf.dart';

class ViewLessonScreen extends StatelessWidget {
  final String docId;

  const ViewLessonScreen({super.key, required this.docId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Lesson Details'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export as PDF',
            onPressed: () async {
              final snapshot = await FirebaseFirestore.instance
                  .collection('lessons')
                  .doc(docId)
                  .get();

              if (snapshot.exists) {
                final lessonData = snapshot.data() as Map<String, dynamic>;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ShareLessonPdfScreen(lesson: lessonData),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lesson not found')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Lesson',
            onPressed: () async {
              final snapshot = await FirebaseFirestore.instance
                  .collection('lessons')
                  .doc(docId)
                  .get();

              if (snapshot.exists) {
                final lessonData = snapshot.data() as Map<String, dynamic>;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditLessonScreen(
                      lessonData: lessonData,
                      docId: docId,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lesson not found')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete Lesson',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('lessons').doc(docId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Lesson not found'));
          }

          final lessonData = snapshot.data!.data() as Map<String, dynamic>;
          final date = DateTime.tryParse(lessonData['date']) ?? DateTime.now();
          final formattedDate = DateFormat('dd MMM yyyy').format(date);
          final customSections = lessonData['customSections'] ?? [];

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Header Card
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                color: Colors.blue.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.class_, color: Colors.blue, size: 32),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              lessonData['className'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Chip(
                            label: Text(formattedDate),
                            backgroundColor: Colors.blue[200],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildRow('Subject', lessonData['subject']),
                      _buildRow('Topic', lessonData['topic']),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Sections
              Text(
                'Sections',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
              const Divider(thickness: 1.2),
              ...customSections.map<Widget>((section) {
                final title = section.keys.first;
                final points = List<String>.from(section[title]);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeIn,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          ...points
                              .map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(fontSize: 18)),
                                Expanded(child: Text(e)),
                              ],
                            ),
                          ))
                              .toList(),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 30),
              // Reuse Button
              ElevatedButton.icon(
                icon: const Icon(Icons.copy),
                label: const Text('Reuse to Add New'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                onPressed: () {
                  final reusedData = Map<String, dynamic>.from(lessonData);
                  reusedData['date'] = DateTime.now().toIso8601String();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddLessonScreen(initialData: reusedData),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lesson'),
        content: const Text('Are you sure you want to delete this lesson?'),
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
            ),
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance
                  .collection('lessons')
                  .doc(docId)
                  .delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Lesson deleted successfully')),
              );
            },
          ),
        ],
      ),
    );
  }
}
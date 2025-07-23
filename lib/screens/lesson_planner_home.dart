import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'add_lesson_screen.dart';
import 'view_lesson_screen.dart';

class LessonPlannerHome extends StatefulWidget {
  const LessonPlannerHome({super.key});

  @override
  State<LessonPlannerHome> createState() => _LessonPlannerHomeState();
}

class _LessonPlannerHomeState extends State<LessonPlannerHome> {
  String searchQuery = '';
  DateTime? selectedDate;
  final currentUser = FirebaseAuth.instance.currentUser;

  // For alternating hint text (with ValueNotifier)
  final ValueNotifier<String> _searchHintNotifier =
  ValueNotifier('Search by class name...');
  Timer? _hintTimer;
  bool _showClassHint = true;

  @override
  void initState() {
    super.initState();
    _hintTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _showClassHint = !_showClassHint;
      _searchHintNotifier.value = _showClassHint
          ? 'Search by class name'
          : 'Search by subject';
    });
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _searchHintNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // <-- This keeps FAB fixed
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(

            gradient: LinearGradient(
              colors: [Color(0xFF2196F3), Color(0xFF21CBF3)],

              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Lesson Planner',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _pickDateFilter,
            tooltip: "Filter by Date",
          ),
          if (selectedDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() => selectedDate = null),
              tooltip: "Clear Date Filter",
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') _showLogoutConfirmation();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [

            // Search Bar with animated hint
            ValueListenableBuilder<String>(
              valueListenable: _searchHintNotifier,
              builder: (context, hint, _) {
                return Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(12),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: hint,
                      prefixIcon: const Icon(Icons.search, color: Colors.blue),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () => setState(() => searchQuery = ''),
                      )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) => setState(() => searchQuery = val.toLowerCase()),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Lesson List
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 70),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('lessons')
                      .where('createdBy', isEqualTo: currentUser?.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return _buildEmptyState();
                    }
                    final filteredLessons = snapshot.data!.docs.where((doc) {
                      final className = (doc['className'] ?? '').toString().toLowerCase();
                      final subject = (doc['subject'] ?? '').toString().toLowerCase();
                      final lessonDate = DateTime.tryParse(doc['date'] ?? '') ?? DateTime.now();
                      final matchesSearch = className.contains(searchQuery) || subject.contains(searchQuery);
                      final matchesDate = selectedDate == null ||
                          (lessonDate.year == selectedDate!.year &&
                              lessonDate.month == selectedDate!.month &&
                              lessonDate.day == selectedDate!.day);
                      return matchesSearch && matchesDate;
                    }).toList();
                    if (filteredLessons.isEmpty) {
                      return _buildEmptyState();
                    }
                    return ListView.builder(
                      itemCount: filteredLessons.length,
                      itemBuilder: (context, index) {
                        final lesson = filteredLessons[index];
                        final className = lesson['className'] ?? 'N/A';
                        final subject = lesson['subject'] ?? 'N/A';
                        final topic = lesson['topic'] ?? 'N/A';
                        final date = DateTime.tryParse(lesson['date'] ?? '') ?? DateTime.now();
                        final formattedDate = DateFormat('dd MMM yyyy').format(date);

                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 150, maxWidth: 400),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeIn,
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(18),
                                  tileColor: Colors.blue.shade50,
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blue[200],
                                    child: Icon(Icons.class_, color: Colors.white),
                                  ),
                                  title: Text(
                                    '$className - $subject',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text('Topic: $topic'),
                                  ),
                                  trailing: Chip(
                                    label: Text(formattedDate),
                                    backgroundColor: Colors.blue[100],
                                    labelStyle: const TextStyle(fontSize: 12),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ViewLessonScreen(docId: lesson.id),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Lesson'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 6,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddLessonScreen()),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // Empty state widget
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book, size: 60, color: Colors.blue[200]),
          const SizedBox(height: 16),
          Text(
            'No lessons found.',
            style: TextStyle(fontSize: 18, color: Colors.blueGrey[700]),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the "+" button to add your first lesson!',
            style: TextStyle(fontSize: 14, color: Colors.blueGrey[400]),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateFilter() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
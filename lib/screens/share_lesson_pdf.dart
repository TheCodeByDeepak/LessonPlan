import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';

class ShareLessonPdfScreen extends StatefulWidget {
  final Map<String, dynamic> lesson;

  const ShareLessonPdfScreen({super.key, required this.lesson});

  @override
  State<ShareLessonPdfScreen> createState() => _ShareLessonPdfScreenState();
}

class _ShareLessonPdfScreenState extends State<ShareLessonPdfScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _shareGeneratedPdf();
    });
  }

  Future<void> _shareGeneratedPdf() async {
    try {
      final pdfData = await _generatePdf(PdfPageFormat.a4, widget.lesson);

      await Printing.sharePdf(
        bytes: pdfData,
        filename: 'Lesson_${widget.lesson['topic'] ?? 'Plan'}.pdf',
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share PDF: $e')),
        );
      }
    }
  }

  Future<Uint8List> _generatePdf(
      PdfPageFormat format, Map<String, dynamic> lesson) async {
    final pdf = pw.Document();

    final date = lesson['date'] ?? '';
    final formattedDate = date.toString().substring(0, 10);
    final customSections = lesson['customSections'] as List<dynamic>? ?? [];

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Lesson Plan',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 16),
              pw.Text('Class: ${lesson['className'] ?? ''}'),
              pw.Text('Subject: ${lesson['subject'] ?? ''}'),
              pw.Text('Topic: ${lesson['topic'] ?? ''}'),
              pw.Text('Date: $formattedDate'),
              pw.SizedBox(height: 16),
              pw.Text('Sections:',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              ...customSections.map((section) {
                final title = (section as Map<String, dynamic>).keys.first;
                final points = List<String>.from(section[title] ?? []);
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(title,
                        style: pw.TextStyle(
                            fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    ...points.map((point) => pw.Text('- $point')),
                    pw.SizedBox(height: 12),
                  ],
                );
              }),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

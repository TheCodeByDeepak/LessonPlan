// models/lesson_model.dart
class LessonModel {
  String className;
  String subject;
  String topic;
  DateTime date;
  List<Map<String, List<String>>> customSections;

  LessonModel({
    required this.className,
    required this.subject,
    required this.topic,
    required this.date,
    required this.customSections,
  });

  Map<String, dynamic> toMap() {
    return {
      'className': className,
      'subject': subject,
      'topic': topic,
      'date': date.toIso8601String(),
      'customSections': customSections,
    };
  }

  factory LessonModel.fromMap(Map<String, dynamic> map) {
    return LessonModel(
      className: map['className'],
      subject: map['subject'],
      topic: map['topic'],
      date: DateTime.parse(map['date']),
      customSections: List<Map<String, List<String>>>.from(
        (map['customSections'] as List).map(
              (section) => Map<String, List<String>>.from(
            (section as Map).map((k, v) => MapEntry(k as String, List<String>.from(v))),
          ),
        ),
      ),
    );
  }
}

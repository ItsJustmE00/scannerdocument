import 'dart:convert';

import 'package:scannerdocument/models/extracted_data.dart';

class ScannedDocument {
  const ScannedDocument({
    required this.id,
    required this.title,
    required this.imagePaths,
    required this.ocrText,
    required this.extractedData,
    required this.createdAt,
  });

  final String id;
  final String title;
  final List<String> imagePaths;
  final String ocrText;
  final ExtractedData extractedData;
  final DateTime createdAt;

  ScannedDocument copyWith({
    String? id,
    String? title,
    List<String>? imagePaths,
    String? ocrText,
    ExtractedData? extractedData,
    DateTime? createdAt,
  }) {
    return ScannedDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      imagePaths: imagePaths ?? this.imagePaths,
      ocrText: ocrText ?? this.ocrText,
      extractedData: extractedData ?? this.extractedData,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'title': title,
      'image_paths': jsonEncode(imagePaths),
      'ocr_text': ocrText,
      'extracted_json': jsonEncode(extractedData.toMap()),
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory ScannedDocument.fromDbMap(Map<String, dynamic> map) {
    final imagePathsRaw = map['image_paths'] as String? ?? '[]';
    final extractedRaw = map['extracted_json'] as String? ?? '{}';

    return ScannedDocument(
      id: map['id'] as String,
      title: map['title'] as String? ?? 'Document sans titre',
      imagePaths:
          (jsonDecode(imagePathsRaw) as List<dynamic>).map((e) => '$e').toList(),
      ocrText: map['ocr_text'] as String? ?? '',
      extractedData: ExtractedData.fromMap(
        (jsonDecode(extractedRaw) as Map<String, dynamic>),
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['created_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}

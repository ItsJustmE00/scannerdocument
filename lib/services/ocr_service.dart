import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:scannerdocument/utils/ocr_post_processor.dart';

class OcrService {
  static const List<TextRecognitionScript> _supportedScripts = [
    TextRecognitionScript.latin,
    TextRecognitionScript.chinese,
    TextRecognitionScript.devanagiri,
    TextRecognitionScript.japanese,
    TextRecognitionScript.korean,
  ];

  final Map<TextRecognitionScript, TextRecognizer> _textRecognizers = {
    for (final script in _supportedScripts)
      script: TextRecognizer(script: script),
  };

  Future<String> extractTextFromImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final candidates = <_ScriptCandidate>[];

    for (final recognizer in _textRecognizers.values) {
      try {
        final recognizedText = await recognizer.processImage(inputImage);
        final rawText = recognizedText.text.trim();

        if (rawText.isEmpty) {
          continue;
        }

        candidates.add(
          _ScriptCandidate(
            text: rawText,
            score: _scoreCandidate(recognizedText, rawText),
          ),
        );
      } catch (_) {
        // Some script modules can be unavailable on specific devices.
      }
    }

    if (candidates.isEmpty) {
      return '';
    }

    candidates.sort((a, b) => b.score.compareTo(a.score));
    return _mergeTopCandidates(candidates);
  }

  Future<String> extractTextFromImages(List<String> imagePaths) async {
    return extractTextFromImagesWithProgress(imagePaths);
  }

  Future<String> extractTextFromImagesWithProgress(
    List<String> imagePaths, {
    void Function(int current, int total)? onProgress,
  }) async {
    final buffer = StringBuffer();
    final total = imagePaths.length;
    var current = 0;

    for (final imagePath in imagePaths) {
      current += 1;
      onProgress?.call(current, total);
      final text = await extractTextFromImage(imagePath);
      if (text.trim().isNotEmpty) {
        if (buffer.isNotEmpty) {
          buffer.writeln('\n---\n');
        }
        buffer.write(text.trim());
      }
    }

    return OcrPostProcessor.normalize(buffer.toString());
  }

  void dispose() {
    for (final recognizer in _textRecognizers.values) {
      recognizer.close();
    }
  }

  double _scoreCandidate(RecognizedText recognizedText, String text) {
    final nonWhitespaceLength = text.replaceAll(RegExp(r'\s+'), '').length;
    final avgConfidence = _averageLineConfidence(recognizedText);
    final languageCount = _recognizedLanguages(recognizedText).length;

    return nonWhitespaceLength + (avgConfidence * 100) + (languageCount * 12);
  }

  double _averageLineConfidence(RecognizedText recognizedText) {
    var sum = 0.0;
    var count = 0;

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final confidence = line.confidence;
        if (confidence == null) {
          continue;
        }
        sum += confidence;
        count += 1;
      }
    }

    if (count == 0) {
      return 0;
    }

    return sum / count;
  }

  Set<String> _recognizedLanguages(RecognizedText recognizedText) {
    final languages = <String>{};
    for (final block in recognizedText.blocks) {
      languages.addAll(block.recognizedLanguages);
      for (final line in block.lines) {
        languages.addAll(line.recognizedLanguages);
      }
    }
    return languages;
  }

  String _mergeTopCandidates(List<_ScriptCandidate> candidates) {
    final best = candidates.first;
    final selected = <_ScriptCandidate>[best];

    for (final candidate in candidates.skip(1)) {
      final isCloseScore = candidate.score >= best.score * 0.72;
      final hasSubstantialText = candidate.text.length >= 24;

      if (isCloseScore && hasSubstantialText) {
        selected.add(candidate);
      }
    }

    final seen = <String>{};
    final mergedLines = <String>[];

    for (final candidate in selected) {
      for (final line in candidate.text.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) {
          continue;
        }

        final normalized = trimmed.toLowerCase().replaceAll(
          RegExp(r'\s+'),
          ' ',
        );
        if (seen.add(normalized)) {
          mergedLines.add(trimmed);
        }
      }
    }

    return mergedLines.join('\n').trim();
  }
}

class _ScriptCandidate {
  const _ScriptCandidate({required this.text, required this.score});

  final String text;
  final double score;
}

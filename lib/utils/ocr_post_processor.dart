class OcrPostProcessor {
  static String normalize(String input) {
    if (input.trim().isEmpty) {
      return '';
    }

    var text = input.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    text = _normalizeArabicDigits(text);

    text = text
        .replaceAll('٫', '.')
        .replaceAll('٬', '')
        .replaceAll('،', ',')
        .replaceAll('؛', ';')
        .replaceAll('ـ', '')
        .replaceAll('ﻻ', 'لا')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ٱ', 'ا');

    // Normalize common Moroccan currency forms to MAD for extraction.
    text = text
        .replaceAll(RegExp(r'د\s*\.\s*م'), ' MAD ')
        .replaceAll(RegExp(r'درهم', caseSensitive: false), ' MAD ')
        .replaceAll(RegExp(r'دراهم', caseSensitive: false), ' MAD ')
        .replaceAll(RegExp(r'\bdhs?\b', caseSensitive: false), ' MAD ');

    // Fix common text-recognition confusions when the character is between digits.
    text = text
        .replaceAllMapped(RegExp(r'(?<=\d)[oO](?=\d)'), (_) => '0')
        .replaceAllMapped(RegExp(r'(?<=\d)[iIl](?=\d)'), (_) => '1')
        .replaceAllMapped(RegExp(r'(?<=\d)[sS](?=\d)'), (_) => '5')
        .replaceAllMapped(RegExp(r'(?<=\d)[bB](?=\d)'), (_) => '8');

    // Normalize spacing but keep line structure for readability.
    text = text
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((line) => line.isNotEmpty)
        .join('\n');

    return text;
  }

  static String _normalizeArabicDigits(String input) {
    const easternArabic = '٠١٢٣٤٥٦٧٨٩';
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    const western = '0123456789';

    var output = input;

    for (var i = 0; i < 10; i++) {
      output = output.replaceAll(easternArabic[i], western[i]);
      output = output.replaceAll(persian[i], western[i]);
    }

    return output;
  }
}

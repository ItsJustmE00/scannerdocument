import 'package:scannerdocument/models/extracted_data.dart';
import 'package:scannerdocument/utils/document_classifier.dart';
import 'package:scannerdocument/utils/document_domain_classifier.dart';
import 'package:scannerdocument/utils/ocr_post_processor.dart';

class DataExtractor {
  static ExtractedData extract(String source) {
    final normalized = OcrPostProcessor.normalize(source).replaceAll('\n', ' ');

    final invoiceMatch = RegExp(
      r'(?:facture|invoice|ref(?:erence)?|numero|no|n[°o]|رقم الفاتورة|فاتورة|رقم)[\s:._#-]*([A-Z0-9-]{3,})',
      caseSensitive: false,
      unicode: true,
    ).firstMatch(normalized);

    final dateMatch = RegExp(
      r'(\d{1,2}[\/.\-]\d{1,2}[\/.\-]\d{2,4}|\d{4}[\/.\-]\d{1,2}[\/.\-]\d{1,2})',
      unicode: true,
    ).firstMatch(normalized);

    const numberPattern = r'\d+(?:[ .]\d{3})*(?:[.,]\d{2})?';
    const currencyPattern = r'(?:MAD|EUR|USD|DH|€|\$|SAR|ريال)';

    final amountMatch = RegExp(
      '($numberPattern)\\s?($currencyPattern)',
      caseSensitive: false,
      unicode: true,
    ).firstMatch(normalized);

    final reverseAmountMatch = amountMatch == null
        ? RegExp(
            '($currencyPattern)\\s?($numberPattern)',
            caseSensitive: false,
            unicode: true,
          ).firstMatch(normalized)
        : null;

    final emailMatch = RegExp(
      r'\b[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\b',
    ).firstMatch(normalized);

    final phoneMatch = RegExp(r'(?:\+?\d[\d\s().-]{7,}\d)', unicode: true)
        .allMatches(normalized)
        .cast<Match?>()
        .map((match) => match)
        .firstWhere((match) {
          if (match == null) {
            return false;
          }
          final candidate = match.group(0) ?? '';
          final digits = candidate.replaceAll(RegExp(r'\D'), '');
          return digits.length >= 8 && digits.length <= 15;
        }, orElse: () => null);

    final amountRaw = amountMatch?.group(1) ?? reverseAmountMatch?.group(2);
    final amount = amountRaw?.replaceAll(' ', '').replaceAll(',', '.');

    final currencyRaw = amountMatch?.group(2) ?? reverseAmountMatch?.group(1);
    final currency = _normalizeCurrency(currencyRaw);

    final invoiceNumber = invoiceMatch?.group(1);

    final category = DocumentClassifier.classify(
      normalized,
      invoiceNumber: invoiceNumber,
      amount: amount,
    );

    final domain = DocumentDomainClassifier.classify(
      normalized,
      category: category,
    );

    return ExtractedData(
      invoiceNumber: invoiceNumber,
      date: dateMatch?.group(1),
      amount: amount,
      currency: currency,
      email: emailMatch?.group(0),
      phone: phoneMatch?.group(0),
      documentCategory: category,
      documentDomain: domain,
    );
  }

  static String? _normalizeCurrency(String? input) {
    if (input == null || input.trim().isEmpty) {
      return null;
    }

    final raw = input.trim().toUpperCase();

    if (raw == '€' || raw == 'EUR') {
      return 'EUR';
    }

    if (raw == r'$' || raw == 'USD') {
      return 'USD';
    }

    if (raw.contains('MAD') ||
        raw == 'DH' ||
        raw.contains('د') ||
        raw == 'DHS') {
      return 'MAD';
    }

    if (raw == 'SAR' || raw.contains('ريال')) {
      return 'SAR';
    }

    return raw;
  }
}

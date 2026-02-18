import 'package:scannerdocument/models/document_category.dart';

class DocumentClassifier {
  static DocumentCategory classify(
    String source, {
    String? invoiceNumber,
    String? amount,
  }) {
    final text = _normalizeForMatch(source);

    final scores = <DocumentCategory, int>{
      DocumentCategory.invoice: 0,
      DocumentCategory.receipt: 0,
      DocumentCategory.contract: 0,
      DocumentCategory.unknown: 0,
    };

    _scoreKeywords(scores, DocumentCategory.invoice, text, const [
      'facture',
      'invoice',
      'numero facture',
      'tva',
      'total ttc',
      'montant du',
      'bon de livraison',
      'فاتورة',
      'رقم الفاتورة',
      'ضريبة',
      'الاجمالي',
      'المبلغ',
    ]);

    _scoreKeywords(scores, DocumentCategory.receipt, text, const [
      'recu',
      'reçu',
      'ticket',
      'caisse',
      'paiement',
      'merci pour votre visite',
      'reglement',
      'إيصال',
      'وصل',
      'قبض',
      'دفع',
      'شكرا لزيارتكم',
    ]);

    _scoreKeywords(scores, DocumentCategory.contract, text, const [
      'contrat',
      'convention',
      'accord',
      'clause',
      'article',
      'signature',
      'entre les soussignes',
      'partie',
      'duration',
      'عقد',
      'اتفاقية',
      'الطرف الاول',
      'الطرف الثاني',
      'المادة',
      'بند',
      'توقيع',
    ]);

    if ((invoiceNumber ?? '').trim().isNotEmpty) {
      scores[DocumentCategory.invoice] =
          (scores[DocumentCategory.invoice] ?? 0) + 3;
    }

    if ((amount ?? '').trim().isNotEmpty) {
      scores[DocumentCategory.invoice] =
          (scores[DocumentCategory.invoice] ?? 0) + 1;
      scores[DocumentCategory.receipt] =
          (scores[DocumentCategory.receipt] ?? 0) + 1;
    }

    final winner = _maxScoreCategory(scores);
    final winnerScore = scores[winner] ?? 0;

    if (winnerScore < 2) {
      return DocumentCategory.unknown;
    }

    return winner;
  }

  static void _scoreKeywords(
    Map<DocumentCategory, int> scores,
    DocumentCategory category,
    String source,
    List<String> keywords,
  ) {
    var count = 0;
    for (final keyword in keywords) {
      if (source.contains(_normalizeForMatch(keyword))) {
        count += 2;
      }
    }
    scores[category] = (scores[category] ?? 0) + count;
  }

  static DocumentCategory _maxScoreCategory(Map<DocumentCategory, int> scores) {
    var bestCategory = DocumentCategory.unknown;
    var bestScore = -1;

    for (final entry in scores.entries) {
      if (entry.value > bestScore) {
        bestScore = entry.value;
        bestCategory = entry.key;
      }
    }

    return bestCategory;
  }

  static String _normalizeForMatch(String input) {
    final lowered = input.toLowerCase();
    final foldedLatin = lowered
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ô', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ç', 'c');

    final foldedArabic = foldedLatin
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ٱ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .replaceAll('ة', 'ه');

    final withoutDiacritics = foldedArabic.replaceAll(
      RegExp(r'[\u064B-\u065F\u0670]'),
      '',
    );

    return withoutDiacritics.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

import 'package:scannerdocument/models/document_category.dart';
import 'package:scannerdocument/models/document_domain.dart';

class DocumentDomainClassifier {
  static DocumentDomain classify(
    String source, {
    DocumentCategory category = DocumentCategory.unknown,
  }) {
    final text = _normalizeForMatch(source);

    final scores = <DocumentDomain, int>{
      DocumentDomain.electricity: 0,
      DocumentDomain.water: 0,
      DocumentDomain.gas: 0,
      DocumentDomain.internet: 0,
      DocumentDomain.telecom: 0,
      DocumentDomain.rent: 0,
      DocumentDomain.banking: 0,
      DocumentDomain.insurance: 0,
      DocumentDomain.government: 0,
      DocumentDomain.retail: 0,
      DocumentDomain.unknown: 0,
    };

    _scoreKeywords(scores, DocumentDomain.electricity, text, const [
      'electricite',
      'electricity',
      'electrique',
      'kwh',
      'compteur',
      'energie',
      'consommation electrique',
      'onee',
      'فاتورة الكهرباء',
      'كهرباء',
      'الطاقه',
      'عداد الكهرباء',
    ]);

    _scoreKeywords(scores, DocumentDomain.water, text, const [
      'eau',
      'water',
      'm3',
      'compteur eau',
      'assainissement',
      'eau potable',
      'فاتورة الماء',
      'ماء',
      'الماء',
      'المياه',
      'عداد الماء',
      'استهلاك الماء',
    ]);

    _scoreKeywords(scores, DocumentDomain.gas, text, const [
      'gaz',
      'butane',
      'propane',
      'gpl',
      'فاتورة الغاز',
      'غاز',
    ]);

    _scoreKeywords(scores, DocumentDomain.internet, text, const [
      'internet',
      'fibre',
      'adsl',
      'wifi',
      'routeur',
      'modem',
      'connexion',
      'انترنت',
      'الياف',
    ]);

    _scoreKeywords(scores, DocumentDomain.telecom, text, const [
      'telephone',
      'mobile',
      'appel',
      'sms',
      'forfait',
      'recharge',
      'maroc telecom',
      'orange',
      'inwi',
      'اتصالات',
      'هاتف',
      'مكالمات',
    ]);

    _scoreKeywords(scores, DocumentDomain.rent, text, const [
      'loyer',
      'bail',
      'location',
      'quittance',
      'lease',
      'ايجار',
      'كراء',
      'مكتري',
    ]);

    _scoreKeywords(scores, DocumentDomain.banking, text, const [
      'banque',
      'bank',
      'rib',
      'virement',
      'releve',
      'compte bancaire',
      'حساب بنكي',
      'تحويل',
      'كشف حساب',
    ]);

    _scoreKeywords(scores, DocumentDomain.insurance, text, const [
      'assurance',
      'prime',
      'sinistre',
      'police',
      'mutuelle',
      'تأمين',
      'تامين',
    ]);

    _scoreKeywords(scores, DocumentDomain.government, text, const [
      'impot',
      'taxe',
      'cnss',
      'douane',
      'redevance',
      'ضريبه',
      'رسوم',
      'جماعه',
    ]);

    _scoreKeywords(scores, DocumentDomain.retail, text, const [
      'magasin',
      'supermarche',
      'caisse',
      'produit',
      'quantite',
      'prix unitaire',
      'ticket',
      'متجر',
      'صندوق',
    ]);

    if (RegExp(r'\b\d+(?:[.,]\d+)?\s?kwh\b').hasMatch(text)) {
      scores[DocumentDomain.electricity] =
          (scores[DocumentDomain.electricity] ?? 0) + 5;
    }

    if (RegExp(r'\b\d+(?:[.,]\d+)?\s?m3\b').hasMatch(text)) {
      scores[DocumentDomain.water] = (scores[DocumentDomain.water] ?? 0) + 5;
    }

    if (category == DocumentCategory.contract &&
        text.contains('abonnement') &&
        text.contains('internet')) {
      scores[DocumentDomain.internet] =
          (scores[DocumentDomain.internet] ?? 0) + 3;
    }

    final winner = _maxScoreDomain(scores);
    final winnerScore = scores[winner] ?? 0;

    if (winnerScore < 2) {
      return DocumentDomain.unknown;
    }

    return winner;
  }

  static void _scoreKeywords(
    Map<DocumentDomain, int> scores,
    DocumentDomain domain,
    String source,
    List<String> keywords,
  ) {
    var count = 0;
    for (final keyword in keywords) {
      if (source.contains(_normalizeForMatch(keyword))) {
        count += 2;
      }
    }
    scores[domain] = (scores[domain] ?? 0) + count;
  }

  static DocumentDomain _maxScoreDomain(Map<DocumentDomain, int> scores) {
    var bestDomain = DocumentDomain.unknown;
    var bestScore = -1;

    for (final entry in scores.entries) {
      if (entry.value > bestScore) {
        bestScore = entry.value;
        bestDomain = entry.key;
      }
    }

    return bestDomain;
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

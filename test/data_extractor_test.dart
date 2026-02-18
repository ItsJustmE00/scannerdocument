import 'package:flutter_test/flutter_test.dart';
import 'package:scannerdocument/models/document_category.dart';
import 'package:scannerdocument/models/document_domain.dart';
import 'package:scannerdocument/utils/data_extractor.dart';
import 'package:scannerdocument/utils/ocr_post_processor.dart';

void main() {
  test('extracts basic fields from scanned text', () {
    const sample = '''
Facture INV-2026-001
Date: 17/02/2026
Total: 1200.50 MAD
Email: contact@example.com
Tel: +212 6 12 34 56 78
''';

    final extracted = DataExtractor.extract(sample);

    expect(extracted.invoiceNumber, 'INV-2026-001');
    expect(extracted.date, '17/02/2026');
    expect(extracted.amount, '1200.50');
    expect(extracted.currency?.toUpperCase(), 'MAD');
    expect(extracted.email, 'contact@example.com');
    expect(extracted.phone, isNotNull);
    expect(extracted.documentCategory, DocumentCategory.invoice);
  });

  test('distinguishes electricity invoice from water receipt', () {
    const electricity = '''
Facture ONEE Electricite
Consommation: 245 kWh
Montant: 350.20 MAD
''';

    const water = '''
Recu Eau Potable
Consommation: 18 m3
Total: 120.00 MAD
''';

    final e = DataExtractor.extract(electricity);
    final w = DataExtractor.extract(water);

    expect(e.documentCategory, DocumentCategory.invoice);
    expect(e.documentDomain, DocumentDomain.electricity);

    expect(w.documentCategory, DocumentCategory.receipt);
    expect(w.documentDomain, DocumentDomain.water);
  });

  test('classifies contract internet domain', () {
    const sample = '''
Contrat d'abonnement fibre internet
Article 1: service ADSL / Fibre
Signature
''';

    final extracted = DataExtractor.extract(sample);

    expect(extracted.documentCategory, DocumentCategory.contract);
    expect(extracted.documentDomain, DocumentDomain.internet);
  });

  test('normalizes arabic digits and currency before extraction', () {
    const sample = 'المبلغ ١٢٣٤٫٥٠ د.م\nإيصال دفع ماء';

    final normalized = OcrPostProcessor.normalize(sample);
    final extracted = DataExtractor.extract(normalized);

    expect(normalized.contains('1234.50'), isTrue);
    expect(extracted.amount, '1234.50');
    expect(extracted.currency, 'MAD');
    expect(extracted.documentCategory, DocumentCategory.receipt);
    expect(extracted.documentDomain, DocumentDomain.water);
  });
}

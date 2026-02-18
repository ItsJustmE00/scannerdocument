import 'package:scannerdocument/models/document_category.dart';
import 'package:scannerdocument/models/document_domain.dart';

class ExtractedData {
  const ExtractedData({
    this.invoiceNumber,
    this.date,
    this.amount,
    this.currency,
    this.email,
    this.phone,
    this.documentCategory = DocumentCategory.unknown,
    this.documentDomain = DocumentDomain.unknown,
  });

  final String? invoiceNumber;
  final String? date;
  final String? amount;
  final String? currency;
  final String? email;
  final String? phone;
  final DocumentCategory documentCategory;
  final DocumentDomain documentDomain;

  bool get isEmpty =>
      invoiceNumber == null &&
      date == null &&
      amount == null &&
      currency == null &&
      email == null &&
      phone == null;

  Map<String, dynamic> toMap() {
    return {
      'invoiceNumber': invoiceNumber,
      'date': date,
      'amount': amount,
      'currency': currency,
      'email': email,
      'phone': phone,
      'documentCategory': documentCategory.key,
      'documentDomain': documentDomain.key,
    };
  }

  factory ExtractedData.fromMap(Map<String, dynamic> map) {
    return ExtractedData(
      invoiceNumber: map['invoiceNumber'] as String?,
      date: map['date'] as String?,
      amount: map['amount'] as String?,
      currency: map['currency'] as String?,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      documentCategory: DocumentCategory.fromKey(
        map['documentCategory'] as String?,
      ),
      documentDomain: DocumentDomain.fromKey(map['documentDomain'] as String?),
    );
  }

  List<MapEntry<String, String>> toDisplayEntries() {
    final entries = <MapEntry<String, String>>[
      MapEntry('Type', documentCategory.label),
      MapEntry('Domaine', documentDomain.label),
    ];

    void addIfPresent(String label, String? value) {
      if (value != null && value.trim().isNotEmpty) {
        entries.add(MapEntry(label, value.trim()));
      }
    }

    addIfPresent('Numero facture', invoiceNumber);
    addIfPresent('Date', date);
    addIfPresent('Montant', amount);
    addIfPresent('Devise', currency);
    addIfPresent('Email', email);
    addIfPresent('Telephone', phone);
    return entries;
  }
}

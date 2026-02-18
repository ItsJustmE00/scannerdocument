enum DocumentCategory {
  invoice('invoice', 'Facture'),
  receipt('receipt', 'Recu'),
  contract('contract', 'Contrat'),
  unknown('unknown', 'Autre');

  const DocumentCategory(this.key, this.label);

  final String key;
  final String label;

  static DocumentCategory fromKey(String? key) {
    switch (key) {
      case 'invoice':
        return DocumentCategory.invoice;
      case 'receipt':
        return DocumentCategory.receipt;
      case 'contract':
        return DocumentCategory.contract;
      default:
        return DocumentCategory.unknown;
    }
  }
}

enum DocumentDomain {
  electricity('electricity', 'Electricite'),
  water('water', 'Eau'),
  gas('gas', 'Gaz'),
  internet('internet', 'Internet'),
  telecom('telecom', 'Telecom'),
  rent('rent', 'Loyer'),
  banking('banking', 'Banque'),
  insurance('insurance', 'Assurance'),
  government('government', 'Administration'),
  retail('retail', 'Commerce'),
  unknown('unknown', 'General');

  const DocumentDomain(this.key, this.label);

  final String key;
  final String label;

  static DocumentDomain fromKey(String? key) {
    switch (key) {
      case 'electricity':
        return DocumentDomain.electricity;
      case 'water':
        return DocumentDomain.water;
      case 'gas':
        return DocumentDomain.gas;
      case 'internet':
        return DocumentDomain.internet;
      case 'telecom':
        return DocumentDomain.telecom;
      case 'rent':
        return DocumentDomain.rent;
      case 'banking':
        return DocumentDomain.banking;
      case 'insurance':
        return DocumentDomain.insurance;
      case 'government':
        return DocumentDomain.government;
      case 'retail':
        return DocumentDomain.retail;
      default:
        return DocumentDomain.unknown;
    }
  }
}

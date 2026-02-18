import 'package:cunning_document_scanner/cunning_document_scanner.dart';

class DocumentScannerService {
  Future<List<String>> scanDocuments({
    int maxPages = 8,
    bool allowGalleryImport = true,
  }) async {
    final files = await CunningDocumentScanner.getPictures(
      noOfPages: maxPages,
      isGalleryImportAllowed: allowGalleryImport,
    );

    return files ?? <String>[];
  }
}

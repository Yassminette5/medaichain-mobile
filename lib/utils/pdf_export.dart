import 'dart:typed_data';

import 'pdf_export_stub.dart'
    if (dart.library.html) 'pdf_export_web.dart'
    if (dart.library.io) 'pdf_export_io.dart'
    as impl;

Future<void> savePdf(Uint8List bytes, {required String filename}) {
  return impl.savePdfImpl(bytes, filename: filename);
}

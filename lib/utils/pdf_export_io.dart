import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<void> savePdfImpl(Uint8List bytes, {required String filename}) async {
  final path = await FilePicker.platform.saveFile(
    dialogTitle: 'Enregistrer le rapport PDF',
    fileName: filename,
    type: FileType.custom,
    allowedExtensions: const ['pdf'],
  );

  if (path == null || path.trim().isEmpty) {
    throw StateError('Save cancelled');
  }

  final file = File(path);
  await file.writeAsBytes(bytes, flush: true);
}

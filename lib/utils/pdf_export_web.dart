import 'dart:html' as html;
import 'dart:typed_data';

Future<void> savePdfImpl(Uint8List bytes, {required String filename}) async {
  final blob = html.Blob(<dynamic>[bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);

  final anchor = html.AnchorElement(href: url)
    ..style.display = 'none'
    ..download = filename;

  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();

  html.Url.revokeObjectUrl(url);
}

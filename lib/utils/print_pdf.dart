import 'dart:typed_data';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class PrintPDF {
  static Future<void> saveAndOpenPDF(Uint8List bytes) async {
    Directory? downloadsDir;

    downloadsDir = Directory("/storage/emulated/0/Download");

    if (!downloadsDir.existsSync()) {
      downloadsDir = await getTemporaryDirectory();
    }

    final filename =
        "struk_${DateTime.now().toIso8601String().replaceAll(':', '-')}.pdf";

    final file = File("${downloadsDir.path}/$filename");

    await file.writeAsBytes(bytes);

    await OpenFile.open(file.path);
  }
}

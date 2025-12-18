import 'dart:typed_data';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class PrintPDF {
  static Future<void> saveAndOpenPDF(Uint8List bytes) async {
    // Folder Download (khusus Android)
    Directory? downloadsDir;

    // 1. Coba ambil folder Download Android
    downloadsDir = Directory("/storage/emulated/0/Download");

    // Jika folder tidak ada, fallback ke temporary
    if (!downloadsDir.existsSync()) {
      downloadsDir = await getTemporaryDirectory();
    }

    // 2. Nama file otomatis
    final filename =
        "struk_${DateTime.now().toIso8601String().replaceAll(':', '-')}.pdf";

    // 3. Path file lengkap
    final file = File("${downloadsDir.path}/$filename");

    // 4. Simpan PDF
    await file.writeAsBytes(bytes);

    // 5. Buka file
    await OpenFile.open(file.path);
  }
}

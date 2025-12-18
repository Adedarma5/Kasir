import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class PrintStruk {
  static Future<Uint8List> generateStruk(
    Map<String, dynamic> order, {
    Uint8List? logo,
  }) async {
    final pdf = pw.Document();

    final rawItems = (order['items'] as List<dynamic>? ?? []);
    final Map<String, Map<String, dynamic>> merged = {};

    for (var it in rawItems) {
      final nama = it['produk']['nama'];
      final jumlah = int.tryParse(it['jumlah'].toString()) ?? 0;
      final subtotal = double.tryParse(it['subtotal'].toString()) ?? 0;
      final hargaSatuan = subtotal / jumlah;

      if (merged.containsKey(nama)) {
        merged[nama]!['jumlah'] += jumlah;
        merged[nama]!['subtotal'] += subtotal;
      } else {
        merged[nama] = {
          'nama': nama,
          'jumlah': jumlah,
          'subtotal': subtotal,
          'harga': hargaSatuan,
        };
      }
    }

    final items = merged.values.toList();

    final tgl = DateTime.now();
    final formatTgl =
        "${tgl.day}/${tgl.month}/${tgl.year} ${tgl.hour}:${tgl.minute.toString().padLeft(2, '0')}";

    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (logo != null)
                pw.Center(child: pw.Image(pw.MemoryImage(logo), width: 70)),

              pw.SizedBox(height: 6),

              pw.Center(
                child: pw.Text(
                  "POKO",
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),

              pw.Center(
                child: pw.Text(
                  "Struk Pembayaran",
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),

              pw.SizedBox(height: 10),

              pw.Text("Nama Pelanggan : ${order['nama_pelanggan']}"),
              pw.Text("Tanggal        : $formatTgl"),

              pw.SizedBox(height: 8),

              pw.Center(child: pw.Text("------------------------------")),

              pw.Center(
                child: pw.Text(
                  "DETAIL PESANAN",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),

              pw.Center(child: pw.Text("------------------------------")),

              pw.SizedBox(height: 4),

              ...items.map((it) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text("${it['nama']} x${it['jumlah']}"),
                        pw.Text("Rp ${it['subtotal'].toInt()}"),
                      ],
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 4),
                      child: pw.Text(
                        "  @ Rp ${it['harga'].toInt()}",
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.SizedBox(height: 6),
                  ],
                );
              }),

              pw.Center(child: pw.Text("------------------------------")),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "TOTAL",
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    "Rp ${order['total_harga']}",
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),

              pw.Center(child: pw.Text("------------------------------")),

              pw.SizedBox(height: 12),

              pw.Center(
                child: pw.Text(
                  "Terima kasih!",
                  style: pw.TextStyle(fontSize: 10),
                ),
              ),

              pw.Center(
                child: pw.Text(
                  "- Ngopi Di Rooftop",
                  style: pw.TextStyle(fontSize: 10),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}

import 'package:flutter/material.dart';
import '../../services/order_service.dart';
import 'riwayat_pesanan_screen.dart';
import 'tambah_item_pesanan_screen.dart';
import '../../utils/print_struk.dart';
import '../../utils/print_pdf.dart';

class DaftarPesananScreen extends StatefulWidget {
  const DaftarPesananScreen({super.key});

  @override
  State<DaftarPesananScreen> createState() => _DaftarPesananScreenState();
}

class _DaftarPesananScreenState extends State<DaftarPesananScreen> {
  late Future<List<dynamic>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    setState(() {
      _ordersFuture = OrderService.getOrders(status: 'pending');
    });
  }

  String _formatRupiah(dynamic value) {
    if (value == null) return 'Rp 0';

    final s = value.toString().split('.')[0]; 
    return 'Rp ${s.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    )}';
  }

  Future<void> _showPrintDialog(
    BuildContext ctx,
    Map<String, dynamic> order,
  ) async {
    await showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.print_rounded, size: 40, color: Colors.blue),
                const SizedBox(height: 10),
                const Text(
                  "Print Struk Pembayaran",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 10),
                _buildPrintPreview(order),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Batal"),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _printStruk(order);
                      },
                      icon: const Icon(Icons.print_rounded),
                      label: const Text("Cetak"),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

 Widget _buildPrintPreview(Map<String, dynamic> order) {
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

  return Container(
    width: double.infinity,
    height: 200, 
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(10),
    ),
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Nama Pelanggan: ${order['nama_pelanggan'] ?? '-'}"),
          const Divider(),
          const Text("Detail Pesanan:",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),

          ...items.map(
            (it) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("- ${it['nama']} x${it['jumlah']}"),
                  Text(
                    "  @ ${_formatRupiah(it['harga'])} → ${_formatRupiah(it['subtotal'])}",
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          const Divider(),
          Text("Total Bayar: ${_formatRupiah(order['total_harga'])}",
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    ),
  );
}


  List<Widget> _buildItemsPreview(dynamic items) {
    if (items == null) return [const Text('-')];

    return (items as List<dynamic>)
        .map(
          (it) => Text(
            "- ${it['produk']['nama']} x${it['jumlah']} "
            "(${_formatRupiah(it['subtotal'])})",
          ),
        )
        .toList();
  }

  Future<void> _printStruk(Map<String, dynamic> order) async {
    try {
      final pdfBytes = await PrintStruk.generateStruk(order);
      await PrintPDF.saveAndOpenPDF(pdfBytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Struk berhasil dibuat!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal membuat struk: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _bayarPesanan(
    Map<String, dynamic> order,
    String namaPelanggan,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Row(
          children: const [
            Icon(Icons.payment_rounded, color: Colors.orange),
            SizedBox(width: 6),
            Text('Konfirmasi Pembayaran'),
          ],
        ),
        content: Text('Proses pembayaran untuk pesanan $namaPelanggan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Ya, Bayar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final result = await OrderService.updateOrder(
        order['id'],
        status: 'selesai',
      );

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pesanan berhasil dibayar!'),
            backgroundColor: Colors.green,
          ),
        );

        await _showPrintDialog(context, Map<String, dynamic>.from(order));
        _loadOrders();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal update order'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildHeader(bool isTablet) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.pending_actions_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pesanan Pending',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Menunggu pembayaran',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, bool isTablet) {
    final rawItems = (order['items'] as List<dynamic>? ?? []).cast<dynamic>();

    final Map<String, Map<String, dynamic>> merged = {};
    for (var it in rawItems) {
      final nama = it['produk']['nama'];
      final jumlah = int.tryParse(it['jumlah'].toString()) ?? 0;
      final subtotal = double.tryParse(it['subtotal'].toString()) ?? 0;

      if (merged.containsKey(nama)) {
        merged[nama]!['jumlah'] += jumlah;
        merged[nama]!['subtotal'] += subtotal;
      } else {
        merged[nama] = {
          'nama': nama,
          'jumlah': jumlah,
          'subtotal': subtotal,
        };
      }
    }

    final mergedItems = merged.values.toList();
    final totalItems =
        mergedItems.fold<int>(0, (sum, it) => sum + (it['jumlah'] as int));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.07),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        collapsedShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient:
                LinearGradient(colors: [Colors.blue.shade300, Colors.blue.shade600]),
          ),
          child: const Icon(Icons.receipt_long_rounded,
              color: Colors.white, size: 24),
        ),
        title: Text(
          order['nama_pelanggan'] ?? 'Pelanggan',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          "$totalItems item • ${_formatRupiah(order['total_harga'])}",
        ),

        children: [
          const SizedBox(height: 6),

          ...mergedItems.map(
            (it) => ListTile(
              dense: true,
              visualDensity: const VisualDensity(vertical: -3),
              contentPadding: EdgeInsets.zero,
              title: Text(it['nama']),
              subtitle: Text("x${it['jumlah']}"),
              trailing: Text(
                _formatRupiah(it['subtotal']),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final changed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TambahItemScreen(order: order),
                      ),
                    );
                    if (changed == true && mounted) _loadOrders();
                  },
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: const Text("Tambah Item"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _bayarPesanan(
                    order,
                    order['nama_pelanggan'] ?? '',
                  ),
                  icon:
                      const Icon(Icons.payment_rounded, size: 18, color: Colors.white),
                  label: const Text(
                    "Bayar",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue.shade800,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.receipt_long_rounded, color: Colors.blue),
            SizedBox(width: 6),
            Text('Daftar Pesanan'),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: Icon(Icons.history_rounded, color: Colors.orange.shade700),
              tooltip: 'Riwayat Pesanan',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RiwayatPesananScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(isTablet),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _ordersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());

                if (snapshot.hasError)
                  return Center(child: Text("Error: ${snapshot.error}"));

                final data = snapshot.data ?? [];
                if (data.isEmpty) {
                  return const Center(child: Text("Belum ada pesanan pending"));
                }

                return RefreshIndicator(
                  onRefresh: () async => _loadOrders(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: data.length,
                    itemBuilder: (_, i) {
                      final order = Map<String, dynamic>.from(data[i]);
                      return _buildOrderCard(order, isTablet);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

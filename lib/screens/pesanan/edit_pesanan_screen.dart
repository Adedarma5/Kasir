import 'package:flutter/material.dart';
import '../../services/order_service.dart';

class EditPesananScreen extends StatefulWidget {
  final dynamic order;

  const EditPesananScreen({super.key, required this.order});

  @override
  State<EditPesananScreen> createState() => _EditPesananScreenState();
}

class _EditPesananScreenState extends State<EditPesananScreen> {
  late List<dynamic> items;
  List<dynamic> produkList = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    items = List.from(widget.order['items']);
    loadProduk();
  }

  Future<void> loadProduk() async {
    produkList = await OrderService.getProduk();
    setState(() {});
  }

  void tambahProduk(dynamic produk) {
    setState(() {
      items.add({
        'produk': produk,
        'produk_id': produk['id'],
        'jumlah': 1,
        'subtotal': produk['harga'],
      });
    });
  }

  void updateJumlah(int index, int jumlah) {
    setState(() {
      items[index]['jumlah'] = jumlah;
      items[index]['subtotal'] =
          jumlah * (items[index]['produk']['harga'] as int);
    });
  }

  Future<void> simpanPerubahan() async {
    setState(() => isLoading = true);

    final finalItems = items.map((e) => {
          'produk_id': e['produk']['id'],
          'jumlah': e['jumlah'],
    }).toList();

    final result = await OrderService.updateItems(
      orderId: widget.order['id'],
      items: finalItems,
    );

    setState(() => isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Pesanan berhasil diperbarui"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Pesanan"),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                return Card(
                  child: ListTile(
                    title: Text(item['produk']['nama']),
                    subtitle: Text("Subtotal: ${item['subtotal']}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            if (item['jumlah'] > 1) {
                              updateJumlah(i, item['jumlah'] - 1);
                            }
                          },
                        ),
                        Text("${item['jumlah']}"),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            updateJumlah(i, item['jumlah'] + 1);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          ElevatedButton(
            onPressed: simpanPerubahan,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(double.infinity, 0),
            ),
            child: isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("Simpan Perubahan"),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/order_service.dart';

class TambahItemScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const TambahItemScreen({super.key, required this.order});

  @override
  State<TambahItemScreen> createState() => _TambahItemScreenState();
}

class _TambahItemScreenState extends State<TambahItemScreen> {
  List<dynamic> produkList = [];
  List<dynamic> filteredProduk = [];
  List<dynamic> addedItems = [];

  bool loading = true;
  String filterKategori = "Semua";

  final formatRupiah = NumberFormat("#,###", "id_ID");

  @override
  void initState() {
    super.initState();
    addedItems = List.from(widget.order['items'] ?? []);
    _loadProduk();
  }

  Future<void> _loadProduk() async {
    try {
      final result = await OrderService.getAllProduk();
      setState(() {
        produkList = result;
        filteredProduk = result;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  List<Map<String, dynamic>> _mergeAddedItems() {
    final Map<int, Map<String, dynamic>> mapData = {};

    for (var item in addedItems) {
      final int id =
          int.tryParse(item['produk']?['id']?.toString() ?? '') ?? 0;

      final int jumlahItem = int.tryParse(item['jumlah']?.toString() ?? '') ?? 0;

      if (mapData.containsKey(id)) {
        final existingJumlah =
            int.tryParse(mapData[id]!['jumlah']?.toString() ?? '') ?? 0;
        mapData[id]!['jumlah'] = existingJumlah + jumlahItem;
      } else {
        mapData[id] = {
          "produk": item['produk'],
          "jumlah": jumlahItem,
        };
      }
    }

    return mapData.values.toList();
  }

  void _applyFilter() {
    List<dynamic> temp = produkList;

    if (filterKategori.toLowerCase() != "semua") {
      temp = temp
          .where((p) =>
              (p['jenis'] ?? '').toString().toLowerCase() ==
              filterKategori.toLowerCase())
          .toList();
    }

    setState(() => filteredProduk = temp);
  }

  Future<void> _tambahItem(dynamic produk) async {
    int jumlah = 1;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                "Tambah Item",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    produk['nama']?.toString() ?? '-',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          if (jumlah > 1) setStateDialog(() => jumlah--);
                        },
                        icon:
                            const Icon(Icons.remove_circle_outline, size: 28),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          jumlah.toString(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setStateDialog(() => jumlah++),
                        icon: const Icon(Icons.add_circle_outline, size: 28),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);

                    try {
                      final int idProduk =
                          int.tryParse(produk['id']?.toString() ?? '') ?? 0;

                      final response = await OrderService.addItemToOrder(
                        widget.order['id'],
                        idProduk,
                        jumlah,
                      );

                      if (response['success']) {
                        setState(() {
                          addedItems.add({
                            "produk": produk,
                            "jumlah": jumlah,
                          });
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("${produk['nama']} ditambahkan"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(response['message'] ?? 'Error'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Error: $e"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text("Tambah"),
                ),
              ],
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tambah Item"),
        backgroundColor: Colors.blue,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "SIMPAN",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Text("Kategori: "),
                      const SizedBox(width: 10),
                      DropdownButton<String>(
                        value: filterKategori,
                        items: ["Semua", "Makanan", "Minuman", "Cemilan"]
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e),
                                ))
                            .toList(),
                        onChanged: (v) {
                          filterKategori = v ?? "Semua";
                          _applyFilter();
                        },
                      ),
                    ],
                  ),
                ),

                if (_mergeAddedItems().isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(top: 5),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Item Ditambahkan",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),

                        SizedBox(
                          height: 70,
                          child: SingleChildScrollView(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: _mergeAddedItems().map((item) {
                                final nama =
                                    item['produk']?['nama']?.toString() ?? '-';
                                final jumlah =
                                    int.tryParse(item['jumlah']?.toString() ?? '') ?? 0;
                                return Chip(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 0),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  labelPadding:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  backgroundColor: Colors.blue[100],
                                  label: Text(
                                    "$nama x$jumlah",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue[900],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Pilih Produk",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: filteredProduk.isEmpty
                      ? const Center(child: Text("Produk tidak ditemukan"))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          itemCount: filteredProduk.length,
                          itemBuilder: (_, i) {
                            final p = filteredProduk[i];
                            final harga =
                                int.tryParse(p['harga']?.toString() ?? '') ?? 0;

                            return Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                minLeadingWidth: 40,
                                leading: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.blue[100],
                                  child: const Icon(Icons.fastfood,
                                      size: 18, color: Colors.blue),
                                ),
                                title: Text(
                                  p['nama']?.toString() ?? '-',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  "Rp ${formatRupiah.format(harga)}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                trailing: const Icon(Icons.add,
                                    color: Colors.green),
                                onTap: () => _tambahItem(p),
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

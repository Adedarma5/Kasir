import 'package:flutter/material.dart';
import '../../services/order_service.dart';

class TambahPesananScreen extends StatefulWidget {
  const TambahPesananScreen({super.key});

  @override
  State<TambahPesananScreen> createState() => _TambahPesananScreenState();
}

class _TambahPesananScreenState extends State<TambahPesananScreen> {
  List<dynamic> _produkList = [];
  List<dynamic> _filteredProdukList = [];
  final List<Map<String, dynamic>> _keranjang = [];
  final _namaController = TextEditingController();
  bool _loading = true;

  String _selectedKategori = 'Semua';
  final List<String> _kategoriOptions = [
    'Semua',
    'Makanan',
    'Minuman',
    'Cemilan',
  ];

  @override
  void initState() {
    super.initState();
    _loadProduk();
  }

  Future<void> _loadProduk() async {
    try {
      final produk = await OrderService.getProduk();
      if (!mounted) return;
      setState(() {
        _produkList = produk;
        _applyFilter();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showSnackBar('Gagal memuat produk: $e', isError: true);
    }
  }

  void _applyFilter() {
    if (_selectedKategori == 'Semua') {
      _filteredProdukList = List.from(_produkList);
    } else {
      _filteredProdukList = _produkList
          .where((p) => p['jenis'] == _selectedKategori)
          .toList();
    }
  }

  void tambahKeKeranjang(Map<String, dynamic> produk) {
    final String id = produk['id'].toString();
    final index = _keranjang.indexWhere((item) => item['id'] == id);

    if (index != -1) {
      int jumlahLama =
          int.tryParse(_keranjang[index]['jumlah'].toString()) ?? 1;
      _keranjang[index]['jumlah'] = jumlahLama + 1;
    } else {
      _keranjang.add({
        'id': id,
        'nama': produk['nama'],
        'harga': double.tryParse(produk['harga'].toString()) ?? 0,
        'jumlah': 1,
      });
    }
    setState(() {});
  }

  double get _total => _keranjang.fold(0.0, (sum, item) {
    final double harga = double.tryParse(item['harga'].toString()) ?? 0.0;
    final int jumlah = int.tryParse(item['jumlah'].toString()) ?? 1;
    return sum + (harga * jumlah);
  });

  String _formatRupiah(dynamic value) {
    int angka = (double.tryParse(value.toString()) ?? 0).toInt();
    String hasil = angka.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return 'Rp $hasil';
  }

  Future<void> _simpanPesanan() async {
    if (_namaController.text.isEmpty || _keranjang.isEmpty) {
      _showSnackBar('Isi nama pelanggan dan pilih produk', isError: true);
      return;
    }

    try {
      final result = await OrderService.createOrder(
        namaPelanggan: _namaController.text,
        items: _keranjang,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _showSnackBar('✓ Pesanan berhasil disimpan!', isSuccess: true);
        setState(() {
          _keranjang.clear();
          _namaController.clear();
        });
      } else {
        _showSnackBar(result['message'] ?? 'Gagal menyimpan pesanan');
      }
    } catch (e) {
      _showSnackBar('Terjadi kesalahan: $e', isError: true);
    }
  }

  void _ubahJumlah(int index, bool tambah) {
    setState(() {
      if (tambah) {
        _keranjang[index]['jumlah']++;
      } else {
        if (_keranjang[index]['jumlah'] > 1) {
          _keranjang[index]['jumlah']--;
        } else {
          _keranjang.removeAt(index);
        }
      }
    });
  }

  void _showSnackBar(
    String message, {
    bool isSuccess = false,
    bool isError = false,
    int duration = 2000,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 12)),
        duration: Duration(milliseconds: duration),
        backgroundColor: isSuccess
            ? Colors.green
            : isError
            ? Colors.orange
            : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _loading
          ? _buildLoading()
          : (isTablet ? _buildTabletLayout() : _buildMobileLayout()),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.brown[800],
      title: Row(
        children: [
          Icon(Icons.add_shopping_cart, color: Colors.green[600], size: 18),
          const SizedBox(width: 6),
          const Text('Tambah Pesanan', style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildLoading() => const Center(
    child: SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
  );

  Widget _buildTabletLayout() => Row(
    children: [
      Expanded(
        flex: 3,
        child: Column(
          children: [
            _buildCustomerForm(),
            _buildFilterDropdown(),
            const SizedBox(height: 6),
            Expanded(child: _buildFilteredProductList()),
          ],
        ),
      ),
      Expanded(
        flex: 2,
        child: Container(color: Colors.white, child: _buildCartSection()),
      ),
    ],
  );

  Widget _buildMobileLayout() => Column(
    children: [
      _buildCustomerForm(),
      _buildFilterDropdown(),
      const SizedBox(height: 6),
      Expanded(child: _buildFilteredProductList()),
      _buildCartSection(),
    ],
  );

  Widget _buildCustomerForm() => Container(
    margin: const EdgeInsets.all(4),
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: Colors.grey[200]!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(3),
              ),
              child: Icon(
                Icons.person_outline,
                color: Colors.blue[700],
                size: 12,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              'Informasi Pelanggan',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Container(
          margin: const EdgeInsets.only(top: 6),
          child: SizedBox(
            width: 250, // lebar form
            height: 35, // tinggi form
            child: TextField(
              controller: _namaController,
              style: const TextStyle(fontSize: 8),
              decoration: InputDecoration(
                isDense: true, // membuat field lebih padat
                labelText: 'Nama Pelanggan',
                labelStyle: const TextStyle(fontSize: 10),
                hintText: 'Masukkan nama',
                hintStyle: const TextStyle(fontSize: 10),
                prefixIcon: const Icon(Icons.badge_outlined, size: 12),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(6),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 3,
                  vertical: 2,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildFilterDropdown() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButton<String>(
        value: _selectedKategori,
        items: _kategoriOptions
            .map(
              (k) => DropdownMenuItem<String>(
                value: k,
                child: Text(k, style: const TextStyle(fontSize: 12)),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value == null) return;
          setState(() {
            _selectedKategori = value;
            _applyFilter();
          });
        },
        isExpanded: true,
        underline: const SizedBox(),
      ),
    );
  }

  Widget _buildFilteredProductList() {
    final makanan = _filteredProdukList
        .where((p) => p['jenis'] == 'Makanan')
        .toList();
    final minuman = _filteredProdukList
        .where((p) => p['jenis'] == 'Minuman')
        .toList();
    final cemilan = _filteredProdukList
        .where((p) => p['jenis'] == 'Cemilan')
        .toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: [
        if (makanan.isNotEmpty) _buildJenisSection('Makanan', makanan),
        if (minuman.isNotEmpty) _buildJenisSection('Minuman', minuman),
        if (cemilan.isNotEmpty) _buildJenisSection('Cemilan', cemilan),
        if (_filteredProdukList.isEmpty)
          _buildEmptyState(
            icon: Icons.inventory_2_outlined,
            text: 'Belum ada produk',
          ),
      ],
    );
  }

  Widget _buildJenisSection(String jenis, List<dynamic> produk) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        Text(
          jenis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const SizedBox(height: 4),
        ...produk.map((p) => _buildProductItem(p)).toList(),
      ],
    );
  }

  Widget _buildProductItem(dynamic produk) {
    final isInCart = _keranjang.any(
      (item) => item['id'] == produk['id'].toString(),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isInCart ? Colors.green : Colors.grey[300]!,
          width: isInCart ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        leading: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.brown[300]!, Colors.brown[500]!],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.coffee, color: Colors.white, size: 16),
        ),
        title: Text(
          produk['nama'],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        subtitle: Text(
          _formatRupiah(produk['harga']),
          style: TextStyle(
            color: Colors.green[700],
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: ElevatedButton.icon(
          onPressed: () => tambahKeKeranjang(produk),
          icon: const Icon(Icons.add_shopping_cart, size: 12),
          label: const Text('Tambah', style: TextStyle(fontSize: 10)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                4,
              ), 
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCartSection() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCartHeader(),
          const SizedBox(height: 6),
          _buildCartList(),
          const SizedBox(height: 6),
          _buildTotalSection(),
          const SizedBox(height: 8),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildCartHeader() => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          Icons.shopping_basket_outlined,
          color: Colors.orange[700],
          size: 14,
        ),
      ),
      const SizedBox(width: 6),
      const Text(
        'Keranjang',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
      const Spacer(),
      if (_keranjang.isNotEmpty)
        TextButton.icon(
          onPressed: () => setState(() => _keranjang.clear()),
          icon: const Icon(Icons.delete_outline, size: 12),
          label: const Text('Hapus', style: TextStyle(fontSize: 10)),
          style: TextButton.styleFrom(foregroundColor: Colors.red[600]),
        ),
    ],
  );

  Widget _buildCartList() => Container(
    constraints: const BoxConstraints(maxHeight: 120),
    child: _keranjang.isEmpty
        ? _buildEmptyState(
            icon: Icons.shopping_cart_outlined,
            text: 'Keranjang kosong',
          )
        : ListView.builder(
            shrinkWrap: true,
            itemCount: _keranjang.length,
            itemBuilder: (context, index) => _buildCartItem(index),
          ),
  );

  Widget _buildCartItem(int index) {
    final item = _keranjang[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['nama'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatRupiah(item['harga'] * item['jumlah']),
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => _ubahJumlah(index, false),
                icon: const Icon(Icons.remove_circle_outline),
                color: Colors.orange[700],
                iconSize: 16,
                padding: EdgeInsets.zero,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '${item['jumlah']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _ubahJumlah(index, true),
                icon: const Icon(Icons.add_circle_outline),
                color: Colors.green[700],
                iconSize: 16,
                padding: EdgeInsets.zero,
              ),
              IconButton(
                onPressed: () => setState(() => _keranjang.removeAt(index)),
                icon: const Icon(Icons.delete_outline),
                color: Colors.red[600],
                iconSize: 16,
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSection() => Container(
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [Colors.brown[50]!, Colors.orange[50]!]),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Pembayaran',
              style: TextStyle(color: Colors.grey[600], fontSize: 10),
            ),
            const SizedBox(height: 2),
            Text(
              _formatRupiah(_total),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.brown[800],
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildSaveButton() => ElevatedButton.icon(
    onPressed: _simpanPesanan,
    icon: const Icon(Icons.check_circle_outline, size: 16),
    label: const Text(
      'Simpan Pesanan',
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.green[600],
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );

  Widget _buildEmptyState({required IconData icon, required String text}) =>
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: Colors.grey[400]),
            const SizedBox(height: 4),
            Text(text, style: TextStyle(color: Colors.grey[600], fontSize: 10)),
          ],
        ),
      );
}

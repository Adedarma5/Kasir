import 'produk_model.dart';

class OrderItem {
  Product produk;
  int jumlah;

  OrderItem({required this.produk, this.jumlah = 1});
}

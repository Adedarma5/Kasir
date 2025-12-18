import 'package:flutter/material.dart';
import '../models/produk_model.dart';

class CartItemTile extends StatelessWidget {
  final Product product;
  final int quantity;
  final VoidCallback onRemove;

  const CartItemTile({super.key, required this.product, required this.quantity, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Jumlah: $quantity'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Rp${(product.price * quantity).toStringAsFixed(0)}'),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onRemove,
            )
          ],
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OrderService {
  static const String baseUrl = 'https://;

 
  static Future<List<dynamic>> getProduk() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/produk'),
      headers: _headers(token),
    );
    return _handleListResponse(response, 'produk');
  }

  
  static Future<List<dynamic>> getOrders({
    required String status,
    String? date,
  }) async {
    final query = <String, String>{'status': status};
    if (date != null && date.isNotEmpty) query['date'] = date;

    final uri = Uri.parse('$baseUrl/orders').replace(queryParameters: query);
    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    return _handleListResponse(response, 'orders');
  }

  static Future<Map<String, dynamic>> createOrder({
    required String namaPelanggan,
    required List<Map<String, dynamic>> items,
  }) async {
    final token = await _getToken();
    final body = {
      'nama_pelanggan': namaPelanggan,
      'items': items
          .map((e) => {'produk_id': e['id'], 'jumlah': e['jumlah']})
          .toList(),
    };

    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: _headers(token),
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateOrder(
    int orderId, {
    required String status,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/orders/$orderId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );

    return _handleResponse(response);
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, dynamic>> updateItems({
    required int orderId,
    required List<Map<String, dynamic>> items,
  }) async {
    final token = await _getToken();

    final response = await http.put(
      Uri.parse('$baseUrl/orders/$orderId/update-items'),
      headers: _headers(token),
      body: jsonEncode({
        'items': items
            .map((e) => {'produk_id': e['produk_id'], 'jumlah': e['jumlah']})
            .toList(),
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> addItemToOrder(
    int orderId,
    int produkId,
    int jumlah,
  ) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/orders/$orderId/add-item'),
      headers: _headers(token),
      body: jsonEncode({'produk_id': produkId, 'jumlah': jumlah}),
    );

    return _handleResponse(response);
  }

  static Future<List<dynamic>> getAllProduk() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/produk'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is List) return data; 
      return data['data'] ?? []; 
    }

    throw Exception('Gagal memuat produk (${response.statusCode})');
  }

  static Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static List<dynamic> _handleListResponse(http.Response response, String key) {
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) return data;
      return data['data'] ?? [];
    } else if (response.statusCode == 401) {
      throw UnauthenticatedException('Token tidak valid');
    } else {
      throw Exception('Gagal memuat $key (${response.statusCode})');
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return {'success': true, 'data': jsonDecode(response.body)};
    } else if (response.statusCode == 401) {
      throw UnauthenticatedException('Token tidak valid');
    } else {
      final error = jsonDecode(response.body);
      return {
        'success': false,
        'message': error['message'] ?? 'Terjadi kesalahan',
      };
    }
  }
}

class UnauthenticatedException implements Exception {
  final String message;
  UnauthenticatedException(this.message);
}

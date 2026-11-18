import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  static const String _baseUrl = 'https://fakestoreapi.com';
  static const Duration _timeout = Duration(seconds: 15);

  static Future<List<Product>> fetchAllProducts() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/products'), headers: {'Accept': 'application/json'})
          .timeout(_timeout);
      if (response.statusCode != 200) {
        throw ApiException('Failed to load products (status ${response.statusCode})');
      }
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException {
      rethrow;
    } on Exception {
      throw const ApiException('Error fetching product list');
    }
  }

  static Future<Product> fetchProductDetail(int id) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/products/$id'), headers: {'Accept': 'application/json'})
          .timeout(_timeout);
      if (response.statusCode != 200) {
        throw ApiException('Failed to load product $id (status ${response.statusCode})');
      }
      final Map<String, dynamic> data = jsonDecode(response.body);
      return Product.fromJson(data);
    } on ApiException {
      rethrow;
    } on Exception {
      throw const ApiException('Error fetching product detail');
    }
  }
}

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/product.dart';
import '../services/api_service.dart';
import '../services/cart_service.dart';
import '../services/notification_service.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import 'cart_page.dart';

class DetailPage extends StatefulWidget {
  final int productId;

  const DetailPage({super.key, required this.productId});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late Future<Product> _futureProduct;
  int quantity = 1;
  bool isAdding = false;

  @override
  void initState() {
    super.initState();
    _futureProduct = ApiService.fetchProductDetail(widget.productId);
  }

  Future<void> addToCart(Product product) async {
    if (isAdding) return;
    setState(() => isAdding = true);
    try {
      final wasLimited = await CartService.add(
        SessionService.currentUser,
        product,
        quantity,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasLimited
                ? 'Stok tidak cukup. Jumlah disesuaikan.'
                : '🎈 ${product.title} ×$quantity masuk keranjang!',
          ),
          backgroundColor: const Color(0xFFE5738A),
        ),
      );
      await NotificationService.showCartNotification(
        productName: product.title,
        quantity: quantity,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menambahkan produk: $e'),
          backgroundColor: const Color(0xFFD9534F),
        ),
      );
    } finally {
      if (mounted) setState(() => isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Product>(
      future: _futureProduct,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Detail Produk'),
              backgroundColor: AppTheme.pink,
              foregroundColor: AppTheme.ink,
              actions: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartPage()),
                  ),
                ),
              ],
            ),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }
        final product = snapshot.data!;
        return ValueListenableBuilder<Box<int>>(
          valueListenable: Hive.box<int>('product_stock').listenable(),
          builder: (context, stockBox, child) {
            final availableStock = CartService.stockOf(product);
            return Scaffold(
              backgroundColor: AppTheme.blush,
              appBar: AppBar(
                title: const Text('Detail Produk'),
                backgroundColor: AppTheme.pink,
                foregroundColor: AppTheme.ink,
                leading: const BackButton(),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartPage()),
                    ),
                  ),
                ],
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildImageGallery(product.image),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.title,
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.ink,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '\$${product.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.pinkDeep,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.yellow,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Color(0xFF9A7410),
                                      size: 19,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      product.rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.ink,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          buildInfoRow(
                            Icons.category_rounded,
                            'Kategori',
                            product.category,
                          ),
                          const SizedBox(height: 10),
                          buildInfoRow(
                            Icons.inventory_2_rounded,
                            'Stok',
                            availableStock > 0
                                ? '$availableStock tersedia'
                                : 'Stok habis',
                          ),
                          const SizedBox(height: 22),
                          buildSectionTitle('Deskripsi Produk'),
                          const SizedBox(height: 8),
                          Text(
                            product.description,
                            textAlign: TextAlign.justify,
                            style: const TextStyle(
                              height: 1.5,
                              color: Color(0xFF6D514D),
                            ),
                          ),
                          const SizedBox(height: 22),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              bottomNavigationBar: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 8,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isAdding || availableStock <= 0
                            ? null
                            : () => addToCart(product),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.pinkDeep,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          isAdding ? 'Menambahkan...' : 'Tambah ke Keranjang',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget buildImageGallery(String imageUrl) {
    return Column(
      children: [
        Container(
          height: 270,
          width: double.infinity,
          color: AppTheme.pinkSoft,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (c, e, s) => const Icon(
              Icons.image_not_supported_rounded,
              size: 70,
              color: AppTheme.pinkDeep,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.pinkDeep),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.ink,
          ),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(color: Color(0xFF6D514D))),
        ),
      ],
    );
  }

  Widget buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.ink,
      ),
    );
  }
}

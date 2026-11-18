import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/cart_item.dart';
import 'services/notification_service.dart';
import 'services/session_service.dart';
import 'pages/root_page.dart';
import 'pages/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(CartItemAdapter());
  }
  await Hive.openBox<CartItem>('cart');
  await Hive.openBox<int>('product_stock');
  await SessionService.init();
  try {
    await NotificationService.init();
  } catch (e) {
    debugPrint('Notifikasi gagal diinisialisasi: $e');
  }

  runApp(const Shopedia());
}

class Shopedia extends StatelessWidget {
  const Shopedia({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Shopedia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFFE5DE),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE5738A),
          primary: const Color(0xFFE5738A),
          secondary: const Color(0xFF6AB0AF),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5A89A),
          foregroundColor: Color(0xFF4A2C2A),
          centerTitle: true,
        ),
      ),
      home: SessionService.isLoggedIn ? const RootPage() : const LoginPage(),
    );
  }
}

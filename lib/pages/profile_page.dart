import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/cart_item.dart';
import '../pages/cart_page.dart';
import '../services/profile_photo_service.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';

class ProfilePage extends StatefulWidget {
  final VoidCallback onLogout;

  const ProfilePage({super.key, required this.onLogout});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Uint8List? photoBytes;

  bool isLoadingPhoto = true;
  bool isSavingPhoto = false;

  String get username => SessionService.currentUser;

  @override
  void initState() {
    super.initState();
    loadProfilePhoto();
  }

  // Memuat foto profil berdasarkan username.
  Future<void> loadProfilePhoto() async {
    final savedPhoto = await ProfilePhotoService.getPhotoBytes(username);

    if (!mounted) return;

    setState(() {
      photoBytes = savedPhoto;
      isLoadingPhoto = false;
    });
  }

  // Memilih dan menyimpan foto profil.
  Future<void> changeProfilePhoto() async {
    if (isSavingPhoto) return;

    setState(() {
      isSavingPhoto = true;
    });

    try {
      final newPhoto = await ProfilePhotoService.pickAndSavePhoto(username);

      if (!mounted) return;

      if (newPhoto == null) return;

      setState(() {
        photoBytes = newPhoto;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto profil berhasil diperbarui! 🎀'),
          backgroundColor: AppTheme.pinkDeep,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan foto: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSavingPhoto = false;
        });
      }
    }
  }

  // Menghapus foto profil.
  Future<void> deleteProfilePhoto() async {
    try {
      await ProfilePhotoService.removePhoto(username);

      if (!mounted) return;

      setState(() {
        photoBytes = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto profil berhasil dihapus.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus foto: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  // Dialog konfirmasi menghapus foto.
  void showDeletePhotoDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.cream,
          title: const Text(
            'Hapus foto profil?',
            style: TextStyle(color: AppTheme.ink, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Foto profil akan dikembalikan ke avatar awal.',
            style: TextStyle(color: AppTheme.ink),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                deleteProfilePhoto();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger,
                foregroundColor: Colors.white,
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  // Dialog konfirmasi logout.
  void showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.cream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Mau logout? 🥺',
            style: TextStyle(color: AppTheme.ink, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Konfirmasi logout akan menghapus session login. Data keranjang tetap tersimpan.',
            style: TextStyle(color: AppTheme.ink),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                widget.onLogout();
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  // Avatar profil.
  Widget buildProfileAvatar() {
    if (isLoadingPhoto) {
      return const CircleAvatar(
        radius: 52,
        backgroundColor: AppTheme.cream,
        child: CircularProgressIndicator(color: AppTheme.pinkDeep),
      );
    }

    if (photoBytes != null) {
      return CircleAvatar(
        radius: 52,
        backgroundColor: AppTheme.cream,
        backgroundImage: MemoryImage(photoBytes!),
      );
    }

    return const CircleAvatar(
      radius: 52,
      backgroundColor: AppTheme.cream,
      child: Text('🎈', style: TextStyle(fontSize: 48)),
    );
  }

  // Kartu menu yang bisa ditekan.
  Widget buildMenuButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? trailing,
  }) {
    return Card(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        leading: CircleAvatar(
          backgroundColor: AppTheme.pinkSoft,
          child: Icon(icon, color: AppTheme.pinkDeep),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppTheme.ink,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF8D6460), fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing != null)
              Text(
                trailing,
                style: const TextStyle(
                  color: AppTheme.pinkDeep,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(width: 5),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.pinkDeep),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.blush,
      body: SafeArea(
        child: Column(
          children: [
            // Header profil.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 25, 20, 25),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.pink, AppTheme.pinkSoft],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      buildProfileAvatar(),
                      Material(
                        color: AppTheme.pinkDeep,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: isSavingPhoto ? null : changeProfilePhoto,
                          child: const Padding(
                            padding: EdgeInsets.all(9),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'My Profile',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '@$username',
                    style: const TextStyle(fontSize: 16, color: AppTheme.ink),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: isSavingPhoto ? null : changeProfilePhoto,
                    icon: const Icon(Icons.photo_library_rounded),
                    label: Text(
                      isSavingPhoto ? 'Menyimpan foto...' : 'Ganti Foto Profil',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.ink,
                      side: const BorderSide(color: AppTheme.ink),
                    ),
                  ),
                  if (photoBytes != null)
                    TextButton.icon(
                      onPressed: isSavingPhoto ? null : showDeletePhotoDialog,
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Hapus Foto'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.danger,
                      ),
                    ),
                ],
              ),
            ),

            // Konten profil.
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  ValueListenableBuilder<Box<CartItem>>(
                    valueListenable: Hive.box<CartItem>('cart').listenable(),
                    builder: (context, box, child) {
                      final itemCount = box.values
                          .where((item) => item.username == username)
                          .length;

                      return buildMenuButton(
                        icon: Icons.shopping_cart_rounded,
                        title: 'Keranjang Saya',
                        subtitle: 'Lihat dan atur produk yang akan dibeli',
                        trailing: '$itemCount produk',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CartPage()),
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // Tombol logout.
                  ElevatedButton.icon(
                    onPressed: showLogoutDialog,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.danger,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

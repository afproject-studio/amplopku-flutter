import 'package:flutter/material.dart';

/// Palet warna utama AmplopKu.
///
/// Seluruh warna utama memakai keluarga ungu agar tampilan antarlayar
/// konsisten. Nama lama seperti [accentOrange] tetap dipertahankan supaya
/// file lama tidak error, tetapi nilainya sudah bukan oranye.
class AppColors {
  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryDark = Color(0xFF5B21B6);
  static const Color primaryDeep = Color(0xFF4C1D95);
  static const Color primaryLight = Color(0xFFA78BFA);
  static const Color primarySoft = Color(0xFFEDE9FE);

  static const Color secondary = Color(0xFF8B5CF6);
  static const Color tertiary = Color(0xFFC4B5FD);
  static const Color accentBlue = Color(0xFF6366F1);
  static const Color accentPink = Color(0xFFDB2777);

  // Warna semantik untuk error/hapus. Tetap bernuansa rose agar jelas,
  // tetapi tidak memakai warna oranye.
  static const Color accentRed = Color(0xFFE11D48);

  // Alias kompatibilitas untuk kode lama yang masih memakai accentOrange.
  static const Color accentOrange = Color(0xFF9333EA);

  static const Color textDark = Color(0xFF251B35);
  static const Color textGrey = Color(0xFF756A84);
  static const Color bgLight = Color(0xFFF8F7FC);
  static const Color border = Color(0xFFE7E0F0);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color white = Colors.white;
}

import 'package:flutter/material.dart';

/// Paleta y gradientes de la app (estilo producto SaaS moderno).
abstract final class AppColors {
  static const Color bgTop = Color(0xFFE8EEFF);
  static const Color bgMid = Color(0xFFF4F6FD);
  static const Color bgBottom = Color(0xFFFDFDFE);

  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color accent = Color(0xFF0EA5E9);

  static const LinearGradient scaffoldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [bgTop, bgMid, bgBottom],
    stops: [0.0, 0.45, 1.0],
  );

  static const LinearGradient heroAccent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  );

  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
  );
}

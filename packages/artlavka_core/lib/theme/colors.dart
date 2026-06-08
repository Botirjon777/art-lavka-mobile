import 'package:flutter/material.dart';

/// Neutral palette. The UI stays quiet (warm off-white + one accent) so the
/// prints are the hero (SPEC §1). Do not add competing brand colors.
abstract final class AppColors {
  // --- Surfaces (warm off-white, not pure white) ----------------------------
  static const Color background = Color(0xFFF7F4EF);
  static const Color surface = Color(0xFFFFFDF9);
  static const Color surfaceMuted = Color(0xFFEEEAE2);

  // --- Ink (warm near-black, softer than #000) ------------------------------
  static const Color ink = Color(0xFF1C1A17);
  static const Color inkMuted = Color(0xFF6B655C);
  static const Color inkFaint = Color(0xFFA7A096);

  // --- The single accent ----------------------------------------------------
  static const Color accent = Color(0xFFE2553B); // warm terracotta
  static const Color accentPressed = Color(0xFFC44730);
  static const Color onAccent = Color(0xFFFFFFFF);

  // --- Lines / dividers ------------------------------------------------------
  static const Color border = Color(0xFFDED8CE);
  static const Color borderFocused = accent;

  // --- Semantic --------------------------------------------------------------
  static const Color success = Color(0xFF3F8F5B);
  static const Color error = Color(0xFFC1392B);
  static const Color warning = Color(0xFFC98A1B);

  static const Color disabled = Color(0xFFCFC8BD);
  static const Color onDisabled = Color(0xFF8A8378);
}

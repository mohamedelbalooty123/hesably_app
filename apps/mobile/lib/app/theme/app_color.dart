import 'package:flutter/material.dart';

/// Verified Stitch design tokens (project 661013469764921318).
///
/// Values marked [AppColor.verified] come directly from the Hesably Design
/// System / Kinetic Finance RTL system in Stitch. Semantic overlay colors
/// (AI, offline, pending, syncing) are derived placeholders documented as
/// unverified — they must be confirmed against final screens before use.
class AppColor {
  const AppColor._();

  static const Color primary = Color(0xFF0A7A3D);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFFAFAF8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF3F4EF);
  static const Color surfaceContainer = Color(0xFFEDEEE9);
  static const Color onBackground = Color(0xFF191C19);
  static const Color outline = Color(0xFF6F7A6E);
  static const Color outlineVariant = Color(0xFFD0CFC8);
  static const Color secondary = Color(0xFF5E5F59);
  static const Color error = Color(0xFFBA1A1A);

  // Derived placeholder semantic colors — NOT verified against Stitch.
  static const Color pendingAmber = Color(0xFFF59E0B);
  static const Color successGreen = Color(0xFF0A7A3D);
}

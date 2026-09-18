import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hesably/app/theme/app_color.dart';
import 'package:hesably/app/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('light theme uses verified Stitch primary token', () {
      final theme = AppTheme.light;

      expect(theme.colorScheme.primary, AppColor.primary);
      expect(theme.scaffoldBackgroundColor, AppColor.background);
      expect(theme.colorScheme.surface, AppColor.surface);
    });

    test('default font family is Cairo', () {
      expect(AppTheme.light.textTheme.bodyLarge?.fontFamily, 'Cairo');
    });

    test('primary buttons enforce 48dp minimum height', () {
      final style = AppTheme.light.filledButtonTheme.style;
      final resolved = style?.minimumSize?.resolve({}) ?? const Size(0, 0);
      expect(resolved.height, 48);
    });

    test('scaffold background matches verified canvas token', () {
      expect(AppTheme.light.scaffoldBackgroundColor, AppColor.background);
    });
  });
}

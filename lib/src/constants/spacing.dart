// lib/src/constants/spacing.dart
import 'package:flutter/material.dart';

/// Global spacing constants for consistent padding and margin across the app
class AppSpacing {
  // Base spacing units
  static const double xs = 2.0;
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double xxl = 20.0;
  static const double xxxl = 24.0;

  // Common EdgeInsets patterns
  static const EdgeInsets zero = EdgeInsets.zero;
  
  // All padding
  static const EdgeInsets allXs = EdgeInsets.all(xs);
  static const EdgeInsets allSm = EdgeInsets.all(sm);
  static const EdgeInsets allMd = EdgeInsets.all(md);
  static const EdgeInsets allLg = EdgeInsets.all(lg);
  static const EdgeInsets allXl = EdgeInsets.all(xl);
  static const EdgeInsets allXxl = EdgeInsets.all(xxl);
  
  // Symmetric padding - horizontal
  static const EdgeInsets horizontalXs = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets horizontalXl = EdgeInsets.symmetric(horizontal: xl);
  static const EdgeInsets horizontalXxl = EdgeInsets.symmetric(horizontal: xxl);
  
  // Symmetric padding - vertical
  static const EdgeInsets verticalXs = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets verticalXl = EdgeInsets.symmetric(vertical: xl);
  static const EdgeInsets verticalXxl = EdgeInsets.symmetric(vertical: xxl);
  
  // Combined symmetric padding - common patterns
  static const EdgeInsets symmetricXs = EdgeInsets.symmetric(horizontal: xs, vertical: xs);
  static const EdgeInsets symmetricSm = EdgeInsets.symmetric(horizontal: sm, vertical: sm);
  static const EdgeInsets symmetricMd = EdgeInsets.symmetric(horizontal: md, vertical: md);
  static const EdgeInsets symmetricLg = EdgeInsets.symmetric(horizontal: lg, vertical: lg);
  static const EdgeInsets symmetricXl = EdgeInsets.symmetric(horizontal: xl, vertical: xl);
  
  // Specific common patterns found in the codebase
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: xl, vertical: md);
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
  static const EdgeInsets sectionPadding = EdgeInsets.all(xl);
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(horizontal: xl, vertical: sm);
  static const EdgeInsets toolbarPadding = EdgeInsets.symmetric(vertical: md);
  
  // Only padding - directional
  static const EdgeInsets onlyTop = EdgeInsets.only(top: xl);
  static const EdgeInsets onlyBottom = EdgeInsets.only(bottom: xl);
  static const EdgeInsets onlyLeft = EdgeInsets.only(left: xl);
  static const EdgeInsets onlyRight = EdgeInsets.only(right: xl);
  
  // Custom only padding
  static EdgeInsets onlyTopCustom(double value) => EdgeInsets.only(top: value);
  static EdgeInsets onlyBottomCustom(double value) => EdgeInsets.only(bottom: value);
  static EdgeInsets onlyLeftCustom(double value) => EdgeInsets.only(left: value);
  static EdgeInsets onlyRightCustom(double value) => EdgeInsets.only(right: value);
  
  // Tree indentation (specific to hierarchical note tree)
  static EdgeInsets treeIndentation(int depth) => EdgeInsets.only(left: depth * xxl);
}

/// Media-specific spacing constants
class MediaSpacing {
  static const double thumbnailSize = 120.0;
  static const EdgeInsets dialogPadding = EdgeInsets.all(AppSpacing.xl);
  static const EdgeInsets fullScreenDialogPadding = EdgeInsets.all(AppSpacing.xl);
}
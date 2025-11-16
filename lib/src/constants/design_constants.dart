// lib/src/constants/design_constants.dart
import 'package:flutter/material.dart';

/// App-wide design constants including spacing, colors, and styling
class AppSpacing {
  // Base values used throughout the app
  static const double small = 8.0;   // Used for: step margins, toolbar padding, tree item spacing
  static const double medium = 12.0; // Used for: step card padding
  static const double large = 16.0;  // Used for: section padding, camera controls, dialog positioning
  static const double xl = 20.0;     // Used for: tree indentation multiplier

  // Zero padding (used in media section for full-width layout)
  static const EdgeInsets zero = EdgeInsets.zero;

  // === STEP-RELATED SPACING ===
  // Step cards - 12px padding inside cards, 8px margin between cards
  static const EdgeInsets stepCardPadding = EdgeInsets.all(1);
  static EdgeInsets stepCardMargin = const EdgeInsets.only(bottom: 0);
  
  // Step image dimensions and spacing
  static const double stepImageWidth = 100.0;
  static const double stepImageHeight = 100.0;  // Square image (80x80)
  static const double stepImageToTextSpacing = 12.0;
  static const double stepImageBorderRadius = 4.0;

  // === SECTION-RELATED SPACING === 
  // Main sections (media, title, metadata) - 16px all around
  static const EdgeInsets sectionPadding = EdgeInsets.all(large);
  
  // Section headers (title/metadata sections) - 8px vertical only
  static const EdgeInsets sectionHeaderPadding = EdgeInsets.symmetric(vertical: small);
  
  // Section cards - 16px horizontal, 12px vertical
  static const EdgeInsets sectionCardPadding = EdgeInsets.symmetric(horizontal: large, vertical: medium);
  
  // === MEDIA-RELATED SPACING ===
  // Media section bottom spacing
  static const EdgeInsets mediaBottomPadding = EdgeInsets.only(bottom: large);
  
  // === CAMERA-RELATED SPACING ===
  // Camera controls - 16px horizontal, 8px vertical
  static const EdgeInsets cameraControlPadding = EdgeInsets.symmetric(horizontal: large, vertical: small);
  
  // === DIALOG/OVERLAY SPACING ===
  // Dialog positioning and padding
  static const EdgeInsets dialogPadding = EdgeInsets.all(large);
  static const double dialogPositioning = large; // For top/right positioning
  
  // === TREE/NAVIGATION SPACING ===
  // Note tree indentation (20px per level)
  static EdgeInsets treeIndentation(int depth) => EdgeInsets.only(left: depth * xl);
  
  // Tree item margins - 16px horizontal, 4px vertical  
  static const EdgeInsets treeItemMargin = EdgeInsets.symmetric(horizontal: large, vertical: 4.0);
  
  // Tree button margins - 8px horizontal, 2px vertical
  static const EdgeInsets treeButtonMargin = EdgeInsets.symmetric(horizontal: small, vertical: 2.0);
  
  // Tree button padding - 8px all around
  static const EdgeInsets treeButtonPadding = EdgeInsets.all(small);
  
  // Tree action padding - 20px right only
  static const EdgeInsets treeActionPadding = EdgeInsets.only(right: xl);
  
  // === PAGE-LEVEL SPACING ===
  // Page horizontal padding - 16px horizontal
  static const EdgeInsets pageHorizontalPadding = EdgeInsets.symmetric(horizontal: large);

  // === UTILITY METHODS ===
  // For cases where you need custom bottom margins (like step cards)
  static EdgeInsets bottomMargin(double value) => EdgeInsets.only(bottom: value);
}

/// Media-specific constants
class MediaSpacing {
  // Thumbnail size for media gallery (updated to 180px as per your edit)
  static const double thumbnailSize = 180.0;
}

/// Typography constants based on actual usage patterns in the app
class AppTextStyles {
  // === FONT SIZES ===
  // Based on actual usage in the codebase
  static const double titleLarge = 28.0;    // Used for: note titles
  static const double titleMedium = 18.0;   // Used for: empty state headings, section headers
  static const double bodyLarge = 16.0;     // Used for: camera button text, main content
  static const double bodyMedium = 14.0;    // Used for: empty state messages
  static const double bodySmall = 12.0;     // Used for: step indicators, metadata, timestamps, hints
  static const double caption = 10.0;       // Used for: very small labels in tree view

  // === TEXT STYLES ===
  // Title styles
  static const TextStyle noteTitle = TextStyle(
    fontSize: titleLarge,
    fontWeight: FontWeight.bold,
  );

  // Section header styles  
  static const TextStyle sectionHeader = TextStyle(
    fontSize: titleMedium,
    color: Colors.grey,
  );

  // Body text styles
  static const TextStyle bodyText = TextStyle(
    fontSize: bodyLarge,
  );

  static const TextStyle emptyStateMessage = TextStyle(
    fontSize: bodyMedium,
  );

  // Small text styles
  static const TextStyle stepIndicator = TextStyle(
    fontSize: bodySmall,
    color: Colors.blue,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle metadata = TextStyle(
    fontSize: bodySmall,
    color: Colors.grey,
  );

  static const TextStyle hint = TextStyle(
    fontSize: bodySmall,
    color: Colors.grey,
  );

  static const TextStyle timestamp = TextStyle(
    fontSize: bodySmall,
    color: Colors.grey,
  );

  static const TextStyle treeLabel = TextStyle(
    fontSize: caption,
    color: Colors.grey,
  );

  // === TEXT-RELATED SPACING ===
  // Spacing around different text elements
  static const EdgeInsets titlePadding = EdgeInsets.symmetric(vertical: 8.0);
  static const EdgeInsets bodyTextPadding = EdgeInsets.symmetric(vertical: 4.0);
  static const EdgeInsets metadataPadding = EdgeInsets.symmetric(vertical: 2.0);
  
  // Line height multipliers for better readability
  static const double titleLineHeight = 1.2;
  static const double bodyLineHeight = 1.4;
  static const double smallTextLineHeight = 1.3;
}

/// App color constants based on actual usage patterns
class AppColors {
  // === GENERAL BACKGROUND COLORS ===
  static const Color appBackground = Color(0xFFFAFAFA);  // Light gray background
  static final Color sectionBackground = const Color(0xFFFFFFFF);  // White sections
  static final Color cardBackground = const Color(0xFFFFFFFF);  // White cards
  static final Color surfaceBackground = const Color(0xFFF5F5F5);  // Very light gray surfaces
  
  // === SPECIFIC SECTION BACKGROUNDS ===
  static final Color mediaBackground = const Color.fromARGB(255, 157, 157, 157);  // Very light background for media
  static const Color stepsBackground = Color(0xFFFFFFFF);  // White steps section
  static final Color toolbarBackground = const Color(0xFFF8F9FA);  // Light toolbar
  static const Color modalBackground = Color.fromARGB(255, 225, 225, 225);  // White modals
  
  // === STEP CARD COLORS ===
  static final Color stepCardBackground = const Color(0xFFFFFFFF);  // White step cards
  static final Color stepCardBorder = const Color(0xFFE1E5E9);  // Light border
  
  // === IMAGE/MEDIA COLORS ===
  static final Color imagePlaceholderBackground = const Color(0xFFF1F3F4);  // Light gray placeholder
  static final Color imageErrorBackground = const Color(0xFFE8EAED);  // Slightly darker for errors
  static final Color iconColor = const Color(0xFF5F6368);  // Medium gray icons
  
  // === ACTION COLORS ===
  static final Color deleteButton = const Color(0xFFEA4335);  // Google red for delete
  static final Color deleteText = const Color(0xFFEA4335);  // Matching delete textr
  
  // === CAMERA COLORS ===
  static const Color cameraBackground = Color(0xFF000000);  // Black camera background
  static const Color cameraOverlay = Color(0x8A000000);  // Semi-transparent overlay
  static const Color cameraControls = Color(0xFFFFFFFF);  // White camera controls
  
  // === OVERLAY COLORS ===
  static const Color fullScreenOverlay = Colors.black;
  static const Color fullScreenContent = Colors.white;
}

/// App styling constants (border radius, sizes, etc.)
class AppStyling {
  // === BORDER RADIUS ===
  static const double stepCardBorderRadius = 8.0;
  static const double imageBorderRadius = 4.0; // Same as stepImageBorderRadius
  
  // === BORDER WIDTHS ===
  static const double defaultBorderWidth = 1.0;
  
  // === ICON SIZES ===
  static const double smallIcon = 16.0;
  static const double mediumIcon = 20.0;
  static const double largeIcon = 24.0;
  
  // === BUTTON CONSTRAINTS ===
  static const BoxConstraints actionButtonConstraints = BoxConstraints(
    minWidth: 24, 
    minHeight: 24
  );
}
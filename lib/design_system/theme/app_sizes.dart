/// Shared dimension tokens (heights, icons, strokes, layout).
///
/// Keep control sizes here so screens never hardcode button/input heights.
abstract final class AppSizes {
  // Icons
  static const double iconXs = 12;
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;
  static const double iconXl = 32;
  static const double iconHuge = 48;

  // Buttons
  static const double buttonHeightSm = 36;
  static const double buttonHeightMd = 44;
  static const double buttonHeightLg = 52;
  static const double iconButtonSize = 40;
  static const double iconButtonTapTarget = 48;

  // Inputs
  static const double inputHeight = 48;

  // Chrome
  static const double appBarHeight = 56;
  static const double bottomNavHeight = 64;

  // Borders / strokes
  static const double borderThin = 1;
  static const double borderMedium = 1.5;
  static const double borderThick = 2;
  static const double loaderStrokeWidth = 2.5;
  static const double loaderStrokeWidthCompact = 2;

  // Dividers
  static const double dividerThickness = 1;

  // Layout
  static const double maxContentWidth = 720;
  static const double minTouchTarget = 48;
}

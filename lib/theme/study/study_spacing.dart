class StudySpacing {
  StudySpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;
  static const double xxxl = 56;

  static const double pageHorizontal = 20;
  static const double pageHorizontalDesktop = 32;

  static double pageHorizontalForWidth(double width) {
    if (width >= 900) return pageHorizontalDesktop;
    if (width < 600) return xs;
    return pageHorizontal;
  }

  static double heroHorizontalForWidth(double width) {
    if (width >= 900) return pageHorizontalDesktop;
    if (width < 600) return md;
    return pageHorizontal;
  }

  static const double sectionGap = 32;
  static const double blockGap = 20;
  static const double cardPadding = 20;
  static const double cardPaddingLarge = 24;

  static const double maxReadingWidth = 920;
  static const double maxContentWidth = 1180;
}

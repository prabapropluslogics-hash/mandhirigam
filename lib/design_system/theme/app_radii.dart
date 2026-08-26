import 'package:flutter/painting.dart';

/// Corner radius tokens and semantic aliases from the UI reference.
abstract final class AppRadii {
  static const double none = 0;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 999;

  static const double button = xl;
  static const double textField = lg;
  static const double searchBar = lg;
  static const double card = md;
  static const double dialog = xl;
  static const double bottomSheet = xl;
  static const double container = md;
  static const double chip = full;
  static const double iconButton = full;
  static const double cover = sm;

  static BorderRadius get buttonBorder => BorderRadius.circular(button);
  static BorderRadius get textFieldBorder => BorderRadius.circular(textField);
  static BorderRadius get searchBarBorder => BorderRadius.circular(searchBar);
  static BorderRadius get cardBorder => BorderRadius.circular(card);
  static BorderRadius get dialogBorder => BorderRadius.circular(dialog);
  static BorderRadius get containerBorder => BorderRadius.circular(container);
  static BorderRadius get coverBorder => BorderRadius.circular(cover);
  static BorderRadius get chipBorder => BorderRadius.circular(chip);

  static BorderRadius get bottomSheetBorder => const BorderRadius.vertical(
        top: Radius.circular(bottomSheet),
      );
}

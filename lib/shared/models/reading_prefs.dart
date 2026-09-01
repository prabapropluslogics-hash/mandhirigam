enum ReadingMode { light, sepia, dark }

enum LineSpacing { tight, normal, relaxed }

class TypefaceOption {
  const TypefaceOption({
    required this.id,
    required this.label,
    this.italic = false,
  });

  final String id;
  final String label;
  final bool italic;
}

class ReadingPrefs {
  const ReadingPrefs({
    this.mode = ReadingMode.light,
    this.brightness = 1,
    this.fontSize = 17,
    this.typefaceId = 'literata',
    this.lineSpacing = LineSpacing.normal,
  });

  final ReadingMode mode;
  final double brightness;
  final double fontSize;
  final String typefaceId;
  final LineSpacing lineSpacing;

  ReadingPrefs copyWith({
    ReadingMode? mode,
    double? brightness,
    double? fontSize,
    String? typefaceId,
    LineSpacing? lineSpacing,
  }) {
    return ReadingPrefs(
      mode: mode ?? this.mode,
      brightness: brightness ?? this.brightness,
      fontSize: fontSize ?? this.fontSize,
      typefaceId: typefaceId ?? this.typefaceId,
      lineSpacing: lineSpacing ?? this.lineSpacing,
    );
  }

  double get lineHeight => switch (lineSpacing) {
        LineSpacing.tight => 1.4,
        LineSpacing.normal => 1.7,
        LineSpacing.relaxed => 2.0,
      };
}

class ProfileStats {
  const ProfileStats({
    required this.displayName,
    required this.booksRead,
    required this.dayStreak,
    required this.timeReading,
    required this.pagesTurned,
    required this.initial,
    required this.isPremium,
    required this.memberLabel,
  });

  final String displayName;
  final String booksRead;
  final String dayStreak;
  final String timeReading;
  final String pagesTurned;
  final String initial;
  final bool isPremium;
  final String memberLabel;
}

class WeeklyActivity {
  const WeeklyActivity({
    required this.values,
    required this.highlightedIndex,
    this.dayLabels = const <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'],
  });

  final List<double> values;
  final int highlightedIndex;
  final List<String> dayLabels;
}

class ReadingStreak {
  const ReadingStreak({
    required this.days,
    required this.filledDots,
    required this.totalDots,
    required this.message,
  });

  final int days;
  final int filledDots;
  final int totalDots;
  final String message;

  String get title => '$days-day reading streak';
}

class ReaderProgress {
  const ReaderProgress({
    required this.currentPage,
    required this.totalPages,
    required this.percent,
    required this.minutesLeft,
  });

  final int currentPage;
  final int totalPages;
  final double percent;
  final int minutesLeft;

  String get pageLabel => 'Page $currentPage of $totalPages';

  String get remainingLabel {
    final int pct = (percent * 100).round();
    return '$pct% · $minutesLeft min left';
  }
}

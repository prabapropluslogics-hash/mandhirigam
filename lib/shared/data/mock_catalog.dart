import 'package:flutter/material.dart';

import '../models/book.dart';
import '../models/profile_stats.dart';
import '../models/reading_prefs.dart';
import '../models/subscription_plan.dart';

/// Static catalog used until APIs exist. Replace this class later.
abstract final class MockCatalog {
  static const String currentUserName = 'Aanya Rao';
  static const String greeting = 'Good evening';

  static const List<String> recentSearches = <String>[
    'winter',
    'R. Adeyemi',
    'short stories',
    'dark academia',
  ];

  static const List<String> filterShortcuts = <String>[
    'Genre',
    'Rating 4+',
    'Length',
  ];

  static const List<String> genres = <String>[
    'Fiction',
    'Mystery',
    'Romance',
    'Sci-Fi',
    'Poetry',
  ];

  static const Book quietHours = Book(
    id: 'quiet-hours',
    title: 'The Quiet Hours',
    author: 'Mira Solenne',
    genre: 'Literary Fiction',
    rating: 4.6,
    reviewCountLabel: '1.4k',
    isPremium: false,
    pages: 286,
    readTime: '4h 10m',
    language: 'English',
    description:
        'A winter of withheld letters, and the rooms that keep their silence.',
    coverStart: Color(0xFF3E4A6B),
    coverEnd: Color(0xFF151820),
    currentChapter: 12,
    chapters: <String>[
      'Dusk in the hallway',
      'The unopened envelope',
      'A kettle left on',
      'Chapter 4',
      'Chapter 5',
      'Chapter 6',
      'Chapter 7',
      'Chapter 8',
      'Chapter 9',
      'Chapter 10',
      'Chapter 11',
      'The Amber Room',
      'Chapter 13',
      'Chapter 14',
      'Chapter 15',
      'Chapter 16',
      'Chapter 17',
      'Chapter 18',
      'Chapter 19',
      'Chapter 20',
      'Chapter 21',
      'Chapter 22',
      'Chapter 23',
      'Last light',
    ],
  );

  static const Book amberSea = Book(
    id: 'amber-sea',
    title: 'Letters from an Amber Sea',
    author: 'Naila Petrov',
    genre: 'Historical Fiction',
    rating: 4.9,
    reviewCountLabel: '2.1k',
    isPremium: true,
    pages: 412,
    readTime: '6h 40m',
    language: 'English',
    description:
        'Along a vanishing coastline, a correspondence begins that will outlast '
        'the war that made it necessary. Petrov maps a country disappearing '
        'into dusk, and a love that learns to speak only in absence. Each tide '
        'returns a page; each page returns a name.',
    coverStart: Color(0xFFC9A36A),
    coverEnd: Color(0xFF2B1A10),
    currentChapter: 2,
    chapters: <String>[
      'The first letter',
      'Harbour lights',
      'Salt on the page',
      'A winter crossing',
      'Names we keep',
    ],
  );

  static const Book wintersAlmanac = Book(
    id: 'winters-almanac',
    title: "Winter's Almanac",
    author: 'H. Bergman',
    genre: 'Literary Fiction',
    rating: 4.7,
    reviewCountLabel: '890',
    isPremium: true,
    pages: 334,
    readTime: '5h 20m',
    language: 'English',
    description:
        'Field notes from a frozen year: markets, moths, and the mathematics of snow.',
    coverStart: Color(0xFF4A5D4A),
    coverEnd: Color(0xFF141A14),
    chapters: <String>['January', 'Thaw'],
  );

  static const Book northWindow = Book(
    id: 'north-window',
    title: 'North Window',
    author: 'Elise Kwan',
    genre: 'Poetry',
    rating: 4.4,
    reviewCountLabel: '320',
    isPremium: false,
    pages: 96,
    readTime: '1h 30m',
    language: 'English',
    description: 'Short lyrics facing the cold glass of a rented room.',
    coverStart: Color(0xFF5A3E6B),
    coverEnd: Color(0xFF1A1220),
    chapters: <String>['Glass', 'Frost'],
  );

  static const Book greenHour = Book(
    id: 'green-hour',
    title: 'The Green Hour',
    author: 'Jonas Hale',
    genre: 'Mystery',
    rating: 4.3,
    reviewCountLabel: '540',
    isPremium: false,
    pages: 368,
    readTime: '6h 05m',
    language: 'English',
    description: 'A botanist vanishes between two greenhouses at closing time.',
    coverStart: Color(0xFF2F5A45),
    coverEnd: Color(0xFF0F1A14),
    chapters: <String>['Closing', 'Soil'],
  );

  static const Book deepCurrent = Book(
    id: 'deep-current',
    title: 'Deep Current',
    author: 'S. Okada',
    genre: 'Sci-Fi',
    rating: 4.5,
    reviewCountLabel: '1.1k',
    isPremium: true,
    pages: 448,
    readTime: '7h 15m',
    language: 'English',
    description: 'A research vessel follows a signal that should not exist.',
    coverStart: Color(0xFF1E3A5F),
    coverEnd: Color(0xFF0B121C),
    chapters: <String>['Sonar', 'Below'],
  );

  static const List<Book> all = <Book>[
    quietHours,
    amberSea,
    wintersAlmanac,
    northWindow,
    greenHour,
    deepCurrent,
  ];

  static const List<Book> trending = <Book>[
    northWindow,
    greenHour,
    deepCurrent,
    quietHours,
  ];

  static Book byId(String id) {
    return all.firstWhere((Book book) => book.id == id, orElse: () => amberSea);
  }

  static List<Book> search(String query) {
    final String needle = query.trim().toLowerCase();
    if (needle.isEmpty) return all;
    return all
        .where(
          (Book book) =>
              book.title.toLowerCase().contains(needle) ||
              book.author.toLowerCase().contains(needle) ||
              book.genre.toLowerCase().contains(needle),
        )
        .toList();
  }

  static const String catalogBrand = 'Folio';

  static const SubscriptionPlan annualPlan = SubscriptionPlan(
    id: 'annual',
    name: 'Annual',
    periodLabel: 'Annual',
    pricePerMonthLabel: r'$4.99/mo',
    billingLabel: r'billed $59.99/yr',
    displayName: 'Folio Premium — Annual',
    subtotalLabel: r'$59.99',
    taxLabel: r'$4.20',
    totalLabel: r'$64.19',
    bestValue: true,
  );

  static const SubscriptionPlan monthlyPlan = SubscriptionPlan(
    id: 'monthly',
    name: 'Monthly',
    periodLabel: 'Monthly',
    pricePerMonthLabel: r'$8.99/mo',
    billingLabel: 'billed monthly',
    displayName: 'Folio Premium — Monthly',
    subtotalLabel: r'$8.99',
    taxLabel: r'$0.63',
    totalLabel: r'$9.62',
  );

  static const List<SubscriptionPlan> plans = <SubscriptionPlan>[
    annualPlan,
    monthlyPlan,
  ];

  static const List<String> subscriptionFeatures = <String>[
    'Unlimited access to 12,000+ premium titles',
    'Download and read offline, anywhere',
    'New releases, first — before anyone else',
    'Sync your library across every device',
  ];

  static SubscriptionPlan planById(String id) {
    return plans.firstWhere(
      (SubscriptionPlan plan) => plan.id == id,
      orElse: () => annualPlan,
    );
  }

  static const List<Book> continueReading = <Book>[
    quietHours,
    amberSea,
  ];

  static const List<Book> downloaded = <Book>[
    quietHours,
    wintersAlmanac,
    northWindow,
    greenHour,
  ];

  static const List<Book> wishlist = <Book>[
    northWindow,
    deepCurrent,
  ];

  static const ReadingStreak readingStreak = ReadingStreak(
    days: 7,
    filledDots: 3,
    totalDots: 4,
    message: 'Read today to keep it going.',
  );

  static const ProfileStats profileStats = ProfileStats(
    displayName: currentUserName,
    booksRead: '148',
    dayStreak: '7',
    timeReading: '312h',
    pagesTurned: '41.2k',
    initial: 'A',
    isPremium: true,
    memberLabel: 'Premium member',
  );

  static const WeeklyActivity weeklyActivity = WeeklyActivity(
    values: <double>[0.42, 0.68, 0.35, 1.0, 0.55, 0.28, 0.22],
    highlightedIndex: 3,
  );

  static const ReaderProgress quietHoursReaderProgress = ReaderProgress(
    currentPage: 142,
    totalPages: 320,
    percent: 0.62,
    minutesLeft: 8,
  );

  static const List<TypefaceOption> typefaces = <TypefaceOption>[
    TypefaceOption(id: 'literata', label: 'Literata'),
    TypefaceOption(id: 'fraunces', label: 'Fraunces', italic: true),
    TypefaceOption(id: 'georgia', label: 'Georgia'),
  ];

  static const String readerLead =
      'he conservatory had been closed since October, but the amber still '
      'held the afternoon. I found the letter where she said it would be — '
      'behind the third pane, where the putty had shrunk from the glass. ';

  static const String readerHighlight = 'Her handwriting had not changed.';

  static const String readerRest =
      ' Only the paper had: thinner, as if the years had worn it from the '
      'inside.\n\nI did not open it at once. The house made its small noises. '
      'A pipe. A window settling. Somewhere below, the clock that no longer '
      'kept time but still believed it should.';

  static String chapterBody(Book book, int chapterIndex) {
    if (book.id == quietHours.id && chapterIndex == 11) {
      return '$readerLead$readerHighlight$readerRest';
    }
    final String title = chapterIndex < book.chapters.length
        ? book.chapters[chapterIndex]
        : 'Chapter ${chapterIndex + 1}';
    return 'The pages of $title keep their own weather. Light collects in '
        'the margins; a sentence waits where you left it. Read on — the room '
        'is still holding the hour.';
  }
}

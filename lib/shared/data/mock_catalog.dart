import 'package:flutter/material.dart';

import '../models/book.dart';

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
      'The twelfth hour',
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
}

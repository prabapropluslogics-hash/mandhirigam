import 'package:flutter/material.dart';

/// Lightweight book model for UI-only mock data.
class Book {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.genre,
    required this.rating,
    required this.reviewCountLabel,
    required this.isPremium,
    required this.pages,
    required this.readTime,
    required this.language,
    required this.description,
    required this.coverStart,
    required this.coverEnd,
    required this.chapters,
    this.currentChapter = 0,
    this.coverAsset,
  });

  final String id;
  final String title;
  final String author;
  final String genre;
  final double rating;
  final String reviewCountLabel;
  final bool isPremium;
  final int pages;
  final String readTime;
  final String language;
  final String description;
  final Color coverStart;
  final Color coverEnd;
  final List<String> chapters;
  final int currentChapter;
  final String? coverAsset;

  double get progress {
    if (chapters.isEmpty) return 0;
    return currentChapter / chapters.length;
  }

  int get totalChapters => chapters.length;

  String get chapterProgressLabel =>
      'Chapter $currentChapter of $totalChapters';
}

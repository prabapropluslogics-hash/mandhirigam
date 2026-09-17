import '../../core/utils/json_map.dart';
import '../../core/utils/money_format.dart';

class CatalogBook {
  const CatalogBook({
    required this.id,
    required this.title,
    required this.description,
    required this.author,
    required this.language,
    required this.accessType,
    required this.price,
    required this.currency,
    this.coverImage,
    this.status = 'PUBLISHED',
    this.publishedAt,
  });

  final String id;
  final String title;
  final String description;
  final String author;
  final String language;
  final String? coverImage;
  final String accessType;
  final int price;
  final String currency;
  final String status;
  final String? publishedAt;

  bool get isPaid => accessType.toUpperCase() == 'PAID';
  bool get isFree => accessType.toUpperCase() == 'FREE';

  String get languageLabel {
    switch (language.toLowerCase()) {
      case 'ta':
        return 'Tamil';
      case 'hi':
        return 'Hindi';
      case 'en':
        return 'English';
      default:
        return language;
    }
  }

  String get priceLabel {
    if (isFree || price <= 0) return 'FREE';
    return formatMoney(minorUnits: price, currency: currency);
  }

  factory CatalogBook.fromJson(Map<String, dynamic> json) {
    return CatalogBook(
      id: asString(json['id'] ?? json['bookId']),
      title: asString(json['title']),
      description: asString(json['description']),
      author: asString(json['author']),
      language: asString(json['language']),
      coverImage: asStringOrNull(json['coverImage']),
      accessType: asString(json['accessType'], 'FREE'),
      price: asInt(json['price']),
      currency: asString(json['currency'], 'INR'),
      status: asString(json['status'], 'PUBLISHED'),
      publishedAt: asStringOrNull(json['publishedAt']),
    );
  }
}

class FeaturedBookRef {
  const FeaturedBookRef({required this.id, required this.title});

  final String id;
  final String title;

  factory FeaturedBookRef.fromJson(Map<String, dynamic> json) {
    return FeaturedBookRef(
      id: asString(json['id']),
      title: asString(json['title']),
    );
  }
}

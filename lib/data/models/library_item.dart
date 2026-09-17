import '../../core/utils/json_map.dart';
import 'catalog_book.dart';

class LibraryItem {
  const LibraryItem({
    required this.bookId,
    required this.title,
    required this.language,
    required this.accessType,
    required this.entitlementType,
    required this.grantedAt,
    this.coverImage,
  });

  final String bookId;
  final String title;
  final String language;
  final String? coverImage;
  final String accessType;
  final String entitlementType;
  final String grantedAt;

  CatalogBook get asBook {
    return CatalogBook(
      id: bookId,
      title: title,
      description: '',
      author: '',
      language: language,
      coverImage: coverImage,
      accessType: accessType,
      price: 0,
      currency: 'INR',
    );
  }

  factory LibraryItem.fromJson(Map<String, dynamic> json) {
    return LibraryItem(
      bookId: asString(json['bookId']),
      title: asString(json['title']),
      language: asString(json['language']),
      coverImage: asStringOrNull(json['coverImage']),
      accessType: asString(json['accessType'], 'PAID'),
      entitlementType: asString(json['entitlementType'], 'LIFETIME'),
      grantedAt: asString(json['grantedAt']),
    );
  }
}

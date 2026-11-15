import 'package:cloud_firestore/cloud_firestore.dart';

/// Product model representing items in the catalog
class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final String? subcategory;
  final int popularity;
  final DateTime createdAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    this.subcategory,
    required this.popularity,
    required this.createdAt,
  });

  /// Convert ProductModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'subcategory': subcategory,
      'popularity': popularity,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create ProductModel from Firestore document
  /// Tolerant of missing or wrongly typed fields (price may be int or double)
  factory ProductModel.fromMap(String id, Map<String, dynamic> map) {
    // Handle price as either int or double
    double price = 0.0;
    if (map['price'] != null) {
      if (map['price'] is int) {
        price = (map['price'] as int).toDouble();
      } else if (map['price'] is double) {
        price = map['price'] as double;
      }
    }

    // Handle createdAt
    DateTime createdAt = DateTime.now();
    if (map['createdAt'] is Timestamp) {
      createdAt = (map['createdAt'] as Timestamp).toDate();
    }

    return ProductModel(
      id: id,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price: price,
      imageUrl: map['imageUrl'] as String? ?? '',
      category: map['category'] as String? ?? '',
      subcategory: map['subcategory'] as String?,
      popularity: map['popularity'] as int? ?? 0,
      createdAt: createdAt,
    );
  }
}

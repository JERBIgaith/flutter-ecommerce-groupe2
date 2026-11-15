import 'package:cloud_firestore/cloud_firestore.dart';

/// Favorite model representing a saved product
class FavoriteModel {
  final String productId;
  final String name;
  final double price;
  final String imageUrl;
  final DateTime addedAt;

  FavoriteModel({
    required this.productId,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.addedAt,
  });

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'addedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Create from Firestore document (tolerant of missing fields)
  factory FavoriteModel.fromMap(String id, Map<String, dynamic> map) {
    double price = 0.0;
    if (map['price'] != null) {
      if (map['price'] is int) {
        price = (map['price'] as int).toDouble();
      } else if (map['price'] is double) {
        price = map['price'] as double;
      }
    }

    DateTime addedAt = DateTime.now();
    if (map['addedAt'] is Timestamp) {
      addedAt = (map['addedAt'] as Timestamp).toDate();
    }

    return FavoriteModel(
      productId: id,
      name: map['name'] as String? ?? '',
      price: price,
      imageUrl: map['imageUrl'] as String? ?? '',
      addedAt: addedAt,
    );
  }
}

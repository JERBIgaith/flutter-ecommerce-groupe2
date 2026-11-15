import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/favorite_model.dart';

/// Service for favorite operations
class FavoriteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream user's favorites
  Stream<List<FavoriteModel>> streamFavorites(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FavoriteModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Add product to favorites
  Future<void> addToFavorites(
    String userId,
    String productId,
    String name,
    double price,
    String imageUrl,
  ) async {
    try {
      final favorite = FavoriteModel(
        productId: productId,
        name: name,
        price: price,
        imageUrl: imageUrl,
        addedAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(productId)
          .set(favorite.toMap());
    } catch (e) {
      rethrow;
    }
  }

  /// Remove product from favorites
  Future<void> removeFromFavorites(String userId, String productId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(productId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(
    String userId,
    String productId,
    bool isFavorite,
    String name,
    double price,
    String imageUrl,
  ) async {
    if (isFavorite) {
      await removeFromFavorites(userId, productId);
    } else {
      await addToFavorites(userId, productId, name, price, imageUrl);
    }
  }
}

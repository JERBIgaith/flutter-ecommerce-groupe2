import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_item_model.dart';

/// Service for cart operations
class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream user's cart items
  Stream<List<CartItemModel>> streamCart(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CartItemModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Add product to cart using transaction (increments quantity if exists)
  Future<void> addToCart(
    String userId,
    String productId,
    String name,
    double price,
    String imageUrl,
    int quantity,
  ) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(productId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (snapshot.exists) {
          // Document exists, increment quantity
          final currentQuantity = snapshot.data()?['quantity'] as int? ?? 1;
          transaction.update(docRef, {
            'quantity': currentQuantity + quantity,
          });
        } else {
          // Document does not exist, create new
          final cartItem = CartItemModel(
            productId: productId,
            name: name,
            price: price,
            imageUrl: imageUrl,
            quantity: quantity,
          );
          transaction.set(docRef, cartItem.toMap());
        }
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Update cart item quantity
  Future<void> updateQuantity(
    String userId,
    String productId,
    int quantity,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(productId)
          .update({'quantity': quantity});
    } catch (e) {
      rethrow;
    }
  }

  /// Remove item from cart
  Future<void> removeFromCart(String userId, String productId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(productId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Clear all cart items
  Future<void> clearCart(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .get();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }
}

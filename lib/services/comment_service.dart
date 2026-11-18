import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment_model.dart';

/// Service for handling product comment operations on Firestore
class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream comments for a product (no orderBy in query - sorted on client)
  Stream<List<CommentModel>> streamComments(String productId) {
    return _firestore
        .collection('products')
        .doc(productId)
        .collection('comments')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CommentModel.fromMap(doc.id, productId, doc.data()))
          .toList();
    });
  }

  /// Add a new comment to a product
  Future<void> addComment({
    required String productId,
    required String userId,
    required String userName,
    required String text,
  }) async {
    await _firestore
        .collection('products')
        .doc(productId)
        .collection('comments')
        .add({
      'userId': userId,
      'userName': userName.trim(),
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update an existing comment (updates ONLY text and updatedAt per rules)
  Future<void> updateComment({
    required String productId,
    required String commentId,
    required String text,
  }) async {
    await _firestore
        .collection('products')
        .doc(productId)
        .collection('comments')
        .doc(commentId)
        .update({
      'text': text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a comment
  Future<void> deleteComment({
    required String productId,
    required String commentId,
  }) async {
    await _firestore
        .collection('products')
        .doc(productId)
        .collection('comments')
        .doc(commentId)
        .delete();
  }
}

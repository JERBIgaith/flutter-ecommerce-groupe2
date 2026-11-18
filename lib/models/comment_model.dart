import 'package:cloud_firestore/cloud_firestore.dart';

/// Comment model representing a user comment on a product
class CommentModel {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final String text;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CommentModel({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    required this.text,
    this.createdAt,
    this.updatedAt,
  });

  /// Check if the comment was edited after creation
  bool get isEdited {
    if (updatedAt == null || createdAt == null) return false;
    return updatedAt!.difference(createdAt!).inSeconds > 2;
  }

  /// Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'text': text,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  /// Create CommentModel from Firestore document map (tolerant of null dates)
  factory CommentModel.fromMap(
    String id,
    String productId,
    Map<String, dynamic> map,
  ) {
    DateTime? createdAtDate;
    if (map['createdAt'] is Timestamp) {
      createdAtDate = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is String) {
      createdAtDate = DateTime.tryParse(map['createdAt'] as String);
    }

    DateTime? updatedAtDate;
    if (map['updatedAt'] is Timestamp) {
      updatedAtDate = (map['updatedAt'] as Timestamp).toDate();
    } else if (map['updatedAt'] is String) {
      updatedAtDate = DateTime.tryParse(map['updatedAt'] as String);
    }

    return CommentModel(
      id: id,
      productId: productId,
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? '',
      text: map['text'] as String? ?? '',
      createdAt: createdAtDate,
      updatedAt: updatedAtDate,
    );
  }
}

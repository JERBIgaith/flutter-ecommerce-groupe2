import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';

/// Service for handling Admin operations on Firestore
class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream all users (client-side sort)
  Stream<List<UserModel>> streamUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();
    });
  }

  /// Stream all orders (client-side sort, no orderBy in query)
  Stream<List<OrderModel>> streamAllOrders() {
    return _firestore.collection('orders').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  /// Create a new product
  Future<void> createProduct({
    required String name,
    required String description,
    required double price,
    required String imageUrl,
    required String category,
    String? subcategory,
    int popularity = 0,
  }) async {
    await _firestore.collection('products').add({
      'name': name.trim(),
      'description': description.trim(),
      'price': price,
      'imageUrl': imageUrl.trim(),
      'category': category.trim(),
      'subcategory': subcategory != null && subcategory.trim().isNotEmpty
          ? subcategory.trim()
          : null,
      'popularity': popularity,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update an existing product
  Future<void> updateProduct({
    required String id,
    required String name,
    required String description,
    required double price,
    required String imageUrl,
    required String category,
    String? subcategory,
    required int popularity,
  }) async {
    await _firestore.collection('products').doc(id).update({
      'name': name.trim(),
      'description': description.trim(),
      'price': price,
      'imageUrl': imageUrl.trim(),
      'category': category.trim(),
      'subcategory': subcategory != null && subcategory.trim().isNotEmpty
          ? subcategory.trim()
          : null,
      'popularity': popularity,
    });
  }

  /// Delete a product
  Future<void> deleteProduct(String id) async {
    await _firestore.collection('products').doc(id).delete();
  }

  /// Create a new category or subcategory with duplicate check
  Future<void> createCategory({
    required String name,
    String? parentId,
  }) async {
    final trimmedName = name.trim();
    final lowerName = trimmedName.toLowerCase();

    // Query categories with the same parentId
    Query query = _firestore.collection('categories');
    if (parentId == null) {
      query = query.where('parentId', isNull: true);
    } else {
      query = query.where('parentId', isEqualTo: parentId);
    }

    final snapshot = await query.get();
    final isDuplicate = snapshot.docs.any((doc) {
      final existingName = (doc.data() as Map<String, dynamic>)['name'] as String? ?? '';
      return existingName.trim().toLowerCase() == lowerName;
    });

    if (isDuplicate) {
      throw Exception('A category with this name already exists');
    }

    final order = snapshot.docs.length;

    await _firestore.collection('categories').add({
      'name': trimmedName,
      'parentId': parentId,
      'order': order,
      'imageUrl': null,
    });
  }

  /// Rename category with product updates
  Future<void> renameCategory({
    required String categoryId,
    required String newName,
  }) async {
    final trimmedNewName = newName.trim();
    final lowerNewName = trimmedNewName.toLowerCase();

    final catDoc = await _firestore.collection('categories').doc(categoryId).get();
    if (!catDoc.exists) {
      throw Exception('Category not found');
    }

    final oldName = catDoc.data()?['name'] as String? ?? '';
    final parentId = catDoc.data()?['parentId'] as String?;

    // Check duplicate name within same parent
    Query query = _firestore.collection('categories');
    if (parentId == null) {
      query = query.where('parentId', isNull: true);
    } else {
      query = query.where('parentId', isEqualTo: parentId);
    }

    final parentSnapshot = await query.get();
    final isDuplicate = parentSnapshot.docs.any((doc) {
      if (doc.id == categoryId) return false;
      final existingName = (doc.data() as Map<String, dynamic>)['name'] as String? ?? '';
      return existingName.trim().toLowerCase() == lowerNewName;
    });

    if (isDuplicate) {
      throw Exception('A category with this name already exists');
    }

    final operations = <void Function(WriteBatch batch)>[];

    // Update the category document name
    operations.add((batch) {
      batch.update(catDoc.reference, {'name': trimmedNewName});
    });

    if (parentId == null) {
      // Top-level category: update products matching oldName category
      final productSnapshot = await _firestore
          .collection('products')
          .where('category', isEqualTo: oldName)
          .get();

      for (var doc in productSnapshot.docs) {
        operations.add((batch) {
          batch.update(doc.reference, {'category': trimmedNewName});
        });
      }
    } else {
      // Subcategory: fetch parent category name first
      final parentDoc =
          await _firestore.collection('categories').doc(parentId).get();
      final parentName = parentDoc.data()?['name'] as String? ?? '';

      final productSnapshot = await _firestore
          .collection('products')
          .where('category', isEqualTo: parentName)
          .where('subcategory', isEqualTo: oldName)
          .get();

      for (var doc in productSnapshot.docs) {
        operations.add((batch) {
          batch.update(doc.reference, {'subcategory': trimmedNewName});
        });
      }
    }

    await _commitInChunks(operations);
  }

  /// Delete category with cascade rule
  /// Deletes products first, then subcategories, then category document LAST.
  /// Returns the count of deleted products.
  Future<int> deleteCategory(String categoryId) async {
    final catDoc = await _firestore.collection('categories').doc(categoryId).get();
    if (!catDoc.exists) return 0;

    final catName = catDoc.data()?['name'] as String? ?? '';
    final parentId = catDoc.data()?['parentId'] as String?;

    final operations = <void Function(WriteBatch batch)>[];
    int deletedProductsCount = 0;

    if (parentId != null) {
      // Subcategory deletion
      final parentDoc =
          await _firestore.collection('categories').doc(parentId).get();
      final parentName = parentDoc.data()?['name'] as String? ?? '';

      final productSnapshot = await _firestore
          .collection('products')
          .where('category', isEqualTo: parentName)
          .where('subcategory', isEqualTo: catName)
          .get();

      deletedProductsCount = productSnapshot.docs.length;

      // 1. Delete products first
      for (var doc in productSnapshot.docs) {
        operations.add((batch) => batch.delete(doc.reference));
      }

      // 2. Delete subcategory document LAST
      operations.add((batch) => batch.delete(catDoc.reference));
    } else {
      // Top-level category deletion
      final subCatSnapshot = await _firestore
          .collection('categories')
          .where('parentId', isEqualTo: categoryId)
          .get();

      final productSnapshot = await _firestore
          .collection('products')
          .where('category', isEqualTo: catName)
          .get();

      deletedProductsCount = productSnapshot.docs.length;

      // 1. Delete products first
      for (var doc in productSnapshot.docs) {
        operations.add((batch) => batch.delete(doc.reference));
      }

      // 2. Delete subcategories
      for (var doc in subCatSnapshot.docs) {
        operations.add((batch) => batch.delete(doc.reference));
      }

      // 3. Delete category document LAST
      operations.add((batch) => batch.delete(catDoc.reference));
    }

    await _commitInChunks(operations);

    return deletedProductsCount;
  }

  /// Count products in a top-level category
  Future<int> countProductsInCategory(String categoryName) async {
    final snapshot = await _firestore
        .collection('products')
        .where('category', isEqualTo: categoryName)
        .get();
    return snapshot.docs.length;
  }

  /// Count products in a subcategory
  Future<int> countProductsInSubcategory(
    String categoryName,
    String subcategoryName,
  ) async {
    final snapshot = await _firestore
        .collection('products')
        .where('category', isEqualTo: categoryName)
        .where('subcategory', isEqualTo: subcategoryName)
        .get();
    return snapshot.docs.length;
  }

  /// Update order status (writes ONLY status field)
  Future<void> updateOrderStatus(String orderId, String status) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': status,
    });
  }

  /// Update payment status (writes ONLY paymentStatus field)
  Future<void> updatePaymentStatus(
    String orderId,
    String paymentStatus,
  ) async {
    await _firestore.collection('orders').doc(orderId).update({
      'paymentStatus': paymentStatus,
    });
  }

  /// Helper to commit write batch operations in chunks of at most 400 ops
  Future<void> _commitInChunks(
    List<void Function(WriteBatch batch)> operations,
  ) async {
    for (int i = 0; i < operations.length; i += 400) {
      final batch = _firestore.batch();
      final chunk = operations.sublist(
        i,
        (i + 400 < operations.length) ? i + 400 : operations.length,
      );
      for (final op in chunk) {
        op(batch);
      }
      await batch.commit();
    }
  }
}

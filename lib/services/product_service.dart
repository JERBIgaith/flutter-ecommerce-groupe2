import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';

/// Service for product and category operations
class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream all products
  Stream<List<ProductModel>> streamProducts() {
    return _firestore.collection('products').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => ProductModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Stream all categories
  Stream<List<CategoryModel>> streamCategories() {
    return _firestore.collection('categories').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => CategoryModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Get single product by ID
  Future<ProductModel?> getProduct(String id) async {
    try {
      final doc = await _firestore.collection('products').doc(id).get();
      if (!doc.exists) return null;
      return ProductModel.fromMap(doc.id, doc.data()!);
    } catch (e) {
      rethrow;
    }
  }
}

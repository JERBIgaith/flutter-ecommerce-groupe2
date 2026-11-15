/// Category model representing product categories and subcategories
class CategoryModel {
  final String id;
  final String name;
  final String? parentId;
  final int order;
  final String? imageUrl;

  CategoryModel({
    required this.id,
    required this.name,
    this.parentId,
    this.order = 0,
    this.imageUrl,
  });

  /// Check if this is a top-level category
  bool get isTopLevel => parentId == null;

  /// Convert CategoryModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'parentId': parentId,
      'order': order,
      'imageUrl': imageUrl,
    };
  }

  /// Create CategoryModel from Firestore document
  /// Tolerant of missing fields
  factory CategoryModel.fromMap(String id, Map<String, dynamic> map) {
    return CategoryModel(
      id: id,
      name: map['name'] as String? ?? '',
      parentId: map['parentId'] as String?,
      order: map['order'] as int? ?? 0,
      imageUrl: map['imageUrl'] as String?,
    );
  }
}

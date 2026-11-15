/// Cart item model representing a product in the cart
class CartItemModel {
  final String productId;
  final String name;
  final double price;
  final String imageUrl;
  final int quantity;

  CartItemModel({
    required this.productId,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.quantity,
  });

  /// Computed subtotal
  double get subtotal => price * quantity;

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'quantity': quantity,
    };
  }

  /// Create from Firestore document (tolerant of missing fields)
  factory CartItemModel.fromMap(String id, Map<String, dynamic> map) {
    double price = 0.0;
    if (map['price'] != null) {
      if (map['price'] is int) {
        price = (map['price'] as int).toDouble();
      } else if (map['price'] is double) {
        price = map['price'] as double;
      }
    }

    int quantity = 1;
    if (map['quantity'] != null) {
      if (map['quantity'] is int) {
        quantity = map['quantity'] as int;
      } else if (map['quantity'] is double) {
        quantity = (map['quantity'] as double).toInt();
      }
    }

    return CartItemModel(
      productId: id,
      name: map['name'] as String? ?? '',
      price: price,
      imageUrl: map['imageUrl'] as String? ?? '',
      quantity: quantity,
    );
  }

  /// Create a copy with updated fields
  CartItemModel copyWith({
    String? productId,
    String? name,
    double? price,
    String? imageUrl,
    int? quantity,
  }) {
    return CartItemModel(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
    );
  }
}

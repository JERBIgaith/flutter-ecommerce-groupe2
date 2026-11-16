import 'package:cloud_firestore/cloud_firestore.dart';

/// Item in an order
class OrderItem {
  final String productId;
  final String name;
  final double price;
  final String imageUrl;
  final int quantity;

  OrderItem({
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
  factory OrderItem.fromMap(Map<String, dynamic> map) {
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

    return OrderItem(
      productId: map['productId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      price: price,
      imageUrl: map['imageUrl'] as String? ?? '',
      quantity: quantity,
    );
  }
}

/// Model representing a user order
class OrderModel {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double total;
  final String status;
  final DateTime? createdAt;
  final String paymentMethod;
  final String paymentStatus;
  final String? paymentReference;
  final String deliveryAddress;
  final String phone;

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.total,
    required this.status,
    this.createdAt,
    required this.paymentMethod,
    required this.paymentStatus,
    this.paymentReference,
    required this.deliveryAddress,
    required this.phone,
  });

  /// Helpers
  bool get isPending => status == 'pending';
  bool get canCancel => status == 'pending';

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'status': status,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'paymentReference': paymentReference,
      'deliveryAddress': deliveryAddress,
      'phone': phone,
    };
  }

  /// Create OrderModel from Firestore document (tolerant of missing fields)
  factory OrderModel.fromMap(String id, Map<String, dynamic> map) {
    double total = 0.0;
    if (map['total'] != null) {
      if (map['total'] is int) {
        total = (map['total'] as int).toDouble();
      } else if (map['total'] is double) {
        total = map['total'] as double;
      }
    }

    List<OrderItem> itemsList = [];
    if (map['items'] is List) {
      itemsList = (map['items'] as List)
          .map((item) =>
              OrderItem.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList();
    }

    DateTime? createdAtDate;
    if (map['createdAt'] != null) {
      if (map['createdAt'] is Timestamp) {
        createdAtDate = (map['createdAt'] as Timestamp).toDate();
      } else if (map['createdAt'] is String) {
        createdAtDate = DateTime.tryParse(map['createdAt'] as String);
      }
    }

    return OrderModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      items: itemsList,
      total: total,
      status: map['status'] as String? ?? 'pending',
      createdAt: createdAtDate,
      paymentMethod: map['paymentMethod'] as String? ?? 'cash_on_delivery',
      paymentStatus: map['paymentStatus'] as String? ?? 'unpaid',
      paymentReference: map['paymentReference'] as String?,
      deliveryAddress: map['deliveryAddress'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
    );
  }
}

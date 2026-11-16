import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

/// Service for handling order Firestore operations
class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream user orders (no composite index query - sorted client side)
  Stream<List<OrderModel>> streamUserOrders(String uid) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  /// Create order document AND clear user cart in a single batch operation
  Future<OrderModel> createOrder({
    required String userId,
    required List<OrderItem> items,
    required double total,
    required String paymentMethod,
    required String deliveryAddress,
    required String phone,
  }) async {
    final batch = _firestore.batch();
    final orderRef = _firestore.collection('orders').doc();

    final orderData = {
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'paymentMethod': paymentMethod,
      'paymentStatus': 'unpaid',
      'paymentReference': null,
      'deliveryAddress': deliveryAddress,
      'phone': phone,
    };

    batch.set(orderRef, orderData);

    // Get all cart items to delete in the same batch
    final cartSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .get();

    for (var doc in cartSnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();

    return OrderModel(
      id: orderRef.id,
      userId: userId,
      items: items,
      total: total,
      status: 'pending',
      createdAt: DateTime.now(),
      paymentMethod: paymentMethod,
      paymentStatus: 'unpaid',
      paymentReference: null,
      deliveryAddress: deliveryAddress,
      phone: phone,
    );
  }

  /// Cancel an order (only while pending)
  Future<void> cancelOrder(String orderId) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': 'cancelled',
    });
  }

  /// Submit payment reference for D17 payment
  Future<void> submitPaymentReference(
    String orderId,
    String reference,
  ) async {
    await _firestore.collection('orders').doc(orderId).update({
      'paymentReference': reference,
      'paymentStatus': 'pending_verification',
    });
  }
}

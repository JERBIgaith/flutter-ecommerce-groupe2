import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

/// Controller for managing order operations and state
class OrderController extends ChangeNotifier {
  final OrderService _orderService = OrderService();

  List<OrderModel> _orders = [];
  StreamSubscription? _ordersSubscription;
  bool _isLoading = false;
  String? _errorMessage;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Start listening to user orders stream
  void listenToOrders(String userId) {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _ordersSubscription?.cancel();
    _ordersSubscription = _orderService.streamUserOrders(userId).listen(
      (orderList) {
        // Client-side sort by createdAt descending (newest first)
        orderList.sort((a, b) {
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return -1;
          if (b.createdAt == null) return 1;
          return b.createdAt!.compareTo(a.createdAt!);
        });

        _orders = orderList;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error streaming orders: $error');
        _errorMessage = 'Failed to load orders';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Stop listening to user orders
  void stopListening() {
    _ordersSubscription?.cancel();
    _ordersSubscription = null;
    _orders = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Place a new order
  Future<OrderModel?> placeOrder({
    required String userId,
    required List<OrderItem> items,
    required double total,
    required String paymentMethod,
    required String deliveryAddress,
    required String phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newOrder = await _orderService.createOrder(
        userId: userId,
        items: items,
        total: total,
        paymentMethod: paymentMethod,
        deliveryAddress: deliveryAddress,
        phone: phone,
      );
      return newOrder;
    } catch (e) {
      debugPrint('Error placing order: $e');
      _errorMessage = 'Failed to place order';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cancel an order
  Future<bool> cancelOrder(String orderId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _orderService.cancelOrder(orderId);
      return true;
    } catch (e) {
      debugPrint('Error cancelling order: $e');
      _errorMessage = 'Failed to cancel order';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Submit payment reference for D17 order
  Future<bool> submitPaymentReference(String orderId, String reference) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _orderService.submitPaymentReference(orderId, reference);
      return true;
    } catch (e) {
      debugPrint('Error submitting payment reference: $e');
      _errorMessage = 'Failed to submit payment reference';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}

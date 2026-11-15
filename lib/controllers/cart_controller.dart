import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/cart_item_model.dart';
import '../services/cart_service.dart';

/// Cart controller managing user cart
class CartController extends ChangeNotifier {
  final CartService _cartService = CartService();

  List<CartItemModel> _items = [];
  StreamSubscription? _cartSubscription;
  bool _isLoading = false;
  String? _errorMessage;

  List<CartItemModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Total number of items (sum of quantities)
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  /// Total price of all items
  double get total => _items.fold(0, (sum, item) => sum + item.subtotal);

  /// Start listening to cart
  void listenToCart(String userId) {
    _cartSubscription = _cartService.streamCart(userId).listen(
      (items) {
        _items = items;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error streaming cart: $error');
        _errorMessage = 'Failed to load cart';
        notifyListeners();
      },
    );
  }

  /// Stop listening to cart
  void stopListening() {
    _cartSubscription?.cancel();
    _items = [];
    _errorMessage = null;
    notifyListeners();
  }

  /// Add item to cart
  Future<void> addToCart(
    String userId,
    String productId,
    String name,
    double price,
    String imageUrl,
    int quantity,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _cartService.addToCart(
        userId,
        productId,
        name,
        price,
        imageUrl,
        quantity,
      );
    } catch (e) {
      debugPrint('Error adding to cart: $e');
      _errorMessage = 'Failed to add to cart';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update item quantity
  Future<void> updateQuantity(
    String userId,
    String productId,
    int quantity,
  ) async {
    try {
      await _cartService.updateQuantity(userId, productId, quantity);
    } catch (e) {
      debugPrint('Error updating quantity: $e');
      _errorMessage = 'Failed to update quantity';
      notifyListeners();
      rethrow;
    }
  }

  /// Remove item from cart
  Future<void> removeItem(String userId, String productId) async {
    try {
      await _cartService.removeFromCart(userId, productId);
    } catch (e) {
      debugPrint('Error removing item: $e');
      _errorMessage = 'Failed to remove item';
      notifyListeners();
      rethrow;
    }
  }

  /// Clear entire cart
  Future<void> clearCart(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _cartService.clearCart(userId);
    } catch (e) {
      debugPrint('Error clearing cart: $e');
      _errorMessage = 'Failed to clear cart';
      rethrow;
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

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../services/admin_service.dart';

/// Controller for Admin state, streaming users and orders, and actions
class AdminController extends ChangeNotifier {
  final AdminService _adminService = AdminService();

  List<UserModel> _users = [];
  List<OrderModel> _allOrders = [];
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription? _usersSubscription;
  StreamSubscription? _ordersSubscription;

  List<UserModel> get users => _users;
  List<OrderModel> get allOrders => _allOrders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Computed dashboard metrics
  int get totalUsers => _users.length;
  int get totalOrders => _allOrders.length;
  int get pendingOrders =>
      _allOrders.where((o) => o.status == 'pending').length;
  int get pendingPaymentVerificationOrders => _allOrders
      .where((o) => o.paymentStatus == 'pending_verification')
      .length;

  /// Revenue sum of totals of orders that are not cancelled and are delivered or paid
  double get revenue => _allOrders
      .where((o) =>
          o.status != 'cancelled' &&
          (o.status == 'delivered' || o.paymentStatus == 'paid'))
      .fold(0.0, (sum, o) => sum + o.total);

  /// Latest 5 orders sorted by createdAt descending
  List<OrderModel> get latestOrders {
    final list = List<OrderModel>.from(_allOrders);
    list.sort((a, b) {
      if (a.createdAt == null && b.createdAt == null) return 0;
      if (a.createdAt == null) return -1;
      if (b.createdAt == null) return 1;
      return b.createdAt!.compareTo(a.createdAt!);
    });
    return list.take(5).toList();
  }

  /// Start listening to users stream
  void listenToUsers() {
    _usersSubscription?.cancel();
    _usersSubscription = _adminService.streamUsers().listen(
      (userList) {
        userList.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        _users = userList;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error streaming users: $error');
        _errorMessage = 'Failed to load users';
        notifyListeners();
      },
    );
  }

  /// Start listening to all orders stream
  void listenToAllOrders() {
    _ordersSubscription?.cancel();
    _ordersSubscription = _adminService.streamAllOrders().listen(
      (orderList) {
        orderList.sort((a, b) {
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return -1;
          if (b.createdAt == null) return 1;
          return b.createdAt!.compareTo(a.createdAt!);
        });
        _allOrders = orderList;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error streaming orders: $error');
        _errorMessage = 'Failed to load orders';
        notifyListeners();
      },
    );
  }

  /// Stop listening to streams
  void stopListening() {
    _usersSubscription?.cancel();
    _ordersSubscription?.cancel();
    _usersSubscription = null;
    _ordersSubscription = null;
    _users = [];
    _allOrders = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Create product
  Future<bool> createProduct({
    required String name,
    required String description,
    required double price,
    required String imageUrl,
    required String category,
    String? subcategory,
    int popularity = 0,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _adminService.createProduct(
        name: name,
        description: description,
        price: price,
        imageUrl: imageUrl,
        category: category,
        subcategory: subcategory,
        popularity: popularity,
      );
      return true;
    } catch (e) {
      debugPrint('Error creating product: $e');
      _errorMessage = 'Failed to create product';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update product
  Future<bool> updateProduct({
    required String id,
    required String name,
    required String description,
    required double price,
    required String imageUrl,
    required String category,
    String? subcategory,
    required int popularity,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _adminService.updateProduct(
        id: id,
        name: name,
        description: description,
        price: price,
        imageUrl: imageUrl,
        category: category,
        subcategory: subcategory,
        popularity: popularity,
      );
      return true;
    } catch (e) {
      debugPrint('Error updating product: $e');
      _errorMessage = 'Failed to update product';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete product
  Future<bool> deleteProduct(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _adminService.deleteProduct(id);
      return true;
    } catch (e) {
      debugPrint('Error deleting product: $e');
      _errorMessage = 'Failed to delete product';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create category
  Future<bool> createCategory({
    required String name,
    String? parentId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _adminService.createCategory(
        name: name,
        parentId: parentId,
      );
      return true;
    } catch (e) {
      debugPrint('Error creating category: $e');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Rename category
  Future<bool> renameCategory({
    required String categoryId,
    required String newName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _adminService.renameCategory(
        categoryId: categoryId,
        newName: newName,
      );
      return true;
    } catch (e) {
      debugPrint('Error renaming category: $e');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete category (returns deleted products count, or null if error)
  Future<int?> deleteCategory(String categoryId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final count = await _adminService.deleteCategory(categoryId);
      return count;
    } catch (e) {
      debugPrint('Error deleting category: $e');
      _errorMessage = 'Failed to delete category';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Count products in top category
  Future<int> countProductsInCategory(String categoryName) async {
    try {
      return await _adminService.countProductsInCategory(categoryName);
    } catch (e) {
      return 0;
    }
  }

  /// Count products in subcategory
  Future<int> countProductsInSubcategory(
    String categoryName,
    String subcategoryName,
  ) async {
    try {
      return await _adminService.countProductsInSubcategory(
        categoryName,
        subcategoryName,
      );
    } catch (e) {
      return 0;
    }
  }

  /// Update order status
  Future<bool> updateOrderStatus(String orderId, String status) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _adminService.updateOrderStatus(orderId, status);
      return true;
    } catch (e) {
      debugPrint('Error updating order status: $e');
      _errorMessage = 'Failed to update order status';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update payment status
  Future<bool> updatePaymentStatus(String orderId, String paymentStatus) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _adminService.updatePaymentStatus(orderId, paymentStatus);
      return true;
    } catch (e) {
      debugPrint('Error updating payment status: $e');
      _errorMessage = 'Failed to update payment status';
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

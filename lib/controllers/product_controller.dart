import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../services/product_service.dart';

/// Sort options for products
enum ProductSort { popularity, newest, priceAsc, priceDesc }

/// Product controller managing product state, filtering, and sorting
class ProductController extends ChangeNotifier {
  final ProductService _productService = ProductService();

  List<ProductModel> _allProducts = [];
  List<CategoryModel> _allCategories = [];
  String? _selectedCategory;
  String? _selectedSubcategory;
  String _searchQuery = '';
  ProductSort _sort = ProductSort.popularity;
  double? _priceRangeStart;
  double? _priceRangeEnd;
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription? _productsSubscription;
  StreamSubscription? _categoriesSubscription;
  Timer? _debounceTimer;

  // Getters
  List<ProductModel> get allProducts => _allProducts;
  String? get selectedCategory => _selectedCategory;
  String? get selectedSubcategory => _selectedSubcategory;
  String get searchQuery => _searchQuery;
  ProductSort get sort => _sort;
  double? get priceRangeStart => _priceRangeStart;
  double? get priceRangeEnd => _priceRangeEnd;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Get top-level categories, ordered
  List<CategoryModel> get categories {
    final topLevel =
        _allCategories.where((cat) => cat.isTopLevel).toList();
    topLevel.sort((a, b) => a.order.compareTo(b.order));
    return topLevel;
  }

  /// Get subcategories of a category, ordered
  List<CategoryModel> subcategoriesOf(String categoryId) {
    final subs = _allCategories
        .where((cat) => cat.parentId == categoryId)
        .toList();
    subs.sort((a, b) => a.order.compareTo(b.order));
    return subs;
  }

  /// Get minimum price from loaded products
  double get minPrice {
    if (_allProducts.isEmpty) return 0.0;
    return _allProducts.map((p) => p.price).reduce((a, b) => a < b ? a : b);
  }

  /// Get maximum price from loaded products
  double get maxPrice {
    if (_allProducts.isEmpty) return 1000.0;
    return _allProducts.map((p) => p.price).reduce((a, b) => a > b ? a : b);
  }

  /// Check if any filters are active
  bool get hasActiveFilters {
    return _selectedCategory != null ||
        _selectedSubcategory != null ||
        _searchQuery.isNotEmpty ||
        _priceRangeStart != null ||
        _priceRangeEnd != null;
  }

  /// Get filtered and sorted products
  List<ProductModel> get products {
    List<ProductModel> result = List.from(_allProducts);

    // Filter by category
    if (_selectedCategory != null) {
      result = result.where((p) => p.category == _selectedCategory).toList();
    }

    // Filter by subcategory
    if (_selectedSubcategory != null) {
      result =
          result.where((p) => p.subcategory == _selectedSubcategory).toList();
    }

    // Filter by price range
    if (_priceRangeStart != null) {
      result = result.where((p) => p.price >= _priceRangeStart!).toList();
    }
    if (_priceRangeEnd != null) {
      result = result.where((p) => p.price <= _priceRangeEnd!).toList();
    }

    // Filter by search query (case and accent insensitive, multi-word)
    if (_searchQuery.isNotEmpty) {
      final words = _searchQuery
          .toLowerCase()
          .split(' ')
          .where((w) => w.isNotEmpty)
          .toList();

      result = result.where((product) {
        final searchText = [
          product.name,
          product.description,
          product.category,
          product.subcategory ?? '',
        ].join(' ').toLowerCase();

        // Remove accents
        final normalized = _removeAccents(searchText);

        // Every word must match
        return words.every((word) {
          final normalizedWord = _removeAccents(word);
          return normalized.contains(normalizedWord);
        });
      }).toList();
    }

    // Sort
    switch (_sort) {
      case ProductSort.popularity:
        result.sort((a, b) => b.popularity.compareTo(a.popularity));
        break;
      case ProductSort.newest:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case ProductSort.priceAsc:
        result.sort((a, b) => a.price.compareTo(b.price));
        break;
      case ProductSort.priceDesc:
        result.sort((a, b) => b.price.compareTo(a.price));
        break;
    }

    return result;
  }

  /// Remove accents from text for search
  String _removeAccents(String text) {
    const withAccents = 'àáâãäåçèéêëìíîïñòóôõöùúûüýÿ';
    const withoutAccents = 'aaaaaaceeeeiiiinooooouuuuyy';

    String result = text;
    for (int i = 0; i < withAccents.length; i++) {
      result = result.replaceAll(withAccents[i], withoutAccents[i]);
    }
    return result;
  }

  /// Start listening to products
  void listenToProducts() {
    _isLoading = true;
    notifyListeners();

    _productsSubscription = _productService.streamProducts().listen(
      (products) {
        _allProducts = products;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error streaming products: $error');
        _errorMessage = 'Failed to load products';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Start listening to categories
  void listenToCategories() {
    _categoriesSubscription = _productService.streamCategories().listen(
      (categories) {
        _allCategories = categories;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error streaming categories: $error');
      },
    );
  }

  /// Stop listening to streams
  void stopListening() {
    _productsSubscription?.cancel();
    _categoriesSubscription?.cancel();
    _debounceTimer?.cancel();
  }

  /// Select a category
  void selectCategory(String? category) {
    _selectedCategory = category;
    _selectedSubcategory = null;
    notifyListeners();
  }

  /// Select a subcategory
  void selectSubcategory(String? subcategory) {
    _selectedSubcategory = subcategory;
    notifyListeners();
  }

  /// Set search query with debounce (300 ms)
  void setSearchQuery(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _searchQuery = query;
      notifyListeners();
    });
  }

  /// Set sort option
  void setSort(ProductSort newSort) {
    _sort = newSort;
    notifyListeners();
  }

  /// Set price range
  void setPriceRange(double? start, double? end) {
    _priceRangeStart = start;
    _priceRangeEnd = end;
    notifyListeners();
  }

  /// Clear all filters
  void clearAllFilters() {
    _selectedCategory = null;
    _selectedSubcategory = null;
    _searchQuery = '';
    _priceRangeStart = null;
    _priceRangeEnd = null;
    _sort = ProductSort.popularity;
    notifyListeners();
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}

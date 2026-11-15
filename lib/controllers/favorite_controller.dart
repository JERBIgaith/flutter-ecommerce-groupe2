import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/favorite_model.dart';
import '../services/favorite_service.dart';

/// Favorite controller managing user favorites
class FavoriteController extends ChangeNotifier {
  final FavoriteService _favoriteService = FavoriteService();

  List<FavoriteModel> _favorites = [];
  StreamSubscription? _favoritesSubscription;

  List<FavoriteModel> get favorites => _favorites;
  int get count => _favorites.length;

  /// Check if a product is favorited
  bool isFavorite(String productId) {
    return _favorites.any((fav) => fav.productId == productId);
  }

  /// Start listening to favorites
  void listenToFavorites(String userId) {
    _favoritesSubscription = _favoriteService.streamFavorites(userId).listen(
      (favorites) {
        _favorites = favorites;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error streaming favorites: $error');
      },
    );
  }

  /// Stop listening to favorites
  void stopListening() {
    _favoritesSubscription?.cancel();
    _favorites = [];
    notifyListeners();
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(
    String userId,
    String productId,
    String name,
    double price,
    String imageUrl,
  ) async {
    try {
      final isFav = isFavorite(productId);
      await _favoriteService.toggleFavorite(
        userId,
        productId,
        isFav,
        name,
        price,
        imageUrl,
      );
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}

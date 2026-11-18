import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/comment_model.dart';
import '../services/comment_service.dart';

/// Controller for managing product comments state and actions
class CommentController extends ChangeNotifier {
  final CommentService _commentService = CommentService();

  List<CommentModel> _comments = [];
  StreamSubscription? _subscription;
  String? _currentProductId;
  bool _isLoading = false;
  String? _errorMessage;

  List<CommentModel> get comments => _comments;
  int get count => _comments.length;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Start listening to comments for a product (cancels any active stream)
  void listenToComments(String productId) {
    if (_currentProductId == productId && _subscription != null) {
      return;
    }

    stopListening();
    _currentProductId = productId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _subscription = _commentService.streamComments(productId).listen(
      (commentList) {
        // Client-side sort by createdAt descending (newest first)
        commentList.sort((a, b) {
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return -1;
          if (b.createdAt == null) return 1;
          return b.createdAt!.compareTo(a.createdAt!);
        });

        _comments = commentList;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error streaming comments: $error');
        _errorMessage = 'Failed to load comments';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Stop listening to comments stream
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _currentProductId = null;
    _comments = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Add a new comment
  Future<bool> addComment({
    required String productId,
    required String userId,
    required String userName,
    required String text,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _commentService.addComment(
        productId: productId,
        userId: userId,
        userName: userName,
        text: text,
      );
      return true;
    } catch (e) {
      debugPrint('Error adding comment: $e');
      _errorMessage = 'Failed to add comment';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update an existing comment
  Future<bool> updateComment({
    required String productId,
    required String commentId,
    required String text,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _commentService.updateComment(
        productId: productId,
        commentId: commentId,
        text: text,
      );
      return true;
    } catch (e) {
      debugPrint('Error updating comment: $e');
      _errorMessage = 'Failed to update comment';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete a comment
  Future<bool> deleteComment({
    required String productId,
    required String commentId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _commentService.deleteComment(
        productId: productId,
        commentId: commentId,
      );
      return true;
    } catch (e) {
      debugPrint('Error deleting comment: $e');
      _errorMessage = 'Failed to delete comment';
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

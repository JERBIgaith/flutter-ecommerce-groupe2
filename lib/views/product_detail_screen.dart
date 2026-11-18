import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/product_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/favorite_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/comment_controller.dart';
import '../models/product_model.dart';
import '../models/comment_model.dart';
import '../widgets/app_network_image.dart';
import '../widgets/guest_guard.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  final _commentTextController = TextEditingController();
  final _commentFormKey = GlobalKey<FormState>();
  bool _isPostingComment = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommentController>().listenToComments(widget.productId);
    });
  }

  @override
  void dispose() {
    _commentTextController.dispose();
    super.dispose();
  }

  Future<void> _handlePostComment() async {
    if (!_commentFormKey.currentState!.validate()) return;

    final authController = context.read<AuthController>();
    final commentController = context.read<CommentController>();
    final profile = authController.profile;
    final userId = profile?.uid;

    if (userId == null) return;

    String userName = 'User';
    if (profile != null && profile.name.trim().isNotEmpty) {
      userName = profile.name.trim();
    } else if (profile != null && profile.email.contains('@')) {
      userName = profile.email.split('@').first;
    }

    setState(() {
      _isPostingComment = true;
    });

    final text = _commentTextController.text.trim();
    final success = await commentController.addComment(
      productId: widget.productId,
      userId: userId,
      userName: userName,
      text: text,
    );

    if (!mounted) return;

    setState(() {
      _isPostingComment = false;
    });

    if (success) {
      _commentTextController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment posted successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            commentController.errorMessage ?? 'Failed to post comment',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _showEditCommentDialog(CommentModel comment) async {
    final textController = TextEditingController(text: comment.text);
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Comment'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: textController,
            maxLines: 3,
            maxLength: 500,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Edit your comment...',
              border: OutlineInputBorder(),
            ),
            validator: Validators.commentText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      final commentController = context.read<CommentController>();
      final success = await commentController.updateComment(
        productId: widget.productId,
        commentId: comment.id,
        text: textController.text.trim(),
      );

      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment updated successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              commentController.errorMessage ?? 'Failed to update comment',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteComment(CommentModel comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text(
          'Are you sure you want to delete this comment? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      final commentController = context.read<CommentController>();
      final success = await commentController.deleteComment(
        productId: widget.productId,
        commentId: comment.id,
      );

      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment deleted'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              commentController.errorMessage ?? 'Failed to delete comment',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productController = context.watch<ProductController>();
    final authController = context.watch<AuthController>();
    final favoriteController = context.watch<FavoriteController>();
    final cartController = context.watch<CartController>();
    final commentController = context.watch<CommentController>();

    final product = productController.allProducts
        .cast<ProductModel?>()
        .firstWhere((p) => p?.id == widget.productId, orElse: () => null);

    if (product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('Product not found'),
        ),
      );
    }

    final isFavorite = favoriteController.isFavorite(product.id);
    final isGuest = authController.isGuest;
    final currentUserId = authController.profile?.uid;

    final comments = commentController.comments;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero image in SliverAppBar with favorite button
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: AppNetworkImage(
                url: product.imageUrl,
                fit: BoxFit.cover,
              ),
            ),
            actions: [
              // Favorite button
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? AppColors.error : null,
                ),
                onPressed: () async {
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  final allowed =
                      await GuestGuard.check(context, isGuest: isGuest);
                  if (!allowed) return;

                  final userId = authController.profile?.uid;
                  if (userId == null) return;

                  try {
                    await favoriteController.toggleFavorite(
                      userId,
                      product.id,
                      product.name,
                      product.price,
                      product.imageUrl,
                    );
                  } catch (e) {
                    if (mounted) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text('Failed to update favorite: $e'),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),

          // Product details and Comments section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),

                  // Price
                  Text(
                    formatPrice(product.price),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Category chips
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        label: Text(product.category),
                        avatar: const Icon(Icons.category, size: 18),
                      ),
                      if (product.subcategory != null)
                        Chip(
                          label: Text(product.subcategory!),
                          avatar: const Icon(Icons.label, size: 18),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Description
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),

                  // Quantity selector
                  Text(
                    'Quantity',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton.outlined(
                        icon: const Icon(Icons.remove),
                        onPressed: _quantity > 1
                            ? () {
                                setState(() {
                                  _quantity--;
                                });
                              }
                            : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Text(
                          '$_quantity',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton.outlined(
                        icon: const Icon(Icons.add),
                        onPressed: _quantity < 99
                            ? () {
                                setState(() {
                                  _quantity++;
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Add to cart button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: cartController.isLoading
                          ? null
                          : () async {
                              final scaffoldMessenger =
                                  ScaffoldMessenger.of(context);
                              final allowed = await GuestGuard.check(
                                context,
                                isGuest: isGuest,
                              );
                              if (!allowed) return;

                              final userId = authController.profile?.uid;
                              if (userId == null) return;

                              try {
                                await cartController.addToCart(
                                  userId,
                                  product.id,
                                  product.name,
                                  product.price,
                                  product.imageUrl,
                                  _quantity,
                                );
                                if (mounted) {
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Added $_quantity ${_quantity == 1 ? 'item' : 'items'} to cart',
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                  setState(() {
                                    _quantity = 1;
                                  });
                                }
                              } catch (e) {
                                if (mounted) {
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to add to cart: $e'),
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                              }
                            },
                      icon: cartController.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.shopping_cart),
                      label: Text(
                        cartController.isLoading ? 'Adding...' : 'Add to cart',
                      ),
                    ),
                  ),
                  const Divider(height: 48),

                  // Comments Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Comments (${commentController.count})',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Comments Input / Guest Prompt
                  if (isGuest)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Icon(Icons.comment_outlined),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text('Log in to leave a comment'),
                            ),
                            FilledButton(
                              onPressed: () => GuestGuard.check(
                                context,
                                isGuest: true,
                              ),
                              child: const Text('Log in'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Form(
                      key: _commentFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          TextFormField(
                            controller: _commentTextController,
                            maxLines: 3,
                            maxLength: 500,
                            decoration: const InputDecoration(
                              hintText: 'Write a comment...',
                              border: OutlineInputBorder(),
                            ),
                            validator: Validators.commentText,
                          ),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed:
                                _isPostingComment ? null : _handlePostComment,
                            icon: _isPostingComment
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.send, size: 18),
                            label: Text(
                              _isPostingComment ? 'Posting...' : 'Post comment',
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Comments List
                  if (commentController.isLoading && comments.isEmpty)
                    const Center(child: CircularProgressIndicator())
                  else if (comments.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'No comments yet. Be the first to comment!',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    )
                  else
                    ...comments.map((comment) {
                      final isOwner = currentUserId == comment.userId;
                      final initial = comment.userName.isNotEmpty
                          ? comment.userName[0].toUpperCase()
                          : 'U';

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                    child: Text(
                                      initial,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              comment.userName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (comment.isEdited) ...[
                                              const SizedBox(width: 6),
                                              Text(
                                                '(edited)',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      fontStyle:
                                                          FontStyle.italic,
                                                    ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        Text(
                                          formatDateTime(comment.createdAt),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isOwner)
                                    PopupMenuButton<String>(
                                      icon: const Icon(
                                        Icons.more_vert,
                                        size: 20,
                                      ),
                                      onSelected: (val) {
                                        if (val == 'edit') {
                                          _showEditCommentDialog(comment);
                                        } else if (val == 'delete') {
                                          _handleDeleteComment(comment);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit, size: 18),
                                              SizedBox(width: 8),
                                              Text('Edit'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.delete,
                                                size: 18,
                                                color: AppColors.error,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Delete',
                                                style: TextStyle(
                                                  color: AppColors.error,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                comment.text,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

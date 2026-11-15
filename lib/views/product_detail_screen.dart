import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/product_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/favorite_controller.dart';
import '../controllers/cart_controller.dart';
import '../models/product_model.dart';
import '../widgets/app_network_image.dart';
import '../widgets/guest_guard.dart';
import '../utils/constants.dart';

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

  @override
  Widget build(BuildContext context) {
    final productController = context.watch<ProductController>();
    final authController = context.watch<AuthController>();
    final favoriteController = context.watch<FavoriteController>();
    final cartController = context.watch<CartController>();
    
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

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero image in SliverAppBar with favorite button
          SliverAppBar(
            expandedHeight: 400,
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
                  color: isFavorite ? Colors.red : null,
                ),
                onPressed: () async {
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  final allowed = await GuestGuard.check(context, isGuest: isGuest);
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

          // Product details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
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
                  const SizedBox(height: 16),

                  // Price
                  Text(
                    formatPrice(product.price),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),

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
                  const SizedBox(height: 24),

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
                  const SizedBox(height: 32),

                  // Quantity selector
                  Text(
                    'Quantity',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
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
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
                  const SizedBox(height: 32),

                  // Add to cart button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: cartController.isLoading
                          ? null
                          : () async {
                              final scaffoldMessenger = ScaffoldMessenger.of(context);
                              final allowed = await GuestGuard.check(context, isGuest: isGuest);
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
                                      content: Text('Added $_quantity ${_quantity == 1 ? 'item' : 'items'} to cart'),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                  // Reset quantity
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
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

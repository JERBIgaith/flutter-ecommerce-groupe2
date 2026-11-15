import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/favorite_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/product_controller.dart';
import '../widgets/app_network_image.dart';
import '../utils/constants.dart';
import 'product_detail_screen.dart';
import 'register_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final favoriteController = context.watch<FavoriteController>();
    final productController = context.watch<ProductController>();
    final isGuest = authController.isGuest;

    // Show guest prompt for anonymous users
    if (isGuest) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Saved'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite_border,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 24),
                Text(
                  'Save your favorite items',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Create an account to save products and access them from any device',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () async {
                    await authController.logout();
                    if (!context.mounted) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const RegisterScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Create account'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => authController.logout(),
                  icon: const Icon(Icons.login),
                  label: const Text('Log in'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final favorites = favoriteController.favorites;

    // Empty state
    if (favorites.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Saved'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite_border,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 24),
                Text(
                  'No saved items yet',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  'Start saving your favorite products',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          final favorite = favorites[index];
          
          // Check if product still exists
          final productExists = productController.allProducts
              .any((p) => p.id == favorite.productId);

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: InkWell(
              onTap: productExists
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ProductDetailScreen(
                            productId: favorite.productId,
                          ),
                        ),
                      );
                    }
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // Product image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AppNetworkImage(
                        url: favorite.imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Product info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            favorite.name,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatPrice(favorite.price),
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (!productExists) ...[
                            const SizedBox(height: 4),
                            Text(
                              'No longer available',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Actions
                    Column(
                      children: [
                        // Add to cart button
                        if (productExists)
                          IconButton(
                            icon: const Icon(Icons.shopping_cart_outlined),
                            onPressed: () async {
                              final userId = authController.profile?.uid;
                              if (userId == null) return;

                              final cartController = context.read<CartController>();
                              try {
                                await cartController.addToCart(
                                  userId,
                                  favorite.productId,
                                  favorite.name,
                                  favorite.price,
                                  favorite.imageUrl,
                                  1,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Added to cart'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to add to cart: $e'),
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                              }
                            },
                            tooltip: 'Add to cart',
                          ),
                        // Remove button
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            final userId = authController.profile?.uid;
                            if (userId == null) return;

                            try {
                              await favoriteController.toggleFavorite(
                                userId,
                                favorite.productId,
                                favorite.name,
                                favorite.price,
                                favorite.imageUrl,
                              );
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to remove: $e'),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            }
                          },
                          tooltip: 'Remove',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

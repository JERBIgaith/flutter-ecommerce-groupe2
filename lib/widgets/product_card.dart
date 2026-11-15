import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../controllers/auth_controller.dart';
import '../controllers/favorite_controller.dart';
import '../utils/constants.dart';
import 'app_network_image.dart';
import 'guest_guard.dart';

/// Product card widget for grid display
class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final favoriteController = context.watch<FavoriteController>();
    final isFavorite = favoriteController.isFavorite(product.id);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image with favorite button
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: AppNetworkImage(
                      url: product.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Favorite button
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite
                              ? Theme.of(context).colorScheme.error
                              : null,
                        ),
                        onPressed: () async {
                          final isGuest = authController.isGuest;
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
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to update favorite: $e'),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Product info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Product name
                    Flexible(
                      child: Text(
                        product.name,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Product price
                    Text(
                      formatPrice(product.price),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/product_controller.dart';
import '../widgets/app_network_image.dart';
import '../widgets/guest_guard.dart';
import '../utils/constants.dart';
import 'register_screen.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final cartController = context.watch<CartController>();
    final productController = context.watch<ProductController>();
    final isGuest = authController.isGuest;

    // Show guest prompt for anonymous users
    if (isGuest) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Cart'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 24),
                Text(
                  'Your shopping cart',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Create an account to save items in your cart and checkout',
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

    final items = cartController.items;

    // Empty state
    if (items.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Cart'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 24),
                Text(
                  'Your cart is empty',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  'Add items to your cart to get started',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final userId = authController.profile?.uid;
    if (userId == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              // Show confirmation dialog
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear cart'),
                  content: const Text('Remove all items from your cart?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                try {
                  await cartController.clearCart(userId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cart cleared'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to clear cart: $e'),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              }
            },
            icon: const Icon(Icons.delete_sweep),
            label: const Text('Clear'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Cart items list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                
                // Check if product still exists
                final productExists = productController.allProducts
                    .any((p) => p.id == item.productId);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        // Product image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AppNetworkImage(
                            url: item.imageUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Product info and quantity controls
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: Theme.of(context).textTheme.titleMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatPrice(item.price),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
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
                              const SizedBox(height: 8),
                              // Quantity controls
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    onPressed: item.quantity > 1
                                        ? () async {
                                            try {
                                              await cartController.updateQuantity(
                                                userId,
                                                item.productId,
                                                item.quantity - 1,
                                              );
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Failed to update: $e'),
                                                    duration: const Duration(seconds: 3),
                                                  ),
                                                );
                                              }
                                            }
                                          }
                                        : null,
                                  ),
                                  Text(
                                    '${item.quantity}',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: productExists && item.quantity < 99
                                        ? () async {
                                            try {
                                              await cartController.updateQuantity(
                                                userId,
                                                item.productId,
                                                item.quantity + 1,
                                              );
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Failed to update: $e'),
                                                    duration: const Duration(seconds: 3),
                                                  ),
                                                );
                                              }
                                            }
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Subtotal and remove button
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatPrice(item.subtotal),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                try {
                                  await cartController.removeItem(userId, item.productId);
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
                );
              },
            ),
          ),

          // Total and checkout section
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      formatPrice(cartController.total),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: items.isEmpty
                        ? null
                        : () => _proceedToCheckout(context),
                    icon: const Icon(Icons.payment),
                    label: const Text('Checkout'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _proceedToCheckout(BuildContext context) async {
    final authController = context.read<AuthController>();
    if (authController.isGuest) {
      await GuestGuard.check(context, isGuest: true);
      return;
    }

    final cartController = context.read<CartController>();
    final productController = context.read<ProductController>();
    final userId = authController.profile?.uid;
    if (userId == null) return;

    final unavailable = cartController.items
        .where((cartItem) => !productController.allProducts
            .any((p) => p.id == cartItem.productId))
        .toList();

    if (unavailable.isNotEmpty) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Unavailable Items'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The following items in your cart are no longer available:',
              ),
              const SizedBox(height: 8),
              ...unavailable.map(
                (item) => Text(
                  '- ${item.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Please remove them before proceeding to checkout.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                for (var item in unavailable) {
                  await cartController.removeItem(userId, item.productId);
                }
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Remove unavailable items'),
            ),
          ],
        ),
      );
      return;
    }

    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CheckoutScreen(),
      ),
    );
  }
}

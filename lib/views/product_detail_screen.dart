import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/product_controller.dart';
import '../models/product_model.dart';
import '../widgets/app_network_image.dart';
import '../utils/constants.dart';

class ProductDetailScreen extends StatelessWidget {
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  Widget build(BuildContext context) {
    final productController = context.watch<ProductController>();
    final product = productController.allProducts
        .cast<ProductModel?>()
        .firstWhere((p) => p?.id == productId, orElse: () => null);

    if (product == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('Product not found'),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero image in SliverAppBar
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: AppNetworkImage(
                url: product.imageUrl,
                fit: BoxFit.cover,
              ),
            ),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

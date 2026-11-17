import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/product_controller.dart';
import '../widgets/product_card.dart';
import '../utils/app_colors.dart';
import 'product_detail_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _FilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productController = context.watch<ProductController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('StyleHub'),
        actions: [
          // Filter button with badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterSheet,
              ),
              if (productController.hasActiveFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _getActiveFilterCount(productController).toString(),
                      style: const TextStyle(
                        color: AppColors.onImage,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      drawer: const _ProductDrawer(),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          productController.setSearchQuery('');
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                productController.setSearchQuery(value);
              },
            ),
          ),

          // Category chips
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // All chip
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('All'),
                    selected: productController.selectedCategory == null,
                    onSelected: (selected) {
                      if (selected) {
                        productController.selectCategory(null);
                      }
                    },
                  ),
                ),
                // Category chips
                ...productController.categories.map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category.name),
                      selected:
                          productController.selectedCategory == category.name,
                      onSelected: (selected) {
                        if (selected) {
                          productController.selectCategory(category.name);
                        } else {
                          productController.selectCategory(null);
                        }
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Product grid
          Expanded(
            child: _buildProductGrid(productController),
          ),
        ],
      ),
    );
  }

  int _getActiveFilterCount(ProductController controller) {
    int count = 0;
    if (controller.selectedCategory != null) count++;
    if (controller.selectedSubcategory != null) count++;
    if (controller.priceRangeStart != null || controller.priceRangeEnd != null) {
      count++;
    }
    return count;
  }

  Widget _buildProductGrid(ProductController productController) {
    if (productController.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (productController.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(productController.errorMessage!),
          ],
        ),
      );
    }

    final products = productController.products;

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No products found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            if (productController.hasActiveFilters)
              FilledButton.icon(
                onPressed: () {
                  productController.clearAllFilters();
                  _searchController.clear();
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear filters'),
              ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Result count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '${products.length} product${products.length != 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),

        // Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(
                product: product,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          ProductDetailScreen(productId: product.id),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Filter bottom sheet
class _FilterSheet extends StatefulWidget {
  const _FilterSheet();

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late ProductSort _selectedSort;
  late RangeValues _priceRange;

  @override
  void initState() {
    super.initState();
    final productController = context.read<ProductController>();
    _selectedSort = productController.sort;

    final min = productController.minPrice;
    final max = productController.maxPrice;
    _priceRange = RangeValues(
      productController.priceRangeStart ?? min,
      productController.priceRangeEnd ?? max,
    );
  }

  @override
  Widget build(BuildContext context) {
    final productController = context.watch<ProductController>();
    final min = productController.minPrice;
    final max = productController.maxPrice;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter & Sort',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Sort options
            Text(
              'Sort by',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Popularity'),
                  selected: _selectedSort == ProductSort.popularity,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedSort = ProductSort.popularity;
                      });
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('Newest'),
                  selected: _selectedSort == ProductSort.newest,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedSort = ProductSort.newest;
                      });
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('Price: Low to High'),
                  selected: _selectedSort == ProductSort.priceAsc,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedSort = ProductSort.priceAsc;
                      });
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('Price: High to Low'),
                  selected: _selectedSort == ProductSort.priceDesc,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedSort = ProductSort.priceDesc;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Price range
            Text(
              'Price range',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            RangeSlider(
              values: _priceRange,
              min: min,
              max: max,
              divisions: 20,
              labels: RangeLabels(
                _priceRange.start.toStringAsFixed(0),
                _priceRange.end.toStringAsFixed(0),
              ),
              onChanged: (values) {
                setState(() {
                  _priceRange = values;
                });
              },
            ),
            Text(
              '${_priceRange.start.toStringAsFixed(0)} - ${_priceRange.end.toStringAsFixed(0)} TND',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Apply button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  productController.setSort(_selectedSort);
                  productController.setPriceRange(
                    _priceRange.start == min ? null : _priceRange.start,
                    _priceRange.end == max ? null : _priceRange.end,
                  );
                  Navigator.pop(context);
                },
                child: const Text('Apply'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Product drawer with category tree
class _ProductDrawer extends StatefulWidget {
  const _ProductDrawer();

  @override
  State<_ProductDrawer> createState() => _ProductDrawerState();
}

class _ProductDrawerState extends State<_ProductDrawer> {
  String? _expandedCategory;

  @override
  Widget build(BuildContext context) {
    final productController = context.watch<ProductController>();

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Drawer header
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'StyleHub',
                  style: TextStyle(
                    color: AppColors.onImage,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Shop by category',
                  style: TextStyle(
                    color: AppColors.onImageMuted,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // All products
          ListTile(
            leading: const Icon(Icons.grid_view),
            title: const Text('All products'),
            selected: productController.selectedCategory == null,
            onTap: () {
              productController.selectCategory(null);
              Navigator.pop(context);
            },
          ),

          const Divider(),

          // Category tree
          ...productController.categories.map((category) {
            final subcategories =
                productController.subcategoriesOf(category.id);
            final hasSubcategories = subcategories.isNotEmpty;
            final isExpanded = _expandedCategory == category.id;
            final isSelected =
                productController.selectedCategory == category.name &&
                    productController.selectedSubcategory == null;

            return Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.category),
                  title: Text(category.name),
                  trailing: hasSubcategories
                      ? Icon(isExpanded
                          ? Icons.expand_less
                          : Icons.expand_more)
                      : null,
                  selected: isSelected,
                  onTap: () {
                    if (hasSubcategories) {
                      setState(() {
                        _expandedCategory =
                            isExpanded ? null : category.id;
                      });
                    } else {
                      productController.selectCategory(category.name);
                      Navigator.pop(context);
                    }
                  },
                ),
                if (hasSubcategories && isExpanded)
                  ...subcategories.map((subcategory) {
                    final isSubSelected =
                        productController.selectedCategory == category.name &&
                            productController.selectedSubcategory ==
                                subcategory.name;

                    return ListTile(
                      contentPadding: const EdgeInsets.only(left: 72, right: 16),
                      title: Text(subcategory.name),
                      selected: isSubSelected,
                      onTap: () {
                        productController.selectCategory(category.name);
                        productController.selectSubcategory(subcategory.name);
                        Navigator.pop(context);
                      },
                    );
                  }),
              ],
            );
          }),
        ],
      ),
    );
  }
}

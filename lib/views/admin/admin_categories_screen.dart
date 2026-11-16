import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/admin_controller.dart';
import '../../controllers/product_controller.dart';
import '../../models/category_model.dart';
import '../../utils/app_colors.dart';

/// Admin Categories management screen with tree view, creation, renaming, and cascade deletion
class AdminCategoriesScreen extends StatelessWidget {
  const AdminCategoriesScreen({super.key});

  Future<void> _showAddCategoryDialog(
    BuildContext context, {
    String? parentId,
    String? parentName,
  }) async {
    final textController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          parentId == null
              ? 'Add Top-Level Category'
              : 'Add Subcategory to "$parentName"',
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: textController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Category Name',
              hintText: parentId == null
                  ? 'e.g. Clothing'
                  : 'e.g. Shirts',
              border: const OutlineInputBorder(),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Category name is required';
              }
              return null;
            },
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
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!context.mounted) return;
      final adminController = context.read<AdminController>();
      final success = await adminController.createCategory(
        name: textController.text.trim(),
        parentId: parentId,
      );

      if (!context.mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category created successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              adminController.errorMessage ?? 'Failed to create category',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _showRenameCategoryDialog(
    BuildContext context,
    CategoryModel category,
  ) async {
    final textController = TextEditingController(text: category.name);
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Rename "${category.name}"'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: textController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'New Category Name',
              border: OutlineInputBorder(),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Category name is required';
              }
              return null;
            },
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
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!context.mounted) return;
      final adminController = context.read<AdminController>();
      final success = await adminController.renameCategory(
        categoryId: category.id,
        newName: textController.text.trim(),
      );

      if (!context.mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category renamed successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              adminController.errorMessage ?? 'Failed to rename category',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteCategory(
    BuildContext context,
    CategoryModel category,
    String? parentName,
  ) async {
    final adminController = context.read<AdminController>();
    final productController = context.read<ProductController>();

    int productCount = 0;
    int subCatCount = 0;

    if (category.isTopLevel) {
      final subCats = productController.subcategoriesOf(category.id);
      subCatCount = subCats.length;
      productCount = await adminController.countProductsInCategory(category.name);
    } else {
      if (parentName != null) {
        productCount = await adminController.countProductsInSubcategory(
          parentName,
          category.name,
        );
      }
    }

    if (!context.mounted) return;

    final String message;
    if (category.isTopLevel) {
      message =
          'Deleting "${category.name}" will also permanently delete $subCatCount subcategories and $productCount products. This cannot be undone.';
    } else {
      message =
          'Deleting subcategory "${category.name}" will also permanently delete $productCount products. This cannot be undone.';
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(message),
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
      if (!context.mounted) return;
      final deletedProducts = await adminController.deleteCategory(category.id);

      if (!context.mounted) return;
      if (deletedProducts != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Category "${category.name}" deleted along with $deletedProducts products.',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              adminController.errorMessage ?? 'Failed to delete category',
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
    final topCategories = productController.categories;

    return Scaffold(
      body: topCategories.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 80,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No categories found',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add your first top-level category to start organizing products.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: topCategories.length,
              itemBuilder: (context, index) {
                final topCat = topCategories[index];
                final subCats = productController.subcategoriesOf(topCat.id);

                final topCatProdCount = productController.allProducts
                    .where((p) => p.category == topCat.name)
                    .length;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6.0),
                  child: ExpansionTile(
                    leading: const Icon(Icons.folder_open),
                    title: Text(
                      topCat.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${subCats.length} subcategories • $topCatProdCount products',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          tooltip: 'Add subcategory',
                          onPressed: () => _showAddCategoryDialog(
                            context,
                            parentId: topCat.id,
                            parentName: topCat.name,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Rename',
                          onPressed: () =>
                              _showRenameCategoryDialog(context, topCat),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.error,
                          ),
                          tooltip: 'Delete',
                          onPressed: () => _handleDeleteCategory(
                            context,
                            topCat,
                            null,
                          ),
                        ),
                      ],
                    ),
                    children: [
                      if (subCats.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'No subcategories. Tap + to add one.',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        )
                      else
                        ...subCats.map((subCat) {
                          final subProdCount = productController.allProducts
                              .where((p) =>
                                  p.category == topCat.name &&
                                  p.subcategory == subCat.name)
                              .length;

                          return ListTile(
                            contentPadding: const EdgeInsets.only(
                              left: 32.0,
                              right: 16.0,
                            ),
                            leading: const Icon(Icons.subdirectory_arrow_right),
                            title: Text(subCat.name),
                            subtitle: Text('$subProdCount products'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 20),
                                  tooltip: 'Rename subcategory',
                                  onPressed: () => _showRenameCategoryDialog(
                                    context,
                                    subCat,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: AppColors.error,
                                  ),
                                  tooltip: 'Delete subcategory',
                                  onPressed: () => _handleDeleteCategory(
                                    context,
                                    subCat,
                                    topCat.name,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoryDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add category'),
      ),
    );
  }
}

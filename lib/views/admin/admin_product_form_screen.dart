import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/admin_controller.dart';
import '../../controllers/product_controller.dart';
import '../../models/product_model.dart';
import '../../utils/image_url.dart';
import '../../widgets/app_network_image.dart';

/// Form screen for creating or editing a product
class AdminProductFormScreen extends StatefulWidget {
  final ProductModel? product;

  const AdminProductFormScreen({
    super.key,
    this.product,
  });

  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _popularityController = TextEditingController();

  String? _selectedCategory;
  String? _selectedSubcategory;
  String _previewImageUrl = '';
  bool _isSubmitting = false;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final p = widget.product!;
      _nameController.text = p.name;
      _descriptionController.text = p.description;
      _priceController.text = p.price.toString();
      _imageUrlController.text = p.imageUrl;
      _popularityController.text = p.popularity.toString();
      _selectedCategory = p.category;
      _selectedSubcategory = p.subcategory;
      _previewImageUrl = p.imageUrl;
    } else {
      _popularityController.text = '0';
    }

    _imageUrlController.addListener(_onImageUrlChanged);
  }

  void _onImageUrlChanged() {
    final text = _imageUrlController.text.trim();
    if (text.isNotEmpty && text != _previewImageUrl) {
      setState(() {
        _previewImageUrl = ImageUrl.normalize(text);
      });
    }
  }

  @override
  void dispose() {
    _imageUrlController.removeListener(_onImageUrlChanged);
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _popularityController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final adminController = context.read<AdminController>();

    final normalizedImage = ImageUrl.normalize(_imageUrlController.text);
    final price = double.parse(_priceController.text.trim());
    final popularity = int.tryParse(_popularityController.text.trim()) ?? 0;

    bool success = false;
    if (_isEditing) {
      success = await adminController.updateProduct(
        id: widget.product!.id,
        name: _nameController.text,
        description: _descriptionController.text,
        price: price,
        imageUrl: normalizedImage,
        category: _selectedCategory!,
        subcategory: _selectedSubcategory,
        popularity: popularity,
      );
    } else {
      success = await adminController.createProduct(
        name: _nameController.text,
        description: _descriptionController.text,
        price: price,
        imageUrl: normalizedImage,
        category: _selectedCategory!,
        subcategory: _selectedSubcategory,
        popularity: popularity,
      );
    }

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Product updated successfully'
                : 'Product created successfully',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            adminController.errorMessage ?? 'Failed to save product',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final productController = context.watch<ProductController>();
    final categories = productController.categories;

    // Subcategories of selected category
    List<String> subcategoryOptions = [];
    if (_selectedCategory != null) {
      final selectedCatDoc = categories.firstWhere(
        (cat) => cat.name == _selectedCategory,
        orElse: () => categories.first,
      );
      subcategoryOptions = productController
          .subcategoriesOf(selectedCatDoc.id)
          .map((sub) => sub.name)
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Product' : 'Add Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  hintText: 'Enter product name',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Product name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter product description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Price
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Price',
                  hintText: 'e.g. 49.99',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Price is required';
                  }
                  final parsed = double.tryParse(val.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Price must be a number greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Image URL and Live Preview
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  hintText: 'Enter HTTP or HTTPS image URL',
                  border: OutlineInputBorder(),
                ),
                validator: ImageUrl.validate,
              ),
              const SizedBox(height: 12),

              // Image Preview Card
              if (_previewImageUrl.isNotEmpty) ...[
                Text(
                  'Image Live Preview:',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: AppNetworkImage(
                      url: _previewImageUrl,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Category Dropdown
              // ignore: deprecated_member_use
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: categories.any((c) => c.name == _selectedCategory)
                    ? _selectedCategory
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Top-Level Category',
                  border: OutlineInputBorder(),
                ),
                items: categories
                    .map((cat) => DropdownMenuItem<String>(
                          value: cat.name,
                          child: Text(cat.name),
                        ))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCategory = val;
                    _selectedSubcategory = null;
                  });
                },
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Category is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Subcategory Dropdown (optional)
              if (_selectedCategory != null && subcategoryOptions.isNotEmpty) ...[
                // ignore: deprecated_member_use
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: subcategoryOptions.contains(_selectedSubcategory)
                      ? _selectedSubcategory
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Subcategory (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('None'),
                    ),
                    ...subcategoryOptions.map(
                      (sub) => DropdownMenuItem<String>(
                        value: sub,
                        child: Text(sub),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedSubcategory = val;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Popularity
              TextFormField(
                controller: _popularityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Popularity Score',
                  hintText: 'Default: 0',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val != null && val.trim().isNotEmpty) {
                    final parsed = int.tryParse(val.trim());
                    if (parsed == null || parsed < 0) {
                      return 'Popularity must be an integer >= 0';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSubmitting
                      ? 'Saving...'
                      : (_isEditing ? 'Update Product' : 'Create Product')),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

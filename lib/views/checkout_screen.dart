import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/order_controller.dart';
import '../models/order_model.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../widgets/app_network_image.dart';
import '../widgets/guest_guard.dart';
import 'd17_payment_screen.dart';
import 'order_confirmation_screen.dart';

/// Checkout screen for placing orders
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedPaymentMethod = 'cash_on_delivery';
  bool _isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authController = context.read<AuthController>();
      if (authController.isGuest) {
        GuestGuard.check(context, isGuest: true);
        return;
      }
      _addressController.text = authController.profile?.address ?? '';
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handlePlaceOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final authController = context.read<AuthController>();
    final cartController = context.read<CartController>();
    final orderController = context.read<OrderController>();

    final userId = authController.profile?.uid;
    if (userId == null) return;

    if (cartController.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty')),
      );
      return;
    }

    setState(() {
      _isPlacingOrder = true;
    });

    final formattedPhone =
        Validators.formatTunisianPhone(_phoneController.text);

    final orderItems = cartController.items
        .map((c) => OrderItem(
              productId: c.productId,
              name: c.name,
              price: c.price,
              imageUrl: c.imageUrl,
              quantity: c.quantity,
            ))
        .toList();

    final createdOrder = await orderController.placeOrder(
      userId: userId,
      items: orderItems,
      total: cartController.total,
      paymentMethod: _selectedPaymentMethod,
      deliveryAddress: _addressController.text.trim(),
      phone: formattedPhone,
    );

    if (!mounted) return;

    setState(() {
      _isPlacingOrder = false;
    });

    if (createdOrder != null) {
      if (_selectedPaymentMethod == 'cash_on_delivery') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                OrderConfirmationScreen(order: createdOrder),
          ),
        );
      } else if (_selectedPaymentMethod == 'd17') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => D17PaymentScreen(order: createdOrder),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            orderController.errorMessage ?? 'Failed to place order',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartController = context.watch<CartController>();
    final items = cartController.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shipping details card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivery Details',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Delivery Address',
                          hintText: 'Enter your full delivery address',
                          prefixIcon: Icon(Icons.location_on_outlined),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                        maxLength: 200,
                        validator: Validators.address,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          hintText: 'e.g. 21234567 or +216 21234567',
                          prefixIcon: Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: Validators.phone,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Payment method selection card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Method',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      // ignore: deprecated_member_use
                      RadioListTile<String>(
                        value: 'cash_on_delivery',
                        // ignore: deprecated_member_use
                        groupValue: _selectedPaymentMethod,
                        // ignore: deprecated_member_use
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedPaymentMethod = value;
                            });
                          }
                        },
                        title: const Text('Cash on delivery'),
                        subtitle: const Text('Pay when package is delivered'),
                        secondary: const Icon(Icons.local_shipping_outlined),
                      ),
                      // ignore: deprecated_member_use
                      RadioListTile<String>(
                        value: 'd17',
                        // ignore: deprecated_member_use
                        groupValue: _selectedPaymentMethod,
                        // ignore: deprecated_member_use
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedPaymentMethod = value;
                            });
                          }
                        },
                        title: const Text('D17'),
                        subtitle: const Text('Pay via D17 mobile application'),
                        secondary: const Icon(Icons.account_balance_wallet_outlined),
                      ),
                      // ignore: deprecated_member_use
                      const RadioListTile<String>(
                        value: 'card',
                        // ignore: deprecated_member_use
                        groupValue: null,
                        // ignore: deprecated_member_use
                        onChanged: null,
                        title: Text('Card payment'),
                        subtitle: Text('Coming soon'),
                        secondary: Icon(Icons.credit_card_outlined),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Order Summary card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Summary',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      ...items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6.0),
                                child: AppNetworkImage(
                                  url: item.imageUrl,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Qty: ${item.quantity} x ${formatPrice(item.price)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                formatPrice(item.subtotal),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            formatPrice(cartController.total),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Place Order Button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isPlacingOrder ? null : _handlePlaceOrder,
                  icon: _isPlacingOrder
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle),
                  label: Text(
                    _isPlacingOrder ? 'Placing Order...' : 'Place Order',
                  ),
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

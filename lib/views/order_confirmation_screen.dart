import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../utils/app_colors.dart';
import 'order_detail_screen.dart';

/// Confirmation screen for cash-on-delivery orders
class OrderConfirmationScreen extends StatelessWidget {
  final OrderModel order;

  const OrderConfirmationScreen({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final shortId =
        order.id.length >= 8 ? order.id.substring(0, 8) : order.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Placed'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 96,
                color: AppColors.success,
              ),
              const SizedBox(height: 24),
              Text(
                'Order Placed Successfully!',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Order Reference: #$shortId',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'Thank you for your purchase. Your cash on delivery order has been received and is currently being processed.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) =>
                            OrderDetailScreen(orderId: order.id),
                      ),
                    );
                  },
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('View order details'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  icon: const Icon(Icons.store),
                  label: const Text('Continue shopping'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

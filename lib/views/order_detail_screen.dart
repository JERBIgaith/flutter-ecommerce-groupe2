import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/order_controller.dart';
import '../models/order_model.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../widgets/app_network_image.dart';
import 'd17_payment_screen.dart';

/// Screen showing detailed information for a single order
class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _isCancelling = false;

  Color _getPaymentStatusColor(String paymentStatus) {
    switch (paymentStatus) {
      case 'unpaid':
        return AppColors.paymentUnpaid;
      case 'pending_verification':
        return AppColors.paymentPending;
      case 'paid':
        return AppColors.paymentPaid;
      case 'failed':
        return AppColors.paymentFailed;
      default:
        return AppColors.paymentUnpaid;
    }
  }

  String _formatPaymentStatusLabel(String paymentStatus) {
    switch (paymentStatus) {
      case 'unpaid':
        return 'Unpaid';
      case 'pending_verification':
        return 'Pending Verification';
      case 'paid':
        return 'Paid';
      case 'failed':
        return 'Failed';
      default:
        return paymentStatus;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Just now';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  Future<void> _handleCancelOrder(OrderModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text(
          'Are you sure you want to cancel this order? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, keep order'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, cancel order'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      setState(() {
        _isCancelling = true;
      });

      final orderController = context.read<OrderController>();
      final success = await orderController.cancelOrder(order.id);

      if (!mounted) return;

      setState(() {
        _isCancelling = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order cancelled successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              orderController.errorMessage ?? 'Failed to cancel order',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildStatusStepper(BuildContext context, String status) {
    if (status == 'cancelled') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: AppColors.statusCancelled.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: AppColors.statusCancelled),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel_outlined, color: AppColors.statusCancelled),
            const SizedBox(width: 12),
            Text(
              'Order Cancelled',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.statusCancelled,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      );
    }

    final steps = ['Pending', 'Confirmed', 'Shipped', 'Delivered'];
    int currentStep = 0;
    switch (status) {
      case 'pending':
        currentStep = 0;
        break;
      case 'confirmed':
        currentStep = 1;
        break;
      case 'shipped':
        currentStep = 2;
        break;
      case 'delivered':
        currentStep = 3;
        break;
    }

    return Row(
      children: List.generate(steps.length, (index) {
        final isCompleted = index <= currentStep;
        final isCurrent = index == currentStep;
        final color = isCompleted
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3);

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (index > 0)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: index <= currentStep
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.2),
                      ),
                    ),
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: color,
                    child: isCompleted
                        ? Icon(
                            Icons.check,
                            size: 14,
                            color: Theme.of(context).colorScheme.onPrimary,
                          )
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                  ),
                  if (index < steps.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: index < currentStep
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.2),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                steps[index],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCompleted
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderController = context.watch<OrderController>();
    final matches =
        orderController.orders.where((o) => o.id == widget.orderId).toList();

    if (matches.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: const Center(
          child: Text('Order not found.'),
        ),
      );
    }

    final order = matches.first;
    final shortId =
        order.id.length >= 8 ? order.id.substring(0, 8) : order.id;
    final paymentColor = _getPaymentStatusColor(order.paymentStatus);

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #$shortId'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Stepper Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order Status',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          _formatDate(order.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildStatusStepper(context, order.status),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Delivery Details Card
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
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.location_on_outlined),
                      title: const Text('Delivery Address'),
                      subtitle: Text(order.deliveryAddress),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.phone_outlined),
                      title: const Text('Phone Number'),
                      subtitle: Text(order.phone),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Payment Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Payment Method',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          order.paymentMethod == 'd17'
                              ? 'D17'
                              : 'Cash on Delivery',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Payment Status',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10.0,
                            vertical: 4.0,
                          ),
                          decoration: BoxDecoration(
                            color: paymentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: paymentColor),
                          ),
                          child: Text(
                            _formatPaymentStatusLabel(order.paymentStatus),
                            style: TextStyle(
                              color: paymentColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (order.paymentReference != null &&
                        order.paymentReference!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Transaction Ref',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            order.paymentReference!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Items Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Items Ordered',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    ...order.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6.0),
                              child: AppNetworkImage(
                                url: item.imageUrl,
                                width: 50,
                                height: 50,
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
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          formatPrice(order.total),
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

            // Actions
            if (order.paymentMethod == 'd17' &&
                order.paymentStatus == 'unpaid' &&
                order.status != 'cancelled') ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => D17PaymentScreen(order: order),
                      ),
                    );
                  },
                  icon: const Icon(Icons.account_balance_wallet),
                  label: const Text('Complete D17 Payment'),
                ),
              ),
              const SizedBox(height: 12),
            ],

            if (order.canCancel) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  onPressed: _isCancelling
                      ? null
                      : () => _handleCancelOrder(order),
                  icon: _isCancelling
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cancel_outlined),
                  label: Text(_isCancelling
                      ? 'Cancelling...'
                      : 'Cancel order'),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

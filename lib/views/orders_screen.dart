import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/order_controller.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../widgets/guest_guard.dart';
import 'order_detail_screen.dart';

/// Screen listing user's past and current orders
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authController = context.read<AuthController>();
      if (authController.isGuest) {
        GuestGuard.check(context, isGuest: true);
      }
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.statusPending;
      case 'confirmed':
        return AppColors.statusConfirmed;
      case 'shipped':
        return AppColors.statusShipped;
      case 'delivered':
        return AppColors.statusDelivered;
      case 'cancelled':
        return AppColors.statusCancelled;
      default:
        return AppColors.statusPending;
    }
  }

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

  String _formatStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
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

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final orderController = context.watch<OrderController>();

    if (authController.isGuest) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Orders')),
        body: const Center(
          child: Text('Please log in to view your orders.'),
        ),
      );
    }

    final orders = orderController.orders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
      ),
      body: orderController.isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 80,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No orders yet',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Your order history will appear here once you place an order.',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12.0),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final shortId = order.id.length >= 8
                        ? order.id.substring(0, 8)
                        : order.id;
                    final itemCount = order.items
                        .fold(0, (sum, item) => sum + item.quantity);
                    final statusColor = _getStatusColor(order.status);
                    final paymentColor =
                        _getPaymentStatusColor(order.paymentStatus);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6.0),
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  OrderDetailScreen(orderId: order.id),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Order #$shortId',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  Text(
                                    _formatDate(order.createdAt),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    '$itemCount item${itemCount > 1 ? 's' : ''}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium,
                                  ),
                                  const Spacer(),
                                  Text(
                                    formatPrice(order.total),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8.0,
                                runSpacing: 4.0,
                                children: [
                                  // Status Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0,
                                      vertical: 4.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          statusColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: statusColor,
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Text(
                                      _formatStatusLabel(order.status),
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  // Payment Status Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0,
                                      vertical: 4.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          paymentColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: paymentColor,
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Text(
                                      _formatPaymentStatusLabel(
                                          order.paymentStatus),
                                      style: TextStyle(
                                        color: paymentColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
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

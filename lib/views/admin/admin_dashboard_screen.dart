import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/admin_controller.dart';
import '../../controllers/product_controller.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import 'admin_order_detail_screen.dart';

/// Admin Dashboard Screen showing overview statistics and recent orders
class AdminDashboardScreen extends StatelessWidget {
  final VoidCallback? onNavigateToOrders;

  const AdminDashboardScreen({
    super.key,
    this.onNavigateToOrders,
  });

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

  String _formatDate(DateTime? date) {
    if (date == null) return 'Just now';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final adminController = context.watch<AdminController>();
    final productController = context.watch<ProductController>();

    final totalUsers = adminController.totalUsers;
    final totalProducts = productController.allProducts.length;
    final topCategories = productController.categories.length;
    final totalOrders = adminController.totalOrders;
    final pendingOrders = adminController.pendingOrders;
    final pendingVerification = adminController.pendingPaymentVerificationOrders;
    final revenue = adminController.revenue;
    final latestOrders = adminController.latestOrders;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview Statistics',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),

          // Metric Grid
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _MetricCard(
                title: 'Revenue',
                value: formatPrice(revenue),
                icon: Icons.attach_money,
                color: Theme.of(context).colorScheme.primary,
              ),
              _MetricCard(
                title: 'Total Orders',
                value: '$totalOrders',
                icon: Icons.receipt_long,
                color: AppColors.statusConfirmed,
              ),
              _MetricCard(
                title: 'Pending Orders',
                value: '$pendingOrders',
                icon: Icons.hourglass_empty,
                color: AppColors.statusPending,
              ),
              _MetricCard(
                title: 'Payment Verification',
                value: '$pendingVerification',
                icon: Icons.verified_user_outlined,
                color: AppColors.paymentPending,
              ),
              _MetricCard(
                title: 'Total Users',
                value: '$totalUsers',
                icon: Icons.people,
                color: AppColors.statusShipped,
              ),
              _MetricCard(
                title: 'Total Products',
                value: '$totalProducts',
                icon: Icons.inventory_2,
                color: Theme.of(context).colorScheme.secondary,
              ),
              _MetricCard(
                title: 'Top Categories',
                value: '$topCategories',
                icon: Icons.category,
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recent Orders Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Orders',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (onNavigateToOrders != null)
                TextButton(
                  onPressed: onNavigateToOrders,
                  child: const Text('View All'),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Recent Orders List
          if (latestOrders.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Text(
                    'No orders placed yet',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            )
          else
            ...latestOrders.map((order) {
              final shortId = order.id.length >= 8
                  ? order.id.substring(0, 8)
                  : order.id;
              final statusColor = _getStatusColor(order.status);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                child: ListTile(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            AdminOrderDetailScreen(orderId: order.id),
                      ),
                    );
                  },
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order #$shortId',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        formatPrice(order.total),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDate(order.createdAt)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 2.0,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: statusColor),
                          ),
                          child: Text(
                            order.status.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color
                              ?.withValues(alpha: 0.8),
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

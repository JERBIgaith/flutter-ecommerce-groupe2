import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/admin_controller.dart';
import '../../models/order_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import 'admin_order_detail_screen.dart';

/// Admin Orders list screen with status and payment status filters
class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  String? _selectedStatusFilter;
  String? _selectedPaymentFilter;

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
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final adminController = context.watch<AdminController>();
    final allOrders = adminController.allOrders;

    List<OrderModel> filtered = List.from(allOrders);

    if (_selectedStatusFilter != null) {
      filtered =
          filtered.where((o) => o.status == _selectedStatusFilter).toList();
    }

    if (_selectedPaymentFilter != null) {
      filtered = filtered
          .where((o) => o.paymentStatus == _selectedPaymentFilter)
          .toList();
    }

    final statusOptions = ['pending', 'confirmed', 'shipped', 'delivered', 'cancelled'];
    final paymentOptions = ['unpaid', 'pending_verification', 'paid', 'failed'];

    return Scaffold(
      body: Column(
        children: [
          // Filter Chips Section
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Status Filters
                Text(
                  'Order Status Filter:',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _selectedStatusFilter == null,
                        onSelected: (selected) {
                          setState(() {
                            _selectedStatusFilter = null;
                          });
                        },
                      ),
                      const SizedBox(width: 6),
                      ...statusOptions.map(
                        (status) => Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: FilterChip(
                            label: Text(_formatStatusLabel(status)),
                            selected: _selectedStatusFilter == status,
                            onSelected: (selected) {
                              setState(() {
                                _selectedStatusFilter =
                                    selected ? status : null;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Payment Status Filters
                Text(
                  'Payment Status Filter:',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _selectedPaymentFilter == null,
                        onSelected: (selected) {
                          setState(() {
                            _selectedPaymentFilter = null;
                          });
                        },
                      ),
                      const SizedBox(width: 6),
                      ...paymentOptions.map(
                        (pStatus) => Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: FilterChip(
                            label: Text(_formatPaymentStatusLabel(pStatus)),
                            selected: _selectedPaymentFilter == pStatus,
                            onSelected: (selected) {
                              setState(() {
                                _selectedPaymentFilter =
                                    selected ? pStatus : null;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Orders List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        allOrders.isEmpty
                            ? 'No orders in system.'
                            : 'No orders match selected filters.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final order = filtered[index];
                      final shortId = order.id.length >= 8
                          ? order.id.substring(0, 8)
                          : order.id;
                      final statusColor = _getStatusColor(order.status);
                      final paymentColor =
                          _getPaymentStatusColor(order.paymentStatus);

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
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                formatPrice(order.total),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_formatDate(order.createdAt)),
                                  Text(
                                    'User: ${order.userId.length > 8 ? order.userId.substring(0, 8) : order.userId}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6.0,
                                runSpacing: 4.0,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                      vertical: 2.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          statusColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: statusColor),
                                    ),
                                    child: Text(
                                      _formatStatusLabel(order.status),
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                      vertical: 2.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          paymentColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: paymentColor),
                                    ),
                                    child: Text(
                                      _formatPaymentStatusLabel(
                                        order.paymentStatus,
                                      ),
                                      style: TextStyle(
                                        color: paymentColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

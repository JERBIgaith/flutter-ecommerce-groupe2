import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../controllers/admin_controller.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../widgets/app_network_image.dart';

/// Admin detail screen for managing a single order's status and payment state
class AdminOrderDetailScreen extends StatefulWidget {
  final String orderId;

  const AdminOrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  bool _isUpdating = false;

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

  Future<void> _updateOrderStatus(String newStatus) async {
    setState(() {
      _isUpdating = true;
    });

    final adminController = context.read<AdminController>();
    final success = await adminController.updateOrderStatus(widget.orderId, newStatus);

    if (!mounted) return;

    setState(() {
      _isUpdating = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order status updated to ${_formatStatusLabel(newStatus)}'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(adminController.errorMessage ?? 'Failed to update order status'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _updatePaymentStatus(String newPaymentStatus) async {
    setState(() {
      _isUpdating = true;
    });

    final adminController = context.read<AdminController>();
    final success =
        await adminController.updatePaymentStatus(widget.orderId, newPaymentStatus);

    if (!mounted) return;

    setState(() {
      _isUpdating = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment status updated to ${_formatPaymentStatusLabel(newPaymentStatus)}',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            adminController.errorMessage ?? 'Failed to update payment status',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _confirmCancelOrder() async {
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
            child: const Text('No'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _updateOrderStatus('cancelled');
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminController = context.watch<AdminController>();
    final matches =
        adminController.allOrders.where((o) => o.id == widget.orderId).toList();

    if (matches.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: const Center(child: Text('Order not found.')),
      );
    }

    final order = matches.first;
    final shortId =
        order.id.length >= 8 ? order.id.substring(0, 8) : order.id;
    final statusColor = _getStatusColor(order.status);
    final paymentColor = _getPaymentStatusColor(order.paymentStatus);

    final canCancel =
        order.status == 'pending' || order.status == 'confirmed';
    final isTerminalStatus =
        order.status == 'delivered' || order.status == 'cancelled';

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #$shortId'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and Customer Card
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10.0,
                            vertical: 4.0,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: statusColor),
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
                        const SizedBox(width: 8),
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
                    const Divider(height: 24),
                    Text(
                      'Customer UID: ${order.userId}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
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
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.location_on_outlined),
                      title: const Text('Address'),
                      subtitle: Text(order.deliveryAddress),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.phone_outlined),
                      title: const Text('Phone'),
                      subtitle: Text(order.phone),
                    ),
                    if (order.hasLocation) ...[
                      const Divider(height: 24),
                      Text(
                        'Delivery Location Pin',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Coordinates: ${order.deliveryLat!.toStringAsFixed(4)}, ${order.deliveryLng!.toStringAsFixed(4)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: SizedBox(
                          height: 140,
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(
                                order.deliveryLat!,
                                order.deliveryLng!,
                              ),
                              initialZoom: 14.0,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.none,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'fl',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(
                                      order.deliveryLat!,
                                      order.deliveryLng!,
                                    ),
                                    width: 36,
                                    height: 36,
                                    child: Icon(
                                      Icons.location_on,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      size: 36,
                                    ),
                                  ),
                                ],
                              ),
                              SimpleAttributionWidget(
                                source: const Text(
                                  'OpenStreetMap contributors',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
                    const SizedBox(height: 8),
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
                              ?.copyWith(fontWeight: FontWeight.bold),
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
                            'Transaction Reference',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          SelectableText(
                            order.paymentReference!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
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
                                    style: Theme.of(context).textTheme.bodySmall,
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

            // Admin Action Buttons
            Text(
              'Admin Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),

            if (isTerminalStatus)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  'Order status is ${order.status}. No further status changes allowed.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              )
            else ...[
              // Move Status Forward
              if (order.status == 'pending')
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isUpdating ? null : () => _updateOrderStatus('confirmed'),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Confirm Order'),
                  ),
                ),
              if (order.status == 'confirmed')
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isUpdating ? null : () => _updateOrderStatus('shipped'),
                    icon: const Icon(Icons.local_shipping_outlined),
                    label: const Text('Mark as Shipped'),
                  ),
                ),
              if (order.status == 'shipped')
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isUpdating ? null : () => _updateOrderStatus('delivered'),
                    icon: const Icon(Icons.inventory),
                    label: const Text('Mark as Delivered'),
                  ),
                ),
              const SizedBox(height: 8),

              // Cancel Order Button
              if (canCancel)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    onPressed: _isUpdating ? null : _confirmCancelOrder,
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancel Order'),
                  ),
                ),
            ],
            const SizedBox(height: 16),

            // Payment Actions
            if (order.paymentMethod == 'd17' &&
                order.paymentStatus == 'pending_verification') ...[
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                      ),
                      onPressed: _isUpdating ? null : () => _updatePaymentStatus('paid'),
                      icon: const Icon(Icons.verified),
                      label: const Text('Mark as Paid'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                      onPressed: _isUpdating ? null : () => _updatePaymentStatus('failed'),
                      icon: const Icon(Icons.error_outline),
                      label: const Text('Mark as Failed'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            if (order.paymentMethod == 'cash_on_delivery' &&
                order.status == 'delivered' &&
                order.paymentStatus != 'paid') ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                  ),
                  onPressed: _isUpdating ? null : () => _updatePaymentStatus('paid'),
                  icon: const Icon(Icons.paid_outlined),
                  label: const Text('Mark as Paid (Cash Collected)'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

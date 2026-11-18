import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../controllers/admin_controller.dart';
import '../../models/order_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import 'admin_order_detail_screen.dart';

/// Admin Orders Map screen showing delivery locations on an interactive map
class AdminOrdersMapScreen extends StatefulWidget {
  const AdminOrdersMapScreen({super.key});

  @override
  State<AdminOrdersMapScreen> createState() => _AdminOrdersMapScreenState();
}

class _AdminOrdersMapScreenState extends State<AdminOrdersMapScreen> {
  static const LatLng _tunisCenter = LatLng(36.8065, 10.1815);
  final MapController _mapController = MapController();

  // Active orders default filter: pending, confirmed, shipped
  Set<String> _selectedStatuses = {'pending', 'confirmed', 'shipped'};
  bool _isFirstFitDone = false;

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

  void _showOrderBottomSheet(BuildContext context, OrderModel order) {
    final shortId =
        order.id.length >= 8 ? order.id.substring(0, 8) : order.id;
    final statusColor = _getStatusColor(order.status);
    final paymentColor = _getPaymentStatusColor(order.paymentStatus);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #$shortId',
                  style: Theme.of(sheetContext)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  formatPrice(order.total),
                  style: Theme.of(sheetContext)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                        color: Theme.of(sheetContext).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
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
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              AdminOrderDetailScreen(orderId: order.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open order'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _fitMapToMarkers(List<OrderModel> ordersWithLoc) {
    if (ordersWithLoc.isEmpty) return;
    final points = ordersWithLoc
        .map((o) => LatLng(o.deliveryLat!, o.deliveryLng!))
        .toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (points.length == 1) {
        _mapController.move(points.first, 14.0);
      } else {
        final bounds = LatLngBounds.fromPoints(points);
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(50.0),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminController = context.watch<AdminController>();
    final allOrders = adminController.allOrders;

    // Filter orders by selected statuses
    final filteredOrders = allOrders
        .where((o) => _selectedStatuses.contains(o.status))
        .toList();

    final ordersWithLocation =
        filteredOrders.where((o) => o.hasLocation).toList();
    final ordersWithoutLocation =
        filteredOrders.where((o) => !o.hasLocation).toList();

    if (!_isFirstFitDone && ordersWithLocation.isNotEmpty) {
      _fitMapToMarkers(ordersWithLocation);
      _isFirstFitDone = true;
    }

    final allStatuses = ['pending', 'confirmed', 'shipped', 'delivered', 'cancelled'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Locations Map'),
      ),
      body: Column(
        children: [
          // Filter Chips and Legend Header
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Active Orders'),
                        selected: _selectedStatuses.length == 3 &&
                            _selectedStatuses.contains('pending') &&
                            _selectedStatuses.contains('confirmed') &&
                            _selectedStatuses.contains('shipped'),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedStatuses = {'pending', 'confirmed', 'shipped'};
                            } else {
                              _selectedStatuses = Set.from(allStatuses);
                            }
                            _fitMapToMarkers(ordersWithLocation);
                          });
                        },
                      ),
                      const SizedBox(width: 6),
                      FilterChip(
                        label: const Text('All Statuses'),
                        selected: _selectedStatuses.length == allStatuses.length,
                        onSelected: (selected) {
                          setState(() {
                            _selectedStatuses = Set.from(allStatuses);
                            _fitMapToMarkers(ordersWithLocation);
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ...allStatuses.map((status) {
                        final isSel = _selectedStatuses.contains(status);
                        final sColor = _getStatusColor(status);
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: FilterChip(
                            label: Text(_formatStatusLabel(status)),
                            selected: isSel,
                            selectedColor: sColor.withValues(alpha: 0.25),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedStatuses.add(status);
                                } else {
                                  if (_selectedStatuses.length > 1) {
                                    _selectedStatuses.remove(status);
                                  }
                                }
                                _fitMapToMarkers(ordersWithLocation);
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Map Legend
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _LegendItem(color: AppColors.statusPending, label: 'Pending'),
                      const SizedBox(width: 12),
                      _LegendItem(color: AppColors.statusConfirmed, label: 'Confirmed'),
                      const SizedBox(width: 12),
                      _LegendItem(color: AppColors.statusShipped, label: 'Shipped'),
                      const SizedBox(width: 12),
                      _LegendItem(color: AppColors.statusDelivered, label: 'Delivered'),
                      const SizedBox(width: 12),
                      _LegendItem(color: AppColors.statusCancelled, label: 'Cancelled'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Map Display
          Expanded(
            flex: 3,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: ordersWithLocation.isNotEmpty
                    ? LatLng(
                        ordersWithLocation.first.deliveryLat!,
                        ordersWithLocation.first.deliveryLng!,
                      )
                    : _tunisCenter,
                initialZoom: 11.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'fl',
                ),
                MarkerLayer(
                  markers: ordersWithLocation.map((order) {
                    final color = _getStatusColor(order.status);
                    return Marker(
                      point: LatLng(order.deliveryLat!, order.deliveryLng!),
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        onTap: () => _showOrderBottomSheet(context, order),
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.onImage, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).shadowColor.withValues(alpha: 0.26),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: AppColors.onImage,
                            size: 24,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SimpleAttributionWidget(
                  source: const Text('OpenStreetMap contributors'),
                ),
              ],
            ),
          ),

          // Collapsible List: Orders Without Location
          Expanded(
            flex: 2,
            child: Card(
              margin: const EdgeInsets.all(8.0),
              child: ExpansionTile(
                initiallyExpanded: false,
                title: Text(
                  'Orders Without Location (${ordersWithoutLocation.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                children: [
                  SizedBox(
                    height: 180,
                    child: ordersWithoutLocation.isEmpty
                        ? const Center(
                            child: Text('All filtered orders have location pins'),
                          )
                        : ListView.builder(
                            itemCount: ordersWithoutLocation.length,
                            itemBuilder: (context, index) {
                              final order = ordersWithoutLocation[index];
                              final shortId = order.id.length >= 8
                                  ? order.id.substring(0, 8)
                                  : order.id;

                              return ListTile(
                                leading: const Icon(Icons.location_off_outlined),
                                title: Text('Order #$shortId'),
                                subtitle: Text(
                                  order.deliveryAddress,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Text(
                                  formatPrice(order.total),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => AdminOrderDetailScreen(
                                        orderId: order.id,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

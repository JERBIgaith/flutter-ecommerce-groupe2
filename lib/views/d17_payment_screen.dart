import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/order_controller.dart';
import '../models/order_model.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import 'order_detail_screen.dart';

/// Screen displaying D17 payment instructions and reference submission
class D17PaymentScreen extends StatefulWidget {
  final OrderModel order;

  const D17PaymentScreen({
    super.key,
    required this.order,
  });

  @override
  State<D17PaymentScreen> createState() => _D17PaymentScreenState();
}

class _D17PaymentScreenState extends State<D17PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _referenceController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _submitReference() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final orderController = context.read<OrderController>();
    final success = await orderController.submitPaymentReference(
      widget.order.id,
      _referenceController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment reference submitted for verification'),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => OrderDetailScreen(orderId: widget.order.id),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            orderController.errorMessage ?? 'Failed to submit reference',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _payLater() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => OrderDetailScreen(orderId: widget.order.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shortId = widget.order.id.length >= 8
        ? widget.order.id.substring(0, 8)
        : widget.order.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('D17 Payment Instructions'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How to Pay with D17',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pay the exact amount using your D17 app to the merchant number below, then enter your transaction reference number to confirm your order.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.storefront_outlined),
                        title: const Text('Merchant D17 Number'),
                        subtitle: SelectableText(
                          Constants.kD17MerchantNumber,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.payments_outlined),
                        title: const Text('Amount to Pay'),
                        subtitle: Text(
                          formatPrice(widget.order.total),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.tag),
                        title: const Text('Order Reference'),
                        subtitle: Text('#$shortId'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Manual Verification Note
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: AppColors.statusPending.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: AppColors.statusPending.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.statusPending,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Please note that D17 payments are verified manually by the store before shipment.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Reference Form Field
              TextFormField(
                controller: _referenceController,
                decoration: const InputDecoration(
                  labelText: 'Transaction Reference',
                  hintText: 'Enter your D17 transaction reference',
                  prefixIcon: Icon(Icons.receipt_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: Validators.d17Reference,
              ),
              const SizedBox(height: 24),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submitReference,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(_isSubmitting
                      ? 'Submitting...'
                      : 'Confirm payment'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : _payLater,
                  child: const Text('Pay later'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

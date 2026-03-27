import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils/formatters.dart';
import '../core/widgets/app_shell.dart';
import '../core/widgets/primary_action_button.dart';
import '../data/models/loan.dart';
import '../state/app_controller.dart';

class PaymentFormScreen extends StatefulWidget {
  const PaymentFormScreen({
    super.key,
    required this.loanId,
  });

  final String loanId;

  @override
  State<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends State<PaymentFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _paymentDateController = TextEditingController(
    text: Formatters.asInputDate(DateTime.now()),
  );
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _paymentDateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppController>(
      builder: (context, controller, _) {
        return FutureBuilder<Loan?>(
          future: controller.getLoanById(widget.loanId),
          builder: (context, snapshot) {
            final loan = snapshot.data;
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (loan == null) {
              return const Scaffold(
                body: Center(child: Text('Loan not found')),
              );
            }

            return AppShell(
              title: 'Add Payment',
              bottomBar: PrimaryActionButton(
                label: 'Save Payment',
                icon: Icons.save_rounded,
                onPressed: () => _savePayment(loan.remainingAmount),
              ),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Remaining amount',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            Formatters.money(loan.remainingAmount),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _amountController,
                          decoration:
                              const InputDecoration(labelText: 'Payment amount'),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) {
                            final number = double.tryParse(value?.trim() ?? '');
                            if (number == null || number <= 0) {
                              return 'Enter a valid amount';
                            }
                            if (number > loan.remainingAmount) {
                              return 'Amount is more than remaining balance';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _PaymentDateField(controller: _paymentDateController),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _noteController,
                          decoration: const InputDecoration(labelText: 'Note'),
                          minLines: 3,
                          maxLines: 4,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _savePayment(double remainingAmount) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.parse(_amountController.text.trim());
    if (amount > remainingAmount) {
      return;
    }

    final controller = context.read<AppController>();
    final saved = await controller.addPaymentAndPromptShare(
      context,
      loanId: widget.loanId,
      amount: amount,
      paymentDate: _paymentDateController.text.trim(),
      note: _noteController.text.trim(),
    );

    if (saved && mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _PaymentDateField extends StatelessWidget {
  const _PaymentDateField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: const InputDecoration(
        labelText: 'Payment date',
        suffixIcon: Icon(Icons.calendar_month_rounded),
      ),
      onTap: () async {
        final initial = controller.text.isEmpty
            ? DateTime.now()
            : DateTime.parse(controller.text);
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          controller.text = Formatters.asInputDate(picked);
        }
      },
    );
  }
}

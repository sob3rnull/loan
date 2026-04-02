import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/state/app_state_controller.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../data/models/loan.dart';
import '../../../widgets/action_button.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/detail_row.dart';
import '../../../widgets/section_card.dart';

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
    text: AppFormatters.inputDate(DateTime.now()),
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
    return Consumer<AppStateController>(
      builder: (context, controller, _) {
        return FutureBuilder<Loan?>(
          future: controller.getLoanById(widget.loanId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final loan = snapshot.data;
            if (loan == null) {
              return const Scaffold(
                body: Center(child: Text('Loan not found.')),
              );
            }

            final borrower = controller.getBorrowerById(loan.borrowerId);

            return AppScaffold(
              title: 'Add Payment',
              bottomBar: ActionButton(
                label: 'Save Payment',
                icon: Icons.save_rounded,
                onPressed: () => _savePayment(loan.remainingAmount),
              ),
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DetailRow(
                          label: 'Borrower',
                          value: borrower?.name ?? '-',
                        ),
                        DetailRow(
                          label: 'Remaining amount',
                          value: AppFormatters.money(loan.remainingAmount),
                        ),
                      ],
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
                            final amount = double.tryParse(value?.trim() ?? '');
                            if (amount == null || amount <= 0) {
                              return 'Enter a valid payment amount.';
                            }
                            if (amount > loan.remainingAmount) {
                              return 'Amount is more than the remaining balance.';
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

    final controller = context.read<AppStateController>();
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
  const _PaymentDateField({
    required this.controller,
  });

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
          controller.text = AppFormatters.inputDate(picked);
        }
      },
    );
  }
}

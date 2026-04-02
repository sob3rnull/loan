import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_routes.dart';
import '../core/utils/formatters.dart';
import '../core/utils/loan_math.dart';
import '../core/widgets/app_shell.dart';
import '../core/widgets/primary_action_button.dart';
import '../state/app_controller.dart';

class LoanFormScreen extends StatefulWidget {
  const LoanFormScreen({
    super.key,
    required this.args,
  });

  final LoanFormArgs args;

  @override
  State<LoanFormScreen> createState() => _LoanFormScreenState();
}

class _LoanFormScreenState extends State<LoanFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _principalController;
  late final TextEditingController _interestController;
  late final TextEditingController _startDateController;
  late final TextEditingController _dueDateController;
  late final TextEditingController _noteController;
  late String _interestType;

  @override
  void initState() {
    super.initState();
    final loan = widget.args.loan;
    _principalController = TextEditingController(
      text: loan == null ? '' : loan.principal.toStringAsFixed(2),
    );
    _interestController = TextEditingController(
      text: loan == null ? '' : loan.interestValue.toStringAsFixed(2),
    );
    _startDateController = TextEditingController(text: loan?.startDate ?? '');
    _dueDateController = TextEditingController(text: loan?.dueDate ?? '');
    _noteController = TextEditingController(text: loan?.note ?? '');
    _interestType = loan?.interestType ?? LoanMath.flat;
  }

  @override
  void dispose() {
    _principalController.dispose();
    _interestController.dispose();
    _startDateController.dispose();
    _dueDateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _totalRepayablePreview {
    final principal = double.tryParse(_principalController.text.trim()) ?? 0;
    final interest = double.tryParse(_interestController.text.trim()) ?? 0;
    return LoanMath.totalRepayable(
      principal: principal,
      interestValue: interest,
      interestType: _interestType,
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.args.loan == null ? 'Add Loan' : 'Edit Loan';

    return AppShell(
      title: title,
      bottomBar: PrimaryActionButton(
        label: 'Save Loan',
        icon: Icons.save_rounded,
        onPressed: _saveLoan,
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _principalController,
                  decoration: const InputDecoration(labelText: 'Principal'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    final number = double.tryParse(value?.trim() ?? '');
                    if (number == null || number <= 0) {
                      return 'Enter a valid principal amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _interestController,
                  decoration: const InputDecoration(labelText: 'Interest'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    final number = double.tryParse(value?.trim() ?? '');
                    if (number == null || number < 0) {
                      return 'Enter a valid interest amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _interestType,
                  decoration: const InputDecoration(labelText: 'Interest type'),
                  items: const [
                    DropdownMenuItem(
                      value: LoanMath.flat,
                      child: Text('Flat amount'),
                    ),
                    DropdownMenuItem(
                      value: LoanMath.percentage,
                      child: Text('Percentage'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _interestType = value;
                    });
                  },
                ),
                const SizedBox(height: 14),
                _DateField(
                  controller: _startDateController,
                  label: 'Start date',
                ),
                const SizedBox(height: 14),
                _DateField(
                  controller: _dueDateController,
                  label: 'Due date',
                ),
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
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Total repayable',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  Text(
                    Formatters.money(_totalRepayablePreview),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveLoan() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final principal = double.parse(_principalController.text.trim());
    final interestValue = double.parse(_interestController.text.trim());
    final controller = context.read<AppController>();

    final saved = await controller.saveLoanAndPromptShare(
      context,
      existingLoan: widget.args.loan,
      borrowerId: widget.args.borrowerId,
      principal: principal,
      interestValue: interestValue,
      interestType: _interestType,
      startDate: _startDateController.text.trim(),
      dueDate: _dueDateController.text.trim(),
      note: _noteController.text.trim(),
    );

    if (saved && mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.controller,
    required this.label,
  });

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_month_rounded),
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

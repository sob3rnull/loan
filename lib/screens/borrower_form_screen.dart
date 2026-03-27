import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_routes.dart';
import '../core/widgets/app_shell.dart';
import '../core/widgets/primary_action_button.dart';
import '../state/app_controller.dart';

class BorrowerFormScreen extends StatefulWidget {
  const BorrowerFormScreen({
    super.key,
    this.args,
  });

  final BorrowerFormArgs? args;

  @override
  State<BorrowerFormScreen> createState() => _BorrowerFormScreenState();
}

class _BorrowerFormScreenState extends State<BorrowerFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    final borrower = widget.args?.borrower;
    _nameController = TextEditingController(text: borrower?.name ?? '');
    _phoneController = TextEditingController(text: borrower?.phone ?? '');
    _addressController = TextEditingController(text: borrower?.address ?? '');
    _noteController = TextEditingController(text: borrower?.note ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.args?.borrower == null ? 'Add Borrower' : 'Edit Borrower';

    return AppShell(
      title: title,
      bottomBar: PrimaryActionButton(
        label: 'Save Borrower',
        icon: Icons.save_rounded,
        onPressed: _saveBorrower,
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneController,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _addressController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Address'),
                  minLines: 2,
                  maxLines: 3,
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
        ],
      ),
    );
  }

  Future<void> _saveBorrower() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final controller = context.read<AppController>();
    final saved = await controller.saveBorrowerAndPromptShare(
      context,
      existingBorrower: widget.args?.borrower,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      note: _noteController.text.trim(),
    );

    if (saved && mounted) {
      Navigator.of(context).pop();
    }
  }
}

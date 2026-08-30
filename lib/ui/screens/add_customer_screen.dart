import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/customer.dart';
import '../../providers/khata_provider.dart';

class AddCustomerScreen extends StatefulWidget {
  final Customer? customer; // If provided, we are in Edit mode

  const AddCustomerScreen({super.key, this.customer});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _purposeController;
  late TextEditingController _phoneController;

  bool get _isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name ?? '');
    _purposeController = TextEditingController(text: widget.customer?.paymentPurpose ?? '');
    _phoneController = TextEditingController(text: widget.customer?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _purposeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<KhataProvider>(context, listen: false);

    final cleanName = _nameController.text.trim();
    final cleanPurpose = _purposeController.text.trim();
    final cleanPhone = _phoneController.text.trim();

    // Check duplicate name for new customer
    if (!_isEditing && provider.allCustomers.any((c) => c.name.toLowerCase() == cleanName.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("A customer with this name already exists!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    bool success;
    if (_isEditing) {
      final updated = Customer(
        id: widget.customer!.id,
        name: cleanName,
        paymentPurpose: cleanPurpose,
        phone: cleanPhone,
      );
      success = await provider.updateCustomer(updated, oldName: widget.customer!.name);
    } else {
      final newCustomer = Customer(
        name: cleanName,
        paymentPurpose: cleanPurpose,
        phone: cleanPhone,
      );
      success = await provider.addCustomer(newCustomer);
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? "Customer updated successfully" : "Customer added successfully"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? "Failed to update customer" : "Failed to add customer"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? "Edit Customer" : "Add Customer"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: theme.primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isEditing
                            ? "Editing name updates their transaction history automatically."
                            : "Create customer details to log accounts & payment transactions.",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Customer Name Field
              Text(
                "Customer Name",
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: "Enter full name",
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Name is required";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Phone Number Field
              Text(
                "Phone Number",
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: "Enter mobile number",
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Phone number is required";
                  }
                  if (value.trim().length < 7) {
                    return "Enter a valid phone number";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Payment Purpose Field
              Text(
                "Payment Purpose / Remarks",
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _purposeController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: "e.g. Milk Supply, Grocery Account, Monthly Rent",
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 24.0),
                    child: Icon(Icons.description_outlined),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Payment purpose is required";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 48),

              // Submit Button
              ElevatedButton(
                onPressed: _submitForm,
                child: Text(_isEditing ? "Save Changes" : "Create Customer"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

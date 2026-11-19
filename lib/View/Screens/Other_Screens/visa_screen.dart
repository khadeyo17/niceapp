import 'package:flutter/material.dart';

class AddVisaScreen extends StatefulWidget {
  const AddVisaScreen({super.key});

  @override
  State<AddVisaScreen> createState() => _AddVisaScreenState();
}

class _AddVisaScreenState extends State<AddVisaScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  bool isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Visa Card'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _cardNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Card Number',
                  prefixIcon: Icon(Icons.credit_card),
                  border: OutlineInputBorder(),
                ),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Enter card number'
                            : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expiryController,
                      keyboardType: TextInputType.datetime,
                      decoration: const InputDecoration(
                        labelText: 'Expiry MM/YY',
                        border: OutlineInputBorder(),
                      ),
                      validator:
                          (value) =>
                              value == null || value.isEmpty
                                  ? 'Enter expiry date'
                                  : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _cvvController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'CVV',
                        border: OutlineInputBorder(),
                      ),
                      validator:
                          (value) =>
                              value == null || value.isEmpty
                                  ? 'Enter CVV'
                                  : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // TODO: Save Visa card to backend or state
                      setState(() => isSaving = true);
                      Future.delayed(const Duration(seconds: 1), () {
                        setState(() => isSaving = false);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Visa card added successfully!'),
                          ),
                        );
                      });
                    }
                  },
                  child:
                      isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            'Add Card',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

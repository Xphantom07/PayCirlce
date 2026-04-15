import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../providers/user_provider.dart';
import '../utils/validators.dart';
import '../widgets/app_logo.dart';

class UserSetupScreen extends StatefulWidget {
  const UserSetupScreen({super.key});

  @override
  State<UserSetupScreen> createState() => _UserSetupScreenState();
}

class _UserSetupScreenState extends State<UserSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final userProvider = context.read<UserProvider>();
    await userProvider.setupUser(
      name: _nameController.text.trim(),
      pin: _pinController.text.trim(),
    );

    if (!mounted) {
      return;
    }
    Navigator.of(context).pushReplacementNamed(routeJoinGroup);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<UserProvider>().isLoading;
    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(4),
          child: AppLogo(size: 40),
        ),
        title: const Text('Create Profile'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              FocusScope.of(context).unfocus();
              setState(() {});
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(paddingMedium),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Set up your account',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter your name',
                ),
                validator: Validators.validateName,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pinController,
                decoration: const InputDecoration(
                  labelText: '4-digit PIN',
                  hintText: 'Enter PIN',
                ),
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                validator: Validators.validatePin,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPinController,
                decoration: const InputDecoration(
                  labelText: 'Confirm PIN',
                  hintText: 'Re-enter PIN',
                ),
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                validator: (value) {
                  final pinError = Validators.validatePin(value);
                  if (pinError != null) {
                    return pinError;
                  }
                  return Validators.validatePinsMatch(
                    _pinController.text.trim(),
                    _confirmPinController.text.trim(),
                  );
                },
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : _submit,
                child: Text(isLoading ? 'Creating...' : 'Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

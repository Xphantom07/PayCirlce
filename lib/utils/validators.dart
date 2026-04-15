class Validators {
  /// Validate user name
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name cannot be empty';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.length > 50) {
      return 'Name cannot exceed 50 characters';
    }
    return null;
  }

  /// Validate PIN
  static String? validatePin(String? value) {
    if (value == null || value.isEmpty) {
      return 'PIN cannot be empty';
    }
    if (value.length != 4) {
      return 'PIN must be exactly 4 digits';
    }
    if (int.tryParse(value) == null) {
      return 'PIN must contain only digits';
    }
    return null;
  }

  /// Validate PINs match
  static String? validatePinsMatch(String? pin, String? confirmPin) {
    if (pin != confirmPin) {
      return 'PINs do not match';
    }
    return null;
  }

  /// Validate group code
  static String? validateGroupCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Group code cannot be empty';
    }
    if (value.length != 6) {
      return 'Group code must be 6 characters';
    }
    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(value)) {
      return 'Group code must contain only uppercase letters and numbers';
    }
    return null;
  }

  /// Validate group name
  static String? validateGroupName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Group name cannot be empty';
    }
    if (value.length < 2) {
      return 'Group name must be at least 2 characters';
    }
    if (value.length > 50) {
      return 'Group name cannot exceed 50 characters';
    }
    return null;
  }

  /// Validate amount (expense)
  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Amount cannot be empty';
    }
    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Please enter a valid amount';
    }
    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }
    if (amount > 999999) {
      return 'Amount is too large';
    }
    return null;
  }
}

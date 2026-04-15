import 'dart:math';

import 'package:uuid/uuid.dart';
import '../constants/app_constants.dart';

class Helpers {
  /// Generate a unique user ID
  static String generateUserId() {
    return const Uuid().v4();
  }

  /// Generate a random group code (6 characters, alphanumeric uppercase)
  static String generateGroupCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(
      groupCodeLength,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  /// Calculate expense split
  static Map<String, double> calculateSplit(
    double amount,
    List<String> participants,
  ) {
    final share = amount / participants.length;
    final split = <String, double>{};

    for (final participant in participants) {
      split[participant] = -share;
    }

    // Payer gets positive balance
    split[participants[0]] = amount - share;

    return split;
  }

  /// Get avatar initials from name
  static String getInitials(String name) {
    return name
        .split(' ')
        .take(2)
        .map((part) => part.isNotEmpty ? part[0].toUpperCase() : '')
        .join();
  }
}

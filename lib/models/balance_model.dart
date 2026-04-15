class Balance {
  final String userId;
  final double amount; // +: owed to user, -: user owes
  final DateTime lastUpdated;

  Balance({
    required this.userId,
    required this.amount,
    required this.lastUpdated,
  });

  /// Convert Balance to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'amount': amount,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// Create Balance from JSON (Firestore)
  factory Balance.fromJson(Map<String, dynamic> json) {
    return Balance(
      userId: json['userId'] as String,
      amount: (json['amount'] as num).toDouble(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  /// Create a copy with some fields replaced
  Balance copyWith({String? userId, double? amount, DateTime? lastUpdated}) {
    return Balance(
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  String toString() => 'Balance(userId: $userId, amount: $amount)';
}

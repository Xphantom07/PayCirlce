class Transaction {
  final String txnId;
  final double amount;
  final String paidBy; // userId
  final List<String> participants; // [userId1, userId2, ...]
  final DateTime timestamp;
  final bool deleted;
  final String? deletedBy; // userId of who deleted it
  final DateTime? deletedAt;
  final String? description;
  final String? tag;

  Transaction({
    required this.txnId,
    required this.amount,
    required this.paidBy,
    required this.participants,
    required this.timestamp,
    this.deleted = false,
    this.deletedBy,
    this.deletedAt,
    this.description,
    this.tag,
  });

  /// Convert Transaction to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'txnId': txnId,
      'amount': amount,
      'paidBy': paidBy,
      'participants': participants,
      'timestamp': timestamp.toIso8601String(),
      'deleted': deleted,
      'deletedBy': deletedBy,
      'deletedAt': deletedAt?.toIso8601String(),
      'description': description,
      'tag': tag,
    };
  }

  /// Create Transaction from JSON (Firestore)
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      txnId: json['txnId'] as String,
      amount: (json['amount'] as num).toDouble(),
      paidBy: json['paidBy'] as String,
      participants: List<String>.from(json['participants'] as List),
      timestamp: DateTime.parse(json['timestamp'] as String),
      deleted: json['deleted'] as bool? ?? false,
      deletedBy: json['deletedBy'] as String?,
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
      description: json['description'] as String?,
      tag: json['tag'] as String?,
    );
  }

  /// Create a copy with some fields replaced
  Transaction copyWith({
    String? txnId,
    double? amount,
    String? paidBy,
    List<String>? participants,
    DateTime? timestamp,
    bool? deleted,
    String? deletedBy,
    DateTime? deletedAt,
    String? description,
    String? tag,
  }) {
    return Transaction(
      txnId: txnId ?? this.txnId,
      amount: amount ?? this.amount,
      paidBy: paidBy ?? this.paidBy,
      participants: participants ?? this.participants,
      timestamp: timestamp ?? this.timestamp,
      deleted: deleted ?? this.deleted,
      deletedBy: deletedBy ?? this.deletedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      description: description ?? this.description,
      tag: tag ?? this.tag,
    );
  }

  @override
  String toString() =>
      'Transaction(id: $txnId, amount: $amount, paidBy: $paidBy, deleted: $deleted)';
}

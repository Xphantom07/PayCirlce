class User {
  final String userId;
  final String name;
  final String email;
  final String? photoUrl;
  final String pinHash;
  final DateTime createdAt;
  final bool isGroupAdmin;

  User({
    required this.userId,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.pinHash,
    required this.createdAt,
    this.isGroupAdmin = false,
  });

  /// Convert User to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'pinHash': pinHash,
      'createdAt': createdAt.toIso8601String(),
      'isGroupAdmin': isGroupAdmin,
    };
  }

  /// Create User from JSON (Firestore)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'] as String,
      name: json['name'] as String,
      email: json['email'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      pinHash: json['pinHash'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isGroupAdmin: json['isGroupAdmin'] as bool? ?? false,
    );
  }

  /// Create a copy with some fields replaced
  User copyWith({
    String? userId,
    String? name,
    String? email,
    String? photoUrl,
    String? pinHash,
    DateTime? createdAt,
    bool? isGroupAdmin,
  }) {
    return User(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      pinHash: pinHash ?? this.pinHash,
      createdAt: createdAt ?? this.createdAt,
      isGroupAdmin: isGroupAdmin ?? this.isGroupAdmin,
    );
  }

  @override
  String toString() =>
      'User(userId: $userId, name: $name, isAdmin: $isGroupAdmin)';
}

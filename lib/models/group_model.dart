class Group {
  final String groupId;
  final String groupCode; // 6-character code
  final String groupName;
  final Set<String> members; // Set of userIds
  final String adminId; // Creator userId
  final DateTime createdAt;
  final List<String> tags;

  Group({
    required this.groupId,
    required this.groupCode,
    required this.groupName,
    required this.members,
    required this.adminId,
    required this.createdAt,
    this.tags = const <String>[],
  });

  /// Convert Group to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'groupCode': groupCode,
      'groupName': groupName,
      'members': members.toList(),
      'adminId': adminId,
      'createdAt': createdAt.toIso8601String(),
      'tags': tags,
    };
  }

  /// Create Group from JSON (Firestore)
  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      groupId: json['groupId'] as String,
      groupCode: json['groupCode'] as String,
      groupName: json['groupName'] as String,
      members: Set<String>.from(json['members'] as List),
      adminId: json['adminId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      tags: List<String>.from(json['tags'] as List? ?? const <String>[]),
    );
  }

  /// Create a copy with some fields replaced
  Group copyWith({
    String? groupId,
    String? groupCode,
    String? groupName,
    Set<String>? members,
    String? adminId,
    DateTime? createdAt,
    List<String>? tags,
  }) {
    return Group(
      groupId: groupId ?? this.groupId,
      groupCode: groupCode ?? this.groupCode,
      groupName: groupName ?? this.groupName,
      members: members ?? this.members,
      adminId: adminId ?? this.adminId,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
    );
  }

  /// Check if user is admin
  bool isUserAdmin(String userId) => userId == adminId;

  /// Check if user is member
  bool isMember(String userId) => members.contains(userId);

  @override
  String toString() =>
      'Group(id: $groupId, code: $groupCode, name: $groupName, members: ${members.length})';
}

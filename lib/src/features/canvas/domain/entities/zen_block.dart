class ZenBlock {
  final String id;
  final String projectId;
  final String type;
  final String content;
  final Map<String, dynamic> metadata;
  final double position;
  final String? parentId;
  final DateTime? createdAt;

  const ZenBlock({
    required this.id,
    required this.projectId,
    required this.type,
    required this.content,
    required this.metadata,
    required this.position,
    this.parentId,
    this.createdAt,
  });

  ZenBlock copyWith({
    String? id,
    String? projectId,
    String? type,
    String? content,
    Map<String, dynamic>? metadata,
    double? position,
    String? parentId,
    DateTime? createdAt,
  }) {
    return ZenBlock(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      type: type ?? this.type,
      content: content ?? this.content,
      metadata: metadata ?? this.metadata,
      position: position ?? this.position,
      parentId: parentId ?? this.parentId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

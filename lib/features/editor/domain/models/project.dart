import 'dart:convert';

import 'package:sticker_studio_ai/features/editor/domain/models/layer.dart';

/// A sticker project: an ordered layer stack on a 512x512 transparent canvas.
class StickerProject {
  const StickerProject({
    required this.id,
    required this.title,
    required this.layers,
    this.folder,
    this.tags = const [],
    this.favorite = false,
    this.createdAt,
    this.updatedAt,
    this.thumbnailPath,
  });

  final String id;
  final String title;

  /// Bottom-to-top paint order.
  final List<Layer> layers;
  final String? folder;
  final List<String> tags;
  final bool favorite;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? thumbnailPath;

  bool get isAnimated => layers.any((l) => l.animation != null);

  StickerProject copyWith({
    String? title,
    List<Layer>? layers,
    String? folder,
    List<String>? tags,
    bool? favorite,
    DateTime? updatedAt,
    String? thumbnailPath,
  }) =>
      StickerProject(
        id: id,
        title: title ?? this.title,
        layers: layers ?? this.layers,
        folder: folder ?? this.folder,
        tags: tags ?? this.tags,
        favorite: favorite ?? this.favorite,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
        thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      );

  String encode() => jsonEncode({
        'id': id,
        'title': title,
        'layers': layers.map((l) => l.toJson()).toList(),
      });

  factory StickerProject.decode(
    String json, {
    String? folder,
    List<String> tags = const [],
    bool favorite = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? thumbnailPath,
  }) {
    final m = jsonDecode(json) as Map<String, dynamic>;
    return StickerProject(
      id: m['id'] as String,
      title: m['title'] as String,
      layers: (m['layers'] as List)
          .map((l) => Layer.fromJson(l as Map<String, dynamic>))
          .toList(),
      folder: folder,
      tags: tags,
      favorite: favorite,
      createdAt: createdAt,
      updatedAt: updatedAt,
      thumbnailPath: thumbnailPath,
    );
  }
}

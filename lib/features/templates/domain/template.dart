import 'package:sticker_studio_ai/features/editor/domain/models/project.dart';

enum TemplateCategory {
  goodMorning,
  goodEvening,
  friday,
  ramadan,
  eid,
  love,
  congratulations,
  islamic,
  birthdays,
  gaming,
  cars,
  anime,
  memes,
  football,
  nature,
  luxury,
  business,
  socialMedia,
}

/// A template is just a serialized project + metadata, so opening a template
/// IS opening a project — no separate pipeline, everything stays editable.
class StickerTemplate {
  const StickerTemplate({
    required this.id,
    required this.category,
    required this.titleAr,
    required this.titleEn,
    required this.projectJson,
    this.premium = false,
  });

  final String id;
  final TemplateCategory category;
  final String titleAr;
  final String titleEn;
  final String projectJson;
  final bool premium;

  StickerProject open() => StickerProject.decode(projectJson);
}

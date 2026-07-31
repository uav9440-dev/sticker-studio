import 'dart:ui';

import 'package:sticker_studio_ai/features/animation/domain/animation_spec.dart';
import 'package:sticker_studio_ai/features/editor/domain/models/layer.dart';
import 'package:sticker_studio_ai/features/editor/domain/models/project.dart';
import 'package:sticker_studio_ai/features/effects/domain/effect.dart';
import 'package:sticker_studio_ai/features/templates/domain/template.dart';

/// Starter templates, built with the real layer model then serialized — the
/// same schema the template CDN will ship, so the store is just more rows.
StickerTemplate _text({
  required String id,
  required TemplateCategory category,
  required String titleAr,
  required String titleEn,
  required String text,
  required String font,
  required TextFill fill,
  required Color color,
  Color? gradientB,
  TextPathMode path = TextPathMode.none,
  List<LayerEffect> effects = const [],
  AnimPreset? anim,
}) {
  final project = StickerProject(
    id: id,
    title: titleAr,
    layers: [
      TextLayer(
        id: '${id}_l1',
        transform: const LayerTransform(),
        text: text,
        fontFamily: font,
        fontSize: 76,
        fill: fill,
        color: color,
        gradientColors: [color, gradientB ?? color],
        pathMode: path,
        pathCurvature: 0.4,
        effects: effects,
        animation: anim == null
            ? null
            : AnimationSpec(
                preset: anim,
                loop: anim.group == AnimGroup.continuous,
                duration: const Duration(milliseconds: 1500),
              ),
        name: text,
      ),
    ],
  );
  return StickerTemplate(
    id: id,
    category: category,
    titleAr: titleAr,
    titleEn: titleEn,
    projectJson: project.encode(),
  );
}

final starterTemplates = <StickerTemplate>[
  _text(
    id: 'tpl_gm_gold',
    category: TemplateCategory.goodMorning,
    titleAr: 'صباح الخير — ذهبي فاخر',
    titleEn: 'Good Morning — Luxury Gold',
    text: 'صباح الخير',
    font: 'Aref Ruqaa',
    fill: TextFill.gold,
    color: const Color(0xFFC9A24B),
    gradientB: const Color(0xFFFFE9A8),
    path: TextPathMode.arcUp,
    effects: const [
      LayerEffect(type: EffectType.shadow, intensity: 0.6, radius: 0.25),
    ],
    anim: AnimPreset.glowPulse,
  ),
  _text(
    id: 'tpl_ge_night',
    category: TemplateCategory.goodEvening,
    titleAr: 'مساء الخير — ليلي',
    titleEn: 'Good Evening — Night',
    text: 'مساء الخير',
    font: 'Amiri',
    fill: TextFill.gradient,
    color: const Color(0xFF5C6BC0),
    gradientB: const Color(0xFF9FA8DA),
    effects: const [
      LayerEffect(
          type: EffectType.glow,
          intensity: 0.7,
          radius: 0.4,
          color: Color(0xFF7986CB)),
    ],
    anim: AnimPreset.float,
  ),
  _text(
    id: 'tpl_friday',
    category: TemplateCategory.friday,
    titleAr: 'جمعة مباركة',
    titleEn: 'Blessed Friday',
    text: 'جمعة مباركة',
    font: 'Reem Kufi',
    fill: TextFill.gradient,
    color: const Color(0xFF2E6E5E),
    gradientB: const Color(0xFFC9A24B),
    path: TextPathMode.arcUp,
    anim: AnimPreset.fadeIn,
  ),
  _text(
    id: 'tpl_ramadan',
    category: TemplateCategory.ramadan,
    titleAr: 'رمضان كريم',
    titleEn: 'Ramadan Kareem',
    text: 'رمضان كريم',
    font: 'Amiri',
    fill: TextFill.gold,
    color: const Color(0xFF4527A0),
    gradientB: const Color(0xFFC9A24B),
    effects: const [
      LayerEffect(
          type: EffectType.sparkles, intensity: 0.6, speed: 0.4,
          color: Color(0xFFFFE9A8)),
    ],
    anim: AnimPreset.breathing,
  ),
  _text(
    id: 'tpl_eid',
    category: TemplateCategory.eid,
    titleAr: 'عيد مبارك',
    titleEn: 'Eid Mubarak',
    text: 'عيد مبارك',
    font: 'Aref Ruqaa',
    fill: TextFill.gold,
    color: const Color(0xFFC9A24B),
    gradientB: const Color(0xFF2E6E5E),
    anim: AnimPreset.pop,
  ),
  _text(
    id: 'tpl_love',
    category: TemplateCategory.love,
    titleAr: 'أحبك ❤️',
    titleEn: 'Love',
    text: 'أحبك ❤️',
    font: 'Cairo',
    fill: TextFill.gradient,
    color: const Color(0xFFE53935),
    gradientB: const Color(0xFFFF8A80),
    anim: AnimPreset.pulse,
  ),
  _text(
    id: 'tpl_congrats',
    category: TemplateCategory.congratulations,
    titleAr: 'ألف مبروك',
    titleEn: 'Congratulations',
    text: 'ألف مبروك 🎉',
    font: 'Marhey',
    fill: TextFill.gradient,
    color: const Color(0xFFC9A24B),
    gradientB: const Color(0xFFE53935),
    anim: AnimPreset.bounceIn,
  ),
  _text(
    id: 'tpl_gaming',
    category: TemplateCategory.gaming,
    titleAr: 'GG — قيمنق',
    titleEn: 'GG — Gaming Neon',
    text: 'GG',
    font: 'Bebas Neue',
    fill: TextFill.neon,
    color: const Color(0xFF00E5FF),
    effects: const [
      LayerEffect(
          type: EffectType.glow,
          intensity: 0.9,
          radius: 0.5,
          color: Color(0xFF00E5FF)),
    ],
    anim: AnimPreset.glowPulse,
  ),
  _text(
    id: 'tpl_bday',
    category: TemplateCategory.birthdays,
    titleAr: 'عيد ميلاد سعيد',
    titleEn: 'Happy Birthday',
    text: 'عيد ميلاد سعيد 🎂',
    font: 'Cairo',
    fill: TextFill.gradient,
    color: const Color(0xFFEC407A),
    gradientB: const Color(0xFFFFD54F),
    anim: AnimPreset.elasticIn,
  ),
  _text(
    id: 'tpl_luxury',
    category: TemplateCategory.luxury,
    titleAr: 'فخامة',
    titleEn: 'Luxury',
    text: 'VIP',
    font: 'Playfair Display',
    fill: TextFill.gold,
    color: const Color(0xFFC9A24B),
    effects: const [
      LayerEffect(type: EffectType.shadow, intensity: 0.7, radius: 0.3),
      LayerEffect(type: EffectType.outline, intensity: 1, radius: 0.08,
          color: Color(0xFF12100E)),
    ],
    anim: AnimPreset.scaleIn,
  ),
];

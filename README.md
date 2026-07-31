# Sticker Studio AI — استوديو الملصقات

An Arabic-first professional design studio for creating static and animated
WhatsApp stickers on Android. Flutter · Material 3 · Riverpod · Clean
Architecture · SQLite.

## What is implemented in this codebase

The editor core is real and working end to end at the architecture level:
an immutable layer model (text and image layers with full serialization), a
Riverpod editor controller with O(1) undo/redo, gesture-driven move / pinch
scale / rotate / flip with center-snapping and angle snapping, a zoomable
512×512 canvas with a transparency checkerboard, safe-margin overlay and
live snap guides, a shared `EffectRenderer` used identically by the live
preview and the exporter (so preview always matches output), a typed effect
catalog covering all 32 requested effects with the paint-category effects
(glow, shadow, outline, blur, bevel, metallic fills, curved text) rendered
today, a full animation system with 21 presets plus keyframes, loop, speed,
delay and a live preview clock, a WhatsApp-compliant export service that
validates the 100 KB / 500 KB / 10 s limits and degrades quality and fps
automatically, a SQLite library with folders, favorites, tags and indexed
search, an offline AI design engine that turns Arabic or English prompts
like «صمّم ملصق صباح الخير ذهبي فاخر» into a complete styled, animated
project, the template system (a template is a serialized project, so every
template is fully editable), Arabic/English localization with Arabic as the
default locale, and the «Night Atelier» Material 3 theme with dark/light
modes and Material You dynamic color harmonized into the brand gold.

## What still needs native or backend work

Animated WebP encoding and MP4 muxing require a small Android platform
channel around libwebp and MediaCodec; the Dart side and its fallbacks are
already in place in `ExportService`. On-device background removal should use
a TFLite/MediaPipe selfie-segmentation model behind the `RemoteDesignBackend`
interface, which also hosts the optional LLM design generation and
text-to-image backends. Direct "add to WhatsApp" uses the
`whatsapp_stickers_handler` plugin already declared in pubspec. The particle
and shader effect categories have their data model and renderer hooks wired;
their fragment shaders live in `assets/shaders` as the next milestone. See
docs/ROADMAP.md for the full sequencing.

## Getting started

Requires Flutter 3.22+. Run `flutter pub get`, then `flutter gen-l10n`, then
`flutter run`. The l10n step generates `lib/l10n/app_localizations.dart`
from the ARB files.

## Project layout

`lib/app` holds the shell, router and theme. `lib/core` holds WhatsApp spec
constants, the Result type and the SQLite bootstrap. Each folder under
`lib/features` is a vertical slice with `domain` (pure models), `application`
(Riverpod controllers), `data` (repositories) and `presentation` (widgets),
so features ship and evolve independently.

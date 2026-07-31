# Architecture

## Principles

The whole app is built around three decisions. First, everything on the
canvas is an immutable `Layer`; edits return new instances, which makes
undo/redo a pointer swap, makes autosave and cloud sync trivial (documents
are plain JSON), and makes templates identical to projects. Second, one
renderer: `EffectRenderer` paints layers for the live editor, for thumbnail
generation, and for every export frame, so what the user previews is
byte-for-byte what WhatsApp receives. Third, capability interfaces: anything
that could be local or remote (AI design, image generation, background
removal, cloud backup) sits behind an abstract interface bound through
Riverpod, so the app is fully functional offline and backends can be added
without touching feature code.

## State flow

UI widgets watch `editorControllerProvider`. Gestures call controller
methods; during a drag the controller uses `History.replace` so the entire
gesture collapses into a single undo step committed on `endGesture`. The
preview clock is a `Ticker` that only ticks while an animation exists or
playback is on, keeping idle CPU at zero. Property sheets write through the
same controller, which means styling, effects and animations are all
undoable through one mechanism.

## Rendering and performance

The canvas is a `CustomPainter` working in 512×512 sticker space and scaled
to the view, so all math is resolution-independent and export needs no
separate coordinate system. Text effects that need copies of the glyph run
(shadow, glow, outline) reuse laid-out `TextPainter`s; image layers decode
once into an LRU `ui.Image` cache injected as `imageResolver`. Shader-class
effects (chrome, holographic, fire…) are fragment shaders loaded with
`FragmentProgram`, driven by the same preview clock; particle effects are a
lightweight emitter painted after the layer. Because painting is plain
Skia/Impeller work, 120 Hz displays are served automatically; the ticker is
frame-callback based, not timer based.

## Export pipeline

`ExportService.renderFrame` records the same paint calls into a
`PictureRecorder`, rasterizes to RGBA and hands frames to encoders. Static
WebP re-encodes at descending quality until it fits the 100 KB WhatsApp
budget. Animated export samples the timeline at the requested fps and, if
over the 500 KB budget, retries at 15/12/10 fps before failing with an
actionable Arabic error message. Animated WebP and MP4 use a platform
channel (`studio/webp`) wrapping libwebp's `WebPAnimEncoder` and
MediaCodec; GIF and PNG are pure Dart via the `image` package. Pack export
builds the tray icon (96×96, ≤50 KB) and hands the pack to
`whatsapp_stickers_handler` for the native "add to WhatsApp" flow.

## Persistence

SQLite stores each project as a JSON document plus indexed columns for
title, folder, favorite and timestamps. Search hits the index, never the
blob. Because a row is self-contained, cloud backup is last-write-wins row
merge by `updated_at`, and importing a shared sticker project is an insert.

## RTL and localization

Arabic is the template locale (`app_ar.arb`); the entire layout tree uses
directional widgets (`EdgeInsetsDirectional`, `ListTile`, `Row` under RTL),
so flipping to English flips the interface automatically. Text layers carry
their own direction flag independent of UI locale, because users routinely
mix Arabic stickers with an English UI and vice versa.

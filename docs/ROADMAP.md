# Roadmap

## Milestone 1 — Ship the core loop (this codebase, hardened)

Wire image_picker/file_picker into the tool rail, add the crop sheet on
ImageLayer, generate library thumbnails on save via `renderFrame`, add the
animation studio sheet (preset grid grouped Entrance/Exit/Continuous, speed
and duration sliders, loop toggle, timeline scrubber over `previewClock`),
and finish the settings screen (theme mode, dynamic color, locale).

## Milestone 2 — Native encoders and WhatsApp

Android platform channel around libwebp for lossy static WebP and
`WebPAnimEncoder` for animated stickers; MediaCodec for MP4. Tray icon
generation, pack builder UI (3–30 stickers), and the
whatsapp_stickers_handler handoff. This milestone makes exports fully
spec-compliant on real devices.

## Milestone 3 — On-device intelligence

MediaPipe selfie/object segmentation for one-tap background removal and
object extraction, running behind `RemoteDesignBackend.removeBackground` so
a server implementation can substitute on low-end devices. Image
enhancement via a small ESRGAN-class TFLite model. Font store: downloadable
Arabic/English font packs plus user TTF/OTF import registered with
`FontLoader` and persisted.

## Milestone 4 — Shader and particle effects

Fragment shaders for chrome, holographic, glass, fire, ice, smoke, light
sweep, lens flare and RGB shift in `assets/shaders`, parameterized by the
existing `LayerEffect` fields (intensity/speed/colors). Particle emitters
(sparkles, stars, snow, rain, confetti, magic dust, lightning) as a pooled
painter driven by the preview clock, exported frame-perfectly because they
read the same clock as `renderFrame`.

## Milestone 5 — Content and cloud

Template CDN with the eighteen categories (JSON packs in the existing
template schema), search and favorites; cloud backup (row sync as described
in ARCHITECTURE.md); community marketplace and sticker sharing; remote LLM
design backend upgrading the offline rule engine; text-to-image generation.

## Milestone 6 — Expansion

Voice-to-sticker (speech-to-text into the AI engine), photo-to-sticker
one-tap flow, Telegram sticker import (TGS/WebM parsing into layers where
possible, flat import otherwise), Instagram story sticker sizes, plugin
system exposing the layer/effect model to third parties, AI animation
generation and color-harmony suggestions.

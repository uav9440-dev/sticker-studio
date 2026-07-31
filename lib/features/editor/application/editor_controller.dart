import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:sticker_studio_ai/core/constants/whatsapp_specs.dart';
import 'package:sticker_studio_ai/features/animation/domain/animation_spec.dart';
import 'package:sticker_studio_ai/features/editor/application/history.dart';
import 'package:sticker_studio_ai/features/editor/domain/models/layer.dart';
import 'package:sticker_studio_ai/features/editor/domain/models/project.dart';
import 'package:sticker_studio_ai/features/effects/domain/effect.dart';

const _uuid = Uuid();

/// Snap guides produced during a drag, consumed by the canvas overlay painter.
class SnapGuides {
  const SnapGuides({this.vertical, this.horizontal});
  final double? vertical; // x of active vertical guide
  final double? horizontal; // y of active horizontal guide
  bool get any => vertical != null || horizontal != null;
}

class EditorState {
  const EditorState({
    required this.project,
    this.selectedLayerId,
    this.canUndo = false,
    this.canRedo = false,
    this.guides = const SnapGuides(),
    this.previewClock = Duration.zero,
    this.playing = false,
  });

  final StickerProject project;
  final String? selectedLayerId;
  final bool canUndo;
  final bool canRedo;
  final SnapGuides guides;

  /// Shared animation clock for live preview; also drives shader effects.
  final Duration previewClock;
  final bool playing;

  Layer? get selected => selectedLayerId == null
      ? null
      : project.layers.where((l) => l.id == selectedLayerId).firstOrNull;

  EditorState copyWith({
    StickerProject? project,
    String? selectedLayerId,
    bool clearSelection = false,
    bool? canUndo,
    bool? canRedo,
    SnapGuides? guides,
    Duration? previewClock,
    bool? playing,
  }) =>
      EditorState(
        project: project ?? this.project,
        selectedLayerId:
            clearSelection ? null : (selectedLayerId ?? this.selectedLayerId),
        canUndo: canUndo ?? this.canUndo,
        canRedo: canRedo ?? this.canRedo,
        guides: guides ?? this.guides,
        previewClock: previewClock ?? this.previewClock,
        playing: playing ?? this.playing,
      );
}

final editorControllerProvider =
    NotifierProvider<EditorController, EditorState>(EditorController.new);

class EditorController extends Notifier<EditorState> {
  late History<StickerProject> _history;
  static const double _snapThreshold = 8; // px in canvas space
  static const double _center = WhatsAppSpecs.stickerSize / 2;

  @override
  EditorState build() {
    final project = StickerProject(
      id: _uuid.v4(),
      title: '',
      layers: const [],
      createdAt: DateTime.now(),
    );
    _history = History(project);
    return EditorState(project: project);
  }

  void loadProject(StickerProject project) {
    _history = History(project);
    state = EditorState(project: project);
  }

  // -- Layer lifecycle ------------------------------------------------------

  void addTextLayer(String text, {bool rtl = true}) {
    final layer = TextLayer(
      id: _uuid.v4(),
      transform: const LayerTransform(),
      text: text,
      textDirectionRtl: rtl,
      name: text.length > 12 ? '${text.substring(0, 12)}…' : text,
    );
    _commit(state.project
        .copyWith(layers: [...state.project.layers, layer]));
    state = state.copyWith(selectedLayerId: layer.id);
  }

  void addImageLayer(String path) {
    final layer = ImageLayer(
      id: _uuid.v4(),
      transform: const LayerTransform(scale: 0.8),
      sourcePath: path,
      name: path.split('/').last,
    );
    _commit(state.project
        .copyWith(layers: [...state.project.layers, layer]));
    state = state.copyWith(selectedLayerId: layer.id);
  }

  void deleteSelected() {
    final id = state.selectedLayerId;
    if (id == null) return;
    _commit(state.project.copyWith(
        layers: state.project.layers.where((l) => l.id != id).toList()));
    state = state.copyWith(clearSelection: true);
  }

  void duplicateSelected() {
    final src = state.selected;
    if (src == null) return;
    final json = src.toJson()..['id'] = _uuid.v4();
    final copy = Layer.fromJson(json).copyWith(
      transform: src.transform
          .copyWith(position: src.transform.position + const Offset(24, 24)),
    );
    _commit(
        state.project.copyWith(layers: [...state.project.layers, copy]));
    state = state.copyWith(selectedLayerId: copy.id);
  }

  void reorderLayer(int oldIndex, int newIndex) {
    final layers = [...state.project.layers];
    final layer = layers.removeAt(oldIndex);
    layers.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, layer);
    _commit(state.project.copyWith(layers: layers));
  }

  void select(String? id) => state = id == null
      ? state.copyWith(clearSelection: true)
      : state.copyWith(selectedLayerId: id);

  // -- Transform gestures ---------------------------------------------------
  // During a gesture we use history.replace so the whole drag is a single
  // undo step, finalized in [endGesture].

  void moveSelected(Offset delta) {
    _updateSelectedLive((l) {
      var next = l.transform.position + delta;
      double? vGuide, hGuide;
      if ((next.dx - _center).abs() < _snapThreshold) {
        next = Offset(_center, next.dy);
        vGuide = _center;
      }
      if ((next.dy - _center).abs() < _snapThreshold) {
        next = Offset(next.dx, _center);
        hGuide = _center;
      }
      state = state.copyWith(
          guides: SnapGuides(vertical: vGuide, horizontal: hGuide));
      return l.copyWith(transform: l.transform.copyWith(position: next));
    });
  }

  void scaleRotateSelected({double scaleFactor = 1, double rotationDelta = 0}) {
    _updateSelectedLive((l) {
      var rot = l.transform.rotation + rotationDelta;
      // Angle snapping at 0/90/180/270°.
      for (final snap in [0.0, math.pi / 2, math.pi, 3 * math.pi / 2]) {
        if ((rot % (2 * math.pi) - snap).abs() < 0.05) rot = snap;
      }
      return l.copyWith(
        transform: l.transform.copyWith(
          scale: (l.transform.scale * scaleFactor).clamp(0.05, 12.0),
          rotation: rot,
        ),
      );
    });
  }

  void flipSelected({bool horizontal = true}) => updateSelected((l) => l.copyWith(
        transform: horizontal
            ? l.transform.copyWith(flipX: !l.transform.flipX)
            : l.transform.copyWith(flipY: !l.transform.flipY),
      ));

  void endGesture() {
    _history.push(state.project);
    state = state.copyWith(
      guides: const SnapGuides(),
      canUndo: _history.canUndo,
      canRedo: _history.canRedo,
    );
  }

  // -- Property edits (each is one undo step) -------------------------------

  void updateSelected(Layer Function(Layer) update) {
    final id = state.selectedLayerId;
    if (id == null) return;
    _commit(_projectWith(id, update));
  }

  void updateSelectedText(TextLayer Function(TextLayer) update) =>
      updateSelected((l) => l is TextLayer ? update(l) : l);

  void setEffect(LayerEffect effect) => updateSelected((l) {
        final effects = [...l.effects];
        final i = effects.indexWhere((e) => e.type == effect.type);
        if (i >= 0) {
          effects[i] = effect;
        } else {
          effects.add(effect);
        }
        return l.copyWith(effects: effects);
      });

  void removeEffect(EffectType type) => updateSelected((l) => l.copyWith(
      effects: l.effects.where((e) => e.type != type).toList()));

  void setAnimation(AnimationSpec? spec) => updateSelected(
      (l) => l.copyWith(animation: spec, clearAnimation: spec == null));

  // -- Undo / redo ----------------------------------------------------------

  void undo() => state = state.copyWith(
        project: _history.undo(),
        canUndo: _history.canUndo,
        canRedo: _history.canRedo,
      );

  void redo() => state = state.copyWith(
        project: _history.redo(),
        canUndo: _history.canUndo,
        canRedo: _history.canRedo,
      );

  // -- Preview clock --------------------------------------------------------

  void tick(Duration clock) => state = state.copyWith(previewClock: clock);
  void setPlaying(bool playing) => state = state.copyWith(playing: playing);

  // -- Internals ------------------------------------------------------------

  StickerProject _projectWith(String id, Layer Function(Layer) update) =>
      state.project.copyWith(
        layers: [
          for (final l in state.project.layers) l.id == id ? update(l) : l
        ],
      );

  void _updateSelectedLive(Layer Function(Layer) update) {
    final id = state.selectedLayerId;
    if (id == null) return;
    final next = _projectWith(id, update);
    _history.replace(next);
    state = state.copyWith(project: next);
  }

  void _commit(StickerProject next) {
    _history.push(next);
    state = state.copyWith(
      project: next,
      canUndo: _history.canUndo,
      canRedo: _history.canRedo,
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

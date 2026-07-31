import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';

final imageCacheProvider =
    Provider<ImageCacheService>((_) => ImageCacheService());

/// Decodes image files once and serves them synchronously to painters and
/// the exporter. Simple LRU keeps memory bounded on long sessions.
class ImageCacheService {
  final _cache = <String, ui.Image>{};
  static const _capacity = 24;

  ui.Image? resolve(String path) => _cache[path];

  Future<ui.Image> load(String path) async {
    final cached = _cache[path];
    if (cached != null) return cached;
    final bytes = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (_cache.length >= _capacity) {
      _cache.remove(_cache.keys.first)?.dispose();
    }
    _cache[path] = frame.image;
    return frame.image;
  }

  void evict(String path) => _cache.remove(path)?.dispose();
}

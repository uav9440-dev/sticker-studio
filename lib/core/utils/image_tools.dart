import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Pure-Dart image utilities that work fully offline.
class ImageTools {
  /// Removes a near-uniform background (white studio shots, logos, clip
  /// art) by sampling the four corners and clearing connected pixels within
  /// [tolerance]. ML segmentation for complex photos arrives in Milestone 3;
  /// this covers the most common sticker sources today.
  static Future<String> removeSolidBackground(String path,
      {int tolerance = 42}) async {
    final src = img.decodeImage(await File(path).readAsBytes())!;
    final rgba = src.convert(numChannels: 4);

    final corners = [
      rgba.getPixel(0, 0),
      rgba.getPixel(rgba.width - 1, 0),
      rgba.getPixel(0, rgba.height - 1),
      rgba.getPixel(rgba.width - 1, rgba.height - 1),
    ];
    final br = corners.map((c) => c.r).reduce((a, b) => a + b) ~/ 4;
    final bg = corners.map((c) => c.g).reduce((a, b) => a + b) ~/ 4;
    final bb = corners.map((c) => c.b).reduce((a, b) => a + b) ~/ 4;

    bool isBg(num r, num g, num b) =>
        (r - br).abs() + (g - bg).abs() + (b - bb).abs() < tolerance * 3;

    // BFS flood fill from the borders so same-colored pixels INSIDE the
    // subject (eyes, highlights) are preserved.
    final visited = List<bool>.filled(rgba.width * rgba.height, false);
    final queue = <int>[];
    void seed(int x, int y) {
      final i = y * rgba.width + x;
      if (!visited[i]) {
        visited[i] = true;
        queue.add(i);
      }
    }

    for (var x = 0; x < rgba.width; x++) {
      seed(x, 0);
      seed(x, rgba.height - 1);
    }
    for (var y = 0; y < rgba.height; y++) {
      seed(0, y);
      seed(rgba.width - 1, y);
    }

    while (queue.isNotEmpty) {
      final i = queue.removeLast();
      final x = i % rgba.width, y = i ~/ rgba.width;
      final px = rgba.getPixel(x, y);
      if (!isBg(px.r, px.g, px.b)) continue;
      px.a = 0;
      for (final (nx, ny) in [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]) {
        if (nx >= 0 && ny >= 0 && nx < rgba.width && ny < rgba.height) {
          final ni = ny * rgba.width + nx;
          if (!visited[ni]) {
            visited[ni] = true;
            queue.add(ni);
          }
        }
      }
    }

    final dir = await getTemporaryDirectory();
    final out = File(p.join(
        dir.path, 'nobg_${DateTime.now().millisecondsSinceEpoch}.png'));
    await out.writeAsBytes(img.encodePng(rgba));
    return out.path;
  }
}

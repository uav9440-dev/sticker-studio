import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sticker_studio_ai/app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // نعرض شاشة الترحيب والشروط مرة واحدة فقط عند أول تشغيل.
  final prefs = await SharedPreferences.getInstance();
  final accepted = prefs.getBool('terms_accepted') ?? false;
  runApp(ProviderScope(child: StickerStudioApp(showWelcome: !accepted)));
}

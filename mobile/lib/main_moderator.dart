import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'moderator_app/app.dart';
import 'moderator_app/offline/offline_queue.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await OfflineQueue.init();
  runApp(const ProviderScope(child: ModeratorApp()));
}

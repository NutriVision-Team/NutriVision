import 'dart:async';
import 'services/optional_messaging_startup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/reminders/data/reminder_runtime.dart';
import 'features/reminders/data/reminder_store.dart';
import 'features/food_catalog/data/local_food_repository.dart';
import 'services/synthetic_app_check.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/config/app_preferences.dart';
import 'services/fcm_service.dart';
import 'services/firebase_data_service.dart';
import 'services/firebase_initializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FirebaseInitializer.instance.initialize();
  await initializeSyntheticAiAppCheck();
  unawaited(
    initializeOptionalMessaging(FirebaseMessagingService.instance.initialize),
  );

  final preferences = await AppPreferences.load();
  final dataService = FirebaseDataService();

  runApp(
    SufraApp(
      preferences: preferences,
      reminders: ReminderRuntime(
        ReminderStore(await SharedPreferences.getInstance()),
      ),
      userRepository: dataService.userRepository,
      nutritionRepository: dataService.nutritionRepository,
      foodRepository: LocalFoodRepository(),
    ),
  );
}

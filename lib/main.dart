import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'models/adapters.dart';
import 'repositories/boxes.dart';
import 'router.dart';
import 'utilities/android_info.dart';
import 'wrapper.dart';

Future<void> setup() async {
  WidgetsFlutterBinding.ensureInitialized();

  initializeDateFormatting();

  AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelGroupKey: 'general_channel_group',
        channelKey: 'reminder_channel',
        channelName: 'Reminder',
        channelDescription: 'Reminder notifications',
        defaultColor: Colors.blue,
        ledColor: Colors.white,
      ),
    ],
    channelGroups: [
      NotificationChannelGroup(
        channelGroupKey: 'general_channel_group',
        channelGroupName: 'General',
      ),
    ],
    debug: kDebugMode,
  );

  await EasyLocalization.ensureInitialized();
  await Hive.initFlutter();

  registerAdapters();
  await openBoxes();
}

Future<void> main() async {
  await setup();

  final androidInfo = await getAndroidInfo(DeviceInfoPlugin());
  final perAppLocale = hasPerAppLocale(androidInfo);

  runApp(
    MyAppWrapper(
      perAppLocale: perAppLocale,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TaskTonic',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      routerConfig: MyAppRouter.instance,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
    );
  }
}

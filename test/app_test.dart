// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tasktonic/main.dart';
import 'package:tasktonic/models/adapters.dart';
import 'package:tasktonic/models/task.dart';
import 'package:tasktonic/pages/home.dart';
import 'package:tasktonic/pages/settings.dart';
import 'package:tasktonic/repositories/boxes.dart';
import 'package:tasktonic/router.dart';
import 'package:tasktonic/screens/language_settings.dart';
import 'package:tasktonic/utilities/date.dart';
import 'package:tasktonic/wrapper.dart';

import '__helpers__/controller.dart';
import '__helpers__/mock.dart';
import '__helpers__/utility.dart';

void main() async {
  final currentDate = DateTime.now();
  final currentDateStr = DateUtilities.formatDate(currentDate);

  Directory? testDirectory;

  setUpAll(() async {
    testDirectory = getTestDirectory();

    initializeDateFormatting();

    TestWidgetsFlutterBinding.ensureInitialized();

    mockPathProviderChannel(testDirectory!.path);
    SharedPreferences.setMockInitialValues({});

    await EasyLocalization.ensureInitialized();
    await Hive.initFlutter();

    registerAdapters();
  });

  setUp(() async {
    await openBoxes();
  });

  tearDown(() async {
    MyAppRouter.instance = null;
    await Hive.deleteFromDisk();
  });

  tearDownAll(() async {
    testDirectory!.deleteSync(recursive: true);
  });

  testWidgets('Should build', (WidgetTester tester) async {
    await tester.runAsync(() async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(
        const MyAppWrapper(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle();
    });
  });

  testWidgets('Should have no task', (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        const MyAppWrapper(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Test Task'), findsNothing);
    });
  });

  testWidgets('Should have a task', (WidgetTester tester) async {
    await tester.runAsync(() async {
      final box = Hive.box<Task>('tasks');
      final task = Task(
        name: 'Test Task',
        description: 'Test Description',
        dateStr: currentDateStr,
      );

      await box.put(task.id, task);

      await tester.pumpWidget(
        const MyAppWrapper(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsOneWidget);
      expect(find.text('Test Task'), findsOneWidget);
    });
  });

  testWidgets('Should create task', (WidgetTester tester) async {
    await tester.runAsync(() async {
      final box = Hive.box<Task>('tasks');

      await tester.pumpWidget(
        const MyAppWrapper(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Test Task'), findsNothing);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);

      await tester.tap(textFields.at(0));
      await tester.pumpAndSettle();
      await tester.enterText(textFields.at(0), 'Test Task');
      await tester.tap(textFields.at(1));
      await tester.pumpAndSettle();
      await tester.enterText(textFields.at(1), 'Test Description');
      await tester.tap(find.byType(TextButton).at(1));
      await box.flush();
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsOneWidget);
      expect(find.text('Test Task'), findsOneWidget);
    });
  });

  testWidgets('Should create task with date and reminder',
      (WidgetTester tester) async {
    await tester.runAsync(() async {
      final box = Hive.box<Task>('tasks');

      await tester.pumpWidget(
        const MyAppWrapper(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Test Task'), findsNothing);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);

      await tester.tap(textFields.at(0));
      await tester.pumpAndSettle();
      await tester.enterText(textFields.at(0), 'Test Task');
      await tester.tap(textFields.at(1));
      await tester.pumpAndSettle();
      await tester.enterText(textFields.at(1), 'Test Description');
      await tester.tap(textFields.at(2));
      await tester.pumpAndSettle();
      await tester.tap(find.text('${currentDate.day}'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(textFields.at(3));
      await tester.pumpAndSettle();
      await tester.tap(find.text('12'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextButton).at(1));
      await box.flush();
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsOneWidget);
      expect(find.text('Test Task'), findsOneWidget);
      expect(find.byType(Chip), findsNWidgets(2));
    });
  });

  testWidgets('Should cancel create task', (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        const MyAppWrapper(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Test Task'), findsNothing);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextButton).at(0));
      await tester.pumpAndSettle();

      expect(find.text('Test Task'), findsNothing);
    });
  });

  testWidgets('Should toggle task', (WidgetTester tester) async {
    await tester.runAsync(() async {
      final box = Hive.box<Task>('tasks');
      final task = Task(
        name: 'Test Task',
        description: 'Test Description',
        dateStr: currentDateStr,
      );

      await box.put(task.id, task);

      await tester.pumpWidget(
        const MyAppWrapper(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byType(ListTile));
      await box.flush();
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_box), findsOneWidget);
    });
  });

  testWidgets('Should show task details', (WidgetTester tester) async {
    await tester.runAsync(() async {
      final box = Hive.box<Task>('tasks');
      final task = Task(
        name: 'Test Task',
        description: 'Test Description',
        dateStr: currentDateStr,
      );

      await box.put(task.id, task);

      await tester.pumpWidget(
        const MyAppWrapper(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsOneWidget);

      await longPress(tester, find.byType(ListTile));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Test Task'), findsNWidgets(2));
      expect(find.text('Test Description'), findsOneWidget);
    });
  });

  testWidgets('Should hide task details', (WidgetTester tester) async {
    await tester.runAsync(() async {
      final box = Hive.box<Task>('tasks');
      final task = Task(
        name: 'Test Task',
        description: 'Test Description',
        dateStr: currentDateStr,
      );

      await box.put(task.id, task);

      await tester.pumpWidget(
        const MyAppWrapper(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsOneWidget);

      await longPress(tester, find.byType(ListTile));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Test Task'), findsNWidgets(2));
      expect(find.text('Test Description'), findsOneWidget);

      await tester.tapAt(tester.getCenter(find.byType(MyApp)));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Test Task'), findsOneWidget);
      expect(find.text('Test Description'), findsNothing);
    });
  });

  testWidgets('Should edit task', (WidgetTester tester) async {
    await tester.runAsync(() async {
      final box = Hive.box<Task>('tasks');
      final task = Task(
        name: 'Test Task',
        description: 'Test Description',
        dateStr: currentDateStr,
      );

      await box.put(task.id, task);

      await tester.pumpWidget(
        const MyAppWrapper(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsOneWidget);

      await longPress(tester, find.byType(ListTile));
      await tester.pumpAndSettle();

      final bottomSheet = find.byType(BottomSheet);
      final bottomSheetButtons = find.descendant(
        of: bottomSheet,
        matching: find.byType(TextButton),
      );

      await tester.tap(bottomSheetButtons.at(0));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);

      expect(find.text('Test Task'), findsOneWidget);
      expect(find.text('Test Description'), findsOneWidget);

      await tester.tap(textFields.at(0));
      await tester.pumpAndSettle();
      await tester.enterText(textFields.at(0), 'Test Task Edited');
      await tester.tap(textFields.at(1));
      await tester.pumpAndSettle();
      await tester.enterText(textFields.at(1), 'Test Description Edited');
      await tester.tap(find.byType(TextButton).at(1));
      await box.flush();
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsOneWidget);
      expect(find.text('Test Task Edited'), findsNWidgets(2));
      expect(find.text('Test Description Edited'), findsOneWidget);
    });
  });

  testWidgets('Should add reminder to existing task',
      (WidgetTester tester) async {
    await tester.runAsync(() async {
      final box = Hive.box<Task>('tasks');
      final task = Task(
        name: 'Test Task',
        description: 'Test Description',
        dateStr: currentDateStr,
      );

      await box.put(task.id, task);

      await tester.pumpWidget(
        const MyAppWrapper(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsOneWidget);

      await longPress(tester, find.byType(ListTile));
      await tester.pumpAndSettle();

      final bottomSheet = find.byType(BottomSheet);
      final bottomSheetButtons = find.descendant(
        of: bottomSheet,
        matching: find.byType(TextButton),
      );

      await tester.tap(bottomSheetButtons.at(0));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);

      await tester.tap(textFields.at(3));
      await tester.pumpAndSettle();
      await tester.tap(find.text('12'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextButton).at(1));
      await box.flush();
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsOneWidget);
      expect(find.text('Test Task'), findsNWidgets(2));
      expect(find.byType(Chip), findsNWidgets(4));
    });
  });

  testWidgets('Should add repeat to existing task',
      (WidgetTester tester) async {
    await tester.runAsync(() async {
      final box = Hive.box<Task>('tasks');
      final task = Task(
        name: 'Test Task',
        description: 'Test Description',
        dateStr: currentDateStr,
        reminderStr: '12:00',
      );

      await box.put(task.id, task);

      await tester.pumpWidget(
        const MyAppWrapper(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsOneWidget);

      await longPress(tester, find.byType(ListTile));
      await tester.pumpAndSettle();

      final bottomSheet = find.byType(BottomSheet);
      final bottomSheetButtons = find.descendant(
        of: bottomSheet,
        matching: find.byType(TextButton),
      );

      await tester.tap(bottomSheetButtons.at(0));
      await tester.pumpAndSettle();

      final checkbox = find.byType(Checkbox);

      await tester.tap(checkbox);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Daily'));
      await tester.tap(find.byType(TextButton).at(1));
      await box.flush();
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsOneWidget);
      expect(find.text('Test Task'), findsNWidgets(2));
      expect(find.byType(Chip), findsNWidgets(4));
    });
  });

  testWidgets('Should cancel edit task', (WidgetTester tester) async {
    await tester.runAsync(() async {
      final box = Hive.box<Task>('tasks');
      final task = Task(
        name: 'Test Task',
        description: 'Test Description',
        dateStr: currentDateStr,
      );

      await box.put(task.id, task);

      await tester.pumpWidget(
        const MyAppWrapper(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsOneWidget);

      await longPress(tester, find.byType(ListTile));
      await tester.pumpAndSettle();

      final bottomSheet = find.byType(BottomSheet);
      final bottomSheetButtons = find.descendant(
        of: bottomSheet,
        matching: find.byType(TextButton),
      );

      await tester.tap(bottomSheetButtons.at(0));
      await tester.pumpAndSettle();

      expect(find.text('Test Task'), findsOneWidget);
      expect(find.text('Test Description'), findsOneWidget);

      await tester.tap(find.byType(TextButton).at(0));
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsOneWidget);
      expect(find.text('Test Task'), findsNWidgets(2));
      expect(find.text('Test Description'), findsOneWidget);
    });
  });

  testWidgets('Should delete task', (WidgetTester tester) async {
    await tester.runAsync(() async {
      final box = Hive.box<Task>('tasks');
      final task = Task(
        name: 'Test Task',
        description: 'Test Description',
        dateStr: currentDateStr,
      );

      await box.put(task.id, task);

      await tester.pumpWidget(
        const MyAppWrapper(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsOneWidget);

      await longPress(tester, find.byType(ListTile));
      await tester.pumpAndSettle();

      final bottomSheet = find.byType(BottomSheet);
      final bottomSheetButtons = find.descendant(
        of: bottomSheet,
        matching: find.byType(TextButton),
      );

      await tester.tap(bottomSheetButtons.at(1));
      await tester.pumpAndSettle();

      final alertDialog = find.byType(AlertDialog);

      expect(alertDialog, findsOneWidget);

      final alertDialogButtons = find.descendant(
        of: alertDialog,
        matching: find.byType(TextButton),
      );

      await tester.tap(alertDialogButtons.at(1));
      await box.flush();
      await tester.pumpAndSettle();

      expect(alertDialog, findsNothing);
      expect(bottomSheet, findsNothing);
      expect(find.byType(ListTile), findsNothing);
    });
  });

  testWidgets('Should cancel delete task', (WidgetTester tester) async {
    await tester.runAsync(() async {
      final box = Hive.box<Task>('tasks');
      final task = Task(
        name: 'Test Task',
        description: 'Test Description',
        dateStr: currentDateStr,
      );

      await box.put(task.id, task);

      await tester.pumpWidget(
        const MyAppWrapper(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsOneWidget);

      await longPress(tester, find.byType(ListTile));
      await tester.pumpAndSettle();

      final bottomSheet = find.byType(BottomSheet);
      final bottomSheetButtons = find.descendant(
        of: bottomSheet,
        matching: find.byType(TextButton),
      );

      await tester.tap(bottomSheetButtons.at(1));
      await tester.pumpAndSettle();

      final alertDialog = find.byType(AlertDialog);

      expect(alertDialog, findsOneWidget);

      final alertDialogButtons = find.descendant(
        of: alertDialog,
        matching: find.byType(TextButton),
      );

      await tester.tap(alertDialogButtons.at(0));
      await tester.pumpAndSettle();

      expect(alertDialog, findsNothing);
      expect(find.byType(ListTile), findsOneWidget);
      expect(find.text('Test Task'), findsNWidgets(2));
      expect(find.text('Test Description'), findsOneWidget);
    });
  });

  testWidgets('Should go to settings', (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        const MyAppWrapper(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsPage), findsOneWidget);
    });
  });

  testWidgets('Should go to language settings', (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        const MyAppWrapper(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsPage), findsOneWidget);

      await tester.tap(find.byType(ListTile).at(0));
      await tester.pumpAndSettle();

      expect(find.byType(LanguageSettingsScreen), findsOneWidget);
    });
  });

  testWidgets('Should change language', (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        const MyAppWrapper(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsPage), findsOneWidget);
      expect(find.text('Languages'), findsOneWidget);

      await tester.tap(find.byType(ListTile).at(0));
      await tester.pumpAndSettle();

      expect(find.byType(LanguageSettingsScreen), findsOneWidget);

      await tester.tap(find.byType(ListTile).at(1));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsPage), findsOneWidget);
      expect(find.text('Langages'), findsOneWidget);

      await tester.tap(find.byType(ListTile).at(0));
      await tester.pumpAndSettle();

      expect(find.byType(LanguageSettingsScreen), findsOneWidget);

      await tester.tap(find.byType(ListTile).at(0));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsPage), findsOneWidget);
      expect(find.text('Languages'), findsOneWidget);
    });
  });

  testWidgets('Should go to settings then home', (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        const MyAppWrapper(
          child: MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsPage), findsOneWidget);

      await tester.tap(find.byIcon(Icons.home));
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
    });
  });
}

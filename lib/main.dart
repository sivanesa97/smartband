import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cron/cron.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart' as overlay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart' as provider;
import 'package:smartband/Providers/OwnerDeviceData.dart';
import 'package:smartband/Providers/SubscriptionData.dart';
import 'package:smartband/Screens/Widgets/SosPage.dart';
import 'package:smartband/SplashScreen.dart';
import 'package:smartband/bluetooth_connection_service.dart';
import 'package:smartband/pushnotifications.dart';
import 'package:http/http.dart' as http;
import 'package:workmanager/workmanager.dart';

import 'firebase_options.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> setupOverlay() async {
  bool status = await overlay.FlutterOverlayWindow.isPermissionGranted();
  if (!status) {
    await overlay.FlutterOverlayWindow.requestPermission();
  }
}

Future<void> showSOSOverlay() async {
  await overlay.FlutterOverlayWindow.showOverlay(
    height: overlay.WindowSize.fullCover,
    width: overlay.WindowSize.fullCover,
    alignment: overlay.OverlayAlignment.bottomCenter,
    visibility: overlay.NotificationVisibility.visibilityPublic,
  );

  // Create and show the SOSPage in the overlay
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SOSPage(),
  ));
}

// @pragma('vm:entry-point')
// void callbackDispatcher() {
//   Workmanager().executeTask((task, inputData) async {
//     await Firebase.initializeApp(
//       options: DefaultFirebaseOptions.currentPlatform,
//     );
//     await checkAndSendReminders();
//     return Future.value(true);
//   });
// }

Future<void> checkAndSendReminders() async {
  final now = DateTime.now();
  final currentDate = DateFormat('dd-MM-yyyy').format(now);
  final currentTime = DateFormat('hh:mm a').format(now);
  print('Current Date: $currentDate, Current Time: $currentTime');

  final reminders = await FirebaseFirestore.instance
      .collection('reminders')
      .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
      .get();

  if (reminders.docs.isNotEmpty) {
    for (var reminder in reminders.docs) {
      final reminderData = reminder.data();
      final userId = reminderData['userId'];
      final title = reminderData['title'];
      final reminderType = reminderData['repeat'];
      final reminderDate = reminderData['date'];
      final reminderTime = reminderData['time'];

      bool shouldSendReminder = false;

      final reminderDateTime = DateFormat('dd-MM-yyyy').parse(reminderDate);

      switch (reminderType) {
        case 'No Repeat':
          shouldSendReminder =
              currentDate == reminderDate && currentTime == reminderTime;
          break;
        case 'Daily':
          shouldSendReminder = currentTime == reminderTime;
          break;
        case 'Weekly':
          final daysDifference = now.difference(reminderDateTime).inDays;
          shouldSendReminder =
              daysDifference % 7 == 0 && currentTime == reminderTime;
          break;
        case 'Monthly':
          final reminderDay = int.parse(reminderDate.split('-')[0]);
          final reminderMonth = int.parse(reminderDate.split('-')[1]);
          final monthsDifference = (now.year - reminderDateTime.year) * 12 +
              now.month -
              reminderMonth;
          shouldSendReminder = now.day == reminderDay &&
              monthsDifference > 0 &&
              monthsDifference % 1 == 0 &&
              currentTime == reminderTime;
          break;
        case 'Yearly':
          final reminderDay = int.parse(reminderDate.split('-')[0]);
          final reminderMonth = int.parse(reminderDate.split('-')[1]);
          final yearsDifference = now.year - reminderDateTime.year;
          shouldSendReminder = now.day == reminderDay &&
              now.month == reminderMonth &&
              yearsDifference > 0 &&
              currentTime == reminderTime;
          break;
      }

      if (shouldSendReminder) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        final fcmToken = userDoc.data()?['fcmKey'];

        if (fcmToken != null) {
          SendNotification sendNotification = SendNotification();
          await sendNotification.sendAlarmNotification(
            fcmToken,
            'Reminder',
            'It\'s time for: $title',
          );
        }
      }
    }
  }
}

// Future<void> _initializeBackgroundService() async {
//   await Workmanager().initialize(
//     callbackDispatcher,
//     isInDebugMode: true,
//   );
//   print("Background service initialized");
//   await Workmanager().registerPeriodicTask(
//     "reminder-check",
//     "checkReminders",
//     frequency: const Duration(minutes: 15), // Minimum allowed frequency
//     initialDelay: const Duration(minutes: 1),
//     constraints: Constraints(
//       networkType: NetworkType.connected,
//     ),
//   );
// }

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
@pragma('vm:entry-point')
void _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // await setupOverlay();
  // await showSOSOverlay();

  // Initialize local notifications
  await flutterLocalNotificationsPlugin.initialize(
    InitializationSettings(android: AndroidInitializationSettings('logo')),
    onDidReceiveNotificationResponse:
        (NotificationResponse notificationResponse) {
      handleNotificationClick(message);
    },
  );
}

void handleNotificationClick(RemoteMessage message) {
  navigatorKey.currentState?.pushNamed('/sos');
}

Future<void> handleCronJob() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await checkAndSendReminders();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // await _initializeBackgroundService();

  final cron = Cron();
  cron.schedule(Schedule.parse('* * * * *'), () async {
    await handleCronJob();
  });

  await initializeService();

  // Initialize notification settings
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('logo');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  FirebaseMessaging.onBackgroundMessage((RemoteMessage message) async {
    _firebaseMessagingBackgroundHandler(message);
  });
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    SendNotification sendNotification = SendNotification();
    sendNotification.showNotification(message.notification?.title ?? "",
        message.notification?.body ?? "", navigatorKey);
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    handleNotificationClick(message);
  });

  // Check for initial notification
  RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    handleNotificationClick(initialMessage);
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.white,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  runApp(ProviderScope(
    child: provider.MultiProvider(
      providers: [
        provider.ChangeNotifierProvider(
            create: (_) => SubscriptionDataProvider()),
        provider.ChangeNotifierProvider(create: (_) => OwnerDeviceData())
      ],
      child: MaterialApp(
        home: SplashScreen(),
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        routes: {
          '/sos': (context) => SOSPage(),
        },
      ),
    ),
  ));
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  service.startService();
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Handle background tasks
  // await setupOverlay();
  // await showSOSOverlay();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Other background tasks
  BluetoothConnectionService().startBluetoothService();

  Timer.periodic(Duration(seconds: 1), (timer) async {
    await BluetoothConnectionService().checkAndReconnect();
    await handleCronJob();
  });

  Timer.periodic(Duration(minutes: 1), (timer) async {
    await checkLocationAndSendNotification();
  });

  FirebaseMessaging.onBackgroundMessage((RemoteMessage message) async {
    _firebaseMessagingBackgroundHandler(message);
  });
}

Future<void> checkLocationAndSendNotification() async {
  Position currentPosition = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );

  DocumentSnapshot userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .get();
  Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
  GeoPoint homeLocation = userData['homeLocation'] as GeoPoint;

  double distance = Geolocator.distanceBetween(
    currentPosition.latitude,
    currentPosition.longitude,
    homeLocation.latitude,
    homeLocation.longitude,
  );

  if (distance > 10000) {
    SendNotification sendNotification = SendNotification();
    sendNotification.showNotification(
        'Emergency!!',
        "Location Alert : Your current location is more than 10 km away from your home.",
        navigatorKey);
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma("vm:entry-point")
void overlayMain() {
  runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SafeArea(child: Material(child: SOSPage()))));
}

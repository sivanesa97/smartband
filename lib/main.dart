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

Future<void> showSOSOverlay(String status) async {
  await overlay.FlutterOverlayWindow.showOverlay(
    height: overlay.WindowSize.fullCover,
    width: overlay.WindowSize.fullCover,
    alignment: overlay.OverlayAlignment.bottomCenter,
    visibility: overlay.NotificationVisibility.visibilityPublic,
  );

  // Create and show the SOSPage in the overlay
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SOSPage(status: status),
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
        final userName = userDoc.data()?['name'];

        if (fcmToken != null) {
          SendNotification sendNotification = SendNotification();
          await sendNotification.sendAlarmNotification(
            fcmToken,
            'Reminder',
            'It\'s time for: $title',
          );

          await FirebaseFirestore.instance.collection('notifications').add({
            'date': currentDate,
            'time': currentTime,
            'userId': userId,
            'userName': userName,
            'title': title,
          });
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
  // await showSOSOverlay()

  // Initialize local notifications
  await flutterLocalNotificationsPlugin.initialize(
    InitializationSettings(android: AndroidInitializationSettings('logo')),
    onDidReceiveNotificationResponse:
        (NotificationResponse notificationResponse) {
      handleNotificationClick(message);
    },
  );
}

void handleNotificationClick(RemoteMessage message) async {
  String status = getStatusFromMessage(message.notification?.title ?? "");
  if (status == '1' || status == '2' || status == '3') {
    await showSOSOverlay(status);
  }
}

String getStatusFromMessage(String title) {
  if (title.contains('Emergency!!')) {
    return '1';
  } else if (title.contains('Location')) {
    return '2';
  } else if (title.contains('Fall Detection')) {
    return '3';
  }
  return '4';
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
          '/sos': (context) {
            final args = ModalRoute.of(context)?.settings.arguments as Map;
            return SOSPage(status: args['status']);
          },
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

  await setupOverlay();

  Timer.periodic(Duration(minutes: 5), (timer) async {
    await checkLocationAndSendNotification();
    await FirebaseMessaging.instance.getToken().then((token) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({'fcmKey': token});
    });
  });

  Timer.periodic(Duration(minutes: 1), (timer) async {
    await handleCronJob();
    await BluetoothConnectionService().checkAndReconnect();
  });

  FirebaseMessaging.onBackgroundMessage((RemoteMessage message) async {
    _firebaseMessagingBackgroundHandler(message);
  });
}

// Future<void> checkLocationAndSendNotification() async {
//   Position currentPosition = await Geolocator.getCurrentPosition(
//     desiredAccuracy: LocationAccuracy.high,
//   );
//   DocumentSnapshot userDoc = await FirebaseFirestore.instance
//       .collection('users')
//       .doc(FirebaseAuth.instance.currentUser!.uid)
//       .get();
//   Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
//   String role = userData['role'].toString();
//   double minimum_km = 0;
//   if (userData.containsKey('minimum_km')) {
//     minimum_km = double.parse(userData['minimum_km'].toString());
//   }
//   if (role == 'watch wearer' && minimum_km > 0) {
//     GeoPoint homeLocation = userData['home_location'] as GeoPoint;

//     double distance = Geolocator.distanceBetween(
//       currentPosition.latitude,
//       currentPosition.longitude,
//       homeLocation.latitude,
//       homeLocation.longitude,
//     );

//     if (distance >= (minimum_km * 1000)) {
//       bool _isEmergency = true;

//       try {
//         SendNotification send = SendNotification();
//         Map<String, dynamic> supervisors = userData['supervisors'];
//         List<String> filteredSupervisors = supervisors.entries
//             .where((entry) => entry.value['status'] == 'active')
//             .map((entry) => entry.key)
//             .toList()
//           ..sort((a, b) => int.parse(supervisors[b]['priority'].toString())
//               .compareTo(int.parse(supervisors[a]['priority'].toString())));

//         String supervisor =
//             filteredSupervisors.first; // Send to the first supervisor only
//         print(supervisor);
//         final sup = await FirebaseFirestore.instance
//             .collection("users")
//             .where('phone_number', isEqualTo: supervisor)
//             .get();
//         await FirebaseFirestore.instance
//             .collection("emergency_alerts")
//             .doc(sup.docs.first.id)
//             .set({
//           "isEmergency": true,
//           "responseStatus": false,
//           "response": "",
//           "phone_number": supervisor,
//           "userUid": FirebaseAuth.instance.currentUser?.uid,
//           "heartbeatRate": 0,
//           "location":
//               "${currentPosition.latitude}°N ${currentPosition.longitude}°E",
//           "spo2": 0,
//           "fallDetection": false,
//           "isManual": false,
//           "timestamp": FieldValue.serverTimestamp()
//         }, SetOptions(merge: true));

//         await FirebaseFirestore.instance
//             .collection("emergency_alerts")
//             .doc(sup.docs.first.id)
//             .collection(sup.docs.first.id)
//             .add({
//           "isEmergency": true,
//           "responseStatus": false,
//           "response": "",
//           "heartbeatRate": 0,
//           "location":
//               "${currentPosition.latitude}°N ${currentPosition.longitude}°E",
//           "spo2": 0,
//           "fallDetection": false,
//           "isManual": false,
//           "timestamp": FieldValue.serverTimestamp()
//         });
//         String responderName = userData['name'] ?? "User";
//         send.sendNotification(supervisor, "Location",
//             "$responderName is away from  HomeLocation. And Their Current Location is  ${currentPosition.latitude}°N ${currentPosition.longitude}°E. Please respond");

//         print(
//             "Message sent to supervisor with phone number: ${supervisor} and priority: ${supervisors[supervisor]['priority']}");

//         await Future.delayed(Duration(seconds: 30));
//         FirebaseFirestore.instance
//             .collection("emergency_alerts")
//             .doc(sup.docs.first.id)
//             .snapshots()
//             .listen((DocumentSnapshot doc) {
//           if (doc.exists && doc["responseStatus"] == true) {
//             _isEmergency = false;
//             FirebaseFirestore.instance
//                 .collection('users')
//                 .doc(FirebaseAuth.instance.currentUser!.uid)
//                 .update({"minimum_km": 0.0});
//           }
//         });
//       } catch (e) {
//         print("Exception $e");
//       }
//     }
//   }
// }

Future<void> checkLocationAndSendNotification() async {
  Position currentPosition = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
  DocumentSnapshot userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .get();
  Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
  String role = userData['role'].toString();
  double minimum_km = 0;
  print(minimum_km);
  if (userData.containsKey('minimum_km')) {
    minimum_km = double.parse(userData['minimum_km'].toString());
  }
  if (role == 'watch wearer' && minimum_km > 0) {
    GeoPoint homeLocation = userData['home_location'] as GeoPoint;

    double distance = Geolocator.distanceBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      homeLocation.latitude,
      homeLocation.longitude,
    );

    if (distance >= (minimum_km * 1000)) {
      bool _isEmergency = true;

      for (var attempt = 1; attempt <= 3; attempt++) {
        if (!_isEmergency) {
          break;
        }
        print("Attempt $attempt");
        // Position location = await updateLocation();
        try {
          SendNotification send = SendNotification();
          Map<String, dynamic> supervisors = userData['supervisors'];
          List<String> filteredSupervisors = supervisors.entries
              .where((entry) => entry.value['status'] == 'active')
              .map((entry) => entry.key)
              .toList()
            ..sort((a, b) => int.parse(supervisors[b]['priority'].toString())
                .compareTo(int.parse(supervisors[a]['priority'].toString())));

          for (var supervisor in filteredSupervisors) {
            if (!_isEmergency) {
              break;
            }
            print(supervisor);
            final sup = await FirebaseFirestore.instance
                .collection("users")
                .where('phone_number', isEqualTo: supervisor)
                .get();
            await FirebaseFirestore.instance
                .collection("emergency_alerts")
                .doc(sup.docs.first.id)
                .set({
              "isEmergency": true,
              "responseStatus": false,
              "response": "",
              "phone_number": supervisor,
              "userUid": FirebaseAuth.instance.currentUser?.uid,
              "heartbeatRate": 0,
              "location":
                  "${currentPosition.latitude}°N ${currentPosition.longitude}°E",
              "spo2": 0,
              "fallDetection": false,
              "isManual": false,
              "timestamp": FieldValue.serverTimestamp()
            }, SetOptions(merge: true));

            await FirebaseFirestore.instance
                .collection("emergency_alerts")
                .doc(sup.docs.first.id)
                .collection(sup.docs.first.id)
                .add({
              "isEmergency": true,
              "responseStatus": false,
              "response": "",
              "heartbeatRate": 0,
              "location":
                  "${currentPosition.latitude}°N ${currentPosition.longitude}°E",
              "spo2": 0,
              "fallDetection": false,
              "isManual": false,
              "timestamp": FieldValue.serverTimestamp()
            });
            String responderName = userData['name'] ?? "User";
            send.sendNotification(supervisor, "Location",
                "$responderName is away from  HomeLocation. And Their Current Location is  ${currentPosition.latitude}°N ${currentPosition.longitude}°E. Please respond");

            print(
                "Message sent to supervisor with phone number: ${supervisor} and priority: ${supervisor}");
            // ScaffoldMessenger.of(context).showSnackBar(
            //   SnackBar(content: Text("Sent Alert to ${supervisor['key']}")),
            // );
            await Future.delayed(Duration(seconds: 30));
            FirebaseFirestore.instance
                .collection("emergency_alerts")
                .doc(sup.docs.first.id)
                .snapshots()
                .listen((DocumentSnapshot doc) {
              if (doc.exists && doc["responseStatus"] == true) {
                // String responderName = userData['name'] ?? "User";
                _isEmergency = false;
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .update({"minimum_km": 0.0});
                // ScaffoldMessenger.of(context).showSnackBar(
                //   SnackBar(
                //     content: Text("$responderName Responded"),
                //   ),
                // );
              }
            });
          }
          if (attempt == 3) {
            _isEmergency = false;
          }
        } catch (e) {
          print("Exception $e");
        }
      }
    }
    // SendNotification sendNotification = SendNotification();
    // sendNotification.showNotification(
    //     'Emergency!!',
    //     "Location Alert : Your current location is more than 10 km away from your home.",
    //     navigatorKey);
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

// @pragma("vm:entry-point")
// void overlayMain() {
//   runApp(MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: SafeArea(child: Material(child: SOSPage(status: '3')))));
// }


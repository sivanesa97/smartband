import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:audio_session/audio_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:provider/provider.dart' as provider;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartband/Providers/OwnerDeviceData.dart';
import 'package:smartband/Providers/SubscriptionData.dart';
import 'package:smartband/Screens/AuthScreen/signin.dart';
import 'package:smartband/Screens/AuthScreen/signup.dart';
import 'package:smartband/Screens/Dashboard/supervisor_dashboard.dart';
import 'package:smartband/Screens/HomeScreen/homepage.dart';
import 'package:smartband/Screens/Widgets/SosPage.dart';
import 'package:smartband/SplashScreen.dart';
import 'package:smartband/bluetooth_connection_service.dart';
import 'package:smartband/pushnotifications.dart';
import 'package:http/http.dart' as http;

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

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await setupOverlay();
  await showSOSOverlay();

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
  // final initialMessage = message.data;
  // if (initialMessage.containsKey('uid')) {
  // Perform any additional navigation if needed
  // For example, you could use the navigatorKey to navigate to a different screen
  navigatorKey.currentState?.pushNamed('/sos');
  // }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // await initializeService();

  // Initialize notification settings
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('logo');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    // showSOSOverlay();
    // handleNotificationClick(message);
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

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    handleNotificationClick(message);
  });

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
        provider.ChangeNotifierProvider(
            create: (_) => OwnerDeviceData())
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

// Future<void> initializeService() async {
//   final service = FlutterBackgroundService();

//   await service.configure(
//     androidConfiguration: AndroidConfiguration(
//       onStart: onStart,
//       autoStart: true,
//       isForegroundMode: true,
//     ),
//     iosConfiguration: IosConfiguration(
//       autoStart: true,
//       onForeground: onStart,
//       onBackground: onIosBackground,
//     ),
//   );

//   service.startService();
// }

// @pragma('vm:entry-point')
// void onStart(ServiceInstance service) async {
//   DartPluginRegistrant.ensureInitialized();

//   if (service is AndroidServiceInstance) {
//     service.on('setAsForeground').listen((event) {
//       service.setAsForegroundService();
//     });

//     service.on('setAsBackground').listen((event) {
//       service.setAsBackgroundService();
//     });
//   }

//   service.on('stopService').listen((event) {
//     service.stopSelf();
//   });

//   // Handle background tasks
//   await setupOverlay();
//   await showSOSOverlay();

//   // Other background tasks
//   BluetoothConnectionService().startBluetoothService();

//   Timer.periodic(Duration(minutes: 1), (timer) async {
//     await checkLocationAndSendNotification();
//   });

//   Timer.periodic(Duration(minutes: 1), (timer) async {
//     await BluetoothConnectionService().checkAndReconnect();
//   });
// }

// Future<void> checkLocationAndSendNotification() async {
//   Position currentPosition = await Geolocator.getCurrentPosition(
//     desiredAccuracy: LocationAccuracy.high,
//   );

//   DocumentSnapshot userDoc = await FirebaseFirestore.instance
//       .collection('users')
//       .doc(FirebaseAuth.instance.currentUser!.uid)
//       .get();
//   Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
//   GeoPoint homeLocation = userData['homeLocation'] as GeoPoint;

//   double distance = Geolocator.distanceBetween(
//     currentPosition.latitude,
//     currentPosition.longitude,
//     homeLocation.latitude,
//     homeLocation.longitude,
//   );

//   if (distance > 10000) {
//     SendNotification sendNotification = SendNotification();
//     sendNotification.showNotification(
//         'Emergency!!',
//         "Location Alert : Your current location is more than 10 km away from your home.",
//         navigatorKey);
//   }
// }

// @pragma('vm:entry-point')
// Future<bool> onIosBackground(ServiceInstance service) async {
//   WidgetsFlutterBinding.ensureInitialized();
//   DartPluginRegistrant.ensureInitialized();
//   return true;
// }

@pragma("vm:entry-point")
void overlayMain() {
  runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SafeArea(child: Material(child: SOSPage()))));
}

// class MyApp extends StatefulWidget {
//   const MyApp({super.key});

//   @override
//   State<MyApp> createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   late Widget initialScreen;

//   @override
//   void initState() {
//     super.initState();
//     _checkLoginStatus();
//   }

//   Future<void> _checkLoginStatus() async {
//     User? user = FirebaseAuth.instance.currentUser;
//     print("inside checkLoginStatus");
//     if (user == null) {
//       initialScreen = const SignIn();
//     } else {
//       print("inside else of checkLoginStatus");
//       final data = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .get();
//       var phoneNumber = data.data()?['phone_number'];

//       var apiData = await BluetoothConnectionService().getApiData(phoneNumber);
//       int ownerStatus = 0;
//       String deviceName = "";
//       if (apiData != null) {
//         deviceName = apiData['deviceName'];
//         if (deviceName == "null") {
//           deviceName = "";
//         }
//         print(apiData);
//         bool isSubscriptionActive = apiData?['isSubscriptionActive'];
//         bool isUserActive = apiData?['isUserActive'];
//         if (isUserActive && isSubscriptionActive) {
//           if (deviceName != "") {
//             ownerStatus = 1;
//           } else {
//             ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text("Device is not assigned!")));
//           }
//         } else if (isUserActive && deviceName != "") {
//           ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text("Please Subscribe to use watch!")));
//         }
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("API Issue! Contact Tech Support!")));
//       }

//       String selected_role = "supervisor";
//       if (ownerStatus == 1) {
//         provider.Provider.of<SubscriptionDataProvider>(context, listen: false)
//             .updateStatus(
//                 active: true, deviceName: deviceName, subscribed: true);
//         selected_role = "watch wearer";
//         print("owner status is watch wearer");
//         initialScreen = const HomepageScreen(hasDeviceId: true);
//       } else {
//         provider.Provider.of<SubscriptionDataProvider>(context, listen: false)
//             .updateStatus(active: false, deviceName: "", subscribed: false);
//         initialScreen = SupervisorDashboard(phNo: phoneNumber);
//       }
//     }
//     setState(() {});
//   }

//   @override
//   Widget build(BuildContext context) {
//     // If initialScreen is null, show loading screen
//     if (initialScreen == null) {
//       return const Scaffold(
//         body: Center(
//           child: CircularProgressIndicator(),
//         ),
//       );
//     }

//     // Otherwise, display the determined initial screen
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'LifeLongCare',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         scaffoldBackgroundColor: Colors.white,
//       ),
//       home: initialScreen,
//     );
//   }
// }

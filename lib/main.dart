import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smartband/Screens/AuthScreen/phone_number.dart';
import 'package:smartband/Screens/AuthScreen/signin.dart';
import 'package:smartband/Screens/HomeScreen/homepage.dart';
import 'package:smartband/pushnotifications.dart';

import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('logo');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  final fcmToken = await FirebaseMessaging.instance.getToken();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    SendNotification sendNotification = SendNotification();
    sendNotification.showNotification(message.notification?.title ?? "", message.notification?.body ?? "");
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
      systemNavigationBarIconBrightness: Brightness.dark));
  runApp(ProviderScope(child: MaterialApp(home: SplashScreen(), debugShowCheckedModeBanner: false)));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Widget initialScreen;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      initialScreen = const SignIn();
    } else {
      final data = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      bool hasDeviceId = data.data()?['device_id'] != "" ? true : false;
      initialScreen = HomepageScreen(hasDeviceId: hasDeviceId);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LifeLongCare',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else if (snapshot.hasData) {
            return HomepageScreen(hasDeviceId: false);
          } else {
            return SplashScreen();
          }
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  Future<void> requestPermissions() async {
    final bluetoothStatus = await Permission.bluetooth.request();
    if (bluetoothStatus.isDenied) {
      print('Bluetooth permission denied');
    }
    print('Bluetooth permission granted');

    // Request Bluetooth scan permission
    final bluetoothScanStatus = await Permission.bluetoothScan.request();
    if (bluetoothScanStatus.isDenied) {
      print('Bluetooth scan permission denied');
    }
    print('Bluetooth scan permission granted');

    // Request Bluetooth connect permission
    final bluetoothConnectStatus = await Permission.bluetoothConnect.request();
    if (bluetoothConnectStatus.isDenied) {
      print('Bluetooth connect permission denied');
    }
    print('Bluetooth connect permission granted');

    // Request Location permission
    final locationStatus = await Permission.locationWhenInUse.request();
    if (locationStatus.isDenied) {
      print('Location permission denied');
    }
    print('Location permission granted');

    // Request Notification permission
    final notificationStatus = await Permission.notification.request();
    if (notificationStatus.isDenied) {
      print('Notification permission denied');
    }
    print('Notification permission granted');
  }

  @override
  void initState() {
    super.initState();
    requestPermissions();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Scaffold(
          body: CustomPaint(
            painter: RadialGradientPainter(_progressAnimation.value),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipOval(
                    child: Container(
                      width: width * 0.6,
                      child: Image.asset(
                        "assets/logo1.png",
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "LONG LIFE CARE",
                    style: TextStyle(fontSize: width * 0.05, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 3000));
      if (mounted) {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final data = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          bool hasDeviceId = data.data()?['device_id'] != "" ? true : false;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => HomepageScreen(hasDeviceId: hasDeviceId),
            ),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => PhoneSignIn(),
            ),
          );
        }
      }
    });
  }
}

class RadialGradientPainter extends CustomPainter {
  final double progress;

  RadialGradientPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: progress,
        colors: [
          Color.fromRGBO(255, 127, 23, 1),
          Colors.white,
        ],
        stops: [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: size.center(Offset.zero), radius: size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
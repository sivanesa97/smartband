import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:smartband/Providers/SubscriptionData.dart';
import 'package:smartband/Screens/AuthScreen/phone_number.dart';
import 'package:smartband/Screens/Dashboard/supervisor_dashboard.dart';
import 'package:smartband/Screens/HomeScreen/homepage.dart';
import 'package:http/http.dart' as http;
import 'package:smartband/bluetooth_connection_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
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
    await Permission.bluetooth.request();
    await Permission.ignoreBatteryOptimizations.request();
    await Permission.backgroundRefresh.request();
    await Permission.systemAlertWindow.request();
    await Permission.microphone.request();
    if (!(await FlutterOverlayWindow.isPermissionGranted())) {
      await FlutterOverlayWindow.requestPermission();
    }
    // await Permission.phone.request();

    print('Notification permission granted');
  }

  Future<void> _initBackgroundService() async {
    final hasPermissions = await FlutterBackground.hasPermissions;
    if (!hasPermissions) {
      await FlutterBackground.initialize(
        androidConfig: const FlutterBackgroundAndroidConfig(
          notificationTitle: "Background Service",
          notificationText: "Playing sound in the background",
          notificationImportance: AndroidNotificationImportance.max,
          enableWifiLock: true,
        ),
      );
    }
  }

  Future<String> getAccessToken() async {
    final jsonString =
        await rootBundle.loadString('assets/service_account.json');
    final serviceAccount = ServiceAccountCredentials.fromJson(jsonString);

    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
    final client = await clientViaServiceAccount(serviceAccount, scopes);
    final accessToken = client.credentials.accessToken;
    print(accessToken.data);
    return accessToken.data;
  }

  @override
  void initState() {
    super.initState();
    requestPermissions();
    _initBackgroundService();
    getAccessToken();

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
                  const SizedBox(height: 16),
                  Text(
                    "LONG LIFE CARE",
                    style:
                        TextStyle(fontSize: width * 0.05, color: Colors.white),
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
          final data = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          print(data.data());
          var phoneNumber = data.data()?['phone_number'] ?? "";

          var apiData =
              await BluetoothConnectionService().getApiData(phoneNumber);
          int ownerStatus = 0;
          String deviceName = "";
          if (apiData != null) {
            deviceName = apiData['deviceName'];
            if (deviceName == "null") {
              deviceName = "";
            }
            print(apiData);
            bool isSubscriptionActive = apiData?['isSubscriptionActive'];
            bool isUserActive = apiData?['isUserActive'];
            if (isUserActive && isSubscriptionActive) {
              if (deviceName != "") {
                ownerStatus = 1;
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Device is not assigned!")));
              }
            } else if (isUserActive && deviceName != "") {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Please Subscribe to use watch!")));
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("API Issue! Contact Tech Support!")));
          }

          // String selected_role = "supervisor";
          if (ownerStatus == 1) {
            Provider.of<SubscriptionDataProvider>(context, listen: false)
                .updateStatus(
                    active: true,
                    deviceName: deviceName,
                    subscribed: true,
                    phoneNumber: phoneNumber);
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => HomepageScreen(hasDeviceId: true),
              ),
            );
          } else {
            Provider.of<SubscriptionDataProvider>(context, listen: false)
                .updateStatus(
                    active: false,
                    deviceName: "",
                    subscribed: false,
                    phoneNumber: phoneNumber);
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => SupervisorDashboard(phNo: phoneNumber),
              ),
            );
          }
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
        colors: const [
          Color.fromRGBO(255, 127, 23, 1),
          Colors.white,
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(
          center: size.center(Offset.zero), radius: size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

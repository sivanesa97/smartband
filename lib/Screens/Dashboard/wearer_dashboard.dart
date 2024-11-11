// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart' as intl;
import 'package:smartband/Providers/OwnerDeviceData.dart';
import 'package:smartband/Screens/AuthScreen/phone_number.dart';
import 'package:smartband/Screens/Widgets/loading.dart';
import 'package:smartband/Screens/Widgets/string_extensions.dart';
import 'package:smartband/bluetooth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:android_intent_plus/android_intent.dart';
import 'dart:io' show Platform;
import 'package:provider/provider.dart' as provider;

import '../Models/usermodel.dart';
import '../Widgets/drawer.dart';
import 'dashboard.dart';

class WearerDashboard extends ConsumerStatefulWidget {
  final BluetoothDevice device;
  final String phNo;

  const WearerDashboard({super.key, required this.device, required this.phNo});

  @override
  ConsumerState<WearerDashboard> createState() => _WearerDashboardState();
}

class _WearerDashboardState extends ConsumerState<WearerDashboard> {
  Timer? _timer;
  bool _isTimerRunning = false;
  bool _isSubscriptionFetched = false;
  final BluetoothDeviceManager bluetoothDeviceManager =
      BluetoothDeviceManager();
  Position locationNew = Position(
      latitude: 12.239842,
      longitude: 80.247384,
      timestamp: DateTime.now(),
      altitudeAccuracy: 1.0,
      headingAccuracy: 1.0,
      accuracy: 1.0,
      altitude: 1.0,
      heading: 1.0,
      speed: 1.0,
      speedAccuracy: 1.0);

  Future<void> openGoogleMaps(double lat, double lng) async {
    if (Platform.isAndroid) {
      final AndroidIntent intent = AndroidIntent(
        action: 'action_view',
        data: Uri.encodeFull('google.navigation:q=$lat,$lng'),
        package: 'com.google.android.apps.maps',
      );

      try {
        await intent.launch();
        return;
      } catch (e) {
        print('Could not open Google Maps app: $e');
      }
      final AndroidIntent genericIntent = AndroidIntent(
        action: 'action_view',
        data: Uri.encodeFull('geo:$lat,$lng'),
      );

      try {
        await genericIntent.launch();
        return;
      } catch (e) {
        print('Could not open generic map intent: $e');
      }
    }
    final Uri url =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      print('Could not open the map in web browser');
      throw 'Could not open the map.';
    }
  }

  String water = "";
  String status = "";
  String subscription = "";

  @override
  void initState() {
    super.initState();
    bluetoothDeviceManager.discoverServicesAndCharacteristics(widget.device);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  DateTime addMonths(DateTime date, int months) {
    int newYear = date.year;
    int newMonth = date.month + months;

    // Handle month overflow
    while (newMonth > 12) {
      newMonth -= 12;
      newYear++;
    }

    // Handle days in month overflow
    int newDay = date.day;
    int daysInNewMonth = DateTime(newYear, newMonth + 1, 0).day;
    if (newDay > daysInNewMonth) {
      newDay = daysInNewMonth;
    }

    return DateTime(newYear, newMonth, newDay);
  }

  void _updateMetrics(List<String> values) async {
    if (FirebaseAuth.instance.currentUser != null) {
      // print(values);
      final deviceOwnerData =
          provider.Provider.of<OwnerDeviceData>(context, listen: false);
      // Check if the values have changed before updating
      if (deviceOwnerData.heartRate != int.parse(values[0].toString()) ||
          deviceOwnerData.spo2 != int.parse(values[1].toString())) {
        provider.Provider.of<OwnerDeviceData>(context, listen: false)
            .updateStatus(
                age: deviceOwnerData.age,
                heartRate: int.parse(values[0].toString()),
                spo2: int.parse(values[1].toString()),
                sosClicked: false);
        await FirebaseFirestore.instance
            .collection("users")
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .update({
          "metrics": {
            "spo2": values[1].toString(),
            "heart_rate": values[0].toString(),
            "fall_axis": "--"
          }
        });
      }
    }
  }

  Future<void> fetchSubscription(String phno) async {
    // print(phno);
    final response = await http.post(
      Uri.parse("https://snvisualworks.com/public/api/auth/check-mobile"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'mobile_number': '$phno',
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      intl.DateFormat dateFormat = intl.DateFormat("dd-MM-yyyy");
      print(data);
      if (data['status'].toString() != 'active') {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        await googleSignIn.signOut();
        await FirebaseAuth.instance.signOut();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("User not active")));
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => PhoneSignIn()),
            (Route<dynamic> route) => false);
        setState(() {
          _isSubscriptionFetched = true;
        });
        return;
      }

      DocumentReference docRef = FirebaseFirestore.instance
          .collection('server_time')
          .doc('current_time');
      await docRef.set({'timestamp': FieldValue.serverTimestamp()});

      DocumentSnapshot docSnapshot = await docRef.get();
      Timestamp serverTimestamp = docSnapshot['timestamp'];
      DateTime serverDate = serverTimestamp.toDate();
      if (data['subscription_date'] != null && data['end_date'] != null) {
        DateTime startDate =
            DateTime.parse(data['subscription_date'].toString());
        DateTime endDate = DateTime.parse(data['end_date'].toString());
        if ((startDate.isAtSameMomentAs(serverDate) ||
                startDate.isBefore(serverDate)) &&
            (endDate.isAtSameMomentAs(serverDate) ||
                endDate.isAfter(serverDate))) {
          setState(() {
            status = data['status'].toString();
            subscription = data['end_date'] == null
                ? "--"
                : intl.DateFormat('yyyy-MM-dd')
                    .format(DateTime.parse(data['end_date']));
            setState(() {
              _isSubscriptionFetched = true;
            });
            print("Fetched");
          });
        } else {
          final GoogleSignIn googleSignIn = GoogleSignIn();
          await googleSignIn.signOut();
          await FirebaseAuth.instance.signOut();
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Subscription To Continue")));
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => PhoneSignIn()),
              (Route<dynamic> route) => false);
          setState(() {
            _isSubscriptionFetched = true;
          });
          return;
        }
      } else {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        await googleSignIn.signOut();
        await FirebaseAuth.instance.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Subscribe to Continue!")));
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => PhoneSignIn()),
            (Route<dynamic> route) => false);
        setState(() {
          _isSubscriptionFetched = true;
        });
        return;
      }
    } else {
      setState(() {
        _isSubscriptionFetched = true;
      });
      print(response.statusCode);
    }
  }

  Future<Position> updateLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        // Handle permission denied case
        print("Location permission denied");
        return Future.error('Location permission denied');
      }
    }

    Position location = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    print("Fetched Location");
    setState(() {
      locationNew = location;
    });
    await openGoogleMaps(location.latitude, location.longitude);
    return location;
  }

  DateTime? _lastBackPressed;
  @override
  Widget build(BuildContext context) {
    final user_data =
        ref.watch(userModelProvider(FirebaseAuth.instance.currentUser!.uid));
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return WillPopScope(
        onWillPop: () async {
          if (_lastBackPressed == null ||
              DateTime.now().difference(_lastBackPressed!) >
                  Duration(seconds: 2)) {
            _lastBackPressed = DateTime.now();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Press back again to exit'),
                duration: Duration(seconds: 2),
              ),
            );
            return false;
          } else {
            return true;
          }
        },
        child: Scaffold(
            drawer: DrawerScreen(
                device: bluetoothDeviceManager.connectedDevices.first,
                phNo: widget.phNo,
                subscription: subscription,
                status: status),
            backgroundColor: Colors.white,
            body: user_data.when(
              data: (user) {
                if (user == null) {
                  return const Center(child: Text("User data is unavailable"));
                }
                if (!_isSubscriptionFetched) {
                  fetchSubscription(user.phone_number.toString());
                }
                return StreamBuilder<Map<String, String>>(
                  stream: bluetoothDeviceManager.characteristicValuesStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: GradientLoadingIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(
                          child: Text("Error reading characteristic values"));
                    }

                    bool sosClicked = false;
                    final characteristicValues = snapshot.data;
                    List<String> values = ['--', '--', '0'];
                    if (characteristicValues != null &&
                        characteristicValues[
                                "beb5483e-36e1-4688-b7f5-ea07361b26a8"] !=
                            null) {
                      values = characteristicValues[
                              "beb5483e-36e1-4688-b7f5-ea07361b26a8"]!
                          .split(',');
                      print(values);
                      if (values.length < 3) {
                        values = ['--', '--', '0'];
                      } else if (values.length == 2 && values[1] == '1') {
                        sosClicked = true;
                      }
                    }
                    return SafeArea(
                        child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                  child: Stack(
                                children: [
                                  SizedBox(
                                    width: width * 0.9,
                                    height: height * 0.17,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(30),
                                      // Rounded corners
                                      child: Image.network(
                                        "https://miro.medium.com/v2/resize:fit:1400/1*qYUvh-EtES8dtgKiBRiLsA.png",
                                        fit: BoxFit
                                            .cover, // Ensure the image covers the container
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width:
                                        MediaQuery.of(context).size.width * 0.9,
                                    height: MediaQuery.of(context).size.height *
                                        0.17,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      // Rounded corners
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color.fromRGBO(0, 83, 188, 0.8),
                                          Color.fromRGBO(0, 0, 0, 0.15),
                                          Color.fromRGBO(0, 83, 188, 0.8),
                                        ], // Gradient colors
                                        begin: Alignment.center,
                                        end: Alignment.centerRight,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(
                                        left: width * 0.07, top: height * 0.02),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Location",
                                          style: TextStyle(
                                              fontSize: width * 0.06,
                                              color: Colors.white),
                                        ),
                                        const SizedBox(
                                          height: 5,
                                        ),
                                        Text(
                                          "Current Location ID :\n${locationNew.latitude}°N ${locationNew.longitude}°E",
                                          style: TextStyle(
                                              fontSize: width * 0.035,
                                              color: Colors.white),
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        InkWell(
                                          onTap: () async {
                                            // setState(() async {
                                            await updateLocation();
                                            // });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(5.0),
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                                color: Colors.white),
                                            child: Text(
                                              "Open in Maps",
                                              style: TextStyle(
                                                fontSize: width * 0.035,
                                                color: const Color.fromRGBO(
                                                    0, 90, 170, 0.8),
                                              ),
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              )),
                              SizedBox(
                                height: height * 0.015,
                              ),
                              Center(
                                child: Container(
                                  height: height * 0.07,
                                  width: width * 0.9,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20.0),
                                      color: Colors.black),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8.0,
                                        vertical: height * 0.01),
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Column(
                                            children: [
                                              Text(
                                                "Status",
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: width * 0.045),
                                              ),
                                              Text(
                                                status.toTitleCase(),
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: width * 0.03),
                                              ),
                                            ],
                                          ),
                                          const VerticalDivider(
                                            color: Colors.white,
                                            thickness: 2,
                                          ),
                                          Column(
                                            children: [
                                              Text(
                                                "Subscription",
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: width * 0.045),
                                              ),
                                              Text(
                                                subscription,
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: width * 0.03),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0),
                                child: Text(
                                  "For You, ",
                                  style: TextStyle(fontSize: width * 0.06),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: width * 0.475,
                                      height: height * 0.45,
                                      child: Column(
                                        children: [
                                          Expanded(
                                              flex: 2,
                                              child: Card(
                                                color: const Color.fromRGBO(
                                                    255, 245, 227, 1),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20)),
                                                elevation: 4,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 12.0,
                                                          top: 12.0),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Image.asset(
                                                            "assets/Mask.png",
                                                            width: 30,
                                                          ),
                                                          SizedBox(
                                                              width:
                                                                  width * 0.02),
                                                          Text(
                                                            "Fall Detection",
                                                            style: TextStyle(
                                                                fontSize:
                                                                    width *
                                                                        0.045),
                                                          ),
                                                        ],
                                                      ),
                                                      Center(
                                                        child: Image.asset(
                                                          values[1] == '1'
                                                              ? "assets/fallaxis.png"
                                                              : "assets/fallaxis0.png",
                                                          height: height * 0.15,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )),
                                          Expanded(
                                            flex: 2,
                                            child: EmergencyCard(
                                              relations: user.relations,
                                              user: user,
                                              sosClicked: sosClicked,
                                              values: values,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: width * 0.01),
                                    Container(
                                      height: height * 0.45,
                                      width: width * 0.475,
                                      child: Column(
                                        children: [
                                          Expanded(
                                              flex: 2,
                                              child: Card(
                                                color: const Color.fromRGBO(
                                                    228, 240, 254, 1),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20)),
                                                elevation: 4,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 12.0,
                                                          left: 12.0),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          const Icon(
                                                              Icons
                                                                  .favorite_outlined,
                                                              size: 30),
                                                          SizedBox(
                                                              width:
                                                                  width * 0.02),
                                                          Text(
                                                            "Heart Rate",
                                                            style: TextStyle(
                                                                fontSize:
                                                                    width *
                                                                        0.045),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Column(
                                                        children: [
                                                          Image.asset(
                                                            "assets/heartrate.png",
                                                            width: width * 0.3,
                                                          ),
                                                          const SizedBox(
                                                            height: 10,
                                                          ),
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Text(
                                                                values[0],
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        width *
                                                                            0.07,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: const Color
                                                                        .fromRGBO(
                                                                        0,
                                                                        83,
                                                                        188,
                                                                        1)),
                                                              ),
                                                              Text(
                                                                " bpm",
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        width *
                                                                            0.03,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: const Color
                                                                        .fromRGBO(
                                                                        0,
                                                                        83,
                                                                        188,
                                                                        1)),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )),
                                          Expanded(
                                              flex: 2,
                                              child: Card(
                                                color: const Color.fromRGBO(
                                                    237, 255, 228, 1),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20)),
                                                elevation: 4,
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                      16.0),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          const Icon(
                                                              Icons.water_drop,
                                                              size: 30),
                                                          SizedBox(
                                                              width:
                                                                  width * 0.02),
                                                          Text(
                                                            "SpO₂",
                                                            style: TextStyle(
                                                                fontSize:
                                                                    width *
                                                                        0.05),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Stack(
                                                        alignment:
                                                            Alignment.center,
                                                        children: [
                                                          Center(
                                                              child: SpO2Gauge(
                                                                  percentage: values[
                                                                              1] !=
                                                                          "--"
                                                                      ? double.parse(
                                                                          values[1]
                                                                              .toString())
                                                                      : 25.0))
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ));
                  },
                );
              },
              error: (error, stackTrace) {
                return const Center(child: Text("Error Fetching User details"));
              },
              loading: () {
                return const Center(child: GradientLoadingIndicator());
              },
            )));
  }
}

class SpO2Gauge extends StatelessWidget {
  final double percentage;

  const SpO2Gauge({required this.percentage});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return CustomPaint(
      size: Size(height * 0.1, height * 0.1),
      painter: SpO2GaugePainter(percentage, height, width),
    );
  }
}

class SpO2GaugePainter extends CustomPainter {
  final double percentage;
  final double startAngle = 3.14 * 0.75; // 135 degrees
  final double sweepAngle = 3.14 * 1.5; // 270 degrees
  final double gapAngle = (pi / 180) + 0.3;
  double height = 0;
  double weight = 0;

  SpO2GaugePainter(this.percentage, this.height, this.weight);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    double radius = size.width / 2;
    Offset center = Offset(size.width / 2, size.height / 2);

    // Background arc
    paint.color = Colors.transparent;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle,
        sweepAngle, false, paint);

    // Yellow arc (0-25%)
    paint.color = Colors.red;
    double yellowSweep = sweepAngle * 0.25 - gapAngle / 2;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle,
        yellowSweep, false, paint);

    // Green arc (25-70%)
    paint.color = Colors.yellow;
    double greenSweep = sweepAngle * 0.43 - gapAngle / 2;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        startAngle + yellowSweep + gapAngle, greenSweep, false, paint);

    // Red arc (70-100%)
    paint.color = Colors.green;
    double redSweep = sweepAngle * 0.3 - gapAngle / 2;
    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + yellowSweep + greenSweep + 2 * gapAngle,
        redSweep,
        false,
        paint);

    // Draw the percentage text
    TextSpan span1 = TextSpan(
        style: TextStyle(color: Colors.black, fontSize: height * 0.025),
        text: '${percentage}');
    TextSpan span2 = TextSpan(
        style: TextStyle(color: Colors.black, fontSize: height * 0.015),
        text: '%');
    final span = TextSpan(
      children: [span1, span2],
    );
    TextPainter tp = TextPainter(
        text: span,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));

    // Calculate the arrow angle based on percentage
    double arrowAngle = startAngle + sweepAngle * (percentage / 100);

    // Draw the arrow
    Paint arrowPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    double arrowLength = radius - 7;
    double arrowBaseWidth = 3;

    double arrowTipX = center.dx + arrowLength * cos(arrowAngle);
    double arrowTipY = center.dy + arrowLength * sin(arrowAngle);

    // Calculate the base of the arrow
    double baseAngle1 = arrowAngle - pi / 2;
    double baseAngle2 = arrowAngle + pi / 2;
    double arrowBase1X = center.dx +
        (arrowLength - 10) * cos(arrowAngle) +
        arrowBaseWidth * cos(baseAngle1);
    double arrowBase1Y = center.dy +
        (arrowLength - 10) * sin(arrowAngle) +
        arrowBaseWidth * sin(baseAngle1);
    double arrowBase2X = center.dx +
        (arrowLength - 10) * cos(arrowAngle) +
        arrowBaseWidth * cos(baseAngle2);
    double arrowBase2Y = center.dy +
        (arrowLength - 10) * sin(arrowAngle) +
        arrowBaseWidth * sin(baseAngle2);

    // Draw the arrow using a Path
    Path arrowPath = Path()
      ..moveTo(arrowTipX, arrowTipY)
      ..lineTo(arrowBase1X, arrowBase1Y)
      ..lineTo(arrowBase2X, arrowBase2Y)
      ..close();

    canvas.drawPath(arrowPath, arrowPaint);

    // Labels at 25% and 99%
    TextStyle labelStyle =
        TextStyle(color: Colors.black, fontSize: height * 0.015);

    // 25% Label
    double label25Angle = startAngle;
    Offset label25Offset = Offset(
      center.dx + (radius + 10) * cos(label25Angle),
      center.dy + (radius + 30) * sin(label25Angle),
    );
    TextSpan label25Span = TextSpan(style: labelStyle, text: '1%');
    TextPainter label25Tp = TextPainter(
        text: label25Span,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr);
    label25Tp.layout();
    label25Tp.paint(canvas,
        label25Offset - Offset(label25Tp.width / 2, label25Tp.height / 2));

    // 99% Label
    double label99Angle = startAngle + sweepAngle;
    Offset label99Offset = Offset(
      center.dx + (radius + 10) * cos(label99Angle),
      center.dy + (radius + 32) * sin(label99Angle),
    );
    TextSpan label99Span = TextSpan(style: labelStyle, text: '99%');
    TextPainter label99Tp = TextPainter(
        text: label99Span,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr);
    label99Tp.layout();
    label99Tp.paint(canvas,
        label99Offset - Offset(label99Tp.width / 2, label99Tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

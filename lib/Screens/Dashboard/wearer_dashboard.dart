import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart' as intl;
import 'package:smartband/Screens/AuthScreen/role_screen.dart';
import 'package:smartband/Screens/Widgets/appBarProfile.dart';
import 'package:smartband/Screens/Widgets/string_extensions.dart';
import 'package:smartband/bluetooth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

import '../Models/usermodel.dart';
import '../Widgets/drawer.dart';
import 'dashboard.dart';

class WearerDashboard extends ConsumerStatefulWidget {
  final BluetoothDevice device;
  final String phNo;

  WearerDashboard({Key? key, required this.device, required this.phNo}) : super(key: key);

  @override
  ConsumerState<WearerDashboard> createState() => _WearerDashboardState();
}

class _WearerDashboardState extends ConsumerState<WearerDashboard> {
  final BluetoothDeviceManager bluetoothDeviceManager =
      BluetoothDeviceManager();
  Position locationNew = const Position(
      latitude: 12.239842,
      longitude: 80.247384,
      timestamp: null,
      accuracy: 1.0,
      altitude: 1.0,
      heading: 1.0,
      speed: 1.0,
      speedAccuracy: 1.0);

  Future<void> openGoogleMaps(double start, double end) async {
    final Uri uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$start,$end');

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $uri';
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

  Future<void> fetchSubscription(String phno)
  async {
    final response = await http.post(
      Uri.parse("https://snvisualworks.com/public/api/auth/check-mobile"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'mobile_number': phno,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      intl.DateFormat dateFormat = intl.DateFormat("dd-MM-yyyy");
      setState(() {
        status = data['status'].toString();
        subscription = data['subscription_period']==null ? "--" : "${data['subscription_period'].toString()} Months";
        print("Fetched");
      });
    }
    else
      {
        print(response.statusCode);
      }
  }

  Future<Position> updateLocation() async {
    Position location = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    print("Fetched Location");
    return location;
  }

  @override
  Widget build(BuildContext context) {
    final user_data =
        ref.watch(userModelProvider(FirebaseAuth.instance.currentUser!.uid));
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
        drawer: DrawerScreen(
          device: bluetoothDeviceManager.connectedDevices.first,
          phNo: widget.phNo,
        ),
        backgroundColor: Colors.white,
        body: user_data.when(
          data: (user) {
            if (user == null) {
              return Center(child: Text("User data is unavailable"));
            }
            fetchSubscription(user.phone_number.toString());
            return StreamBuilder<Map<String, String>>(
              stream: bluetoothDeviceManager.characteristicValuesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                      child:
                          CircularProgressIndicator(color: Colors.blueAccent));
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text("Error reading characteristic values"));
                }

                final characteristicValues = snapshot.data;
                List<String> values = (characteristicValues![
                            "beb5483e-36e1-4688-b7f5-ea07361b26a8"] ??
                        "--,--,0")
                    .split(',');
                Timer.periodic(Duration(minutes: 30), (Timer timer) async {
                  if (FirebaseAuth.instance.currentUser!.uid != null) {
                    await FirebaseFirestore.instance
                        .collection("users")
                        .doc(FirebaseAuth.instance.currentUser!.uid)
                        .update({
                      "metrics": {
                        "spo2": values[2].toString(),
                        "heart_rate": values[1].toString(),
                        "fall_axis": "-- -- --"
                      }
                    });
                  }
                });
                bool sosClicked = values[2] == '1' ? true : false;
                return SafeArea(
                    child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        // Adjust this to fit content
                        children: [
                          // Profile Picture
                          GestureDetector(
                            onTap: () {
                              Scaffold.of(context).openDrawer();
                            },
                            child: Container(
                              margin: EdgeInsets.all(10.0),
                              child: CircleAvatar(
                                radius: 20,
                                backgroundImage: NetworkImage(
                                  FirebaseAuth.instance.currentUser!.photoURL ??
                                      "https://t4.ftcdn.net/jpg/03/26/98/51/360_F_326985142_1aaKcEjMQW6ULp6oI9MYuv8lN9f8sFmj.jpg",
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 3),
                          // Spacing between profile picture and text
                          // Greeting Message
                          Expanded(
                            // Use Expanded to take up remaining space
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      "Hello ${user.name.split(' ')[0].toTitleCase()}",
                                      style: TextStyle(
                                        fontSize: width * 0.055,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Icon(
                                      Icons.keyboard_arrow_down
                                    )
                                  ],
                                ),
                                Text(
                                  DateTime.now().hour > 12
                                      ? DateTime.now().hour > 16
                                          ? "Good Evening ${DateTime.now().day.toString().padLeft(2,'0')}/${DateTime.now().month.toString().padLeft(2,'0')}/${DateTime.now().year.toString().substring(2,)}"
                                          : "Good Afternoon ${DateTime.now().day.toString().padLeft(2,'0')}/${DateTime.now().month.toString().padLeft(2,'0')}/${DateTime.now().year.toString().substring(2,)}"
                                      : "Good Morning ${DateTime.now().day.toString().padLeft(2,'0')}/${DateTime.now().month.toString().padLeft(2,'0')}/${DateTime.now().year.toString().substring(2,)}",
                                  style: TextStyle(
                                    fontSize: width * 0.04,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                child: Image.asset(
                                  "assets/profile_icon.png",
                                  width: 25,
                                  height: 25,
                                ),
                                onTap: () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                      builder: (context) => HomePage(
                                          phNo: user.phone_number.toString())));
                                },
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Icon(
                                Icons.notifications,
                                size: 25,
                              )
                            ],
                          ),
                          SizedBox(
                            width: width * 0.01,
                          )
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                              child: Stack(
                            children: [
                              Container(
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
                                width: MediaQuery.of(context).size.width * 0.9,
                                height:
                                    MediaQuery.of(context).size.height * 0.17,
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Location",
                                      style: TextStyle(
                                          fontSize: width * 0.06,
                                          color: Colors.white),
                                    ),
                                    SizedBox(
                                      height: 5,
                                    ),
                                    Text(
                                      "Current Location ID :\n${locationNew.latitude}°N ${locationNew.longitude}°E",
                                      style: TextStyle(
                                          fontSize: width * 0.035,
                                          color: Colors.white),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    InkWell(
                                      onTap: () {
                                        setState(() async {
                                          locationNew = await updateLocation();
                                        });
                                        openGoogleMaps(locationNew.latitude,
                                            locationNew.longitude);
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(5.0),
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                            color: Colors.white),
                                        child: Text(
                                          "Open in Maps",
                                          style: TextStyle(
                                            fontSize: width * 0.035,
                                            color: Color.fromRGBO(0, 90, 170, 0.8),
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
                                    horizontal: 8.0, vertical: height * 0.01),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      // Column(
                                      //   children: [
                                      //     Text(
                                      //       "Water",
                                      //       style: TextStyle(
                                      //           color: Colors.white,
                                      //           fontSize: width * 0.045),
                                      //     ),
                                      //     Text(
                                      //       "2Litre",
                                      //       style: TextStyle(
                                      //           color: Colors.white,
                                      //           fontSize: width * 0.03),
                                      //     ),
                                      //   ],
                                      // ),
                                      // VerticalDivider(
                                      //   color: Colors.white,
                                      //   thickness: 2,
                                      // ),
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
                                      VerticalDivider(
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
                            padding: EdgeInsets.symmetric(horizontal: 20.0),
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
                                            color: Color.fromRGBO(255, 245, 227, 1),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20)),
                                            elevation: 4,
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 12.0, top: 12.0),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(
                                                          Icons
                                                              .monitor_heart_outlined,
                                                          size: 30),
                                                      SizedBox(
                                                          width: width * 0.02),
                                                      Text(
                                                        "Fall Detection",
                                                        style: TextStyle(
                                                            fontSize:
                                                                width * 0.045),
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
                                                    BorderRadius.circular(20)),
                                            elevation: 4,
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 12.0, left: 12.0),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                          Icons
                                                              .favorite_outlined,
                                                          size: 30),
                                                      SizedBox(
                                                          width: width * 0.02),
                                                      Text(
                                                        "Heart Rate",
                                                        style: TextStyle(
                                                            fontSize:
                                                                width * 0.045),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 8),
                                                  Column(
                                                    children: [
                                                      Image.asset(
                                                        "assets/heartrate.png",
                                                        width: width * 0.3,
                                                      ),
                                                      SizedBox(
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
                                                                color: Color.fromRGBO(0, 83, 188, 1)
                                                            ),
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
                                                                color: Color.fromRGBO(0, 83, 188, 1)
                                                            ),
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
                                                    BorderRadius.circular(20)),
                                            elevation: 4,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(Icons.water_drop,
                                                          size: 30),
                                                      SizedBox(
                                                          width: width * 0.02),
                                                      Text(
                                                        "SpO₂",
                                                        style: TextStyle(
                                                            fontSize:
                                                                width * 0.05),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 8),
                                                  Stack(
                                                    alignment: Alignment.center,
                                                    children: [
                                                      Center(
                                                          child: SpO2Gauge(
                                                              percentage: values[
                                                                          1] !=
                                                                      "--"
                                                                  ? int.parse(
                                                                      values[1]
                                                                          .toString())
                                                                  : 25))
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
            return Center(child: Text("Error Fetching User details"));
          },
          loading: () {
            return Center(
                child: CircularProgressIndicator(color: Colors.blueAccent));
          },
        ));
  }
}

class SpO2Gauge extends StatelessWidget {
  final int percentage;

  SpO2Gauge({required this.percentage});

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
  final int percentage;
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
        textDirection: TextDirection.ltr
    );
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
        textDirection: TextDirection.ltr
    );
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
        textDirection: TextDirection.ltr
    );
    label99Tp.layout();
    label99Tp.paint(canvas,
        label99Offset - Offset(label99Tp.width / 2, label99Tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

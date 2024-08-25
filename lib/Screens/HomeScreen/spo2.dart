import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smartband/Providers/OwnerDeviceData.dart';
import 'package:smartband/Screens/AuthScreen/role_screen.dart';
import 'package:smartband/Screens/Widgets/string_extensions.dart';
import 'package:smartband/bluetooth.dart';
import '../Models/usermodel.dart';
import '../Widgets/drawer.dart';
import 'package:provider/provider.dart' as provider;

class Spo2Screen extends ConsumerStatefulWidget {
  final BluetoothDevice device;
  final String phNo;

  const Spo2Screen({super.key, required this.device, required this.phNo});

  @override
  ConsumerState<Spo2Screen> createState() => _Spo2ScreenState();
}

class _Spo2ScreenState extends ConsumerState<Spo2Screen> {
  final BluetoothDeviceManager bluetoothDeviceManager =
      BluetoothDeviceManager();
  // Position location_new = const Position(
  //     latitude: 12.239842,
  //     longitude: 80.247384,
  //     timestamp: null,
  //     accuracy: 1.0,
  //     altitude: 1.0,
  //     heading: 1.0,
  //     speed: 1.0,
  //     speedAccuracy: 1.0);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final user_data =
        ref.watch(userModelProvider(FirebaseAuth.instance.currentUser!.uid));
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final deviceOwnerData = provider.Provider.of<OwnerDeviceData>(context);
    return Scaffold(
        backgroundColor: Colors.white,
        body: user_data.when(
          data: (user) {
            if (user == null) {
              return const Center(child: Text("User data is unavailable"));
            }
            return SafeArea(
                child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(
                    height: 20,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                          padding: const EdgeInsets.all(15),
                          width: width * 0.95,
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.network(
                                  "https://img.freepik.com/free-psd/human-organs-character-composition_23-2150610255.jpg?w=740&t=st=1722582551~exp=1722583151~hmac=9063f493678bb77871c62d73d0ebf86776220ef9f1ef77d6d81eac42809654b2",
                                  width: width * 0.4,
                                ),
                              ),
                              const SizedBox(
                                width: 15,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Health Age",
                                    style: TextStyle(
                                        fontSize: width * 0.05,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        deviceOwnerData.age.toString(),
                                        style: TextStyle(
                                            fontSize: width * 0.1,
                                            color: Colors.white),
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Text(
                                        "years",
                                        style: TextStyle(
                                            fontSize: width * 0.05,
                                            color: Colors.white),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    width: width * 0.4,
                                    child: Text(
                                      "Congrats! You're on a healthier track.",
                                      maxLines: 2,
                                      style: TextStyle(
                                          fontSize: width * 0.03,
                                          color: Colors.white),
                                    ),
                                  )
                                ],
                              )
                            ],
                          )),
                      const SizedBox(
                        height: 10,
                      ),
                      Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 15.0),
                              child: Text(
                                "Track your SPO2",
                                style: TextStyle(
                                    fontSize: width * 0.05,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          )),
                      const SizedBox(
                        height: 10,
                      ),
                      Container(
                          padding: const EdgeInsets.all(15),
                          width: width * 0.95,
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(228, 240, 254, 1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Image.asset(
                                    "assets/heart_rate_1.png",
                                    width: width * 0.4,
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        deviceOwnerData.spo2.toString(),
                                        style: TextStyle(fontSize: width * 0.1),
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Column(
                                        children: [
                                          Image.asset("assets/spo2_icon.png"),
                                          Text(
                                            "%",
                                            style: TextStyle(
                                                fontSize: width * 0.04),
                                          )
                                        ],
                                      )
                                    ],
                                  )
                                ],
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Container(
                                width: width * 0.8,
                                height: height * 0.01,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  gradient: const LinearGradient(colors: [
                                    Colors.green,
                                    Colors.yellow,
                                    Colors.orange,
                                    Colors.red
                                  ], stops: [
                                    0.175,
                                    0.275,
                                    0.35,
                                    1.0
                                  ]),
                                ),
                              ),
                              Container(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 100),
                                child: const Icon(
                                  Icons.arrow_drop_down_sharp,
                                  size: 20,
                                  color: Colors.black,
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Text(
                                    "Average",
                                    style: TextStyle(fontSize: width * 0.035),
                                  ),
                                  Text(
                                    "Healthy",
                                    style: TextStyle(fontSize: width * 0.035),
                                  ),
                                  Text(
                                    "Maximum",
                                    style: TextStyle(fontSize: width * 0.035),
                                  ),
                                  Text(
                                    "Danger",
                                    style: TextStyle(fontSize: width * 0.035),
                                  )
                                ],
                              )
                            ],
                          )),
                      const SizedBox(
                        height: 15,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Image.asset(
                          "assets/heart_rate.png",
                          width: width * 0.9,
                        ),
                      )
                    ],
                  )
                ],
              ),
            ));
          },
          error: (error, stackTrace) {
            return const Center(child: Text("Error Fetching User details"));
          },
          loading: () {
            return const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent));
          },
        ));
  }
}

class SpO2Gauge extends StatelessWidget {
  final int percentage;

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
    paint.color = Colors.yellow;
    double yellowSweep = sweepAngle * 0.25 - gapAngle / 2;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle,
        yellowSweep, false, paint);

    // Green arc (25-70%)
    paint.color = Colors.green;
    double greenSweep = sweepAngle * 0.43 - gapAngle / 2;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        startAngle + yellowSweep + gapAngle, greenSweep, false, paint);

    // Red arc (70-100%)
    paint.color = Colors.red;
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

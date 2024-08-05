import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartband/Screens/AuthScreen/role_screen.dart';
import 'package:smartband/Screens/AuthScreen/signin.dart';
import 'package:smartband/Screens/HomeScreen/homepage.dart';
import 'package:smartband/Screens/Models/messaging.dart';


class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  OtpVerificationScreen({super.key, required this.phoneNumber});

  @override
  _OtpVerificationScreenState createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  late Timer _timer;
  int _start = 60;

  String _verificationId = '';
  final _otpControllers = List.generate(6, (index) => TextEditingController());
  final _focusNodes = List.generate(6, (index) => FocusNode());
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int otp_num = 100000 + Random().nextInt(999999 - 100000 + 1);

  void startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          timer.cancel();
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  void _verifyPhone(String phoneNumber) async {
    if (phoneNumber.substring(3, phoneNumber.length).isNotEmpty) {
      print(phoneNumber.substring(3, phoneNumber.length));
      print(otp_num);
      Messaging messaging = Messaging();
      // messaging.sendSMS(widget.phoneNumber, "Your OTP is $otp_num");
    }
  }

  void _verifyOtp(String phNo, int generated_otp) async {
    String otp = _otpControllers.map((controller) => controller.text).join();
    try {
      print("${otp}  ${generated_otp}");
      if (true)
      // if (int.parse(otp) == generated_otp)
      {
        final data = await FirebaseFirestore.instance
            .collection("users")
            .where("phone_number",
                isEqualTo: int.parse(phNo.substring(3, phNo.length)))
            .get();
        if (data.docs.isNotEmpty) {
          final email = data.docs.first.data()['email'];

          await FirebaseAuth.instance
              .signInWithEmailAndPassword(email: email, password: "admin123");
          print(FirebaseAuth.instance.currentUser!.uid);
          await FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .update({'fcmKey': await FirebaseMessaging.instance.getToken()});
          Navigator.of(context, rootNavigator: true)
              .pushReplacement(MaterialPageRoute(
                  maintainState: true,
                  builder: (context) => HomepageScreen(
                        hasDeviceId: false,
                      )));
        }
        else {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => HomePage(
                    phNo: widget.phoneNumber,
                  )));
        }
      }
    } catch (e) {
      print('Failed to sign in: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    startTimer();
    _verifyPhone(widget.phoneNumber);
  }

  @override
  void dispose() {
    _timer.cancel();
    _otpControllers.forEach((controller) => controller.dispose());
    _focusNodes.forEach((node) => node.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final TextStyle style = TextStyle(
      fontSize: width * 0.1,
      fontWeight: FontWeight.bold,
    );
    const Gradient gradient = LinearGradient(
      colors: <Color>[
        Colors.redAccent,
        Colors.yellow,
        Colors.redAccent,
      ],
    );

    int minutes = _start ~/ 60;
    int seconds = _start % 60;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Stack(
            children: [
              Container(
                height: height / 2,
                decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(30.0),
                        bottomLeft: Radius.circular(30.0)),
                    color: Colors.blueAccent.withOpacity(0.2)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    SizedBox(height: height * 0.1),
                    Text(
                      'Enter verification code',
                      style: TextStyle(
                        fontSize: width * 0.07,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Image.asset(
                      "assets/otp_page.png",
                      width: width * 0.3,
                    ),
                    Card(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'We have sent OTP on your mobile number',
                              style: TextStyle(fontSize: height * 0.02),
                            ),
                            Text(
                              '${widget.phoneNumber}',
                              style: TextStyle(
                                  fontSize: height * 0.02,
                                  fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: height * 0.01),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(6, (index) {
                                return Container(
                                  width: 40,
                                  child: TextField(
                                    controller: _otpControllers[index],
                                    focusNode: _focusNodes[index],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 24),
                                    keyboardType: TextInputType.number,
                                    maxLength: 1,
                                    onChanged: (value) {
                                      if (value.isNotEmpty && index < 5) {
                                        FocusScope.of(context).requestFocus(
                                            _focusNodes[index + 1]);
                                      } else if (value.isEmpty && index > 0) {
                                        FocusScope.of(context).requestFocus(
                                            _focusNodes[index - 1]);
                                      }
                                    },
                                    decoration: InputDecoration(
                                      counterText: "",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                            SizedBox(height: height * 0.01),
                            _start == 0
                                ? TextButton(
                                    onPressed: () {
                                      // Resend OTP logic
                                      otp_num = 100000 +
                                          Random().nextInt(999999 - 100000 + 1);
                                      _verifyPhone(widget.phoneNumber);
                                      setState(() {
                                        _start = 90;
                                      });
                                      startTimer();
                                    },
                                    child: Text(
                                      'Resend',
                                      style: TextStyle(
                                        fontSize: height * 0.015,
                                        color: Color.fromRGBO(0, 83, 188, 1),
                                      ),
                                    ),
                                  )
                                : Text(
                                    'Resend the OTP in ${seconds.toString().padLeft(2, '0')} seconds',
                                    style: TextStyle(
                                        fontSize: height * 0.015,
                                        color: Colors.grey),
                                  ),
                            SizedBox(height: height * 0.01),
                            Center(
                                child: Container(
                              width: width * 0.9,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Color.fromRGBO(0, 83, 188, 1),
                              ),
                              child: TextButton(
                                onPressed: () {
                                  _verifyOtp(widget.phoneNumber, otp_num);
                                },
                                child: Text(
                                  'Verify OTP',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: width * 0.05),
                                ),
                              ),
                            )),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

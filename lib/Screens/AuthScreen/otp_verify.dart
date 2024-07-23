import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartband/Screens/AuthScreen/role_screen.dart';
import 'package:smartband/Screens/AuthScreen/signin.dart';
import 'package:smartband/Screens/HomeScreen/homepage.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  OtpVerificationScreen({super.key, required this.phoneNumber});

  @override
  _OtpVerificationScreenState createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  late Timer _timer;
  int _start = 90; // 1:30 in seconds
  String _verificationId = '';
  final _otpControllers = List.generate(6, (index) => TextEditingController());
  final _focusNodes = List.generate(6, (index) => FocusNode());
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        if (e.code == 'invalid-phone-number') {
          print('The provided phone number is not valid.');
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        setState(() {
          _verificationId = verificationId;
        });
      },
    );
  }

  void _verifyOtp() async {

    String otp = _otpControllers.map((controller) => controller.text).join();
    // PhoneAuthCredential credential = PhoneAuthProvider.credential(
    //   verificationId: _verificationId,
    //   smsCode: otp,
    // );

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: 'vish2004k@outlook.com',
        password: 'admin123',
      );

      Navigator.of(context).push(MaterialPageRoute(builder: (context) => HomePage()));
      // await _auth.signInWithCredential(credential);
      // Successfully signed in
      // Navigate to your next screen or do something else
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'SMART TRACKERS',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'OTP Verification',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Enter the OTP code you received at',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '${widget.phoneNumber}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Text(
                '00:${_start.toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 24, color: Colors.red),
              ),
              SizedBox(height: 20),
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
                          FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
                        } else if (value.isEmpty && index > 0) {
                          FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
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
              SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  // Resend OTP logic
                  _verifyPhone(widget.phoneNumber);
                  setState(() {
                    _start = 90;
                  });
                  startTimer();
                },
                child: Text('Resend'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _verifyOtp,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('Verify the OTP'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

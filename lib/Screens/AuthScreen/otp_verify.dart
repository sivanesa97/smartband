import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartband/Providers/OwnerDeviceData.dart';
import 'package:smartband/Providers/SubscriptionData.dart';
import 'package:smartband/Screens/AuthScreen/success_screen.dart';
import 'package:smartband/Screens/Models/messaging.dart';
import 'package:smartband/bluetooth_connection_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpVerificationScreen({super.key, required this.phoneNumber});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  late Timer _timer;
  int _start = 60;
  bool _isVerifying = false;

  final _otpControllers = List.generate(6, (index) => TextEditingController());
  final _focusNodes = List.generate(6, (index) => FocusNode());
  int otpNum = 100000 + Random().nextInt(999999 - 100000 + 1);

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
    if (phoneNumber.length >= 3) {
      print("Your OTP is $otpNum");
      Messaging messaging = Messaging();
      messaging.sendSMS(phoneNumber, "Your OTP is $otpNum");
    }
  }

  void _verifyOtp(String phNo, int generatedOtp, BuildContext context) async {
    String otp = _otpControllers.map((controller) => controller.text).join();
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text("Please enter complete 6-digit OTP!"),
            ],
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // Check if entered OTP matches generated OTP sent via SMS
    if (int.tryParse(otp) != generatedOtp) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.lock_clock_outlined, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text("Invalid OTP! Please enter the correct OTP sent to your phone."),
            ],
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      final data = await FirebaseFirestore.instance
          .collection("users")
          .where("phone_number", isEqualTo: phNo)
          .get();
      var apiData = await BluetoothConnectionService().getApiData(phNo);
      final prefs = await SharedPreferences.getInstance();
      int ownerStatus = 0;
      String deviceName = "";

      if (apiData != null) {
        deviceName = apiData['deviceName'] ?? "";
        if (deviceName == "null") {
          deviceName = "";
        }
        bool isSubscriptionActive = apiData['isSubscriptionActive'] ?? false;
        bool isUserActive = apiData['isUserActive'] ?? false;
        if (isUserActive && isSubscriptionActive) {
          if (deviceName != "") {
            ownerStatus = 1;
            if (!mounted) return;
            Provider.of<SubscriptionDataProvider>(context, listen: false)
                .updateStatus(
                    active: true,
                    deviceName: deviceName,
                    subscribed: true,
                    phoneNumber: widget.phoneNumber);
            final deviceOwnerData =
                Provider.of<OwnerDeviceData>(context, listen: false);
            int age = 0;
            if (data.docs.isNotEmpty) {
              var dob = data.docs.first.data()['dob'];
              if (dob != null && dob != '') {
                try {
                  DateTime birthdate =
                      DateFormat("yyyy-MM-dd").parse(dob.toString());
                  DateTime currentDate = DateTime.now();
                  age = currentDate.year - birthdate.year;
                  if (currentDate.month < birthdate.month ||
                      (currentDate.month == birthdate.month &&
                          currentDate.day < birthdate.day)) {
                    age--;
                  }
                } catch (e) {
                  debugPrint(e.toString());
                }
              }
            }
            if (!mounted) return;
            Provider.of<OwnerDeviceData>(context, listen: false).updateStatus(
                age: age,
                heartRate: deviceOwnerData.heartRate,
                spo2: deviceOwnerData.spo2,
                sosClicked: false);
          } else {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("Device is not assigned!"),
                backgroundColor: Colors.orange.shade800,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        } else if (isUserActive && deviceName != "") {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Please Subscribe to use watch!"),
              backgroundColor: Colors.orange.shade800,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        } else if (deviceName != "") {
          ownerStatus = 1;
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("API Issue! Contact Tech Support!"),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }

      prefs.setInt('ownerStatus', ownerStatus);

      if (data.docs.isNotEmpty) {
        final email = data.docs.first.data()['email'];
        await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: "admin123");
        await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .update({'fcmKey': await FirebaseMessaging.instance.getToken()});
        if (!mounted) return;
        if (ownerStatus == 1) {
          Navigator.of(context, rootNavigator: true).pushReplacement(
              MaterialPageRoute(
                  maintainState: true,
                  builder: (context) => RoleSelectionScreen(
                      role: 'watch wearer',
                      phNo: '',
                      deviceId: '',
                      status: '1')));
        } else {
          Provider.of<SubscriptionDataProvider>(context, listen: false)
              .updateStatus(
                  active: false,
                  deviceName: "",
                  subscribed: false,
                  phoneNumber: widget.phoneNumber);
          if (!mounted) return;
          Navigator.of(context, rootNavigator: true).pushReplacement(
              MaterialPageRoute(
                  maintainState: true,
                  builder: (context) => RoleSelectionScreen(
                      role: 'supervisor',
                      phNo: phNo,
                      deviceId: '',
                      status: '1')));
        }
      } else {
        String selectedRole = "supervisor";
        if (ownerStatus == 1) {
          selectedRole = "watch wearer";
        } else {
          if (!mounted) return;
          Provider.of<SubscriptionDataProvider>(context, listen: false)
              .updateStatus(
                  active: false,
                  deviceName: "",
                  subscribed: false,
                  phoneNumber: widget.phoneNumber);
        }
        if (!mounted) return;
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => RoleSelectionScreen(
                phNo: phNo,
                role: selectedRole,
                deviceId: deviceName,
                status: '2')));
      }
    } catch (e) {
      debugPrint('Failed to sign in: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
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
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    int minutes = _start ~/ 60;
    int seconds = _start % 60;
    String timerText =
        "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar with Back Button
              Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 12.0, right: 16.0),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.maybePop(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Hero Illustration
              Center(
                child: Container(
                  width: size.width * 0.40,
                  height: size.width * 0.40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFE0EDFF),
                        const Color(0xFFF0F6FF).withOpacity(0.5),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0052CC).withOpacity(0.08),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Image.asset(
                      "assets/otp_page.png",
                      width: size.width * 0.26,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.mark_email_read_rounded,
                          size: 60,
                          color: Color(0xFF0052CC),
                        );
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Headings
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const Center(
                      child: Text(
                        'Enter verification code',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Center(
                      child: Text(
                        'We have sent OTP on your mobile number',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFDBEAFE)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.phone_android_rounded,
                              size: 16,
                              color: Color(0xFF0052CC),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.phoneNumber,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0052CC),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Main Card with Pin Inputs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18.0, vertical: 24.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withOpacity(0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // 6 Pin TextFields
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (index) {
                          return SizedBox(
                            width: (size.width - 110) / 6,
                            height: 56,
                            child: TextField(
                              controller: _otpControllers[index],
                              focusNode: _focusNodes[index],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(1),
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (value) {
                                if (value.isNotEmpty && index < 5) {
                                  _focusNodes[index + 1].requestFocus();
                                } else if (value.isEmpty && index > 0) {
                                  _focusNodes[index - 1].requestFocus();
                                }
                                setState(() {});
                              },
                              decoration: InputDecoration(
                                counterText: "",
                                contentPadding: EdgeInsets.zero,
                                filled: true,
                                fillColor: _otpControllers[index].text.isNotEmpty
                                    ? const Color(0xFFF0F7FF)
                                    : const Color(0xFFF8FAFC),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: _otpControllers[index].text.isNotEmpty
                                        ? const Color(0xFF0052CC)
                                        : const Color(0xFFE2E8F0),
                                    width: _otpControllers[index].text.isNotEmpty
                                        ? 1.5
                                        : 1.0,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF0052CC),
                                    width: 2.0,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 20),

                      // Timer & Resend
                      _start == 0
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Didn't receive code? ",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    otpNum = 100000 +
                                        Random().nextInt(999999 - 100000 + 1);
                                    _verifyPhone(widget.phoneNumber);
                                    setState(() {
                                      _start = 60;
                                    });
                                    startTimer();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text("New OTP sent!"),
                                        backgroundColor:
                                            const Color(0xFF0052CC),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Resend Code',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0052CC),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.timer_outlined,
                                    size: 15,
                                    color: Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Resend the OTP in $timerText',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                      const SizedBox(height: 24),

                      // Verify OTP Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isVerifying
                              ? null
                              : () {
                                  _verifyOtp(
                                      widget.phoneNumber, otpNum, context);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0052CC),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                const Color(0xFF0052CC).withOpacity(0.6),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isVerifying
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Verify OTP',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

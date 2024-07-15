import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smartband/Screens/HomeScreen/homepage.dart';
import '../Models/twilio_service.dart';
import '../Widgets/appBar.dart';
import 'dart:math';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _username = TextEditingController();
  final TextEditingController _emailId = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _dateOfBirth = TextEditingController();
  final TextEditingController _phone_number = TextEditingController();
  final TextEditingController _height = TextEditingController();
  final TextEditingController _weight = TextEditingController();
  final TextEditingController _emailConn = TextEditingController();
  final TextEditingController _otpConn = TextEditingController();

  bool _isValid = false;
  String? _selectedGender;
  String? _selectedRole = "watch wearer";

  void _validateUsername(String value) {
    setState(() {
      _isValid = value.isNotEmpty &&
          value.length >= 3 &&
          RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value);
    });
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<GeoPoint> getLocation() async {
    Position location = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    return GeoPoint(location.latitude, location.longitude);
  }

  Future<void> signUpWithCredentials(int otp_num) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Creating account... Please wait")));
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailId.text,
        password: _password.text,
      );
      if (_selectedRole == "watch wearer") {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Fetching Location... Please wait")));
        final locationData = await getLocation();
        await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .set({
          'name': _username.text,
          'dob': _dateOfBirth.text,
          'height': double.parse(_height.text),
          'weight': double.parse(_weight.text),
          'email': _emailId.text,
          'gender': _selectedGender,
          'phone_number': int.parse(_phone_number.text),
          'relations': [],
          'location': locationData,
          'metrics': {'heart_rate': 0, 'steps': 0, 'fall_axis': 0},
          'role': _selectedRole,
          "emergency": {
            "name": "",
            "blood_group": "",
            "medical_notes": "",
            "address": "",
            "medications": "",
            "organ_donor": false,
            "contact": 0,
          },
          'steps_goal': 0
        });
      }
      else {
        if (_otpConn.text == otp_num.toString()) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Fetching Location... Please wait")));
          final locationData = await getLocation();
          await FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .set({
            'name': _username.text,
            'dob': _dateOfBirth.text,
            'height': double.parse(_height.text),
            'weight': double.parse(_weight.text),
            'email': _emailId.text,
            'gender': _selectedGender,
            'phone_number': int.parse(_phone_number.text),
            'relations': FieldValue.arrayUnion([_emailConn.text]),
            'location': locationData,
            'metrics': {'heart_rate': 0, 'steps': 0, 'fall_axis': 0},
            'role': "supervisor",
            "emergency": {
              "name": "",
              "blood_group": "",
              "medical_notes": "",
              "address": "",
              "medications": "",
              "organ_donor": false,
              "contact": 0,
            },
            'steps_goal': 0
          });
          print("User created");
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Account created successfully")));
          Navigator.of(context, rootNavigator: true).pushReplacement(
            MaterialPageRoute(
                maintainState: true, builder: (context) => HomepageScreen()),
          );
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Invalid OTP")));
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("The password provided is too weak.")));
      } else if (e.code == 'email-already-in-use') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("The account already exists for that email.")));
      }
    } catch (e) {
      print(e);
    }
  }

  final TwilioService twilioService = TwilioService(
    accountSid: 'ACf1f0c0870c825a03dc6db124b365cf6a',
    authToken: 'fa856967b5f8bc971b3b783197c3ce33',
    fromNumber: '+17628009114',
  );

  Future<List<Map<String, dynamic>>> _fetchRelationDetails(
      String email, int otp_num) async {
    List<Map<String, dynamic>> relationDetails = [];
    bool madeCall = false;
    var userDoc = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();
    if (userDoc.docs.isNotEmpty) {
      final data = userDoc.docs.first.data()['phone_number'];
      print(data);
      await twilioService.sendSms('+91${data}', 'Your OTP is ${otp_num}');
    }
    return relationDetails;
  }

  void _showRoleDialog() {
    bool sent = false;
    int otp_num = 100000 + Random().nextInt(999999 - 100000 + 1);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Select Role'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Role',
                      ),
                      value: _selectedRole,
                      items: ['watch wearer', 'supervisor'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child:
                              Text(value[0].toUpperCase() + value.substring(1)),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedRole = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _selectedRole == "supervisor"
                        ? TextFormField(
                            controller: _emailConn,
                            decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Email',
                                suffixIcon: IconButton(
                                    onPressed: () {
                                      sent = true;
                                      _otpConn.text="";
                                      _fetchRelationDetails(
                                          _emailConn.text, otp_num);
                                    },
                                    icon: Icon(sent ? Icons.check : Icons.send))),
                          )
                        : const SizedBox.shrink(),
                    SizedBox(height: 16,),
                    _selectedRole == "supervisor"
                        ? TextFormField(
                            controller: _otpConn,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'OTP',
                            ),
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    signUpWithCredentials(otp_num);
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppBarWidget(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Sign up",
                style: TextStyle(
                  fontSize: 35,
                ),
              ),
              SizedBox(
                height: height * 0.09,
              ),
              Center(
                child: SizedBox(
                  width: width * 0.9,
                  child: TextFormField(
                    controller: _username,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'Name',
                      suffixIcon: _isValid
                          ? const Icon(Icons.check, color: Colors.green)
                          : null,
                    ),
                    onChanged: _validateUsername,
                  ),
                ),
              ),
              SizedBox(height: height * 0.015),
              Center(
                child: SizedBox(
                  width: width * 0.9,
                  child: TextFormField(
                    controller: _emailId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Email',
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: height * 0.015,
              ),
              Center(
                child: SizedBox(
                  width: width * 0.9,
                  child: TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Password',
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: height * 0.015,
              ),
              Center(
                child: SizedBox(
                  width: width * 0.9,
                  child: TextFormField(
                    controller: _phone_number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Phone Number',
                    ),
                  ),
                ),
              ),
              SizedBox(height: height * 0.015),
              Center(
                child: SizedBox(
                  width: width * 0.9,
                  child: TextFormField(
                    controller: _dateOfBirth,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'D.o.B',
                    ),
                  ),
                ),
              ),
              SizedBox(height: height * 0.015),
              Center(
                child: SizedBox(
                  width: width * 0.9,
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Select your gender',
                    ),
                    value: _selectedGender,
                    items: ['Male', 'Female', 'Other'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedGender = newValue;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(
                height: height * 0.015,
              ),
              Center(
                child: SizedBox(
                  width: width * 0.9,
                  child: TextFormField(
                    controller: _height,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Height',
                    ),
                  ),
                ),
              ),
              SizedBox(height: height * 0.015),
              Center(
                child: SizedBox(
                  width: width * 0.9,
                  child: TextFormField(
                    controller: _weight,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Weight',
                    ),
                  ),
                ),
              ),
              SizedBox(height: height * 0.015),
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: "Already have an account?",
                          style: TextStyle(fontSize: 14),
                        ),
                        WidgetSpan(
                          child: Icon(
                            Icons.arrow_right_alt,
                            size: 16,
                            weight: 700,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: height * 0.015,
              ),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    _showRoleDialog();
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(width * 0.9, 50),
                    backgroundColor: Colors.black26,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    "SIGN UP",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              SizedBox(
                height: height * 0.03,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

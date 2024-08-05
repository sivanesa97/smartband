import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smartband/Screens/HomeScreen/homepage.dart';
import 'package:http/http.dart' as http;
import 'dart:math';

class SignupScreen extends StatefulWidget {
  String phNo;
  String role;

  SignupScreen({super.key, required this.phNo, required this.role});

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

  DateTime? _selectedDate;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _dateOfBirth.text = "${picked.year}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}";
      });
    }
  }

  bool _isValid = false;
  String? _selectedGender;
  String? _selectedRole = "watch wearer";

  void _validateUsername(String value) {
    setState(() {
      _isValid = value.isNotEmpty &&
          value.length >= 3 &&
          RegExp(r"^[a-zA-Z]+(([' -][a-zA-Z ])?[a-zA-Z]*)*$").hasMatch(value);
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

  Future<void> signUpWithCredentials() async {
    try {
      try {
        final datas = await FirebaseFirestore.instance
            .collection('users')
            .where("email", isEqualTo: _emailId.text)
            .get();
        if (datas.docs.isEmpty)
          {
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: _emailId.text,
              password: "admin123",
            );
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Creating account... Please wait")));
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Fetching Location... Please wait")));
            final locationData = await getLocation();
            await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: _emailId.text,
              password: "admin123",
            );
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
              'isSOSClicked': false,
              'location': locationData,
              'home_location': locationData,
              'metrics': {'heart_rate': '0', 'spo2': '0', 'fall_axis': "-- -- --"},
              'role': widget.role,
              "emergency": {
                "name": "",
                "blood_group": "",
                "medical_notes": "",
                "address": "",
                "medications": "",
                "organ_donor": false,
                "contact": 0,
              },
              'device_id': "",
              'steps_goal': 0,
              'fcmKey': await FirebaseMessaging.instance.getToken()
            });

            if (widget.role == "watch wearer")
              {
                final response = await http.post(
                  Uri.parse("https://snvisualworks.com/public/api/auth/register"),
                  headers: <String, String>{
                    'Content-Type': 'application/json; charset=UTF-8',
                  },
                  body: jsonEncode(<String, dynamic>{
                    'name': _username.text,
                    'mobile_number': _phone_number.text,
                    'email': _emailId.text,
                    'date_of_birth': _dateOfBirth.text,
                    'gender': _selectedGender?.toLowerCase(),
                    'height': double.parse(_height.text).toInt(),
                    'weight': double.parse(_weight.text).toInt(),
                  }),
                );
                print(response.statusCode);
              }

            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Account created successfully")));
            Navigator.of(context, rootNavigator: true).pushReplacement(
                MaterialPageRoute(
                    maintainState: true,
                    builder: (context) => HomepageScreen(hasDeviceId: false,)));
          }
        else
          {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Account already exists with this mail ID ")));
          }
      }
      catch (exception)
    {
      User? user = FirebaseAuth.instance.currentUser;
      user?.delete();
      print("Account deleted");
    }
    } on FirebaseAuthException catch (e) {
      User? user = FirebaseAuth.instance.currentUser;
      user?.delete();
      print("Account deleted");
      if (e.code == 'weak-password') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("The password provided is too weak.")));
      } else if (e.code == 'email-already-in-use') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("The account already exists for that email.")));
      }
      else
        {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Error : ${e.message}")));
        }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchRelationDetails(String email,
      int otp_num) async {
    List<Map<String, dynamic>> relationDetails = [];
    bool madeCall = false;
    var userDoc = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();
    if (userDoc.docs.isNotEmpty) {
      final data = userDoc.docs.first.data()['phone_number'];
      // await twilioService.sendSms('+91${data}', 'Your OTP is ${otp_num}');
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
                                _otpConn.text = "";
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
                    if (_selectedRole == 'supervisor' &&
                        _emailConn.text != "" ||
                        _selectedRole == 'watch wearer') {
                      signUpWithCredentials();
                      Navigator.of(context, rootNavigator: true).pop();
                    }
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
  void initState() {
    // TODO: implement initState
    super.initState();
    _phone_number.text = widget.phNo.substring(3,widget.phNo.length);
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery
        .of(context)
        .size
        .height;
    final width = MediaQuery
        .of(context)
        .size
        .width;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: height * 0.02,),
                SizedBox(
                  height: height * 0.075,
                ),
                Text(
                  "Personal Information",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: width * 0.08,
                  ),
                ),
                SizedBox(
                  height: height * 0.01,
                ),
                Center(
                  child: SizedBox(
                    width: width * 0.9,
                    child: TextFormField(
                      controller: _username,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: 'Full Name',
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
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Email',
                        suffixIcon: RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(_emailId.text)
                            ? const Icon(Icons.check, color: Colors.green)
                            : null,
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
                      readOnly: true,
                      decoration: InputDecoration(
                        suffixIcon: RegExp(r'^(?!([0-9])\1{9,})(\+?\d{1,4}[\s-]?)?(\(?\d{3}\)?[\s-]?)?[\d\s-]{7,10}$').hasMatch(_phone_number.text) ? Icon(Icons.check, color: Colors.green,) : Icon(Icons.close, color: Colors.red,),
                        border: const OutlineInputBorder(),
                        labelText: 'Phone Number',
                      ),

                    ),
                  ),
                ),
                SizedBox(height: height * 0.015),
                widget.role == 'supervisor' ? SizedBox.shrink() : Center(
                  child: SizedBox(
                    width: width * 0.9,
                    child: TextFormField(
                      controller: _dateOfBirth,
                      decoration: InputDecoration(
                        labelText: 'Select Birth Date',
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.calendar_today),
                          onPressed: () => _selectDate(context),
                        ),
                      ),
                      readOnly: true,
                    ),
                  ),
                ),
                SizedBox(height: height * 0.015),
                widget.role == 'supervisor' ? SizedBox.shrink() : Center(
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
                          child: Text(value, style: TextStyle(fontWeight: FontWeight.w400),),
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
                widget.role == 'supervisor' ? SizedBox.shrink() : Center(
                  child: SizedBox(
                    width: width * 0.9,
                    child: TextFormField(
                      controller: _height,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Height (in cm)',
                      ),
                    ),
                  ),
                ),
                SizedBox(height: height * 0.015),
                widget.role == 'supervisor' ? SizedBox.shrink() : Center(
                  child: SizedBox(
                    width: width * 0.9,
                    child: TextFormField(
                      controller: _weight,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Weight (in Kg)',
                      ),
                    ),
                  ),
                ),
                SizedBox(height: height * 0.015),
                SizedBox(
                  height: height * 0.015,
                ),
                SizedBox(
                  height: 50,
                  child: InkWell(
                    onTap: () {
                      if (widget.role=='supervisor')
                      {
                        _selectedGender = "Male";
                        _dateOfBirth.text = '2024-01-01';
                        _height.text = "0.0";
                        _weight.text = "0.0";
                      }
                      else if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(_emailId.text))
                        {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please enter valid email id")));
                        }
                      else if (!RegExp(r'^(19|20)\d{2}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])$').hasMatch(_dateOfBirth.text))
                      {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please enter valid date of birth")));
                      }
                      else if (_height.text.isNotEmpty && _weight.text.isNotEmpty)
                      {
                        try
                        {
                          double val = double.parse(_height.text);
                          if (val<100.0 || val>250.0)
                            {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please enter a valid height")));
                            }
                        }
                        catch(Exception){
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please enter a valid height")));
                        }
                        try
                        {
                          double val1 = double.parse(_weight.text);
                        }
                        catch(Exception){
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please enter a valid weight")));
                        }
                      }
                      if (_username.text != "" && _emailId.text != "" &&
                          _phone_number.text != "" && _dateOfBirth.text != "" &&
                          _height.text != "" && _weight.text != "" && _selectedGender!="" )
                        {
                          signUpWithCredentials();
                        }
                      else
                        {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please enter all fields")));
                        }
                    },
                    child : Container(
                      width: width * 0.9,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                          color: Color.fromRGBO(0, 83, 188, 1),
                          borderRadius: BorderRadius.circular(30)
                      ),
                      child: Text(
                        "Continue",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: width * 0.05),
                      ),
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
      ),
    );
  }
}

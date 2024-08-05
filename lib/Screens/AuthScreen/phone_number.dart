import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:smartband/Screens/AuthScreen/otp_verify.dart';

class PhoneSignIn extends StatefulWidget {
  @override
  _PhoneSignInState createState() => _PhoneSignInState();
}

class _PhoneSignInState extends State<PhoneSignIn> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _phoneController = TextEditingController();

  String country_code = "";

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

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Stack(
            children:
            [
              Container(
                height : height / 2,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(30.0),
                      bottomLeft: Radius.circular(30.0)
                  ),
                  color: Colors.blueAccent.withOpacity(0.2)
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    SizedBox(
                      height: height * 0.1,
                    ),
                    Text(
                      'Login',
                      style: TextStyle(fontSize: width * 0.07, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16,),
                    Image.asset(
                      "assets/phone.png",
                      width: width * 0.4,
                    ),
                    Card(
                      color: Colors.white,
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Column(
                          children: [
                            IntlPhoneField(
                              controller: _phoneController,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(30))
                                ),
                                hintText: "Enter your Phone Number",
                                suffixIcon: RegExp(r'^(?!([0-9])\1{9,})(\+?\d{1,4}[\s-]?)?(\(?\d{3}\)?[\s-]?)?[\d\s-]{7,10}$').hasMatch(_phoneController.text) ? Icon(Icons.check, color: Colors.green,) : Icon(Icons.close, color: Colors.red,)
                              ),
                              initialCountryCode: 'LK',
                              onChanged: (phone) {
                                print(phone.completeNumber);
                                setState(() {
                                  country_code = phone.countryCode;
                                });
                              },
                            ),
                            SizedBox(
                              height: height * 0.01,
                            ),
                            Text(
                              'Enter your phone number to continue. We will send an OTP for verification.',
                              style: TextStyle(fontSize: width * 0.04,),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(
                              height: height * 0.05,
                            ),
                            Center(
                                child: Container(
                                  width: width * 0.9,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: Color.fromRGBO(0, 83, 188, 1),
                                  ),
                                  child: TextButton(
                                    onPressed: ()
                                    {
                                      if (_phoneController.text.isNotEmpty)
                                      {
                                        Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (context) =>  OtpVerificationScreen(phoneNumber: '${country_code}${_phoneController.text}',)));
                                      }
                                    },
                                    child: Text(
                                      'Continue',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: width * 0.05
                                      ),
                                    ),
                                  ),
                                )
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ]
          ),
        ),
      ),
    );
  }
}
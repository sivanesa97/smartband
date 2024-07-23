import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:smartband/Screens/AuthScreen/otp_verify.dart';

class PhoneSignIn extends StatefulWidget {
  @override
  _PhoneSignInState createState() => _PhoneSignInState();
}

class _PhoneSignInState extends State<PhoneSignIn> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  String _verificationId = '';
  bool _codeSent = false;

  Future<void> _verifyPhoneNumber() async {
    await _auth.verifyPhoneNumber(
      phoneNumber: "+${country_code}"+_phoneController.text,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        print(
            'Phone number automatically verified and user signed in: ${_auth.currentUser!.uid}');
      },
      verificationFailed: (FirebaseAuthException e) {
        print('Phone number verification failed: ${e.message}');
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _codeSent = true;
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> _signInWithPhoneNumber() async {
    final PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: _verificationId,
      smsCode: _codeController.text,
    );

    await _auth.signInWithCredential(credential);
    print('Successfully signed in UID: ${_auth.currentUser!.uid}');
  }
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShaderMask(
                shaderCallback: (bounds) {
                  return gradient.createShader(
                    Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                  );
                },
                child: Text(
                  "LIFELONGCARE",
                  style: style.copyWith(color: Colors.white),
                ),
              ),
              SizedBox(height: height * 0.05,),
              Text(
                'Verify Your Phone Number',
                style: TextStyle(fontSize: width * 0.06, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: height * 0.07,),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Phone Number',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              SizedBox(height: 16),
              IntlPhoneField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(
                    borderSide: BorderSide()
                  ),
                ),
                initialCountryCode: 'IN', // Default country code
                onChanged: (phone) {
                  print(phone.completeNumber);
                  setState(() {
                    country_code = phone.countryCode;
                  });
                },
              ),
              SizedBox(
                height: height * 0.1,
              ),
              Center(
                  child: Container(
                    width: width * 0.5,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: LinearGradient(
                          colors: <Color>[
                            Colors.redAccent,
                            Colors.orangeAccent.withOpacity(0.9),
                            Colors.redAccent,
                          ],
                        )
                    ),
                    child: TextButton(
                      onPressed: ()
                      {
                        Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (context) =>  OtpVerificationScreen(phoneNumber: '${country_code}${_phoneController.text}',)));
                      },
                      child: Text(
                        'Get OTP Code',
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
      ),
    );
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:smartband/Screens/AuthScreen/forgot_password.dart';
import 'package:smartband/Screens/AuthScreen/signup.dart';
import 'package:smartband/Screens/HomeScreen/homepage.dart';
import 'package:smartband/Screens/Widgets/appBar.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();

  Future<void> signInWithCredentials() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Signing In... Please wait")));
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _username.text,
        password: _password.text,
      );
      User? user = await FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'fcmKey' : await FirebaseMessaging.instance.getToken()
      });
      final data = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      bool hasDeviceId = data.data()!['device_id']=="" ? false : true;
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(maintainState: true, builder: (context) => HomepageScreen(hasDeviceId: hasDeviceId,)),
      );
      print("Login Successful");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Login Successful")));
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Wrong password provided for that user.';
      } else {
        errorMessage = 'Error: ${e.message}';
      }
      _showErrorDialog(errorMessage);
    } catch (e) {
      print(e);
      _showErrorDialog('An unexpected error occurred.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Authentication Error'),
        content: Text(message),
        actions: <Widget>[
          ElevatedButton(
            child: const Text('Ok'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<GeoPoint> getLocation() async {
    Position location = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    return GeoPoint(location.latitude, location.longitude);
  }

  Future<UserCredential?> signinWithGoogle(BuildContext context) async {
    try {
      await GoogleSignIn().disconnect();
      await GoogleSignIn().signOut();
    } catch (error) {
      print('Error signing out: $error');
    }

    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    if (googleUser == null) {
      print('Google sign-in aborted');
      return null;
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential data = await FirebaseAuth.instance.signInWithCredential(credential);
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      final docRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        await docRef.set({
          'name': currentUser.displayName,
          'dob': "",
          'height': 0,
          'weight': 0,
          'phone_number': 0,
          'email': currentUser.email,
          'relations': [],
          'location': await getLocation(),
          'metrics': {'heart_rate': 0, 'steps': 0, 'fall_axis': 0},
          'role': 'watch wearer',
          "emergency": {
            "name": "",
            "blood_group": "",
            "medical_notes": "",
            "address": "",
            "medications": "",
            "organ_donor": false,
            "contact": 0,
          },
          'gender': '',
          'steps_goal': 0,
          'isSOSCLicked': false,
          'device_id': "",
          'fcmKey' : await FirebaseMessaging.instance.getToken()
        });
        print('User document created successfully');
        Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          maintainState: true,
          builder: (context) => HomepageScreen(hasDeviceId: false,),
        ),
      );
      } else {
        FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
          'fcmKey' : await FirebaseMessaging.instance.getToken()
        });
        print('User document already exists');
        final data = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
        bool hasDeviceId = data.data()!['device_id']=="" ? false : true;
        Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          maintainState: true,
          builder: (context) => HomepageScreen(hasDeviceId: hasDeviceId,),
        ),
      );
      }
    }
    return data;
  }

  void _validateUsername(String value) {
    setState(() {
      _isValid = value.isNotEmpty && value.length >= 3 && RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value);
    });
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  bool _isValid = false;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: const AppBarWidget(),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Login",
                  style: TextStyle(
                    fontSize: 35,
                  ),
                ),
                SizedBox(
                  height: height * 0.1,
                ),
                Center(
                  child: SizedBox(
                    width: width * 0.9,
                    child: TextFormField(
                      controller: _username,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: 'Email',
                        suffixIcon: _isValid ? const Icon(Icons.check, color: Colors.green) : null,
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
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Password',
                      ),
                    ),
                  ),
                ),
                SizedBox(height: height * 0.02),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.of(context, rootNavigator: true)
                            .push(MaterialPageRoute(
                          maintainState: true,
                          builder: (context) => SignupScreen(phNo: "",role: "",),
                        ));
                      },
                      child: const Text(
                        "Sign Up",
                      ),
                    ),
                    InkWell(
                        onTap: () {
                          Navigator.of(context, rootNavigator: true)
                              .push(MaterialPageRoute(
                            maintainState: true,
                            builder: (context) => const ForgotPassword(),
                          ));
                        },
                        child: const Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                  text: "Forgot your Password?",
                                  style: TextStyle(fontSize: 14)
                              ),
                              WidgetSpan(
                                child: Icon(Icons.arrow_right_alt,size: 16, weight: 700, color: Colors.redAccent,),
                              ),
                            ],
                          ),
                        )
                    )
                  ],
                ),
                SizedBox(height: height * 0.03),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      signInWithCredentials();
                    },
                    style: ElevatedButton.styleFrom(
                        minimumSize: Size(width * 0.9, 50),
                        backgroundColor: Colors.black26,
                        foregroundColor: Colors.white),
                    child: const Text(
                      "LOGIN",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                SizedBox(
                  height: height * 0.25,
                ),
                const Center(
                  child: Text(
                      "Or Login with Social Account"
                  ),
                ),
                SizedBox(
                  height: height * 0.02,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                        onTap: () {
                          signinWithGoogle(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: const [BoxShadow(
                                color: Colors.grey,
                                blurRadius: 5.0,
                              ),],
                              borderRadius: BorderRadius.circular(20.0)
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 30.0),
                            child: Icon(
                              Icons.g_mobiledata,
                              size: 40,
                              color: Colors.black45,
                            ),
                          ),
                        )
                    ),
                    SizedBox(width: width*0.05,),
                    InkWell(
                        onTap: () {
                          signinWithGoogle(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: const [BoxShadow(
                                color: Colors.grey,
                                blurRadius: 5.0,
                              ),],
                              borderRadius: BorderRadius.circular(20.0)
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 30.0),
                            child: Icon(
                              Icons.facebook_outlined,
                              size: 40,
                              color: Colors.black45,
                            ),
                          ),
                        )
                    ),
                  ],
                )
              ],
            ),
          ),
        )
    );
  }
}

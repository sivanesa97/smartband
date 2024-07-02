import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../Widgets/appBar.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _username = TextEditingController();
  final TextEditingController _emailId = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _dateofBirth = TextEditingController();
  final TextEditingController _height = TextEditingController();
  final TextEditingController _weight = TextEditingController();

  bool _isValid = false;
  String? _selectedGender;

  void _validateUsername(String value) {
    setState(() {
      _isValid = value.isNotEmpty && value.length >= 3 && RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value);
    });
  }

  @override
  void dispose()
  {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> signUpWithCredentials() async
  {
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailId.text,
        password: _password.text,
      );
      await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).set({
        'name': _username.text,
        'dob': _dateofBirth.text,
        'height': double.parse(_height.text),
        'weight': double.parse(_weight.text),
        'email': _emailId.text,
        'relations': []
      });

      print("User created");
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
      }
    } catch (e) {
      print(e);
    }
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
                      controller: _emailId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Email',
                      ),
                    ),
                  ),
                ),
                SizedBox(height: height * 0.015,),
                Center(
                  child: SizedBox(
                    width: width * 0.9,
                    child: TextFormField(
                      controller: _password,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Password',
                      ),
                    ),
                  ),
                ),
                SizedBox(height: height * 0.015),
                Center(
                  child: SizedBox(
                    width: width * 0.9,
                    child: TextFormField(
                      controller: _dateofBirth,
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
                SizedBox(height: height * 0.015,),
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
                    onTap: () {},
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
                SizedBox(height: height * 0.015,),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      signUpWithCredentials();
                      Navigator.of(context, rootNavigator: true)
                          .pop();
                    },
                    style: ElevatedButton.styleFrom(
                        minimumSize: Size(width * 0.9, 50),
                        backgroundColor: Colors.black26,
                        foregroundColor: Colors.white),
                    child: const Text(
                      "SIGN UP",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
    );
  }
}

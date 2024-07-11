import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smartband/Screens/Widgets/appBar.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  bool _isValid = false, _active = false;
  @override
  Widget build(BuildContext context) {
    Future<void> resetPassword(String email, String newPassword) async {
      FirebaseAuth auth = FirebaseAuth.instance;
      try {
        await auth.confirmPasswordReset(
          code: email,
          newPassword: newPassword,
        );
      } catch (e) {
        print("Failed to reset password: $e");
      }
    }

    void _validateUsername(String value) {
      setState(() {
        // Example validation: username should be at least 3 characters long and alphanumeric
        _isValid = value.isNotEmpty && value.length >= 3 && RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value);
      });
    }

    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: const AppBarWidget(),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Forgot Password",
              style: TextStyle(
                fontSize: 36
              ),
            ),
            SizedBox(height: height * 0.1,),
            const Text(
              "Please, enter your email address. You will receive a link to create a new password via email."
            ),
            SizedBox(
              height: height * 0.015,
            ),
            Center(
              child: SizedBox(
                width: width * 0.9,
                child: TextFormField(
                  // controller: _password,
                  decoration:  InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: 'Email',
                    suffixIcon: _isValid ? const Icon(Icons.check, color: Colors.green) : null,
                  ),
                  onChanged: _validateUsername,
                ),
              ),
            ),
            _active == true ? SizedBox(height: height * 0.05) : const SizedBox.shrink(),
            _active == true ? Center(
              child: SizedBox(
                width: width * 0.9,
                child: TextFormField(
                  // controller: _password,
                  decoration:  InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: 'Email',
                    suffixIcon: _isValid ? const Icon(Icons.check, color: Colors.green) : null,
                  ),
                  onChanged: _validateUsername,
                ),
              ),
            ) : const SizedBox.shrink(),
            SizedBox(height: height * 0.05),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _active = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                    minimumSize: Size(width * 0.9, 50),
                    backgroundColor: Colors.black26,
                    foregroundColor: Colors.white),
                child: const Text(
                  "Next",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

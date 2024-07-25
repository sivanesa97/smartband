import 'package:flutter/material.dart';
import 'package:smartband/Screens/AuthScreen/phone_number.dart';
import 'package:smartband/Screens/AuthScreen/signin.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      "assets/logo.jpg",
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: 10,),
                    Text(
                        "Your Health Our Priority",
                      style: TextStyle(fontSize: width * 0.06),
                    ),
                    SizedBox(height: 10,),
                    Text(
                      "Welcome to Longlifecare..!",
                      style: TextStyle(fontSize: width * 0.06),
                    ),
                  ],
                )
              ),
              SizedBox(
                height: 50,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
                      maintainState: true,
                      builder: (context) =>
                          PhoneSignIn(),
                    ));
                  },
                  child: Container(
                    width: width * 0.9,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Colors.redAccent,
                        Colors.orangeAccent.withOpacity(0.9),
                        Colors.redAccent,
                      ]),
                      borderRadius: BorderRadius.circular(30)
                    ),
                    child: Text(
                        "Let's get started",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: width * 0.05),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

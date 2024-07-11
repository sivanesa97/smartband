import 'package:flutter/material.dart';
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
                flex: 9,
                child: Image.network(
                  "https://placements.lk/storage/Company/LogoImages/1637824455.jpg",
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
                      maintainState: true,
                      builder: (context) =>
                          const SignIn(),
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(width * 0.9, 50),
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white
                  ),
                  child: const Text("Let's Get Started"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

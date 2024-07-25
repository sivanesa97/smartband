import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smartband/Screens/AuthScreen/signup.dart';
import 'package:smartband/Screens/Dashboard/supervisor_dashboard.dart';
import 'package:smartband/Screens/DrawerScreens/aboutus.dart';
import 'package:smartband/Screens/HomeScreen/homepage.dart';

class HomePage extends StatefulWidget {
  String phNo;
  HomePage({super.key, required this.phNo});
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  late List<Widget> _children;

  @override
  void initState() {
    super.initState();
    _children = [
      MainScreen(phNo: widget.phNo),
      Aboutus(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.white,
      body: _children[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: 'Info',
          ),
        ],
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.orange,
        showUnselectedLabels: false,
      ),
    );
  }
}

class MainScreen extends StatelessWidget {
  String phNo;
  MainScreen({super.key, required this.phNo});

  Future<GeoPoint> getLocation() async {
    Position location = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    return GeoPoint(location.latitude, location.longitude);
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'LONGLIFECARE',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: height * 0.07),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                children: [
                  Text(
                    'Welcome to Longlifecare!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Our app ensures the safety and well-being of your elderly loved ones. Together, let\'s create a safer future.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: height * 0.07),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => SignupScreen(phNo: phNo, role: "watch wearer",)));
              },
              child: Container(
                width: width * 0.9,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(width: 1, color: Colors.blueGrey),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.watch, color: Colors.white, size: width * 0.15),
                    SizedBox(width: width * 0.1),
                    Text(
                      'Device Owner',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: width * 0.055,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: height * 0.07),
            GestureDetector(
              onTap: () async {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => SignupScreen(phNo: phNo, role: "supervisor",)));
              },
              child: Container(
                width: width * 0.9,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(width: 1, color: Colors.blueGrey),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.account_circle_outlined, color: Colors.white, size: width * 0.15),
                    SizedBox(width: width * 0.1),
                    Text(
                      'Monitoring Person',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: width * 0.055,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

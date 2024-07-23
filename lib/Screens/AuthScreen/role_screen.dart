import 'package:flutter/material.dart';
import 'package:smartband/Screens/AuthScreen/signup.dart';
import 'package:smartband/Screens/Dashboard/supervisor_dashboard.dart';
import 'package:smartband/Screens/DrawerScreens/aboutus.dart';
import 'package:smartband/Screens/HomeScreen/homepage.dart';

class SmartTrackersApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _children = [
    MainScreen(),
    Aboutus(),
  ];

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.white,
      body: _children[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        items: [
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
      ),
    );
  }
}

class MainScreen extends StatelessWidget {
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
              'SMART TRACKERS',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: height * 0.07),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                children: [
                  Text(
                    'Welcome to Smart Tracker!',
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
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => HomepageScreen(hasDeviceId: false)));
              },
              child: Container(
                width: width * 0.9,
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(width: 1, color: Colors.blueGrey)
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.watch, color: Colors.white, size: width * 0.15,),
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
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => SupervisorDashboard()));
              },
              child: Container(
                width: width * 0.9,
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(width: 1, color: Colors.blueGrey)
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.account_circle_outlined, color: Colors.white, size: width * 0.15,),
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
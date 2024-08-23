import 'package:flutter/material.dart';
import 'package:smartband/Screens/Dashboard/supervisor_dashboard.dart';
import 'package:smartband/Screens/HomeScreen/homepage.dart';

class RoleSelectionScreen extends StatelessWidget {
  final String role;
  final String phNo;

  RoleSelectionScreen({required this.role, required this.phNo});

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final person = role == 'supervisor' ? 'Monitoring Person' : 'Device Owner';

    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              role == 'supervisor'
                  ? 'assets/image231.png'
                  : 'assets/image230.png',
              fit: BoxFit.cover,
            ),
          ),
          // Content on top of the background image
          Positioned(
            top: screenHeight * 0.03,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                person,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            top: screenHeight * 0.4, // Adjust position as needed
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: screenWidth * 0.3,
                ),
                SizedBox(height: 10),
                Text(
                  'Logged in successfully\nas a $person',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                SizedBox(height: screenHeight * 0.3),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to the next screen
                    if (role == 'supervisor') {
                      Navigator.of(context, rootNavigator: true)
                          .pushReplacement(MaterialPageRoute(
                              maintainState: true,
                              builder: (context) => SupervisorDashboard(
                                    phNo: phNo,
                                  )));
                    } else {
                      Navigator.of(context, rootNavigator: true)
                          .pushReplacement(MaterialPageRoute(
                              maintainState: true,
                              builder: (context) => const HomepageScreen(
                                    hasDeviceId: true,
                                  )));
                    }
                  },
                  child: Text(
                    'Continue',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(
                        horizontal: screenHeight * 0.15,
                        vertical: screenWidth * 0.03),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

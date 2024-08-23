import 'package:flutter/material.dart';
import 'package:smartband/Screens/AuthScreen/signup.dart';
import 'package:smartband/Screens/Dashboard/supervisor_dashboard.dart';
import 'package:smartband/Screens/HomeScreen/homepage.dart';

class RoleSelectionScreen extends StatefulWidget {
  final String role;
  final String phNo;
  final String deviceId;
  final String status;
  final int subscribe;

  RoleSelectionScreen({
    required this.role,
    required this.phNo,
    required this.deviceId,
    required this.status,
    required this.subscribe,
  });

  @override
  _RoleSelectionScreenState createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  @override
  void initState() {
    super.initState();

    // Show alert automatically if subscription status is 1
    if (widget.subscribe == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              contentPadding: EdgeInsets.zero,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Close button at the top-right
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  // Title text on the next line
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Make Sure Your Subscription',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Content text
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Take the first step towards a healthier and happier life',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  SizedBox(height: 16),
                ],
              ),
              // actions: [
              //   TextButton(
              //     onPressed: () {
              //       Navigator.of(context).pop();
              //     },
              //     child: Text('OK'),
              //   ),
              // ],
            );
          },
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final person =
        widget.role == 'supervisor' ? 'Monitoring Person' : 'Device Owner';

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              widget.role == 'supervisor'
                  ? 'assets/image231.png'
                  : 'assets/image230.png',
              fit: BoxFit.cover,
            ),
          ),
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
            top: screenHeight * 0.4,
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
                    if (widget.status == '1') {
                      if (widget.role == 'supervisor') {
                        Navigator.of(context, rootNavigator: true)
                            .pushReplacement(MaterialPageRoute(
                                maintainState: true,
                                builder: (context) => SupervisorDashboard(
                                      phNo: widget.phNo,
                                    )));
                      } else {
                        Navigator.of(context, rootNavigator: true)
                            .pushReplacement(MaterialPageRoute(
                                maintainState: true,
                                builder: (context) => const HomepageScreen(
                                      hasDeviceId: true,
                                    )));
                      }
                    } else {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => SignupScreen(
                                phNo: widget.phNo,
                                role: widget.role,
                                deviceId: widget.deviceId,
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

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
  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.white,
      body: MainScreen(phNo: widget.phNo,),
    );
  }
}

class MainScreen extends StatefulWidget {
  String phNo;
  MainScreen({super.key, required this.phNo});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  Future<GeoPoint> getLocation() async {
    Position location = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    return GeoPoint(location.latitude, location.longitude);
  }

  String selected_role = 'watch wearer';

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  "assets/logo.jpg",
                  height: 100,
                  width: 100,
                ),
                Text(
                  'LONGLIFECARE',
                  style: TextStyle(
                    fontSize: width * 0.04,
                  ),
                ),
                SizedBox(height: height * 0.05),
                Text(
                  'Select one to continue',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: width * 0.05,
                    fontWeight: FontWeight.bold
                  ),
                ),
                SizedBox(height: height * 0.07),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          selected_role = 'watch wearer';
                        });
                      },
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15.0),
                            child: Image.network(
                              "https://img.freepik.com/free-photo/close-up-senior-person-while-learning_23-2149072430.jpg?w=360&t=st=1722356681~exp=1722357281~hmac=394f6420821dd3d25555d49bd8f4931f3907a92092a88075987a74c3a9f90235",
                              width: width * 0.42,
                              height: height * 0.3,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(height: height * 0.02),
                          Text(
                            'Device Owner',
                            style: TextStyle(
                              color: selected_role=='watch wearer' ? Color.fromRGBO(0, 83, 188, 1) : Colors.black,
                              fontSize: width * 0.045,
                            ),
                          ),
                          SizedBox(height: height * 0.02),
                          if (selected_role=='watch wearer')
                            Container(
                              padding: EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.lightGreen
                              ),
                              child: Icon(
                                  Icons.check,
                                  color: Colors.white,
                              ),
                            )
                          else
                            Container(
                              padding: EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white
                              ),
                              child: Icon(
                                Icons.check,
                                color: Colors.white,
                              ),
                            )
                        ],
                      ),
                    ),
                    SizedBox(width: width * 0.05),
                    GestureDetector(
                      onTap: () async {
                        setState(() {
                          selected_role = "supervisor";
                        });
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15.0),
                            child: Image.network(
                              "https://img.freepik.com/premium-photo/front-view-people-studying-classroom_23-2150312847.jpg?w=996",
                              fit: BoxFit.cover,
                              height: height * 0.3,
                              width: width * 0.42,
                            ),
                          ),
                          SizedBox(height: height * 0.02),
                          Text(
                            'Monitoring Person',
                            style: TextStyle(
                              color: selected_role=="supervisor" ? Color.fromRGBO(0, 83, 188, 1) : Colors.black,
                              fontSize: width * 0.045,
                            ),
                          ),
                          SizedBox(height: height * 0.02,),
                          if (selected_role=='supervisor')
                            Container(
                              padding: EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.lightGreen
                              ),
                              child: Icon(
                                  Icons.check,
                                  color: Colors.white,
                              ),
                            )
                          else
                            Container(
                              padding: EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white
                              ),
                              child: Icon(
                                  Icons.check,
                                color: Colors.white,
                              ),
                            )
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: height * 0.15,),
                Center(
                    child: Container(
                      width: width * 0.9,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Color.fromRGBO(0, 83, 188, 1),
                      ),
                      child: TextButton(
                        onPressed: ()
                        {
                          Navigator.of(context).push(MaterialPageRoute(builder: (context) => SignupScreen(phNo: widget.phNo, role: selected_role,)));
                        },
                        child: Text(
                          'Continue',
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
      ),
    );
  }
}

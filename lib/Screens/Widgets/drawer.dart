import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:smartband/Screens/DrawerScreens/aboutus.dart';
import 'package:smartband/Screens/DrawerScreens/emergencycard.dart';
import 'package:smartband/Screens/DrawerScreens/helpandsupport.dart';
import 'package:smartband/Screens/DrawerScreens/profilepage.dart';
import 'package:smartband/Screens/DrawerScreens/reportproblem.dart';
import 'package:smartband/Screens/HomeScreen/upgrade.dart';
import 'package:smartband/Screens/SplashScreen/splash.dart';

import '../AuthScreen/signin.dart';
import '../HomeScreen/settings.dart';

class DrawerScreen extends StatefulWidget {
  BluetoothDevice device;
  DrawerScreen({super.key, required this.device});

  @override
  State<DrawerScreen> createState() => _DrawerScreenState();
}

class _DrawerScreenState extends State<DrawerScreen> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Drawer(
        backgroundColor: Colors.white,
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  SizedBox(height: 8,),
                  Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.device.platformName,
                              style: TextStyle(
                                fontSize: width * 0.05,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              widget.device.remoteId.toString(),
                              style: TextStyle(
                                fontSize: width * 0.04,
                              ),
                            ),
                            SizedBox(height: 8),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  print("Disconnect : ${bluetoothDeviceManager.connectedDevices}");
                                  bluetoothDeviceManager.disconnectFromDevice();
                                  // bluetoothDeviceManager.connectedDevices = [];
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10.0, vertical: 5.0),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10.0),
                                  gradient: LinearGradient(colors: [
                                    Colors.redAccent,
                                    Colors.orangeAccent.withOpacity(0.9),
                                    Colors.redAccent,
                                  ]),),
                                child: Text('Remove', style: TextStyle(fontSize: width * 0.04, color: Colors.white),),
                              ),
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Image.asset(
                            "assets/watch.png",
                            width: width * 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                              maintainState: true,
                              builder: (context) => const Upgradescreen()));
                    },
                    child: const ListTile(
                      leading: Icon(
                        Icons.upgrade,
                        color: Colors.black26,
                      ),
                      title: Text("Alarms"),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                              maintainState: true,
                              builder: (context) => const Profilepage()));
                    },
                    child: const ListTile(
                      leading: Icon(
                        Icons.info_outline,
                        color: Colors.black26,
                      ),
                      title: Text("Profile"),
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                              maintainState: true,
                              builder: (context) => const Upgradescreen()));
                    },
                    child: const ListTile(
                      leading: Icon(
                        Icons.upgrade,
                        color: Colors.black26,
                      ),
                      title: Text("Upgrade"),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                              maintainState: true,
                              builder: (context) => const Aboutus()));
                    },
                    child: const ListTile(
                      leading: Icon(
                        Icons.info_outline,
                        color: Colors.black26,
                      ),
                      title: Text("About Us"),
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      Navigator.of(context, rootNavigator: true)
                          .pushAndRemoveUntil(MaterialPageRoute(
                              builder: (context) => const SplashScreen()), (Route<dynamic> route) => false);
                      final GoogleSignIn googleSignIn = GoogleSignIn();
                      await googleSignIn.signOut();
                      await FirebaseAuth.instance.signOut();
                    },
                    child: const ListTile(
                      leading: Icon(
                        Icons.logout,
                        color: Colors.black26,
                      ),
                      title: Text("Sign Out"),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                              maintainState: true,
                              builder: (context) => const Reportproblem()));
                    },
                    child: const ListTile(
                      leading: Icon(
                        Icons.warning,
                        color: Colors.black54,
                      ),
                      title: Text("Report an issue"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ));
  }
}

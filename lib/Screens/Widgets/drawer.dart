import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:smartband/Screens/AuthScreen/phone_number.dart';
import 'package:smartband/Screens/DrawerScreens/aboutus.dart';
import 'package:smartband/Screens/DrawerScreens/emergencycard.dart';
import 'package:smartband/Screens/DrawerScreens/helpandsupport.dart';
import 'package:smartband/Screens/DrawerScreens/profilepage.dart';
import 'package:smartband/Screens/DrawerScreens/reportproblem.dart';
import 'package:smartband/Screens/HomeScreen/manage_access.dart';
import 'package:smartband/Screens/HomeScreen/upgrade.dart';
import 'package:smartband/Screens/Widgets/coming_soon.dart';

import '../AuthScreen/signin.dart';
import '../HomeScreen/settings.dart';

class DrawerScreen extends StatefulWidget {
  BluetoothDevice? device;
  String phNo;
  DrawerScreen({super.key, required this.device, required this.phNo});

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
                  Padding(
                      padding:EdgeInsets.symmetric(horizontal: 10),
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: const ListTile(
                          leading: Icon(
                            Icons.arrow_back,
                            color: Colors.black26,
                          ),
                        ),
                      ),
                  ),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.0),
                      child: Container(
                      decoration: BoxDecoration(
                          color: Color.fromRGBO(0, 83, 188, 1),
                          borderRadius: BorderRadius.circular(15.0)
                      ),
                      child: widget.device!=null ?  Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.device!.platformName,
                                style: TextStyle(
                                  fontSize: width * 0.05,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                widget.device!.remoteId.toString(),
                                style: TextStyle(
                                  fontSize: width * 0.04,
                                  color: Colors.white
                                ),
                              ),
                              SizedBox(height: 8),
                            ],
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: Image.asset(
                              "assets/watch.png",
                              width: width * 0.3,
                              height: height * 0.2,
                              fit: BoxFit.fitWidth,
                            ),
                          ),
                        ],
                      ) : Text(
                        "You have not connected a device",
                        maxLines: 2,
                        style: TextStyle(
                            fontSize: width * 0.05,
                            fontWeight: FontWeight.bold,
                            color: Colors.white
                        ),
                      ),
                    ),
                  ),
                  widget.device!=null ?  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          print("Disconnect : ${bluetoothDeviceManager.connectedDevices}");
                          bluetoothDeviceManager.disconnectFromDevice();
                          bluetoothDeviceManager.connectedDevices = [];
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10.0),
                        width: width * 0.4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15.0),
                          color: Colors.white,
                          border: Border.all(color: Color.fromRGBO(0, 83, 188, 1), width: 3)
                        ),
                        child: Text(
                            "Remove",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color.fromRGBO(0, 83, 188, 1),
                            ),
                        ),
                      )
                    ),
                  ) : SizedBox.shrink(),
                  InkWell(
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                              maintainState: true,
                              builder: (context) => const ComingSoon()));
                    },
                    child: const ListTile(
                      leading: Icon(
                        Icons.alarm,
                        color: Colors.black26,
                      ),
                      title: Text("Alarm"),
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
                  InkWell(
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                              maintainState: true,
                              builder: (context) => ManageAccess(phNo: widget.phNo,)));
                    },
                    child: const ListTile(
                      leading: Icon(
                        Icons.supervisor_account,
                        color: Colors.black26,
                      ),
                      title: Text("Manage Access"),
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
                      title: Text("Upgrade"),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                              maintainState: true,
                              builder: (context) => Aboutus(phNo: widget.phNo,)));
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
                              builder: (context) => PhoneSignIn()), (Route<dynamic> route) => false);
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
                              builder: (context) => Reportproblem(phNo: widget.phNo,)));
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

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:smartband/Screens/AuthScreen/phone_number.dart';
import 'package:smartband/Screens/DrawerScreens/aboutus.dart';

import 'package:smartband/Screens/DrawerScreens/profilepage.dart';
import 'package:smartband/Screens/DrawerScreens/reportproblem.dart';

class DrawerSupervisorScreen extends StatefulWidget {
  BluetoothDevice? device;
  String phNo;
  DrawerSupervisorScreen({super.key, required this.device, required this.phNo});

  @override
  State<DrawerSupervisorScreen> createState() => _DrawerSupervisorScreenState();
}

class _DrawerSupervisorScreenState extends State<DrawerSupervisorScreen> {
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
                  // InkWell(
                  //   onTap: () {
                  //     Navigator.of(context, rootNavigator: true).push(
                  //         MaterialPageRoute(
                  //             maintainState: true,
                  //             builder: (context) => ManageAccess(phNo: widget.phNo,)));
                  //   },
                  //   child: const ListTile(
                  //     leading: Icon(
                  //       Icons.supervisor_account,
                  //       color: Colors.black26,
                  //     ),
                  //     title: Text("Manage Access"),
                  //   ),
                  // ),
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

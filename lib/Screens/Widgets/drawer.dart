import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:smartband/Screens/DrawerScreens/aboutus.dart';
import 'package:smartband/Screens/DrawerScreens/emergencycard.dart';
import 'package:smartband/Screens/DrawerScreens/helpandsupport.dart';
import 'package:smartband/Screens/DrawerScreens/reportproblem.dart';

import '../AuthScreen/signin.dart';

class DrawerScreen extends StatefulWidget {
  const DrawerScreen({super.key});

  @override
  State<DrawerScreen> createState() => _DrawerScreenState();
}

class _DrawerScreenState extends State<DrawerScreen> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Drawer(
        width: width * 0.65,
        backgroundColor: Colors.white,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 30.0),
                child: Image.network(
                  "https://placements.lk/storage/Company/LogoImages/1637824455.jpg",
                  width: 75,
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
                    Icons.info,
                    color: Colors.black26,
                  ),
                  title: Text("About Us"),
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(
                          maintainState: true,
                          builder: (context) => const Emergencycard()));
                },
                child: const ListTile(
                  leading: Icon(
                    Icons.assignment,
                    color: Colors.black26,
                  ),
                  title: Text("Emergency Card"),
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(
                          maintainState: true,
                          builder: (context) => const Helpandsupport()));
                },
                child: const ListTile(
                  leading: Icon(
                    Icons.help,
                    color: Colors.black26,
                  ),
                  title: Text("Help and support"),
                ),
              ),

              SizedBox(
                height: height * 0.4,
              ),
              InkWell(
                onTap: () async {
                  Navigator.of(context, rootNavigator: true).pushReplacement(
                    MaterialPageRoute(builder: (context) => const SignIn()),
                  );
                  final GoogleSignIn googleSignIn = GoogleSignIn();
                  await googleSignIn.signOut();
                  await FirebaseAuth.instance.signOut();
                },
                child: const ListTile(
                  leading: Icon(
                    Icons.help,
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
                    Icons.help,
                    color: Colors.black26,
                  ),
                  title: Text("Report an issue"),
                ),
              ),
            ],
          ),
        ));
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:smartband/Screens/AuthScreen/signin.dart';

class AppBarProfileWidget extends StatefulWidget implements PreferredSizeWidget {
  const AppBarProfileWidget({super.key});

  @override
  State<AppBarProfileWidget> createState() => _AppBarProfileWidgetState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _AppBarProfileWidgetState extends State<AppBarProfileWidget> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return AppBar(
      surfaceTintColor: Colors.transparent,
      backgroundColor: Colors.white,
      leading: Padding(
        padding: const EdgeInsets.only(left: 0),
        child: GestureDetector(
          onTap: () {
            Scaffold.of(context).openDrawer();
          },
          child: const Icon(Icons.menu),
        ),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: EdgeInsets.only(left: width * 0.17),
            child: Image.network(
              "https://placements.lk/storage/Company/LogoImages/1637824455.jpg",
              width: 100,
            ),
          ),
          GestureDetector(
            onTap: () async {
              Navigator.of(context, rootNavigator: true).pushReplacement(
                MaterialPageRoute(builder: (context) => const SignIn()),
              );
              final GoogleSignIn googleSignIn = GoogleSignIn();
              await googleSignIn.signOut();
              await FirebaseAuth.instance.signOut();
            },
            child: const Padding(
              padding: EdgeInsets.all(10.0),
              child: const Icon(Icons.account_circle_outlined),
            ),
          ),
        ],
      ),
    );
  }
}
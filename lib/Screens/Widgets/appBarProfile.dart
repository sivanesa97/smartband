import 'package:flutter/material.dart';
import 'package:smartband/Screens/DrawerScreens/profilepage.dart';

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
      surfaceTintColor: Colors.white,
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
              Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (context) => const Profilepage()));
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
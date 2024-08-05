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
        padding: const EdgeInsets.only(left: 5),
        child: GestureDetector(
          onTap: () {
            Scaffold.of(context).openDrawer();
          },
          child: const Icon(Icons.menu, size: 30,),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: () async {
            Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (context) => const Profilepage()));
          },
          child: const Padding(
            padding: EdgeInsets.only(right: 10),
            child: const Icon(Icons.account_circle_outlined, size: 30,),
          ),
        ),
      ],
    );
  }
}
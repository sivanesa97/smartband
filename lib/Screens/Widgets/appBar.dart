import 'package:flutter/material.dart';

class AppBarWidget extends StatefulWidget implements PreferredSizeWidget{
  const AppBarWidget({super.key});

  @override
  State<AppBarWidget> createState() => _AppBarWidgetState();
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _AppBarWidgetState extends State<AppBarWidget> {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      surfaceTintColor: Colors.white,
      backgroundColor: Colors.white,
      leading: Padding(
        padding: const EdgeInsets.only(left: 0),
        child: GestureDetector(
          onTap: () async {
            Navigator.of(context, rootNavigator: true).pop();
          },
          child: const Icon(Icons.chevron_left),
        ),
      ),
      // title: Align(
      //   alignment: const Alignment(-0.25, 0),
      //   child: Image.asset(
      //     "assets/logo.jpg",
      //     height: 60,
      //   ),
      // )
    );
  }
}

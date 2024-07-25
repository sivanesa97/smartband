import 'package:flutter/material.dart';
import 'package:smartband/Screens/Widgets/appBar.dart';

class Readingscreen extends StatefulWidget {
  String title;
  String reading;
  Readingscreen({super.key, required this.title, required this.reading});

  @override
  State<Readingscreen> createState() => _ReadingscreenState();
}

class _ReadingscreenState extends State<Readingscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarWidget(),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Text(
              widget.title
            ),
            Text(
              widget.reading
            )
          ],
        ),
      ),
    );
  }
}

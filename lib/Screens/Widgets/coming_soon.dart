import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ComingSoon extends StatelessWidget {
  const ComingSoon({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            width: width,
            height: height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.construction,
                  color: Color.fromRGBO(0, 83, 188, 1),
                  size: width * 0.3,
                ),
                SizedBox(width: width * 0.05,),
                Text("Coming Soon", style: TextStyle(
                  fontSize: width * 0.07
                ),)
              ],
            ),
          )
        ),
      ),
    );
  }
}

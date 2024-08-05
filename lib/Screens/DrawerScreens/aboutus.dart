import 'package:flutter/material.dart';
import 'package:smartband/Screens/HomeScreen/settings.dart';
import 'package:smartband/Screens/Widgets/appBar.dart';
import 'package:smartband/Screens/Widgets/drawer.dart';

class Aboutus extends StatefulWidget {
  final String? phNo;
  Aboutus({super.key, required this.phNo});

  @override
  State<Aboutus> createState() => _AboutusState();
}

class _AboutusState extends State<Aboutus> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppBarWidget(),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Who are We?",
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600
                  ),
                ),
                SizedBox(height: 10,),
                Text(
                  "We, innovay is an IT consultant company focused on providing Consulting, Social Media Management, Mobile Apps, Google Apps, Cloud and Business Process Solution Development Services to USA, Australia, Europe and Asia. By using our enhanced global delivery models with innovative software platforms approach and industry expertise, we offer various web solutions. We have the expertise in Social Media Optimization, Google Apps and Mobile Apps development such as iPhone as well as Android HTML5 Native Mobile Apps.",
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w200,
                  ),
                ),
                SizedBox(height: 20,),
                Text(
                  "Vision",
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600
                  ),
                ),
                SizedBox(height: 10,),
                Text(
                  "Our drive is towards establishing innovay as the benchmark IT Solutions provider worldwide.",
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w200,
                  ),
                ),
                SizedBox(height: 20,),
                Text(
                  "Mission",
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600
                  ),
                ),
                SizedBox(height: 10,),
                Text(
                  "Our objective is to meet the customers need in an effective manner on time by adapting to the following policies: \nTo continuously train and educate latest technologies and trends to the entire Innovay team to produce innovative products and solutions. \nProvide cost effective solutions with quick turnaround time.\nPrepare the team to build and maintain long lasting customer relationship across the globe.\nContinuously launch creative and innovative products to meet market needs.",
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w200,
                  ),
                ),
                SizedBox(height: 10,),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

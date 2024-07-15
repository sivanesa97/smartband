import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:smartband/Screens/Widgets/appBar.dart';
import 'package:smartband/Screens/Widgets/appBarProfile.dart';

class Notificationscreen extends StatefulWidget {
  const Notificationscreen({super.key});

  @override
  State<Notificationscreen> createState() => _NotificationscreenState();
}

class _NotificationscreenState extends State<Notificationscreen> {
  bool isWaterTimeEnabled = true;
  bool isTabletTimeEnabled = false;
  bool isWalkingTimeEnabled = false;
  bool isExerciseTimeEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBarWidget(),
        body: Column(children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Notification', style: TextStyle(fontSize: 18)),
                  Icon(Icons.edit, color: Colors.black),
                ],
              ),
              decoration:
                  BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                    color: Colors.grey[300],
                  ),
            ),
          ),
          SwitchListTile(
            title: Text('Water Time'),
            secondary: Icon(FontAwesomeIcons.glassWater),
            value: isWaterTimeEnabled,
            onChanged: (bool value) {
              setState(() {
                isWaterTimeEnabled = value;
              });
            },
          ),
          SwitchListTile(
            title: Text('Tablet Time'),
            secondary: Icon(FontAwesomeIcons.pills),
            value: isTabletTimeEnabled,
            onChanged: (bool value) {
              setState(() {
                isTabletTimeEnabled = value;
              });
            },
          ),
          SwitchListTile(
            title: Text('Walking Time'),
            secondary: Icon(FontAwesomeIcons.personWalking),
            value: isWalkingTimeEnabled,
            onChanged: (bool value) {
              setState(() {
                isWalkingTimeEnabled = value;
              });
            },
          ),
          SwitchListTile(
            title: Text('Exercise Time'),
            secondary: Icon(FontAwesomeIcons.dumbbell),
            value: isExerciseTimeEnabled,
            onChanged: (bool value) {
              setState(() {
                isExerciseTimeEnabled = value;
              });
            },
          ),
        ]));
  }
}

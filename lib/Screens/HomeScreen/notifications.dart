import 'package:flutter/material.dart';
import 'package:smartband/Screens/Widgets/appBar.dart';

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
        appBar: const AppBarWidget(),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
              decoration:
                  BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                    color: Colors.grey[300],
                  ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Notification', style: TextStyle(fontSize: 18)),
                  Icon(Icons.edit, color: Colors.black),
                ],
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Water Time'),
            secondary: const Icon(Icons.water_drop_outlined),
            value: isWaterTimeEnabled,
            onChanged: (bool value) {
              setState(() {
                isWaterTimeEnabled = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Tablet Time'),
            secondary: const Icon(Icons.medication_outlined),
            value: isTabletTimeEnabled,
            onChanged: (bool value) {
              setState(() {
                isTabletTimeEnabled = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Walking Time'),
            secondary: const Icon(Icons.directions_walk_outlined),
            value: isWalkingTimeEnabled,
            onChanged: (bool value) {
              setState(() {
                isWalkingTimeEnabled = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Exercise Time'),
            secondary: const Icon(Icons.fitness_center_outlined),
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


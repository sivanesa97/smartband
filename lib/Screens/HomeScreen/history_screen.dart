import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartband/Screens/HomeScreen/settings.dart';
import 'package:smartband/Screens/Widgets/appBarProfile.dart';
import 'package:smartband/Screens/Widgets/drawer.dart';
import 'package:smartband/Screens/Widgets/string_extensions.dart';

import '../AuthScreen/role_screen.dart';
import '../Models/usermodel.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  BluetoothDevice device;
  String phNo;

  HistoryScreen({super.key, required this.device, required this.phNo});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    List<List<dynamic>> history_items = [
      [Icons.add, "Water Reminder", "3min ago", "Sent", Color.fromRGBO(0, 83, 188, 1)],
      [Icons.change_circle_outlined, "SOS alert", "5min ago", "Received", Color.fromRGBO(171, 0, 0, 1)],
      [Icons.medical_information_outlined, "Tablet Reminder", "1min ago", "Sent", Color.fromRGBO(255, 203, 0, 1)],
      [Icons.star_border_sharp, "Sleep alert", "2min ago", "Sent", Color.fromRGBO(88, 164, 160, 1)],
      [Icons.change_circle_outlined, "SOS alert", "4min ago", "Received", Color.fromRGBO(171, 0, 0, 1)],
    ];
    final user_data =
        ref.watch(userModelProvider(FirebaseAuth.instance.currentUser!.uid));
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
        drawer: DrawerScreen(
          device: bluetoothDeviceManager.connectedDevices.first,
          phNo: widget.phNo,
        ),
        backgroundColor: Colors.white,
        body: user_data.when(
          data: (user) {
            if (user == null) {
              return Center(child: Text("User data is unavailable"));
            }
            return SafeArea(
                child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    // Adjust this to fit content
                    children: [
                      // Profile Picture
                      GestureDetector(
                        onTap: () {
                          Scaffold.of(context).openDrawer();
                        },
                        child: Container(
                          margin: EdgeInsets.all(10.0),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage(
                              FirebaseAuth.instance.currentUser!.photoURL ??
                                  "https://t4.ftcdn.net/jpg/03/26/98/51/360_F_326985142_1aaKcEjMQW6ULp6oI9MYuv8lN9f8sFmj.jpg",
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 3),
                      // Spacing between profile picture and text
                      // Greeting Message
                      Expanded(
                        // Use Expanded to take up remaining space
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "Hello ${user.name.split(' ')[0].toTitleCase()}",
                                  style: TextStyle(
                                    fontSize: width * 0.055,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Icon(Icons.keyboard_arrow_down)
                              ],
                            ),
                            Text(
                              DateTime.now().hour > 12
                                  ? DateTime.now().hour > 16
                                      ? "Good Evening ${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year.toString().substring(
                                            2,
                                          )}"
                                      : "Good Afternoon ${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year.toString().substring(
                                            2,
                                          )}"
                                  : "Good Morning ${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year.toString().substring(
                                        2,
                                      )}",
                              style: TextStyle(
                                fontSize: width * 0.04,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            child: Image.asset(
                              "assets/profile_icon.png",
                              width: 25,
                              height: 25,
                            ),
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => HomePage(
                                      phNo: user.phone_number.toString())));
                            },
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Icon(
                            Icons.notifications,
                            size: 25,
                          )
                        ],
                      ),
                      SizedBox(
                        width: width * 0.01,
                      )
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.all(10),
                    child: Text(
                      "History",
                      textAlign: TextAlign.left,
                      style: TextStyle(fontSize: width * 0.05, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: SizedBox(
                        height: height * 0.7,
                        child: ListView.builder(
                            itemCount: history_items.length,
                            itemBuilder: (context, index) {
                              return Column(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 15, vertical: 15),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15.0),
                                      color: Color.fromRGBO(255, 255, 255, 1),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.5),
                                          spreadRadius: 3,
                                          blurRadius: 3,
                                          offset: Offset(
                                              0, 0), // changes position of shadow
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              margin: EdgeInsets.only(right: 10),
                                              padding: EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                  color: history_items[index][4],
                                                  shape: BoxShape.circle),
                                              child: Icon(
                                                history_items[index][0],
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              history_items[index][1],
                                              style: TextStyle(
                                                  fontSize: width * 0.045),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              history_items[index][2],
                                              style: TextStyle(
                                                  color: Color.fromRGBO(
                                                      115, 115, 115, 1)),
                                            ),
                                            Text(
                                              history_items[index][3],
                                              style: TextStyle(
                                                  color: Color.fromRGBO(
                                                      0, 83, 188, 1)),
                                            )
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    height: 20,
                                  )
                                ],
                              );
                            }),
                      ),
                  )
                ],
              ),
            ));
          },
          error: (error, stackTrace) {
            return Center(child: Text("Error Fetching User details"));
          },
          loading: () {
            return Center(
                child: CircularProgressIndicator(color: Colors.blueAccent));
          },
        ));
  }
}

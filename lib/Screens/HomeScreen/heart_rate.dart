import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartband/Screens/AuthScreen/role_screen.dart';
import 'package:smartband/Screens/Widgets/string_extensions.dart';
import 'package:smartband/bluetooth.dart';

import '../Models/usermodel.dart';
import '../Widgets/drawer.dart';

class HeartrateScreen extends ConsumerStatefulWidget {
  final BluetoothDevice device;
  final String phNo;

  HeartrateScreen({Key? key, required this.device, required this.phNo}) : super(key: key);

  @override
  ConsumerState<HeartrateScreen> createState() => _HeartrateScreenState();
}

class _HeartrateScreenState extends ConsumerState<HeartrateScreen> {
  final BluetoothDeviceManager bluetoothDeviceManager =
  BluetoothDeviceManager();

  @override
  Widget build(BuildContext context) {
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
                                    Icon(
                                        Icons.keyboard_arrow_down
                                    )
                                  ],
                                ),
                                Text(
                                  DateTime.now().hour > 12
                                      ? DateTime.now().hour > 16
                                      ? "Good Evening ${DateTime.now().day.toString().padLeft(2,'0')}/${DateTime.now().month.toString().padLeft(2,'0')}/${DateTime.now().year.toString().substring(2,)}"
                                      : "Good Afternoon ${DateTime.now().day.toString().padLeft(2,'0')}/${DateTime.now().month.toString().padLeft(2,'0')}/${DateTime.now().year.toString().substring(2,)}"
                                      : "Good Morning ${DateTime.now().day.toString().padLeft(2,'0')}/${DateTime.now().month.toString().padLeft(2,'0')}/${DateTime.now().year.toString().substring(2,)}",
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
                      SizedBox(height: 20,),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(15),
                            width: width * 0.95,
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  child: Image.network(
                                    "https://img.freepik.com/free-psd/human-organs-character-composition_23-2150610255.jpg?w=740&t=st=1722582551~exp=1722583151~hmac=9063f493678bb77871c62d73d0ebf86776220ef9f1ef77d6d81eac42809654b2",
                                    width: width * 0.4,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                SizedBox(width: 15,),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Health Age",
                                      style: TextStyle(
                                        fontSize: width * 0.05,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          "25",
                                          style: TextStyle(
                                              fontSize: width * 0.1,
                                              color: Colors.white
                                          ),
                                        ),
                                        SizedBox(width: 10,),
                                        Text(
                                          "years",
                                          style: TextStyle(
                                              fontSize: width * 0.05,
                                              color: Colors.white
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      width: width * 0.4,
                                      child: Text(
                                        "Congrats! You're on a healthier track.",
                                        maxLines: 2,
                                        style: TextStyle(
                                            fontSize: width * 0.03,
                                            color: Colors.white
                                        ),
                                      ),
                                    )
                                  ],
                                )
                              ],
                            )
                          ),
                          SizedBox(height: 10,),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                                child: Text(
                                  "Track your Heart Rate",
                                  style: TextStyle(
                                      fontSize: width * 0.05,
                                      fontWeight: FontWeight.bold
                                  ),
                                ),
                              ),
                            )
                          ),
                          SizedBox(height: 10,),
                          Container(
                              padding: EdgeInsets.all(15),
                              width: width * 0.95,
                              decoration: BoxDecoration(
                                color: Color.fromRGBO(228, 240, 254, 1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Image.asset(
                                          "assets/heart_rate_1.png",
                                          width: width * 0.4,
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            "67",
                                            style: TextStyle(
                                                fontSize: width * 0.1
                                            ),
                                          ),
                                          SizedBox(width: 10,),
                                          Column(
                                            children: [
                                              Icon(
                                                Icons.favorite,
                                                color: Colors.red,
                                              ),
                                              Text(
                                                "BPM",
                                                style: TextStyle(
                                                    fontSize: width * 0.04
                                                ),
                                              )
                                            ],
                                          )
                                        ],
                                      )
                                    ],
                                  ),
                                  SizedBox(height: 10,),
                                  Container(
                                    width: width * 0.8,
                                    height: height * 0.01,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      gradient: LinearGradient(
                                          colors: [
                                            Colors.green,
                                            Colors.yellow,
                                            Colors.orange,
                                            Colors.red
                                          ],
                                        stops: [0.175, 0.275, 0.35, 1.0]
                                      ),
                                    ),
                                  ),
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    padding: EdgeInsets.only(left: 100),
                                    child: Icon(
                                      Icons.arrow_drop_down_sharp,
                                      size: 20,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      Text(
                                          "Average",
                                          style: TextStyle(
                                            fontSize: width * 0.035
                                          ),
                                      ),
                                      Text(
                                          "Healthy",
                                          style: TextStyle(
                                            fontSize: width * 0.035
                                          ),
                                      ),
                                      Text(
                                          "Maximum",
                                          style: TextStyle(
                                            fontSize: width * 0.035
                                          ),
                                      ),
                                      Text(
                                          "Danger",
                                          style: TextStyle(
                                            fontSize: width * 0.035
                                          ),
                                      )
                                    ],
                                  )
                                ],
                              )
                          ),
                          SizedBox(height: 15,),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 15),
                            child: Image.asset(
                              "assets/heart_rate.png",
                              width: width * 0.9,
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                )
            );
          },
          error: (error, stackTrace) {
            return Center(child: Text("Error Fetching User details"));
          },
          loading: () {
            return Center(
                child: CircularProgressIndicator(color: Colors.blueAccent));
          },
        )
    );
  }
}
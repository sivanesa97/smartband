import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smartband/Screens/Widgets/string_extensions.dart';
import 'package:smartband/bluetooth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

import '../Models/usermodel.dart';
import '../Widgets/drawer.dart';
import 'dashboard.dart';

class WearerDashboard extends ConsumerStatefulWidget {
  final BluetoothDevice device;

  WearerDashboard({Key? key, required this.device}) : super(key: key);

  @override
  ConsumerState<WearerDashboard> createState() => _WearerDashboardState();
}

class _WearerDashboardState extends ConsumerState<WearerDashboard> {
  final BluetoothDeviceManager bluetoothDeviceManager =
      BluetoothDeviceManager();
  Position location_new = Position(latitude: 12.239842, longitude: 80.247384, timestamp: null, accuracy: 1.0, altitude: 1.0, heading: 1.0, speed: 1.0, speedAccuracy: 1.0);

  Future<void> openGoogleMaps(double start, double end) async {
    final String googleMapsUrl =
        'https://www.google.com/maps/search/?api=1&query=$start,$end';

    if (await canLaunch(googleMapsUrl)) {
      await launch(googleMapsUrl);
    } else {
      throw 'Could not open the map.';
    }
  }

  String water = "";
  String status = "";
  String subscription = "";

  @override
  void initState() {
    super.initState();
    bluetoothDeviceManager.discoverServicesAndCharacteristics(widget.device);
    fetchData();
  }

  Future<void> fetchData() async {
    final response = await http.get(Uri.parse('https://example.com/data'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        water = data['water'];
        status = data['status'];
        subscription = data['subscription'];
      });
    } else {
      throw Exception('Failed to load data');
    }
  }



  Future<Position> updateLocation() async {
    Position location = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    print("Fetched Location");
    return location;
  }

  @override
  Widget build(BuildContext context) {
    final user_data =
        ref.watch(userModelProvider(FirebaseAuth.instance.currentUser!.uid));
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
        drawer: DrawerScreen(device: bluetoothDeviceManager.connectedDevices.first,),
        backgroundColor: Colors.white,
        body: user_data.when(
          data: (user) {
            if (user == null) {
              return Center(child: Text("User data is unavailable"));
            }

            return StreamBuilder<Map<String, String>>(
              stream: bluetoothDeviceManager.characteristicValuesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Center(
                      child: CircularProgressIndicator(
                          color: Colors.blueAccent));
                }
                if (snapshot.hasError) {
                  return Center(
                      child:
                      Text("Error reading characteristic values"));
                }

                final characteristicValues = snapshot.data ?? {};
                List<String> values = (characteristicValues[
                "beb5483e-36e1-4688-b7f5-ea07361b26a8"] ??
                    "--,--,--,--,--,0")
                    .split(',');
                Timer.periodic(Duration(minutes: 10),
                        (Timer timer) async {
                      if (FirebaseAuth.instance.currentUser!.uid != null) {
                        await FirebaseFirestore.instance
                            .collection("users")
                            .doc(FirebaseAuth.instance.currentUser!.uid)
                            .update({
                          "metrics": {
                            "spo2": values[3],
                            "heart_rate": values[4],
                            "fall_axis":
                            "${values[0]} ${values[1]} ${values[2]}"
                          }
                        });
                      }
                    });
                bool sosClicked = values[1] == '1' ? true : false;
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
                                    radius: 30, // Adjust size as needed
                                    backgroundImage: NetworkImage(
                                      FirebaseAuth.instance.currentUser!
                                          .photoURL ??
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
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Hello ${user.name.split(' ')[0].toTitleCase()}",
                                      style: TextStyle(
                                        fontSize: width * 0.055,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Text(
                                      DateTime.now().hour > 12 ? DateTime.now().hour > 16 ? "Good Evening" : "Good Afternoon" : "Good Morning",
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
                                  Icon(
                                    Icons.add,
                                    size: 30,
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Icon(
                                    Icons.notifications,
                                    size: 30,
                                  )
                                ],
                              ),
                              SizedBox(
                                width: width * 0.01,
                              )
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: width * 0.9,
                                        height: height * 0.2,
                                        child: ClipRRect(
                                          borderRadius:
                                          BorderRadius.circular(30),
                                          // Rounded corners
                                          child: Image.network(
                                            "https://miro.medium.com/v2/resize:fit:1400/1*qYUvh-EtES8dtgKiBRiLsA.png",
                                            fit: BoxFit
                                                .cover, // Ensure the image covers the container
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width:
                                        MediaQuery.of(context).size.width *
                                            0.9,
                                        height:
                                        MediaQuery.of(context).size.height *
                                            0.2,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                          BorderRadius.circular(30),
                                          // Rounded corners
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color.fromRGBO(72, 151, 217, 0.8),
                                              Color.fromRGBO(0, 0, 0, 0.2),
                                              Color.fromRGBO(72, 151, 217, 0.8),
                                            ], // Gradient colors
                                            begin: Alignment.center,
                                            end: Alignment.centerRight,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(
                                            left: width * 0.07,
                                            top: height * 0.02),
                                        child: Column(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Location",
                                              style: TextStyle(
                                                  fontSize: width * 0.07,
                                                  color: Colors.white),
                                            ),
                                            SizedBox(
                                              height: 5,
                                            ),
                                            Text(
                                              "Current Location ID :\n${location_new.latitude}°N ${location_new.longitude}°E",
                                              style: TextStyle(
                                                  fontSize: width * 0.04,
                                                  color: Colors.white),
                                            ),
                                            SizedBox(
                                              height: 10,
                                            ),
                                            InkWell(
                                              onTap: () {
                                                setState(() async {
                                                  location_new =
                                                  await updateLocation();
                                                });
                                                openGoogleMaps(
                                                    location_new.latitude,
                                                    location_new.longitude);
                                              },
                                              child: Container(
                                                padding: EdgeInsets.all(5.0),
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                    BorderRadius.circular(
                                                        10.0),
                                                    color: Colors.white),
                                                child: Text(
                                                  "Open in Maps",
                                                  style: TextStyle(
                                                    fontSize: width * 0.04,
                                                    color: Color.fromRGBO(
                                                        88, 106, 222, 0.9),
                                                  ),
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                  )),
                              SizedBox(
                                height: height * 0.015,
                              ),
                              Center(
                                child: Container(
                                  height: height * 0.1,
                                  width: width * 0.9,
                                  decoration: BoxDecoration(
                                      borderRadius:
                                      BorderRadius.circular(20.0),
                                      color: Colors.black),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8.0,
                                        vertical: height * 0.025),
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Column(
                                            children: [
                                              Text(
                                                "Water",
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize:
                                                    width * 0.045),
                                              ),
                                              Text(
                                                "2Litre",
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: width * 0.03),
                                              ),
                                            ],
                                          ),
                                          VerticalDivider(
                                            color: Colors.white,
                                            thickness: 2,
                                          ),
                                          Column(
                                            children: [
                                              Text(
                                                "Status",
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize:
                                                    width * 0.045),
                                              ),
                                              Text(
                                                "Active",
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: width * 0.03),
                                              ),
                                            ],
                                          ),
                                          VerticalDivider(
                                            color: Colors.white,
                                            thickness: 2,
                                          ),
                                          Column(
                                            children: [
                                              Text(
                                                "Subscription",
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize:
                                                    width * 0.045),
                                              ),
                                              Text(
                                                "10/12/2024",
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: width * 0.03),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Padding(
                                padding:
                                EdgeInsets.symmetric(horizontal: 20.0),
                                child: Text(
                                  "For You, ",
                                  style: TextStyle(fontSize: width * 0.06),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0),
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: width * 0.475,
                                      height: height * 0.5,
                                      child: Column(
                                        children: [
                                          Expanded(
                                              flex: 3,
                                              child: Card(
                                                color: Color.fromRGBO(
                                                    255, 255, 200, 0.8),
                                                shape:
                                                RoundedRectangleBorder(
                                                    borderRadius:
                                                    BorderRadius
                                                        .circular(
                                                        20)),
                                                elevation: 4,
                                                child: Padding(
                                                  padding:
                                                  const EdgeInsets.only(
                                                      left: 12.0,
                                                      top: 12.0),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Icon(
                                                              Icons
                                                                  .monitor_heart_outlined,
                                                              size: 30),
                                                          SizedBox(
                                                              width: width *
                                                                  0.02),
                                                          Text(
                                                            "Fall Detection",
                                                            style: TextStyle(
                                                                fontSize:
                                                                width *
                                                                    0.045),
                                                          ),
                                                        ],
                                                      ),
                                                      Center(
                                                        child: Image.asset(
                                                          "assets/fallaxis.png",
                                                          width:
                                                          width * 0.4,
                                                        ),
                                                      ),
                                                      Center(
                                                        child: Image.asset(
                                                          "assets/fallaxis1.png",
                                                          height:
                                                          height * 0.02,
                                                        ),
                                                      )

                                                      // Row(
                                                      //   children: [
                                                      //     Text(
                                                      //       "${'X : '+values[0]}\nY : ${values[1]}\nZ : ${values[2]}",
                                                      //       style: TextStyle(fontSize: width*0.07, fontWeight: FontWeight.bold),
                                                      //     ),
                                                      //     SizedBox(width: width * 0.02),
                                                      //     // Text("-1"),
                                                      //   ],
                                                      // ),
                                                    ],
                                                  ),
                                                ),
                                              )),
                                          Expanded(
                                            flex: 2,
                                            child: EmergencyCard(
                                              relations: user.relations,
                                              user: user.name,
                                              sosClicked: sosClicked,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      height: height * 0.5,
                                      width: width * 0.475,
                                      child: Column(
                                        children: [
                                          Expanded(
                                              flex: 2,
                                              child: Card(
                                                color: const Color.fromRGBO(
                                                    111, 211, 255,
                                                    0.4),
                                                shape:
                                                RoundedRectangleBorder(
                                                    borderRadius:
                                                    BorderRadius
                                                        .circular(
                                                        20)),
                                                elevation: 4,
                                                child: Padding(
                                                  padding:
                                                  const EdgeInsets.only(top: 12.0, left: 12.0),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          const Icon(
                                                              Icons
                                                                  .favorite_outlined,
                                                              size: 30),
                                                          SizedBox(
                                                              width: width *
                                                                  0.02),
                                                          Text(
                                                            "Heart Rate",
                                                            style: TextStyle(
                                                                fontSize:
                                                                width *
                                                                    0.04),
                                                          ),
                                                        ],
                                                      ),
                                                      SizedBox(height: 8),
                                                      Row(
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Text(
                                                                values[3],
                                                                style: TextStyle(
                                                                    fontSize:
                                                                    width * 0.07,
                                                                    fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                              ),
                                                              Text(
                                                                " bpm",
                                                                style: TextStyle(
                                                                    fontSize:
                                                                    width * 0.03,
                                                                    fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                              ),
                                                            ],
                                                          ),
                                                          SizedBox(width: 10,),
                                                          Image.asset(
                                                            "assets/heartrate.png",
                                                            width:
                                                            width * 0.23,
                                                          )
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )),
                                          Expanded(
                                              flex: 3,
                                              child: Card(
                                                color: const Color.fromRGBO(
                                                    50, 255, 50, 0.2),
                                                shape:
                                                RoundedRectangleBorder(
                                                    borderRadius:
                                                    BorderRadius
                                                        .circular(
                                                        20)),
                                                elevation: 4,
                                                child: Padding(
                                                  padding:
                                                  const EdgeInsets.all(
                                                      16.0),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Icon(
                                                              Icons
                                                                  .water_drop,
                                                              size: 30),
                                                          SizedBox(
                                                              width: width *
                                                                  0.02),
                                                          Text(
                                                            "SPo2",
                                                            style: TextStyle(
                                                                fontSize:
                                                                width *
                                                                    0.05),
                                                          ),
                                                        ],
                                                      ),
                                                      SizedBox(height: 8),
                                                      Stack(
                                                        alignment: Alignment.center,
                                                        children: [
                                                          Padding(
                                                            padding: EdgeInsets.only(top: 15),
                                                            child: Text(
                                                              values[4],
                                                              style: TextStyle(
                                                                  fontSize:
                                                                  width * 0.07,
                                                                  fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                            ),
                                                          ),
                                                          Image.asset(
                                                            "assets/spo2.png",
                                                            width: width * 0.475,
                                                          )
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ));
              },
            );
          },
          error: (error, stackTrace) {
            return Center(child: Text("Error Fetching User details"));
          },
          loading: () {
            return Center(
                child: CircularProgressIndicator(
                    color: Colors.blueAccent));
          },
        )
    );
  }
}

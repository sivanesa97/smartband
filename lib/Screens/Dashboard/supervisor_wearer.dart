import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartband/Screens/HomeScreen/settings.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Models/twilio_service.dart';
import '../Models/usermodel.dart';
import '../Widgets/appBarProfile.dart';
import '../Widgets/drawer.dart';
import 'dashboard.dart';
import 'dart:math';

class SupervisorWearer extends ConsumerStatefulWidget {
  const SupervisorWearer({super.key});

  @override
  ConsumerState<SupervisorWearer> createState() => _WearerDashboardState();
}

class _WearerDashboardState extends ConsumerState<SupervisorWearer> {
  String dropdownValue = 'No Users';

  // Function to show supervisor dialog and handle OTP verification
  void _showSupervisorDialog(int otp_num) async {
    if (_emailConn.text != FirebaseAuth.instance.currentUser!.email &&
        _otpConn.text == otp_num.toString()) {
      String emailToCheck = _emailConn.text;
      var usersCollection = FirebaseFirestore.instance.collection("users");
      var querySnapshot =
      await usersCollection.where('email', isEqualTo: emailToCheck).get();
      if (querySnapshot.docs.isNotEmpty) {
        await usersCollection
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .update({
          "relations": FieldValue.arrayUnion([emailToCheck])
        });

        Navigator.of(context, rootNavigator: true).pop();
      } else {
        // Handle email not existing case
        print("Email does not exist in the collection.");
      }
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Invalid OTP")));
    }
  }

  // Function to fetch relation details where current user email is in relations array
  Future<List<Map<String, dynamic>>> _fetchRelationDetails(List<String> email) async {
    List<Map<String, dynamic>> relationDetails = [];
    for(String i in email)
      {
        var userDoc = await FirebaseFirestore.instance
            .collection('users')
            .where('email',
            isEqualTo: i)
            .get();

        if (userDoc.docs.isNotEmpty) {
          relationDetails.add(userDoc.docs.first.data());
        }
      }
    return relationDetails;
  }

  final TwilioService twilioService = TwilioService(
    accountSid: 'ACf1f0c0870c825a03dc6db124b365cf6a',
    authToken: 'fa856967b5f8bc971b3b783197c3ce33',
    fromNumber: '+17628009114',
  );

  Future<List<Map<String, dynamic>>> _fetchPhoneDetails(
      String email, int otp_num) async {
    List<Map<String, dynamic>> relationDetails = [];
    bool madeCall = false;
    var userDoc = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();
    if (userDoc.docs.isNotEmpty) {
      final data = userDoc.docs.first.data()['phone_number'];
      await twilioService.sendSms('+91${data}', 'Your OTP is ${otp_num}');
    }
    return relationDetails;
  }

  Future<void> openGoogleMaps(double start, double end) async {
    final String googleMapsUrl =
        'https://www.google.com/maps/search/?api=1&query=$start,$end';

    if (await canLaunch(googleMapsUrl)) {
      await launch(googleMapsUrl);
    } else {
      throw 'Could not open the map.';
    }
  }

  String? _selectedRole = "watch wearer";
  final TextEditingController _emailConn = TextEditingController();
  final TextEditingController _otpConn = TextEditingController();

  void _showRoleDialog() {
    bool sent = false;
    int otp_num = 100000 + Random().nextInt(999999 - 100000 + 1);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Select Role'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Role',
                      ),
                      value: _selectedRole,
                      items: ['watch wearer', 'supervisor'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child:
                          Text(value[0].toUpperCase() + value.substring(1)),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedRole = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _selectedRole == "supervisor"
                        ? TextFormField(
                      controller: _emailConn,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Email',
                          suffixIcon: IconButton(
                              onPressed: () {
                                sent = true;
                                _fetchPhoneDetails(
                                    _emailConn.text, otp_num);
                              },
                              icon:
                              Icon(sent ? Icons.check : Icons.send))),
                    )
                        : const SizedBox.shrink(),
                    const SizedBox(height: 16),
                    _selectedRole == "supervisor"
                        ? TextFormField(
                      controller: _otpConn,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'OTP',
                      ),
                    )
                        : const SizedBox.shrink(),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    _showSupervisorDialog(otp_num);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user_data =
    ref.watch(userModelProvider(FirebaseAuth.instance.currentUser!.uid));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppBarProfileWidget(),
      drawer: DrawerScreen(device: bluetoothDeviceManager.connectedDevices.first,),
      body: SafeArea(
        child: user_data.when(
          data: (user) {
            Map<String, dynamic> relation = {};
            return FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchRelationDetails(user!.relations),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                      child: CircularProgressIndicator(color: Colors.blueAccent));
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error fetching relation details"));
                } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  List<Map<String, dynamic>> relationDetails = snapshot.data!;
                  if (dropdownValue == 'No Users') {
                    dropdownValue = relationDetails.first['email'];
                    relation = relationDetails.first;
                  }

                  return Column(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.1,
                        width: MediaQuery.of(context).size.width * 0.95,
                        child: Center(
                          child: DropdownButton<String>(
                            value: dropdownValue,
                            isExpanded: true,
                            itemHeight: 100,
                            underline: const SizedBox(),
                            icon: const Icon(Icons.arrow_drop_down_sharp),
                            style: const TextStyle(color: Colors.white),
                            onChanged: (String? value) {
                              setState(() {
                                dropdownValue = value!;
                              });
                            },
                            items: relationDetails.map<DropdownMenuItem<String>>(
                                    (Map<String, dynamic> relation) {
                                  return DropdownMenuItem<String>(
                                    value: relation['email'],
                                    child: Padding(
                                      padding: EdgeInsets.all(5),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          color: Colors.grey.withOpacity(0.5),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                            children: [
                                              const CircleAvatar(
                                                radius: 30.0,
                                                backgroundColor: Colors.white,
                                                child: Icon(
                                                  Icons.account_circle_outlined,
                                                  size: 35,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              Text(
                                                relation['name'],
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 16,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const Icon(
                                                Icons.stacked_line_chart,
                                                size: 50,
                                                color: Colors.black,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Consumer(
                          builder: (context, watch, child) {
                            final height = MediaQuery.of(context).size.height;
                            final width = MediaQuery.of(context).size.width;
                            final supervisorModel =
                            ref.watch(supervisorModelProvider(dropdownValue));
                            return supervisorModel.when(
                              data: (data) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(height: 16,),
                                        Center(
                                            child: Stack(
                                              children: [
                                                Container(
                                                  width: width * 0.92,
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
                                                      0.92,
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
                                                      const SizedBox(
                                                        height: 5,
                                                      ),
                                                      Text(
                                                        "Current Location ID :\n${data!.first.latitude}°N ${data!.first.longitude}°E",
                                                        style: TextStyle(
                                                            fontSize: width * 0.04,
                                                            color: Colors.white),
                                                      ),
                                                      const SizedBox(
                                                        height: 10,
                                                      ),
                                                      InkWell(
                                                        onTap: () {
                                                          openGoogleMaps(
                                                              data!.first.latitude,
                                                              data!.first.longitude);
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
                                                              color: const Color.fromRGBO(
                                                                  88, 106, 222, 0.9),
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            )
                                        ),
                                        SizedBox(height: 16,),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                            MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: width * 0.45,
                                                height: height * 0.3,
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
                                                              ],
                                                            ),
                                                          ),
                                                        )),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                height: height * 0.45,
                                                width: width * 0.45,
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
                                                                SizedBox(height: 5),
                                                                Row(
                                                                  children: [
                                                                    Row(
                                                                      children: [
                                                                        Text(
                                                                          data.first.metrics['heart_rate'].toString(),
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
                                                                    SizedBox(width: 5,),
                                                                    Image.asset(
                                                                      "assets/heartrate.png",
                                                                      width: data.first.metrics['heart_rate']!='--' && int.parse(data.first.metrics['heart_rate'])>100 ? width * 0.17 : width * 0.2,
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
                                                                        data.first.metrics['spo2'].toString(),
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
                                        SizedBox(height: 16,),
                                        Center(
                                          child: GestureDetector(
                                            onTap: () {
                                              _showRoleDialog();
                                              print("Adding users");
                                            },
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 10.0),
                                              child: const Text(
                                                "Add users",
                                                style: TextStyle(fontSize: 18),
                                              ),
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              },
                              error: (error, stackTrace) {
                                return Text("Error : $error");
                              },
                              loading: () {
                                return Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.blueAccent),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                } else {
                  return Center(
                    child: GestureDetector(
                      onTap: () {
                        _showRoleDialog();
                        print("Adding users");
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 10.0),
                        child: const Text(
                          "No Users found\nAdd users",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  );
                }
              },
            );
          },
          error: (error, stackTrace) {
            return Center(
              child: Text("Error Fetching User details"),
            );
          },
          loading: () {
            return Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            );
          },
        ),
      ),
    );
  }
}

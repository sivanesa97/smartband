import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:smartband/Screens/AuthScreen/phone_number.dart';
import 'package:smartband/Screens/Dashboard/wearer_dashboard.dart';
import 'package:smartband/Screens/HomeScreen/settings.dart';
import 'package:smartband/Screens/Models/messaging.dart';
import 'package:smartband/Screens/Widgets/loading.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'dart:io' show Platform;
import 'package:intl/intl.dart' as intl;
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../Models/usermodel.dart';
import '../Widgets/appBarProfile.dart';
import '../Widgets/drawer.dart';
import 'dashboard.dart';
import 'dart:math';

class SupervisorWearer extends ConsumerStatefulWidget {
  String phno;
  SupervisorWearer({super.key, required this.phno});

  @override
  ConsumerState<SupervisorWearer> createState() => _WearerDashboardState();
}

class _WearerDashboardState extends ConsumerState<SupervisorWearer> {
  String dropdownValue = 'No Users';

  // Function to show supervisor dialog and handle OTP verification

  // Function to fetch relation details where current user email is in relations array
  Future<List<Map<String, dynamic>>> _fetchRelationDetails(
      List<String> phone_number) async {
    List<Map<String, dynamic>> relationDetails = [];
    for (String i in phone_number) {
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('phone_number', isEqualTo: i)
          .get();

      if (userDoc.docs.isNotEmpty) {
        relationDetails.add(userDoc.docs.first.data());
      }
      // await Future.delayed(Duration(minutes: 1));
    }
    return relationDetails;
  }

  Future<List<Map<String, dynamic>>> _fetchPhoneDetails(
      String phone_number, int otp_num) async {
    List<Map<String, dynamic>> relationDetails = [];
    bool madeCall = false;
    var userDoc = await FirebaseFirestore.instance
        .collection('users')
        .where('phone_number', isEqualTo: PhoneNo)
        .get();
    if (userDoc.docs.isNotEmpty) {
      final data = userDoc.docs.first.data()['phone_number'];
      print(otp_num);
      Messaging messaging = Messaging();
      messaging.sendSMS(PhoneNo, "Your OTP is $otp_num");
    }
    return relationDetails;
  }

  Future<void> openGoogleMaps(double lat, double lng) async {
    if (Platform.isAndroid) {
      final AndroidIntent intent = AndroidIntent(
        action: 'action_view',
        data: Uri.encodeFull('google.navigation:q=$lat,$lng'),
        package: 'com.google.android.apps.maps',
      );

      try {
        await intent.launch();
        return;
      } catch (e) {
        print('Could not open Google Maps app: $e');
      }
      final AndroidIntent genericIntent = AndroidIntent(
        action: 'action_view',
        data: Uri.encodeFull('geo:$lat,$lng'),
      );

      try {
        await genericIntent.launch();
        return;
      } catch (e) {
        print('Could not open generic map intent: $e');
      }
    }
    final Uri url =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      print('Could not open the map in web browser');
      throw 'Could not open the map.';
    }
  }

  String? _selectedRole = "supervisor";
  String PhoneNo = "";
  final TextEditingController _phoneConn = TextEditingController();
  final TextEditingController _otpConn = TextEditingController();

  String status = "";
  String subscription = "";
  bool _isSubscriptionFetched = false;

  Future<void> fetchSubscription(String phno) async {
    print(phno);
    final response = await http.post(
      Uri.parse("https://snvisualworks.com/public/api/auth/check-mobile"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'mobile_number': '$phno',
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      intl.DateFormat dateFormat = intl.DateFormat("dd-MM-yyyy");
      print(data);
      if (data['status'].toString() != 'active') {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        await googleSignIn.signOut();
        await FirebaseAuth.instance.signOut();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("User not active")));
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => PhoneSignIn()),
            (Route<dynamic> route) => false);
        return;
      }

      DocumentReference docRef = FirebaseFirestore.instance
          .collection('server_time')
          .doc('current_time');
      await docRef.set({'timestamp': FieldValue.serverTimestamp()});

      DocumentSnapshot docSnapshot = await docRef.get();
      Timestamp serverTimestamp = docSnapshot['timestamp'];
      DateTime serverDate = serverTimestamp.toDate();
      if (data['subscription_date'] != null && data['end_date'] != null) {
        DateTime startDate =
            DateTime.parse(data['subscription_date'].toString());
        DateTime endDate = DateTime.parse(data['end_date'].toString());
        if ((startDate.isAtSameMomentAs(serverDate) ||
                startDate.isBefore(serverDate)) &&
            (endDate.isAtSameMomentAs(serverDate) ||
                endDate.isAfter(serverDate))) {
          setState(() {
            status = data['status'].toString();
            subscription = data['end_date'] == null
                ? "--"
                : intl.DateFormat('yyyy-MM-dd')
                    .format(DateTime.parse(data['end_date']));
            setState(() {
              _isSubscriptionFetched = true;
            });
            print("Fetched");
          });
        } else {
          final GoogleSignIn googleSignIn = GoogleSignIn();
          await googleSignIn.signOut();
          await FirebaseAuth.instance.signOut();
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Subscription To Continue")));
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => PhoneSignIn()),
              (Route<dynamic> route) => false);
          return;
        }
      } else {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        await googleSignIn.signOut();
        await FirebaseAuth.instance.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Subscribe to Continue!")));
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => PhoneSignIn()),
            (Route<dynamic> route) => false);
        return;
      }
    } else {
      print(response.statusCode);
    }
  }

  void _showSupervisorDialog(int otp_num) async {
    // String phn = '+94735833006';
    // if (otp_num.toString() == _otpConn.text) {
    if (true) {
      if (PhoneNo != widget.phno) {
        String phonetoCheck = PhoneNo;
        print(phonetoCheck);
        var usersCollection = FirebaseFirestore.instance.collection("users");
        var ownerSnapshot = await usersCollection
            .where('phone_number', isEqualTo: phonetoCheck)
            .where('role', isEqualTo: 'watch wearer')
            .get();

        if (ownerSnapshot.docs.isNotEmpty) {
          var docData = ownerSnapshot.docs.first.data();
          Map<String, dynamic> supervisors =
              Map<String, dynamic>.from(docData['supervisors'] ?? {});

          int highestPriority = 0;
          if (supervisors.isNotEmpty) {
            highestPriority = supervisors.values.map((s) {
              return int.tryParse(s['priority']) ?? 0;
            }).reduce((a, b) => a > b ? a : b);
          }

          int newPriority = highestPriority + 1;

          supervisors[widget.phno] = {
            'priority': newPriority.toString(),
            'status': 'active',
          };

          await ownerSnapshot.docs.first.reference.update({
            'supervisors': supervisors,
          });
        }

        var querySnapshot = await usersCollection
            .where('phone_number', isEqualTo: widget.phno)
            // .where('phone_number', isEqualTo: phn)
            .get();
        if (querySnapshot.docs.isNotEmpty) {
          var data = querySnapshot.docs.first.data()['relations'];
          print(data);
          await querySnapshot.docs.first.reference.update({
            // "relations": FieldValue.arrayUnion([widget.phNo.toString()])
            "relations": FieldValue.arrayUnion([phonetoCheck.toString()])
          });

          Navigator.of(context, rootNavigator: true).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Phone number does not exist in the collection.")));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please enter a different number")));
      }
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Invalid OTP")));
    }
  }

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
                        ? IntlPhoneField(
                            initialCountryCode: 'LK',
                            controller: _phoneConn,
                            onChanged: (phone) => {
                              setState(() {
                                PhoneNo = phone.completeNumber;
                              })
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Phone Number',
                              suffixIcon: IconButton(
                                onPressed: () {
                                  sent = true;
                                  _fetchPhoneDetails(PhoneNo, otp_num);
                                },
                                icon: Icon(sent ? Icons.check : Icons.send),
                              ),
                            ),
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
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppBarProfileWidget(),
      drawer: DrawerScreen(
          device: bluetoothDeviceManager.connectedDevices.first,
          phNo: widget.phno,
          subscription: "",
          status: ""),
      body: SafeArea(
        child: user_data.when(
          data: (user) {
            Map<String, dynamic> relation = {};
            return FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchRelationDetails(user!.relations),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: GradientLoadingIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error fetching relation details"));
                } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  List<Map<String, dynamic>> relationDetails = snapshot.data!;
                  if (dropdownValue == 'No Users') {
                    dropdownValue =
                        relationDetails.first['phone_number'].toString();
                    relation = relationDetails.first;
                  }
                  if (!_isSubscriptionFetched) {
                    fetchSubscription(dropdownValue);
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
                            items: relationDetails
                                .map<DropdownMenuItem<String>>(
                                    (Map<String, dynamic> relation) {
                              return DropdownMenuItem<String>(
                                value: relation['phone_number'].toString(),
                                child: Padding(
                                  padding: EdgeInsets.all(5),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Color.fromRGBO(10, 81, 174, 1)
                                          .withOpacity(0.5),
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
                                          // const Icon(
                                          //   Icons.stacked_line_chart,
                                          //   size: 30,
                                          //   color: Colors.black,
                                          // ),
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
                            final supervisorModel = ref
                                .watch(supervisorModelProvider(dropdownValue));
                            return supervisorModel.when(
                              data: (data) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 0.0),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          height: 16,
                                        ),
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
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.92,
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.2,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(30),
                                                // Rounded corners
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Color.fromRGBO(
                                                        72, 151, 217, 0.8),
                                                    Color.fromRGBO(
                                                        0, 0, 0, 0.2),
                                                    Color.fromRGBO(
                                                        72, 151, 217, 0.8),
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
                                                    "Current Location ID :\n${data!.first.latitude}°N ${data.first.longitude}°E",
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
                                                          data!
                                                              .first.longitude);
                                                    },
                                                    child: Container(
                                                      padding:
                                                          EdgeInsets.all(5.0),
                                                      decoration: BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      10.0),
                                                          color: Colors.white),
                                                      child: Text(
                                                        "Open in Maps",
                                                        style: TextStyle(
                                                          fontSize:
                                                              width * 0.04,
                                                          color: const Color
                                                              .fromRGBO(88, 106,
                                                              222, 0.9),
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ),
                                          ],
                                        )),
                                        _isSubscriptionFetched
                                            ? Center(
                                                child: Container(
                                                  height: height * 0.07,
                                                  width: width * 0.9,
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20.0),
                                                      color: Colors.black),
                                                  child: Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 8.0,
                                                            vertical:
                                                                height * 0.01),
                                                    child: Center(
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceEvenly,
                                                        children: [
                                                          // Column(
                                                          //   children: [
                                                          //     Text(
                                                          //       "Water",
                                                          //       style: TextStyle(
                                                          //           color: Colors.white,
                                                          //           fontSize: width * 0.045),
                                                          //     ),
                                                          //     Text(
                                                          //       "2Litre",
                                                          //       style: TextStyle(
                                                          //           color: Colors.white,
                                                          //           fontSize: width * 0.03),
                                                          //     ),
                                                          //   ],
                                                          // ),
                                                          // VerticalDivider(
                                                          //   color: Colors.white,
                                                          //   thickness: 2,
                                                          // ),
                                                          Column(
                                                            children: [
                                                              Text(
                                                                "Status",
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        width *
                                                                            0.045),
                                                              ),
                                                              Text(
                                                                status
                                                                    .toUpperCase(),
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        width *
                                                                            0.03),
                                                              ),
                                                            ],
                                                          ),
                                                          const VerticalDivider(
                                                            color: Colors.white,
                                                            thickness: 2,
                                                          ),
                                                          Column(
                                                            children: [
                                                              Text(
                                                                "Subscription",
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        width *
                                                                            0.045),
                                                              ),
                                                              Text(
                                                                subscription,
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        width *
                                                                            0.03),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : const SizedBox.shrink(),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20.0),
                                          child: Row(
                                            children: [
                                              Text(
                                                "For You, ",
                                                style: TextStyle(
                                                    fontSize: width * 0.06),
                                              ),
                                              SizedBox(width: 8),
                                              GestureDetector(
                                                onTap: () {
                                                  final Uri phoneUri = Uri(
                                                    scheme: 'tel',
                                                    path: dropdownValue,
                                                  );
                                                  launchUrl(phoneUri);
                                                },
                                                child: Icon(
                                                  Icons.call,
                                                  color: Colors
                                                      .green, // You can change the color as needed
                                                  size: width *
                                                      0.07, // Adjust the size according to your design
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          height: 16,
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: width * 0.45,
                                                height: height * 0.45,
                                                child: Column(
                                                  children: [
                                                    Expanded(
                                                        flex: 2,
                                                        child: Card(
                                                          color: Color.fromRGBO(
                                                              255,
                                                              255,
                                                              200,
                                                              0.8),
                                                          shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          20)),
                                                          elevation: 4,
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    left: 12.0,
                                                                    top: 12.0),
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Row(
                                                                  children: [
                                                                    Image.asset(
                                                                      "assets/Mask.png",
                                                                      width: 30,
                                                                    ),
                                                                    SizedBox(
                                                                        width: width *
                                                                            0.02),
                                                                    Text(
                                                                      "Fall Detection",
                                                                      style: TextStyle(
                                                                          fontSize:
                                                                              width * 0.045),
                                                                    ),
                                                                  ],
                                                                ),
                                                                Center(
                                                                  child: Image
                                                                      .asset(
                                                                    data.first.metrics['fall_axis'] ==
                                                                            '1'
                                                                        ? "assets/fallaxis.png"
                                                                        : "assets/fallaxis0.png",
                                                                    height:
                                                                        height *
                                                                            0.15,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        )),
                                                    Expanded(
                                                        flex: 2,
                                                        child: Card(
                                                          color: Color.fromRGBO(
                                                              255, 234, 234, 1),
                                                          shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          18)),
                                                          elevation: 4,
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    vertical:
                                                                        5.0,
                                                                    horizontal:
                                                                        15.0),
                                                            child: Column(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceAround,
                                                              children: [
                                                                Row(
                                                                  children: [
                                                                    Icon(
                                                                        Icons
                                                                            .warning,
                                                                        size:
                                                                            25),
                                                                    SizedBox(
                                                                        width: width *
                                                                            0.01),
                                                                    Text(
                                                                        'Emergency',
                                                                        style: TextStyle(
                                                                            fontSize:
                                                                                width * 0.05)),
                                                                  ],
                                                                ),
                                                                Stack(
                                                                  alignment:
                                                                      Alignment
                                                                          .center,
                                                                  children: [
                                                                    Container(
                                                                      width: width *
                                                                          0.25,
                                                                      height:
                                                                          width *
                                                                              0.25,
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        borderRadius:
                                                                            BorderRadius.circular(width *
                                                                                0.5),
                                                                        color: Colors
                                                                            .white,
                                                                        boxShadow: const [
                                                                          BoxShadow(
                                                                            color:
                                                                                Colors.redAccent,
                                                                            blurRadius:
                                                                                5.0,
                                                                          ),
                                                                        ],
                                                                        border: Border.all(
                                                                            color:
                                                                                Colors.redAccent,
                                                                            width: 10.0),
                                                                      ),
                                                                    ),
                                                                    Container(
                                                                      width: width *
                                                                          0.15,
                                                                      height:
                                                                          width *
                                                                              0.15,
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        borderRadius:
                                                                            BorderRadius.circular(width *
                                                                                0.5),
                                                                        color: Colors
                                                                            .black26,
                                                                        boxShadow: const [
                                                                          BoxShadow(
                                                                            color:
                                                                                Colors.redAccent,
                                                                            blurRadius:
                                                                                5.0,
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    Text(
                                                                      "SOS",
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .white,
                                                                          fontSize:
                                                                              20),
                                                                    ),
                                                                  ],
                                                                ),
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
                                                          color: const Color
                                                              .fromRGBO(
                                                              228, 240, 254, 1),
                                                          shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          20)),
                                                          elevation: 4,
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    top: 12.0,
                                                                    left: 12.0),
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
                                                                        size:
                                                                            30),
                                                                    SizedBox(
                                                                        width: width *
                                                                            0.02),
                                                                    Text(
                                                                      "Heart Rate",
                                                                      style: TextStyle(
                                                                          fontSize:
                                                                              width * 0.045),
                                                                    ),
                                                                  ],
                                                                ),
                                                                SizedBox(
                                                                    height: 8),
                                                                Column(
                                                                  children: [
                                                                    Image.asset(
                                                                      "assets/heartrate.png",
                                                                      width:
                                                                          width *
                                                                              0.3,
                                                                    ),
                                                                    SizedBox(
                                                                      height:
                                                                          10,
                                                                    ),
                                                                    Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .center,
                                                                      children: [
                                                                        Text(
                                                                          (data.first.metrics['heart_rate'] ?? '')
                                                                              .toString(),
                                                                          style: TextStyle(
                                                                              fontSize: width * 0.07,
                                                                              fontWeight: FontWeight.bold,
                                                                              color: Color.fromRGBO(0, 83, 188, 1)),
                                                                        ),
                                                                        Text(
                                                                          " bpm",
                                                                          style: TextStyle(
                                                                              fontSize: width * 0.03,
                                                                              fontWeight: FontWeight.bold,
                                                                              color: Color.fromRGBO(0, 83, 188, 1)),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        )),
                                                    Expanded(
                                                        flex: 2,
                                                        child: Card(
                                                          color: const Color
                                                              .fromRGBO(
                                                              50, 255, 50, 0.2),
                                                          shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          20)),
                                                          elevation: 4,
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(16.0),
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
                                                                        size:
                                                                            30),
                                                                    SizedBox(
                                                                        width: width *
                                                                            0.02),
                                                                    Text(
                                                                      "SpO₂",
                                                                      style: TextStyle(
                                                                          fontSize:
                                                                              width * 0.05),
                                                                    ),
                                                                  ],
                                                                ),
                                                                SizedBox(
                                                                    height: 8),
                                                                Stack(
                                                                  alignment:
                                                                      Alignment
                                                                          .center,
                                                                  children: [
                                                                    Center(
                                                                        child: SpO2Gauge(
                                                                            percentage: data.first.metrics['spo2'] != null
                                                                                ? (data.first.metrics['spo2'] is String ? double.parse(data.first.metrics['spo2']) : (data.first.metrics['spo2'] as num).toDouble())
                                                                                : 25.0))
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
                                    ),
                                  ),
                                );
                              },
                              error: (error, stackTrace) {
                                return Text("Error : $error");
                              },
                              loading: () {
                                return Center(
                                  child: GradientLoadingIndicator(),
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/user.png', // replace with your image path
                          width: width * 1, // adjust the width as needed
                          height: width * 1, // adjust the height as needed
                        ),
                        const SizedBox(height: 20),

                        // Add Users Button
                        GestureDetector(
                          onTap: () {
                            _showRoleDialog();
                            print("Adding users");
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: width * 0.02,
                                horizontal: width * 0.2),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                            child: const Text(
                              "Add Users",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
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
              child: GradientLoadingIndicator(),
            );
          },
        ),
      ),
    );
  }
}

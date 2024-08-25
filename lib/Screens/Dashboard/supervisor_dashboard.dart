import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:smartband/Screens/AuthScreen/phone_number.dart';
import 'package:smartband/Screens/Dashboard/wearer_dashboard.dart';
import 'package:smartband/Screens/HomeScreen/settings.dart';
import 'package:smartband/Screens/Widgets/drawer_supervisor.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart' as intl;

import '../DrawerScreens/profilepage.dart';
import '../Models/usermodel.dart';
import '../Widgets/appBarProfile.dart';
import '../Widgets/drawer.dart';
import 'package:smartband/Screens/Widgets/string_extensions.dart';
import 'dart:math';

import 'dashboard.dart';

class SupervisorDashboard extends ConsumerStatefulWidget {
  String phNo;
  SupervisorDashboard({super.key, required this.phNo});

  @override
  ConsumerState<SupervisorDashboard> createState() => _WearerDashboardState();
}

class _WearerDashboardState extends ConsumerState<SupervisorDashboard> {
  String dropdownValue = 'No Users';
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = 0;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Function to show supervisor dialog and handle OTP verification
  void _showSupervisorDialog(int otp_num) async {
    if (_phNoConn.text != widget.phNo) {
      // _otpConn.text == otp_num.toString()) {
      String phonetoCheck = _phNoConn.text;
      var usersCollection = FirebaseFirestore.instance.collection("users");
      var querySnapshot = await usersCollection
          .where('phone_number', isEqualTo: widget.phNo)
          .get();

      final docs1 = await FirebaseFirestore.instance
          .collection('users')
          .where('phone_number', isEqualTo: phonetoCheck)
          .get();
      if (docs1.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Phone Number does not exist in the collection.")));
      } else if (querySnapshot.docs.isNotEmpty) {
        await usersCollection
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .update({
          "relations": FieldValue.arrayUnion([phonetoCheck])
        });

        Navigator.of(context, rootNavigator: true).pop();
      }
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Invalid OTP")));
    }
  }

  // Function to fetch relation details where current user email is in relations array
  Future<List<Map<String, dynamic>>> _fetchRelationDetails(
      List<String> phoneNumber) async {
    List<Map<String, dynamic>> relationDetails = [];
    for (String i in phoneNumber) {
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('phone_number', isEqualTo: i)
          .get();
      if (userDoc.docs.isNotEmpty) {
        relationDetails.add(userDoc.docs.first.data());
      }
    }
    return relationDetails;
  }

  Future<List<Map<String, dynamic>>> _fetchPhoneDetails(
      String phNo, int otp_num) async {
    List<Map<String, dynamic>> relationDetails = [];
    bool madeCall = false;
    var userDoc = await FirebaseFirestore.instance
        .collection('users')
        .where('phone_number', isEqualTo: phNo)
        .get();
    if (userDoc.docs.isNotEmpty) {
      final data = userDoc.docs.first.data()['phone_number'];
      // await twilioService.sendSms('+91${data}', 'Your OTP is ${otp_num}');
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
  final TextEditingController _phNoConn = TextEditingController();
  final TextEditingController _otpConn = TextEditingController();

  String status = "";
  String subscription = "";
  bool _isSubscriptionFetched = false;

  void _showRoleDialog() {
    bool sent = false;
    int otp_num = 100000 + Random().nextInt(999999 - 100000 + 1);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Supervise an account'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _selectedRole == "supervisor"
                        ? TextFormField(
                            controller: _phNoConn,
                            decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Phone Number',
                                suffixIcon: IconButton(
                                    onPressed: () {
                                      sent = true;
                                      _fetchPhoneDetails(
                                          _phNoConn.text, otp_num);
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

  String getGreetingMessage() {
    final now = DateTime.now();
    final formattedDate =
        "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year.toString().substring(2)}";

    if (now.hour > 16) {
      return "Good Evening $formattedDate";
    } else if (now.hour > 12) {
      return "Good Afternoon $formattedDate";
    } else {
      return "Good Morning $formattedDate";
    }
  }

  final List<BottomNavigationBarItem> _bottomNavigationBarItems =
      <BottomNavigationBarItem>[
    const BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: 'Home',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.favorite_outline),
      label: 'Heartrate',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.water_drop),
      label: 'SpO2',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.history),
      label: 'History',
    ),
  ];

  Widget HeaderText(text) {
    return Text(
      "Hello ${text}",
      style: TextStyle(
        fontSize: MediaQuery.of(context).size.width * 0.050,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user_data =
        ref.watch(userModelProvider(FirebaseAuth.instance.currentUser!.uid));

    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        backgroundColor: Colors.white,
        leading: Padding(
          padding: const EdgeInsets.only(left: 5),
          child: Builder(
            builder: (context) => GestureDetector(
              onTap: () {
                Scaffold.of(context).openDrawer();
              },
              child: const Icon(Icons.menu, size: 30),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                user_data.when(data: (user) {
                  return HeaderText(user!.name);
                }, error: (Object error, StackTrace stackTrace) {
                  return HeaderText("User");
                }, loading: () {
                  return HeaderText("User");
                }),
                const Icon(Icons.keyboard_arrow_down),
              ],
            ),
            Text(
              getGreetingMessage(),
              style: TextStyle(
                fontSize: width * 0.04,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              size: 30,
            ),
            onPressed: () {
              _showRoleDialog();
            },
            tooltip: 'Add User',
          ),
          GestureDetector(
            onTap: () async {
              Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(builder: (context) => const Profilepage()));
            },
            child: const Padding(
              padding: EdgeInsets.only(right: 10),
              child: const Icon(
                Icons.account_circle_outlined,
                size: 30,
              ),
            ),
          ),
        ],
      ),
      drawer: DrawerScreen(
          device: null, phNo: widget.phNo, status: "", subscription: ""),
      body: user_data.when(
        data: (user) {
          Map<String, dynamic> relation = {};
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchRelationDetails(user?.relations ?? []),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                    child: CircularProgressIndicator(color: Colors.blueAccent));
              } else if (snapshot.hasError) {
                return Center(child: Text("Error fetching relation details"));
              } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                List<Map<String, dynamic>> relationDetails = snapshot.data!;
                if (dropdownValue == 'No Users') {
                  dropdownValue =
                      relationDetails.first['phone_number'].toString();
                  relation = relationDetails.first;
                }
                print("DropDown : ${dropdownValue}");
                if (!_isSubscriptionFetched) {
                  fetchSubscription(dropdownValue);
                }
                return Column(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.1,
                      width: MediaQuery.of(context).size.width * 0.95,
                      child: Center(
                        child: Row(
                          children: [
                            Expanded(
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
                                      value:
                                          relation['phone_number'].toString(),
                                      child: Padding(
                                        padding: const EdgeInsets.all(5),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            color: const Color.fromRGBO(
                                                    0, 83, 188, 1)
                                                .withOpacity(0.5),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(10),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                const CircleAvatar(
                                                  radius: 30.0,
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  child: Icon(
                                                    Icons
                                                        .account_circle_outlined,
                                                    size: 35,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                Text(
                                                  relation['name'],
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.05,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const Icon(
                                                  Icons.stacked_line_chart,
                                                  size: 50,
                                                  color: Colors.white,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ).toList(),
                              ),
                            ),
                          ],
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
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 0),
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
                                            width: width * 0.9,
                                            height: height * 0.17,
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
                                                0.9,
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.17,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                              // Rounded corners
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color.fromRGBO(
                                                      0, 83, 188, 0.8),
                                                  Color.fromRGBO(0, 0, 0, 0.15),
                                                  Color.fromRGBO(
                                                      0, 83, 188, 0.8),
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
                                                      fontSize: width * 0.06,
                                                      color: Colors.white),
                                                ),
                                                const SizedBox(
                                                  height: 5,
                                                ),
                                                Text(
                                                  "Current Location ID :\n${data!.first.latitude}°N ${data!.first.longitude}°E",
                                                  style: TextStyle(
                                                      fontSize: width * 0.035,
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
                                                    padding:
                                                        EdgeInsets.all(5.0),
                                                    decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10.0),
                                                        color: Colors.white),
                                                    child: Text(
                                                      "Open in Maps",
                                                      style: TextStyle(
                                                        fontSize: width * 0.035,
                                                        color: const Color
                                                            .fromRGBO(
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
                                        height: 16,
                                      ),
                                      Center(
                                        child: Container(
                                          height: height * 0.07,
                                          width: width * 0.9,
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20.0),
                                              color: Colors.black),
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 8.0,
                                                vertical: height * 0.01),
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
                                                            color: Colors.white,
                                                            fontSize:
                                                                width * 0.045),
                                                      ),
                                                      Text(
                                                        status.toTitleCase(),
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize:
                                                                width * 0.03),
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
                                                            color: Colors.white,
                                                            fontSize:
                                                                width * 0.045),
                                                      ),
                                                      Text(
                                                        subscription,
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize:
                                                                width * 0.03),
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
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: width * 0.475,
                                              height: height * 0.45,
                                              child: Column(
                                                children: [
                                                  Expanded(
                                                      flex: 2,
                                                      child: Card(
                                                        color: Color.fromRGBO(
                                                            255, 245, 227, 1),
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
                                                                    "assets/fall_axis_icon.png",
                                                                    width: 30,
                                                                  ),
                                                                  SizedBox(
                                                                      width: width *
                                                                          0.02),
                                                                  Text(
                                                                    "Fall Detection",
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            width *
                                                                                0.04),
                                                                  ),
                                                                ],
                                                              ),
                                                              Center(
                                                                child:
                                                                    Image.asset(
                                                                  data.first.metrics[
                                                                              'fall_axis'] ==
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
                                                                  vertical: 5.0,
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
                                                                      size: 25),
                                                                  SizedBox(
                                                                      width: width *
                                                                          0.01),
                                                                  Text(
                                                                      'Emergency',
                                                                      style: TextStyle(
                                                                          fontSize:
                                                                              width * 0.04)),
                                                                ],
                                                              ),
                                                              Stack(
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                children: [
                                                                  Container(
                                                                    width:
                                                                        width *
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
                                                                          color: Colors
                                                                              .redAccent,
                                                                          width:
                                                                              10.0),
                                                                    ),
                                                                  ),
                                                                  Container(
                                                                    width:
                                                                        width *
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
                                              width: width * 0.475,
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
                                                                  Image.asset(
                                                                    "assets/heart_rate_icon.png",
                                                                    width: 30,
                                                                  ),
                                                                  SizedBox(
                                                                      width: width *
                                                                          0.02),
                                                                  Text(
                                                                    "Heart Rate",
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            width *
                                                                                0.045),
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
                                                                    height: 10,
                                                                  ),
                                                                  Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .center,
                                                                    children: [
                                                                      Text(
                                                                        data.first
                                                                            .metrics['heart_rate'],
                                                                        style: TextStyle(
                                                                            fontSize: width *
                                                                                0.07,
                                                                            fontWeight:
                                                                                FontWeight.bold),
                                                                      ),
                                                                      Text(
                                                                        " bpm",
                                                                        style: TextStyle(
                                                                            fontSize: width *
                                                                                0.03,
                                                                            fontWeight:
                                                                                FontWeight.bold),
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
                                                            237, 255, 228, 1),
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
                                                                  Image.asset(
                                                                      "assets/spo2_icon.png"),
                                                                  SizedBox(
                                                                      width: width *
                                                                          0.02),
                                                                  Text(
                                                                    "SpO₂",
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            width *
                                                                                0.04),
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
                                                                          percentage: data.first.metrics['spo2'] != "--"
                                                                              ? int.parse(data.first.metrics['spo2'].toString())
                                                                              : 1))
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
                                      SizedBox(
                                        height: 16,
                                      ),
                                      // Center(
                                      //   child: GestureDetector(
                                      //     onTap: () {
                                      //       _showRoleDialog();
                                      //       print("Adding users");
                                      //     },
                                      //     child: Padding(
                                      //       padding: EdgeInsets.symmetric(
                                      //           vertical: 10.0),
                                      //       child: const Text(
                                      //         "Add users",
                                      //         style: TextStyle(fontSize: 18),
                                      //       ),
                                      //     ),
                                      //   ),
                                      // )
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
      // bottomNavigationBar: BottomNavigationBar(
      //   backgroundColor: Colors.white,
      //   items: _bottomNavigationBarItems,
      //   currentIndex: _selectedIndex,
      //   selectedItemColor: Colors.black,
      //   showUnselectedLabels: false,
      //   onTap: _onItemTapped,
      //   type: BottomNavigationBarType.fixed,
      // ),
    );
  }
}

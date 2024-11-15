// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smartband/Providers/OwnerDeviceData.dart';
import 'package:smartband/Screens/AuthScreen/role_screen.dart';
import 'package:smartband/Screens/Dashboard/supervisor_dashboard.dart';
import 'package:smartband/Screens/Dashboard/wearer_dashboard.dart';
import 'package:smartband/Screens/HomeScreen/heart_rate.dart';
import 'package:smartband/Screens/HomeScreen/history_screen.dart';
import 'package:smartband/Screens/HomeScreen/settings.dart';
import 'package:smartband/Screens/HomeScreen/spo2.dart';
import 'package:smartband/Screens/Models/usermodel.dart';
import 'package:smartband/Screens/Widgets/drawer.dart';
import 'package:smartband/pushnotifications.dart';
import 'package:provider/provider.dart' as provider;

class DashboardScreen extends ConsumerStatefulWidget {
  final String? device_name;
  final String mac_address;
  final BluetoothDevice device;
  final String phNo;
  final String subscription;
  final String status;

  const DashboardScreen(this.phNo,
      {super.key,
      required this.device_name,
      required this.mac_address,
      required this.device,
      required this.subscription,
      required this.status});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = 0;
  }

  String? user;

  @override
  Widget build(BuildContext context) {
    final userData =
        ref.watch(userModelProvider(FirebaseAuth.instance.currentUser!.uid));
    // int index = 0;

    return userData.when(
      data: (data) {
        setState(() {
          user = data?.role;
        });
        List<Widget> _widgetOptions = <Widget>[
          WearerDashboard(
            device: widget.device,
            phNo: data!.phone_number.toString(),
          ),
          HeartrateScreen(
            device: widget.device,
            phNo: data.phone_number.toString(),
          ),
          Spo2Screen(
            device: widget.device,
            phNo: data.phone_number.toString(),
          ),
          HistoryScreen(
            device: widget.device,
            phNo: data.phone_number.toString(),
          ),
        ];

        List<BottomNavigationBarItem> _bottomNavigationBarItems =
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
            icon: Icon(Icons.water_drop_outlined),
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

        return user == "watch wearer"
            ? Scaffold(
                drawer: DrawerScreen(
                    device: bluetoothDeviceManager.connectedDevices.first,
                    phNo: widget.phNo,
                    subscription: widget.subscription,
                    status: widget.status),
                appBar: AppBar(
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
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    // Adjust this to fit content
                    children: [
                      // Profile Picture
                      // GestureDetector(
                      //   onTap: () {
                      //     Scaffold.of(context).openDrawer();
                      //   },
                      //   child: Container(
                      //     margin: EdgeInsets.all(10.0),
                      //     child: CircleAvatar(
                      //       radius: 20,
                      //       backgroundImage: NetworkImage(
                      //         FirebaseAuth.instance.currentUser!.photoURL ??
                      //             "https://t4.ftcdn.net/jpg/03/26/98/51/360_F_326985142_1aaKcEjMQW6ULp6oI9MYuv8lN9f8sFmj.jpg",
                      //       ),
                      //     ),
                      //   ),
                      // ),
                      // SizedBox(width: 3),
                      // Spacing between profile picture and text
                      // Greeting Message
                      Expanded(
                        // Use Expanded to take up remaining space
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                userData.when(data: (user) {
                                  return HeaderText(user!.name);
                                }, error:
                                    (Object error, StackTrace stackTrace) {
                                  return HeaderText("User");
                                }, loading: () {
                                  return HeaderText("User");
                                }),
                                // const Icon(Icons.keyboard_arrow_down)
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
                                fontSize:
                                    MediaQuery.of(context).size.width * 0.04,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          // GestureDetector(
                          //   child: Image.asset(
                          //     "assets/profile_icon.png",
                          //     width: 25,
                          //     height: 25,
                          //   ),
                          //   onTap: () {
                          //     Navigator.of(context).push(MaterialPageRoute(
                          //         builder: (context) =>
                          //             HomePage(phNo: widget.phNo)));
                          //   },
                          // ),
                          const SizedBox(
                            width: 10,
                          ),
                          const Icon(
                            Icons.notifications,
                            size: 25,
                          )
                        ],
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.01,
                      )
                    ],
                  ),
                ),
                body: Center(
                  child: _widgetOptions.elementAt(_selectedIndex),
                ),
                bottomNavigationBar: BottomNavigationBar(
                  backgroundColor: Colors.white,
                  items: _bottomNavigationBarItems,
                  currentIndex: _selectedIndex,
                  selectedItemColor: Colors.black,
                  showUnselectedLabels: false,
                  onTap: _onItemTapped,
                  type: BottomNavigationBarType.fixed,
                ),
              )
            : Scaffold(
                body: SupervisorDashboard(
                  phNo: data!.phone_number.toString(),
                ),
              );
      },
      error: (error, StackTrace) => const SizedBox(),
      loading: () => const SizedBox(),
    );
  }
}

class EmergencyCard extends StatefulWidget {
  final List<String> relations;
  final UserModel user;
  bool sosClicked = false;
  List<String> values;

  EmergencyCard(
      {super.key,
      required this.relations,
      required this.user,
      required this.sosClicked,
      required this.values});

  @override
  State<EmergencyCard> createState() => _EmergencyCardState();
}

class _EmergencyCardState extends State<EmergencyCard> {
  bool _isEmergency = false;
  @override
  void didUpdateWidget(covariant EmergencyCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if sosClicked value has changed
    if (widget.sosClicked != oldWidget.sosClicked && widget.sosClicked) {
      _handleSOSClick(true);
    }
  }

  Future<void> _handleSOSClick(bool sosClicked) async {
    final deviceOwnerData =
        provider.Provider.of<OwnerDeviceData>(context, listen: false);
    setState(() {
      _isEmergency = true;
    });
    for (var attempt = 1; attempt <= 3; attempt++) {
      if (!_isEmergency) {
        break;
      }
      print("Attempt ");
      print(attempt);
      // Position location = await updateLocation();
      try {
        if (FirebaseAuth.instance.currentUser!.uid.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection("users")
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .update({
            "metrics": {
              "spo2": deviceOwnerData.spo2,
              "heart_rate": deviceOwnerData.heartRate,
              "fall_axis": "-- -- --"
            }
          });
        }
        final data = await FirebaseFirestore.instance
            .collection("users")
            .where('phone_number',
                isEqualTo: widget.user.phone_number.toString())
            .get();
        Position location = await updateLocation();
        SendNotification send = SendNotification();
        for (QueryDocumentSnapshot<Map<String, dynamic>> i in data.docs) {
          print(i);
          if (!_isEmergency) {
            break;
          }
          print("Sending");
          print("Email : ${i.data()['email']}"); // Fixed by adding null check
          print("Inside SOS Click");

          Map<String, Map<String, dynamic>> supervisors =
              Map<String, Map<String, dynamic>>.from(i.data()['supervisors']);
          var filteredSupervisors = supervisors.entries
              .where((entry) => entry.value['status'] == 'active')
              .toList()
            ..sort((a, b) => int.parse(b.value['priority'].toString())
                .compareTo(int.parse(a.value['priority'].toString())));

          for (var supervisor in filteredSupervisors) {
            if (!_isEmergency) {
              break;
            }
            final sup = await FirebaseFirestore.instance
                .collection("users")
                .where('phone_number', isEqualTo: supervisor.key)
                .get();
            await FirebaseFirestore.instance
                .collection("emergency_alerts")
                .doc(sup.docs.first.id)
                .set({
              "isEmergency": true,
              "responseStatus": false,
              "response": "",
              "phone_number": supervisor.key,
              "userUid": FirebaseAuth.instance.currentUser?.uid,
              "heartbeatRate": deviceOwnerData.heartRate,
              "location": "0°N 0°E",
              "spo2": deviceOwnerData.spo2,
              "fallDetection": false,
              "isManual": true,
              "timestamp": FieldValue.serverTimestamp()
            }, SetOptions(merge: true));

            await FirebaseFirestore.instance
                .collection("emergency_alerts")
                .doc(sup.docs.first.id)
                .collection(sup.docs.first.id)
                .add({
              "isEmergency": true,
              "responseStatus": false,
              "response": "",
              "heartbeatRate": deviceOwnerData.heartRate,
              "location": "0°N 0°E",
              "spo2": deviceOwnerData.spo2,
              "fallDetection": false,
              "isManual": true,
              "timestamp": FieldValue.serverTimestamp()
            });
            String responderName =
                i.data()['name'] ?? "User"; // Fixed by adding null check
            send.sendNotification(supervisor.key, "Emergency!!",
                "$responderName has clicked the SOS Button from ${location.latitude}°N ${location.longitude}°E. Please respond");

            print(
                "Message sent to supervisor with phone number: ${supervisor.key} and priority: ${supervisor.value}");

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Sent Alert to ${supervisor.key}")),
            );
            await Future.delayed(Duration(seconds: 30));
            FirebaseFirestore.instance
                .collection("emergency_alerts")
                .doc(sup.docs.first.id)
                .snapshots()
                .listen((DocumentSnapshot doc) {
              if (doc.exists && doc["responseStatus"] == true) {
                setState(() {
                  _isEmergency = false;
                });
                FirebaseFirestore.instance
                    .collection("users")
                    .where('phone_number', isEqualTo: supervisor.key)
                    .get()
                    .then((QuerySnapshot snapshot) {
                  Map<String, dynamic> data =
                      snapshot.docs.first.data() as Map<String, dynamic>;
                  String responder = data['name'] ?? "User";
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("$responder Responded"),
                    ),
                  );
                });
              }
            });
          }
        }

        if (attempt == 3) {
          setState(() {
            _isEmergency = false;
          });
        }
      } catch (e) {
        print("Exception ${e}");
      }
    }
  }

  Future<Position> updateLocation() async {
    Position location = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    print("Fetched Location");

    final user = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .update({"location": GeoPoint(location.latitude, location.longitude)});
    return location;
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Card(
      color: const Color.fromRGBO(255, 234, 234, 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 15.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, size: 25),
                SizedBox(width: width * 0.01),
                Text('Emergency', style: TextStyle(fontSize: width * 0.05)),
              ],
            ),
            InkWell(
              onTap: () async {
                _handleSOSClick(widget.sosClicked);
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: width * 0.25,
                    height: width * 0.25,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(width * 0.5),
                      color:
                          widget.sosClicked ? Colors.redAccent : Colors.white,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.redAccent,
                          blurRadius: 5.0,
                        ),
                      ],
                      border: Border.all(color: Colors.redAccent, width: 10.0),
                    ),
                  ),
                  Container(
                    width: width * 0.15,
                    height: width * 0.15,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(width * 0.5),
                      color: Colors.black26,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.redAccent,
                          blurRadius: 5.0,
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    "SOS",
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

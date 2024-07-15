import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smartband/Screens/Dashboard/supervisor_dashboard.dart';
import 'package:smartband/Screens/Dashboard/wearer_dashboard.dart';
import 'package:smartband/Screens/DrawerScreens/emergencycard.dart';
import 'package:smartband/Screens/HomeScreen/settings.dart';
import 'package:smartband/Screens/Models/usermodel.dart';

import '../Models/twilio_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  String device_name;
  String mac_address;
  DashboardScreen({Key? key, required this.device_name, required this.mac_address}) : super(key: key);

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
  Widget build(BuildContext context) {
    final userData = ref.watch(userModelProvider(FirebaseAuth.instance.currentUser!.uid));

    return userData.when(data: (data) {
      String? user = data?.role;
      List<Widget> _widgetOptions = user == "watch wearer"
          ? <Widget>[
        const WearerDashboard(),
        const SupervisorDashboard(),
        const Emergencycard(),
        Settingscreen(device_name: widget.device_name, mac_address: widget.mac_address,),
      ]
          : <Widget>[
        const SupervisorDashboard(),
      ];

      List<BottomNavigationBarItem> _bottomNavigationBarItems = user == "watch wearer"
          ? <BottomNavigationBarItem>[
        const BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.add_box_outlined),
          label: 'Health',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.highlight),
          label: 'Emergency',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings', // Label for the new page
        ),
      ]
          : <BottomNavigationBarItem>[
        const BottomNavigationBarItem(
          icon: Icon(Icons.add_box_outlined),
          label: 'Health',
        ),
      ];

      return Scaffold(
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
      );
    }, error: (error, StackTrace) {
      return SizedBox();
    }, loading: () {
      return SizedBox();
    });
  }

}

class InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final String subtitle;

  InfoCard(
      {required this.title,
      required this.value,
      required this.icon,
      required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Card(
      color: Colors.white54.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 30),
                SizedBox(width: width * 0.02),
                Text(
                  title,
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Text(
                  value,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  width: width * 0.02,
                ),
                Text(subtitle),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class EmergencyCard extends StatefulWidget {
  List<String> relations;
  String user;
  EmergencyCard({super.key, required this.relations, required this.user});

  @override
  State<EmergencyCard> createState() => _EmergencyCardState();
}

class _EmergencyCardState extends State<EmergencyCard> {
  Future<Position> updateLocation() async {
    Position location = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    print("Fetched Location");

    final user = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .update({"location": GeoPoint(location.latitude, location.longitude)});
    return location;
  }

  final TwilioService twilioService = TwilioService(
    accountSid: 'ACf1f0c0870c825a03dc6db124b365cf6a',
    authToken: 'fa856967b5f8bc971b3b783197c3ce33',
    fromNumber: '+17628009114',
  );

  Future<List<Map<String, dynamic>>> _fetchRelationDetails(List<String> relations, String user_email) async {
    List<Map<String, dynamic>> relationDetails = [];
    bool madeCall = false;
    for (String email in relations) {
      User? user = FirebaseAuth.instance.currentUser;
      var userDoc = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: email).get();
      if (userDoc.docs.isNotEmpty) {
        FirebaseFirestore.instance
            .collection("users")
            .doc(user!.uid)
            .update({"isSOSClicked": true});

        final data = userDoc.docs.first.data()['phone_number'];
        Position current = await updateLocation();

        await twilioService.sendSms('+91${data}', 'SOS Button Clicked by ${user_email} from ${current.latitude}°N ${current.longitude}°E');
        if (!madeCall)
          {
            await twilioService.makeCall(
              '+91$data',
              "<Response><Say>$user_email has clicked the SOS button. Please check out.</Say></Response>",
            );
            madeCall = !madeCall;
          }

        Future.delayed(Duration(seconds: 5), () {
          FirebaseFirestore.instance
              .collection("users")
              .doc(user!.uid)
              .update({"isSOSClicked": false});
        });
      }
    }
    return relationDetails;
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Card(
      color: Colors.white54.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Row(
              children: [
                Icon(Icons.error, size: 25),
                SizedBox(width: width * 0.01),
                Text('Emergency', style: TextStyle(fontSize: 20)),
              ],
            ),
            InkWell(
              onTap: () async {
                _fetchRelationDetails(widget.relations, widget.user);
                // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                //     content: Text(
                //         "Location Updated to ${current.latitude}°N, ${current.longitude}°E")));

              },
              child: Stack(alignment: Alignment.center, children: [
                Container(
                  width: width * 0.3,
                  height: width * 0.3,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(width * 0.5),
                      color: Colors.white70,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.grey,
                          blurRadius: 5.0,
                        ),
                      ],
                      border: Border.all(color: Colors.grey, width: 10.0)),
                ),
                Container(
                  width: width * 0.15,
                  height: width * 0.15,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(width * 0.5),
                    color: Colors.black26,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.grey,
                        blurRadius: 5.0,
                      ),
                    ],
                  ),
                ),
                Text(
                  "SOS",
                  style: TextStyle(color: Colors.white, fontSize: 20),
                )
              ]),
            )
          ],
        ),
      ),
    );
  }
}

class FactCard extends StatelessWidget {
  final String fact;

  FactCard({required this.fact});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white54.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          fact,
          textAlign: TextAlign.left,
        ),
      ),
    );
  }
}
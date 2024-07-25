import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smartband/Screens/Dashboard/supervisor_dashboard.dart';
import 'package:smartband/Screens/Dashboard/supervisor_wearer.dart';
import 'package:smartband/Screens/Dashboard/wearer_dashboard.dart';
import 'package:smartband/Screens/DrawerScreens/emergencycard.dart';
import 'package:smartband/Screens/HomeScreen/settings.dart';
import 'package:smartband/Screens/Models/usermodel.dart';
import 'package:smartband/pushnotifications.dart';
import '../Models/twilio_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final String device_name;
  final String mac_address;
  final BluetoothDevice device;

  DashboardScreen({
    Key? key,
    required this.device_name,
    required this.mac_address,
    required this.device,
  }) : super(key: key);

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

  String? user;

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userModelProvider(FirebaseAuth.instance.currentUser!.uid));

    return userData.when(
      data: (data) {
        setState(() {
          user = data?.role;
        });
        List<Widget> _widgetOptions = <Widget>[
          WearerDashboard(device: widget.device),
          const SupervisorWearer(),
          const Emergencycard(),
          Settingscreen(device_name: widget.device_name, mac_address: widget.mac_address),
        ];

        List<BottomNavigationBarItem> _bottomNavigationBarItems = <BottomNavigationBarItem>[
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
            label: 'Settings',
          ),
        ];

        print(user);

        return user == "watch wearer"
            ? Scaffold(
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
            : const Scaffold(
          body: SupervisorDashboard(),
        );
      },
      error: (error, StackTrace) => SizedBox(),
      loading: () => SizedBox(),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final String subtitle;

  InfoCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.subtitle,
  });

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
                  style: TextStyle(fontSize: width * 0.05),
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
                SizedBox(width: width * 0.02),
                Text(subtitle),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class EmergencyCard extends StatefulWidget {
  final List<String> relations;
  final String user;
  bool sosClicked = false;

  EmergencyCard({
    super.key,
    required this.relations,
    required this.user,
    required this.sosClicked,
  });

  @override
  State<EmergencyCard> createState() => _EmergencyCardState();
}

class _EmergencyCardState extends State<EmergencyCard> {
  final TwilioService twilioService = TwilioService(
    accountSid: 'ACf1f0c0870c825a03dc6db124b365cf6a',
    authToken: 'fa856967b5f8bc971b3b783197c3ce33',
    fromNumber: '+17628009114',
  );

  @override
  void didUpdateWidget(covariant EmergencyCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if sosClicked value has changed
    if (widget.sosClicked != oldWidget.sosClicked && widget.sosClicked) {
      _handleSOSClick(true);
    }
  }

  Future<void> _handleSOSClick(bool sosClicked) async {
    Position location = await updateLocation();


    try
    {
      final data = await FirebaseFirestore.instance.collection("users").where('relations', arrayContains: FirebaseAuth.instance.currentUser!.email).get();
      SendNotification send = SendNotification();
      for(QueryDocumentSnapshot<Map<String, dynamic>> i in data.docs)
      {
        print("Email : ${i.data()['email']}");
        // String? email = await FirebaseAuth.instance.currentUser!.email;
        send.sendNotification(i.data()['email'], "Emergency!!", "User has clicked SOS Button from ${location.latitude}°N ${location.longitude}°E. Please respond");
        print("Message sent");
      }
    }
    catch(e)
    {
      print("Exception ${e}");
    }

    // Notify user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("SOS alert sent to supervisors")),
    );
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

  Future<void> _fetchRelationDetails(List<String> relations, String user_email) async {
    bool madeCall = false;
    for (String email in relations) {
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userDoc.docs.isNotEmpty) {
        print(userDoc.docs.first.data());

        final data = userDoc.docs.first.data()['phone_number'];
        Position current = await updateLocation();

        await twilioService.sendSms(
          '+91$data',
          'SOS Button Clicked by $user_email from ${current.latitude}°N ${current.longitude}°E',
        );

        if (!madeCall) {
          await twilioService.makeCall(
            '+91$data',
            "<Response><Say>$user_email has clicked the SOS button. Please check out.</Say></Response>",
          );
          madeCall = true;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Card(
      color: Color.fromRGBO(255, 100, 100, 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Row(
              children: [
                Icon(Icons.warning, size: 25),
                SizedBox(width: width * 0.01),
                Text('Emergency', style: TextStyle(fontSize: 20)),
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
                      color: widget.sosClicked ? Colors.redAccent : Colors.white,
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
                  Text(
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

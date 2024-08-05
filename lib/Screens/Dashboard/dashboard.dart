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
import 'package:smartband/Screens/HomeScreen/heart_rate.dart';
import 'package:smartband/Screens/HomeScreen/history_screen.dart';
import 'package:smartband/Screens/HomeScreen/settings.dart';
import 'package:smartband/Screens/HomeScreen/spo2.dart';
import 'package:smartband/Screens/Models/usermodel.dart';
import 'package:smartband/Screens/Widgets/coming_soon.dart';
import 'package:smartband/pushnotifications.dart';


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

  @override
  void initState() {
    super.initState();
    _selectedIndex = 0;
  }

  String? user;

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(userModelProvider(FirebaseAuth.instance.currentUser!.uid));
    int index = 0;

    return userData.when(
      data: (data) {
        setState(() {
          user = data?.role;
        });
        List<Widget> _widgetOptions = <Widget>[
          WearerDashboard(device: widget.device, phNo: data!.phone_number.toString(),),
          HeartrateScreen(device: widget.device, phNo: data.phone_number.toString(),),
          Spo2Screen(device: widget.device, phNo: data.phone_number.toString(),),
          HistoryScreen(device: widget.device, phNo: data.phone_number.toString(),),
        ];

        List<BottomNavigationBarItem> _bottomNavigationBarItems = <BottomNavigationBarItem>[
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
            : Scaffold(
          body: SupervisorDashboard(phNo: data!.phone_number.toString(),),
        );
      },
      error: (error, StackTrace) => SizedBox(),
      loading: () => SizedBox(),
    );
  }
}

class EmergencyCard extends StatefulWidget {
  final List<String> relations;
  final UserModel user;
  bool sosClicked = false;
  List<String> values;

  EmergencyCard({
    super.key,
    required this.relations,
    required this.user,
    required this.sosClicked,
    required this.values
  });

  @override
  State<EmergencyCard> createState() => _EmergencyCardState();
}

class _EmergencyCardState extends State<EmergencyCard> {
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
      if (FirebaseAuth.instance.currentUser!.uid.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .update({
          "metrics": {
            "spo2": widget.values[1],
            "heart_rate": widget.values[0],
            "fall_axis":
            "-- -- --"
          }
        });
      }
      final data = await FirebaseFirestore.instance.collection("users").where('relations', arrayContains: widget.user.phone_number.toString()).get();
      SendNotification send = SendNotification();
      for(QueryDocumentSnapshot<Map<String, dynamic>> i in data.docs)
      {
        print("Sending");
        // await Future.delayed(Duration(seconds: 5), (){});
        print("Email : ${i.data()['email']}");
        // String? email = await FirebaseAuth.instance.currentUser!.email;
        send.sendNotification(i.data()['phone_number'].toString(), "Emergency!!", "${widget.user.name} has clicked SOS Button from ${location.latitude}°N ${location.longitude}°E. Please respond");
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

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Card(
        color: Color.fromRGBO(255, 234, 234, 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 15.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Row(
              children: [
                Icon(Icons.warning, size: 25),
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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smartband/Screens/Dashboard/wearer_dashboard.dart';
import 'package:smartband/Screens/Models/usermodel.dart';
import 'package:smartband/Screens/Widgets/appBarProfile.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final user_data = ref.watch(userModelProvider);

    return WearerDashboard();
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final String subtitle;

  InfoCard({required this.title, required this.value, required this.icon, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Card(
      color: Colors.white24.withOpacity(0.2),
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
                SizedBox(width: width * 0.02,),
                Text(subtitle),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class EmergencyCard extends StatelessWidget {
  Future<Position> updateLocation()
  async {
    Position location = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    print("Fetched Location");

    final user = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance.collection("users").doc(user!.uid).update({
      "location" : GeoPoint(location.latitude , location.longitude)
    });
    return location;
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Card(
      color: Colors.white24.withOpacity(0.2),
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
                Position current = await updateLocation();
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Location Updated to ${current.latitude}°N, ${current.longitude}°E")));
              },
              child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: width * 0.3,
                      height: width * 0.3,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(width * 0.5),
                          color: Colors.white70,
                          boxShadow: const [BoxShadow(
                            color: Colors.grey,
                            blurRadius: 5.0,
                          ),],
                          border: Border.all(color: Colors.grey, width: 10.0)
                      ),
                    ),
                    Container(
                      width: width * 0.15,
                      height: width * 0.15,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(width * 0.5),
                        color: Colors.black26,
                        boxShadow: const [BoxShadow(
                          color: Colors.grey,
                          blurRadius: 5.0,
                        ),],
                      ),
                    ),
                    Text(
                      "SOS",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20
                      ),
                    )
                  ]
              ),
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
      color: Colors.white24.withOpacity(0.2),
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
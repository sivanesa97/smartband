import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppBarProfileWidget(),
      body: user_data.when(
        data: (user) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello ${user?.name}!',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Row(
                        children: [
                          Icon(Icons.info, size: 16),
                          SizedBox(width: 4),
                          Text('Last workout 2 days ago'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: MediaQuery.of(context).size.height * 0.25,
                  child: Row(
                    children: [
                      Expanded(
                        child: InfoCard(
                          title: 'Heart Rate',
                          value: '${user?.metrics["heart_rate"]}',
                          icon: Icons.favorite,
                          subtitle: 'Resting',
                        ),
                      ),
                      Expanded(
                        child: InfoCard(
                          title: 'Fall Axis',
                          value: '${user?.metrics["fall_axis"]}',
                          icon: Icons.device_hub,
                          subtitle: 'Resting',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: MediaQuery.of(context).size.height * 0.25,
                  child: Row(
                    children: [
                      Expanded(
                        child: InfoCard(
                          title: 'Steps',
                          value: '${user?.metrics["steps"]}',
                          icon: Icons.directions_walk,
                          subtitle: 'Today',
                        ),
                      ),
                      Expanded(
                        child: EmergencyCard(),
                      ),
                    ],
                  ),
                ),
                FactCard(
                  fact:
                  'Imagine going to the doctor and getting a prescription for a chocolate bar! It happened in the 1800\'s to treat tuberculosis.',
                ),
              ],
            ),
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
    );
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
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: InkWell(
        onTap: () {
          // Handle emergency SOS action here
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.error, size: 25),
                  SizedBox(width: width * 0.01),
                  Text('Emergency', style: TextStyle(fontSize: 20)),
                ],
              ),
              SizedBox(height: height * 0.035),
              Stack(
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
            ],
          ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartband/Screens/Widgets/drawer.dart';

import '../Models/usermodel.dart';
import '../Widgets/appBarProfile.dart';
import 'dashboard.dart';

class WearerDashboard extends ConsumerStatefulWidget {
  const WearerDashboard({super.key});

  @override
  ConsumerState<WearerDashboard> createState() => _WearerDashboardState();
}

class _WearerDashboardState extends ConsumerState<WearerDashboard> {
  @override
  Widget build(BuildContext context) {
    final user_data = ref.watch(userModelProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppBarProfileWidget(),
      drawer: DrawerScreen(),
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
                        'Hello \n${user?.name}!',
                        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Row(
                        children: [
                          Icon(Icons.info, size: 16),
                          SizedBox(width: 4),
                          Text('Last workout 2 days ago', style: TextStyle(fontSize: 20),),
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
                          child: EmergencyCard()
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

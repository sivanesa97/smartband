import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  final BluetoothDevice device;
  final String phNo;

  const HistoryScreen({super.key, required this.device, required this.phNo});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with TickerProviderStateMixin {
  final Query<Map<String, dynamic>> _notificationsHistory;
  final Query<Map<String, dynamic>> _emergencyAlertsHistory;
  late final TabController _tabController;

  _HistoryScreenState()
      : _notificationsHistory = FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid),
        _emergencyAlertsHistory =
            FirebaseFirestore.instance.collection('emergency_alerts');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFEBF4FF),
        title: TabBar(
          overlayColor: MaterialStateProperty.all(Colors.blue.withOpacity(0.2)),
          controller: _tabController,
          indicator: BoxDecoration(
            color: const Color.fromRGBO(0, 83, 188, 1),
            borderRadius: BorderRadius.circular(25.0),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.black,
          tabs: const <Widget>[
            Padding(padding: EdgeInsets.all(30), child: Tab(text: 'Reminders')),
            Padding(
              padding: EdgeInsets.all(25),
              child: Tab(text: 'Emergency Alerts'),
            )
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab: All
          StreamBuilder<QuerySnapshot>(
            stream: _notificationsHistory.snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.blueAccent));
              } else if (snapshot.hasError) {
                return const Center(
                    child: Text("Error Fetching Notifications"));
              } else if (snapshot.hasData) {
                var historyItems = snapshot.data!.docs.map((doc) {
                  var data = doc.data() as Map<String, dynamic>;

                  String timestampString = data['time'] as String? ?? '';
                  String date = data['date'] as String? ?? '';
                  DateTime dateTime = DateTime.now();
                  try {
                    dateTime = DateFormat("dd-MM-yyyy hh:mm a")
                        .parse("$date $timestampString");
                  } catch (e) {
                    print("Invalid date format: $timestampString");
                    dateTime = DateTime.now();
                  }

                  String title = data['title'] as String? ?? 'No Title';
                  String name = data['userName'] as String? ?? 'Unknown';
                  return [
                    title,
                    name,
                    formattedTimestamp(dateTime),
                  ];
                }).toList();
                return SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            "History",
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.05,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.7,
                          child: ListView.builder(
                            itemCount: historyItems.length,
                            itemBuilder: (context, index) {
                              return Column(
                                children: [
                                  Card(
                                    elevation: 4,
                                    shadowColor: Colors.grey.withOpacity(0.5),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 15, vertical: 15),
                                      leading: Container(
                                        margin:
                                            const EdgeInsets.only(right: 10),
                                        padding: const EdgeInsets.all(10),
                                        decoration: const BoxDecoration(
                                          color: Colors.blue,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.notification_important,
                                          color: Colors.white,
                                        ),
                                      ),
                                      title: Text(
                                        historyItems[index][0],
                                        style: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.045,
                                        ),
                                      ),
                                      subtitle: Text(
                                        "From " + historyItems[index][1],
                                        style: const TextStyle(
                                          color:
                                              Color.fromRGBO(115, 115, 115, 1),
                                        ),
                                      ),
                                      trailing: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            historyItems[index][2],
                                            style: const TextStyle(
                                              color:
                                                  Color.fromRGBO(0, 83, 188, 1),
                                            ),
                                          ),
                                          const Text(
                                            "Received",
                                            style: const TextStyle(
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                      tileColor: const Color.fromRGBO(
                                          255, 255, 255, 1),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(15.0),
                                      ),
                                      visualDensity:
                                          VisualDensity.adaptivePlatformDensity,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return const Center(child: Text("No Notifications"));
              }
            },
          ),
          // Tab: Emergency Alerts
          StreamBuilder<QuerySnapshot>(
            stream: _emergencyAlertsHistory.snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.blueAccent));
              } else if (snapshot.hasError) {
                return const Center(
                    child: Text("Error Fetching Emergency Alerts"));
              } else if (snapshot.hasData) {
                var emergencyAlertsItems = snapshot.data!.docs.map((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  DateTime dateTime = data['timestamp'].toDate();
                  // String formattedDateTime =
                  //     DateFormat('dd MMMM yyyy at hh:mm:ss a').format(dateTime);
                  // print(formattedDateTime);
                  String title = '';
                  if (data['fallDetection'] == true) {
                    title = 'Fall Detection Alert';
                  } else if (data['isEmergency'] == true) {
                    title = 'SOS Alert';
                  } else {
                    title = 'Location Alert';
                  }
                  String phoneNumber = data['phone_number'] as String? ?? '';
                  bool status = data['responseStatus'] as bool? ?? false;

                  return [
                    '', // Store document ID for later use
                    title,
                    phoneNumber,
                    dateTime,
                    status ? 'Responded' : 'Missed',
                  ];
                }).toList();
                return SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            "Emergency Alerts",
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.05,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.7,
                          child: ListView.builder(
                            itemCount: emergencyAlertsItems.length,
                            itemBuilder: (context, index) {
                              return Column(
                                children: [
                                  Card(
                                    elevation: 4,
                                    shadowColor: Colors.grey.withOpacity(0.5),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 15, vertical: 15),
                                      leading: Container(
                                        margin:
                                            const EdgeInsets.only(right: 10),
                                        padding: const EdgeInsets.all(10),
                                        decoration: const BoxDecoration(
                                          color: Colors.blue,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.notification_important,
                                          color: Colors.white,
                                        ),
                                      ),
                                      title: Text(
                                        emergencyAlertsItems[index][1]
                                            as String,
                                        style: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.045,
                                        ),
                                      ),
                                      subtitle: FutureBuilder<String>(
                                        future: _getUserNameFromFirebase(
                                            emergencyAlertsItems[index][2]
                                                as String),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const Center(
                                                child:
                                                    CircularProgressIndicator());
                                          } else if (snapshot.hasError) {
                                            return Text(
                                                'Error: ${snapshot.error}');
                                          } else if (snapshot.hasData) {
                                            return Text(
                                              "To ${snapshot.data}",
                                              style: const TextStyle(
                                                color: Color.fromRGBO(
                                                    115, 115, 115, 1),
                                              ),
                                            );
                                          }
                                          return const SizedBox.shrink();
                                        },
                                      ),
                                      trailing: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            formattedTimestamp(
                                                emergencyAlertsItems[index][3]
                                                    as DateTime),
                                            style: const TextStyle(
                                              color:
                                                  Color.fromRGBO(0, 83, 188, 1),
                                            ),
                                          ),
                                          Text(
                                            emergencyAlertsItems[index][4]
                                                as String,
                                            style: const TextStyle(
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                      tileColor: const Color.fromRGBO(
                                          255, 255, 255, 1),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(15.0),
                                      ),
                                      visualDensity:
                                          VisualDensity.adaptivePlatformDensity,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return const Center(child: Text("No Emergency Alerts"));
              }
            },
          ),
        ],
      ),
    );
  }

  Future<String> _getUserNameFromFirebase(String phoneNumber) async {
    final snapshot = await FirebaseFirestore.instance
        .collection("users")
        .where('phone_number', isEqualTo: phoneNumber)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.get('name') as String;
    } else {
      return 'Unknown';
    }
  }

  String formattedTimestamp(DateTime dateTime) {
    print(dateTime);
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return '${difference.inSeconds} seconds ago';
    }
  }
}

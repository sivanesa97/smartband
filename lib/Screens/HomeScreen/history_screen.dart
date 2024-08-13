import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  final BluetoothDevice device;
  final String phNo;

  const HistoryScreen({super.key, required this.device, required this.phNo});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with TickerProviderStateMixin {
  final CollectionReference _notificationsHistory =
      FirebaseFirestore.instance.collection('notifications_history');
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  final Map<String, Map<String, dynamic>> historyMap = {
    'water': {
      'icon': Icons.add,
      'title': "Water Reminder",
      'color': const Color.fromRGBO(0, 83, 188, 1),
    },
    'sos': {
      'icon': Icons.change_circle_outlined,
      'title': "SOS alert",
      'color': const Color.fromRGBO(171, 0, 0, 1),
    },
    'tablet': {
      'icon': Icons.medical_information_outlined,
      'title': "Tablet Reminder",
      'color': const Color.fromRGBO(255, 203, 0, 1),
    },
    'sleep': {
      'icon': Icons.star_border_sharp,
      'title': "Sleep alert",
      'color': const Color.fromRGBO(88, 164, 160, 1),
    },
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFEBF4FF),
        title: TabBar(
          overlayColor: WidgetStateProperty.all(Colors.blue.withOpacity(0.2)),
          controller: _tabController,
          indicator: BoxDecoration(
            color: const Color.fromRGBO(0, 83, 188, 1), // Active tab color
            borderRadius: BorderRadius.circular(25.0), // Rounded corners
          ),
          labelColor: Colors.white, // Text color for active tab
          unselectedLabelColor: Colors.black, // Text color for inactive tabs
          tabs: const <Widget>[
            Padding(padding: EdgeInsets.all(30), child: Tab(text: 'All')),
            Padding(
              padding: EdgeInsets.all(25),
              child: Tab(text: 'Unread'),
            ),
            Padding(
              padding: EdgeInsets.all(25),
              child: Tab(text: 'Deleted'),
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

                  Timestamp? timestamp = data['time_stamp'];
                  DateTime dateTime = timestamp?.toDate() ?? DateTime.now();

                  String type = data['type'] ?? 'unknown';
                  var mapEntry = historyMap[type] ??
                      {
                        'icon': Icons.notification_important, // Default icon
                        'title': 'Unknown Type',
                        'color': Colors.blue, // Default color
                      };
                  return [
                    doc.id, // Store document ID for later use
                    mapEntry['icon'],
                    mapEntry['title'],
                    formattedTimestamp(dateTime),
                    data['notification_status'] ?? 'Unknown Status',
                    mapEntry['color'],
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
                              return Dismissible(
                                key: Key(historyItems[index][0]), // Unique key
                                direction: DismissDirection.endToStart,
                                onDismissed: (direction) {
                                  // Update the status to 'Deleted'
                                  _notificationsHistory
                                      .doc(historyItems[index][0])
                                      .update({
                                    'notification_status': 'deleted',
                                  });
                                },
                                background: Container(
                                  padding: const EdgeInsets.only(right: 20),
                                  alignment: Alignment.centerRight,
                                  color: Colors.red,
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                child: Column(
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
                                          decoration: BoxDecoration(
                                            color: historyItems[index][5],
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            historyItems[index][1],
                                            color: Colors.white,
                                          ),
                                        ),
                                        title: Text(
                                          historyItems[index][2],
                                          style: TextStyle(
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.045,
                                          ),
                                        ),
                                        subtitle: Text(
                                          historyItems[index][3],
                                          style: const TextStyle(
                                            color: Color.fromRGBO(
                                                115, 115, 115, 1),
                                          ),
                                        ),
                                        trailing: Text(
                                          historyItems[index][4],
                                          style: const TextStyle(
                                            color:
                                                Color.fromRGBO(0, 83, 188, 1),
                                          ),
                                        ),
                                        tileColor: const Color.fromRGBO(
                                            255, 255, 255, 1),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(15.0),
                                        ),
                                        // contentPadding: const EdgeInsets.all(10),
                                        visualDensity: VisualDensity
                                            .adaptivePlatformDensity,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                  ],
                                ),
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
          //Tab Bar: Unread
          StreamBuilder<QuerySnapshot>(
            stream: _notificationsHistory
                .where('notification_status', isEqualTo: 'unread')
                .snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.blueAccent));
              } else if (snapshot.hasError) {
                return const Center(
                    child: Text("Error Fetching Notifications"));
              } else if (snapshot.hasData) {
                var deletedItems = snapshot.data!.docs.map((doc) {
                  var data = doc.data() as Map<String, dynamic>;

                  Timestamp? timestamp = data['time_stamp'];
                  DateTime dateTime = timestamp?.toDate() ?? DateTime.now();

                  String type = data['type'] ?? 'unknown';

                  var mapEntry = historyMap[type] ??
                      {
                        'icon': Icons.notification_important,
                        'title': 'Unknown Type',
                        'color': Colors.blue,
                      };

                  return [
                    doc.id,
                    mapEntry['icon'],
                    mapEntry['title'],
                    formattedTimestamp(dateTime),
                    data['notification_status'] ?? 'Unknown Status',
                    mapEntry['color'],
                  ];
                }).toList();

                return ListView.builder(
                  itemCount: deletedItems.length,
                  itemBuilder: (context, index) {
                    return Card(
                      elevation: 4,
                      color: Colors.white,
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: deletedItems[index][5],
                              shape: BoxShape.circle),
                          child: Icon(
                            deletedItems[index][1],
                            color: Colors.white,
                          ),
                        ),
                        title: Text(deletedItems[index][2]),
                        subtitle: Text(deletedItems[index][3]),
                        trailing: Text(deletedItems[index][4]),
                      ),
                    );
                  },
                );
              } else {
                return const Center(child: Text("No Deleted Notifications"));
              }
            },
          ),
          // Tab: Deleted
          StreamBuilder<QuerySnapshot>(
            stream: _notificationsHistory
                .where('notification_status', isEqualTo: 'Deleted')
                .snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.blueAccent));
              } else if (snapshot.hasError) {
                return const Center(
                    child: Text("Error Fetching Notifications"));
              } else if (snapshot.hasData) {
                var deletedItems = snapshot.data!.docs.map((doc) {
                  var data = doc.data() as Map<String, dynamic>;

                  Timestamp? timestamp = data['time_stamp'];
                  DateTime dateTime = timestamp?.toDate() ?? DateTime.now();

                  String type = data['type'] ?? 'unknown';

                  var mapEntry = historyMap[type] ??
                      {
                        'icon': Icons.notification_important,
                        'title': 'Unknown Type',
                        'color': Colors.blue,
                      };

                  return [
                    doc.id,
                    mapEntry['icon'],
                    mapEntry['title'],
                    formattedTimestamp(dateTime),
                    data['notification_status'] ?? 'Unknown Status',
                    mapEntry['color'],
                  ];
                }).toList();

                return ListView.builder(
                  itemCount: deletedItems.length,
                  itemBuilder: (context, index) {
                    return Card(
                      color: Colors.white,
                      elevation: 4,
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: deletedItems[index][5],
                              shape: BoxShape.circle),
                          child: Icon(
                            deletedItems[index][1],
                            color: Colors.white,
                          ),
                        ),
                        title: Text(deletedItems[index][2]),
                        subtitle: Text(deletedItems[index][3]),
                        trailing: Text(deletedItems[index][4]),
                      ),
                    );
                  },
                );
              } else {
                return const Center(child: Text("No Deleted Notifications"));
              }
            },
          ),
        ],
      ),
    );
  }

  String formattedTimestamp(DateTime dateTime) {
    // Implement your timestamp formatting logic here
    return "${dateTime.hour}:${dateTime.minute}";
  }
}

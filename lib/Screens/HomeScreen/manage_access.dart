import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartband/Screens/Models/messaging.dart';

import '../Models/usermodel.dart';

class ManageAccess extends ConsumerStatefulWidget {
  String phNo;

  ManageAccess({super.key, required this.phNo});

  @override
  ConsumerState<ManageAccess> createState() => _ManageAccessState();
}

class _ManageAccessState extends ConsumerState<ManageAccess> {
  String? _selectedRole = "supervisor";
  final TextEditingController _phoneConn = TextEditingController();
  final TextEditingController _otpConn = TextEditingController();
  final TextEditingController _priorityInputController =
      TextEditingController();

  void _showRoleDialog({String? phoneNumber, String? priority}) {
    bool sent = false;
    int otp_num = 100000 + Random().nextInt(999999 - 100000 + 1);

    // If editing, pre-fill the phone number and priority fields
    if (phoneNumber != null && priority != null) {
      _phoneConn.text = phoneNumber;
      _priorityInputController.text = priority;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Add/Edit Supervisor'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _phoneConn,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Phone Number',
                        suffixIcon: IconButton(
                          onPressed: () {
                            sent = true;
                            _fetchPhoneDetails(_phoneConn.text, otp_num);
                          },
                          icon: Icon(sent ? Icons.check : Icons.send),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _otpConn,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'OTP',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priorityInputController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Priority',
                      ),
                    ),
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

  void _showSupervisorDialog(int otp_num) async {
    // String phn = '+94965538193';
    if (_phoneConn.text != widget.phNo) {
      // _otpConn.text == otp_num.toString()) {
      String phonetoCheck = _phoneConn.text;
      print(phonetoCheck);
      var usersCollection = FirebaseFirestore.instance.collection("users");
      var ownerSnapshot = await usersCollection
          .where('phone_number', isEqualTo: widget.phNo)
          .get();
      if (ownerSnapshot.docs.isNotEmpty) {
        var docData = ownerSnapshot.docs.first.data();
        if (docData.containsKey('supervisors') &&
            docData['supervisors'] != null) {
          if (_priorityInputController.text.isNotEmpty &&
              int.parse(_priorityInputController.text) > 0) {
            Map<String, dynamic> supervisors =
                Map<String, dynamic>.from(docData['supervisors']);
            supervisors[phonetoCheck] = {
              'priority': _priorityInputController.text,
              'status': 'active'
            };

            await ownerSnapshot.docs.first.reference.update({
              'supervisors': supervisors,
            });
          }
        } else {
          await ownerSnapshot.docs.first.reference.set({
            'supervisors': {
              phonetoCheck: {
                'priority': _priorityInputController.text,
                'status': 'active'
              }
            }
          }, SetOptions(merge: true));
        }
      }
      var querySnapshot = await usersCollection
          .where('phone_number', isEqualTo: phonetoCheck)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        var data = querySnapshot.docs.first.data()['relations'];
        print(data);
        await querySnapshot.docs.first.reference.update({
          "relations": FieldValue.arrayUnion([widget.phNo.toString()])
        });

        Navigator.of(context, rootNavigator: true).pop();
      } else {
        // Handle email not existing case
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Phone number does not exist in the collection.")));
      }
    } else if (_phoneConn.text == widget.phNo) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a different number")));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Invalid OTP")));
    }
  }

  Stream<List<Map<String, String>>> _fetchRelationDetails(String phNo) {
    return FirebaseFirestore.instance
        .collection('users')
        .where('phone_number', isEqualTo: phNo)
        .snapshots()
        .map((QuerySnapshot query) {
      List<Map<String, String>> supervisorsList = [];
      for (var doc in query.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        if (data.containsKey('supervisors')) {
          Map<String, dynamic> supervisors =
              data['supervisors'] as Map<String, dynamic>;

          supervisorsList.addAll(supervisors.entries.map((e) {
            // Ensure all fields are present and convert to string where necessary
            String phone = e.key;
            String priority = e.value['priority']?.toString() ??
                '0'; // Default to '0' if null
            String status = e.value['status']?.toString() ??
                'inactive'; // Default to 'inactive' if null
            return {'phone': phone, 'priority': priority, 'status': status};
          }).toList());
        }
      }

      // Ensure priority is sorted correctly
      supervisorsList.sort((a, b) {
        // Convert priority to int for sorting
        int priorityA = int.tryParse(a['priority'] ?? '0') ?? 0;
        int priorityB = int.tryParse(b['priority'] ?? '0') ?? 0;
        return priorityA.compareTo(priorityB);
      });

      return supervisorsList;
    });
  }

  Future<List<Map<String, dynamic>>> _fetchPhoneDetails(
      String phone_number, int otp_num) async {
    List<Map<String, dynamic>> relationDetails = [];
    bool madeCall = false;
    var userDoc = await FirebaseFirestore.instance
        .collection('users')
        .where('phone_number', isEqualTo: phone_number)
        .get();
    if (userDoc.docs.isNotEmpty) {
      // print(userDoc.docs);
      final data = userDoc.docs.first.data()['phone_number'];

      Messaging messaging = Messaging();
      messaging.sendSMS(data, "Your OTP is $otp_num");
      // await twilioService.sendSms('+91${data}', 'Your OTP is ${otp_num}');
    }
    return relationDetails;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final userData =
        ref.watch(userModelProvider(FirebaseAuth.instance.currentUser!.uid));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
        ),
        title: Align(
          alignment: Alignment.center,
          child: Text(
            "Manage Access",
            style: TextStyle(
              fontSize: width * 0.05,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 20),
            child: Icon(
              Icons.add,
              color: Colors.white,
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(width: width * 0.6),
                  Text(
                    "Edit",
                    style: TextStyle(
                      fontSize: width * 0.04,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: width * 0.04),
                  Text(
                    "Delete",
                    style: TextStyle(
                      fontSize: width * 0.04,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(width: width * 0.04),
                  Text(
                    "Status",
                    style: TextStyle(
                      fontSize: width * 0.04,
                      color: Colors.black,
                    ),
                  )
                ],
              ),
              userData.when(
                data: (data) {
                  return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _fetchRelationDetails(widget.phNo.toString()),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator(
                          color: Color.fromRGBO(0, 83, 188, 1),
                        );
                      } else if (snapshot.hasError) {
                        return Center(child: Text("Error: ${snapshot.error}"));
                      }
                      var details = snapshot.data!;
                      return Column(
                        children: [
                          Container(
                              height: height * 0.75,
                              child: ListView.builder(
                                itemCount: details.length,
                                itemBuilder: (context, index) {
                                  final relationDetail = details[index];
                                  final phone = relationDetail['phone']!;
                                  final priority = relationDetail['priority']!;
                                  final status = relationDetail['status']!;

                                  return Container(
                                    padding: EdgeInsets.only(
                                        left: 10.0, top: 10.0, bottom: 10.0),
                                    margin: EdgeInsets.symmetric(
                                        horizontal: 15.0, vertical: 5.0),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: Colors.white,
                                          child: Icon(
                                            Icons.account_circle,
                                            color:
                                                Color.fromRGBO(0, 83, 188, 1),
                                            size: width * 0.1,
                                          ),
                                        ),
                                        SizedBox(width: width * 0.01),
                                        SizedBox(
                                          width: width * 0.4,
                                          child: Text(
                                            phone,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: width * 0.05),
                                        GestureDetector(
                                          onTap: () {
                                            _showRoleDialog(
                                              phoneNumber: phone,
                                              priority: priority,
                                            );
                                          },
                                          child: const Icon(
                                            Icons.edit,
                                            color: Colors.black,
                                          ),
                                        ),
                                        SizedBox(width: width * 0.05),
                                        GestureDetector(
                                          onTap: () async {
                                            final data = await FirebaseFirestore
                                                .instance
                                                .collection('users')
                                                // .where('phone_number',
                                                //     isEqualTo: '+94965538193')
                                                .where('phone_number',
                                                    isEqualTo: widget.phNo)
                                                .get();

                                            if (data.docs.isNotEmpty) {
                                              var docRef =
                                                  data.docs.first.reference;
                                              var docData =
                                                  data.docs.first.data();

                                              if (docData
                                                  .containsKey('supervisors')) {
                                                Map<String, dynamic>
                                                    supervisors =
                                                    Map<String, dynamic>.from(
                                                        docData['supervisors']);
                                                supervisors.remove(phone);
                                                await docRef.update({
                                                  'supervisors': supervisors,
                                                });
                                              }
                                            }
                                          },
                                          child: Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                        ),
                                        SizedBox(width: width * 0.06),
                                        Switch(
                                          value:
                                              status == 'active' ? true : false,
                                          activeColor: Colors.blue,
                                          onChanged: (bool newValue) async {
                                            setState(() {
                                              relationDetail['status'] =
                                                  newValue == true
                                                      ? 'active'
                                                      : 'inactive';
                                            });
                                            print(newValue);
                                            var usersCollection =
                                                FirebaseFirestore.instance
                                                    .collection("users");
                                            var ownerSnapshot =
                                                await usersCollection
                                                    // .where('phone_number',
                                                    //     isEqualTo:
                                                    //         '+94965538193')
                                                    .where('phone_number',
                                                        isEqualTo: widget.phNo)
                                                    .get();

                                            if (ownerSnapshot.docs.isNotEmpty) {
                                              var docData = ownerSnapshot
                                                  .docs.first
                                                  .data();
                                              if (docData
                                                  .containsKey('supervisors')) {
                                                Map<String, dynamic>
                                                    supervisors =
                                                    Map<String, dynamic>.from(
                                                        docData['supervisors']);
                                                supervisors[phone] = {
                                                  'priority': priority,
                                                  'status':
                                                      relationDetail['status']
                                                };
                                                await ownerSnapshot
                                                    .docs.first.reference
                                                    .update({
                                                  'supervisors': supervisors,
                                                });
                                              }
                                            }
                                          },
                                        ),
                                        SizedBox(width: width * 0.06),
                                        // Icon(
                                        //   Icons.toggle_on,
                                        //   color: Colors.green,
                                        //   size: width * 0.1,
                                        // ),
                                      ],
                                    ),
                                  );
                                },
                              )),
                          GestureDetector(
                            onTap: () {
                              _showRoleDialog();
                            },
                            child: Container(
                              width: width * 0.9,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              decoration: BoxDecoration(
                                  color: Color.fromRGBO(0, 83, 188, 1),
                                  borderRadius: BorderRadius.circular(30)),
                              child: Text(
                                "Add Members",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: width * 0.05),
                              ),
                            ),
                          )
                        ],
                      );
                    },
                  );
                },
                error: (error, stackTrace) {
                  return Center(child: Text("Error: $error"));
                },
                loading: () {
                  return CircularProgressIndicator(
                    color: Color.fromRGBO(0, 83, 188, 1),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

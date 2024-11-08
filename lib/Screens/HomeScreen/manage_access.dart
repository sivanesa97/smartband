import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:smartband/Screens/Models/messaging.dart';
import 'package:smartband/Screens/Widgets/loading.dart';

import '../Models/usermodel.dart';

class ManageAccess extends ConsumerStatefulWidget {
  String phNo;

  ManageAccess({super.key, required this.phNo});

  @override
  ConsumerState<ManageAccess> createState() => _ManageAccessState();
}

class _ManageAccessState extends ConsumerState<ManageAccess> {
  String? _selectedRole = "supervisor";
  String supervisorPhoneNo = "";
  final TextEditingController _phoneConn = TextEditingController();
  final TextEditingController _otpConn = TextEditingController();
  final TextEditingController _priorityInputController =
      TextEditingController();

  void _showRoleDialog(
      {String? phoneNumber, String? priority, String? status}) {
    bool sent = false;
    String activeStatus = status ?? 'active';
    int otp_num = 100000 + Random().nextInt(999999 - 100000 + 1);

    // If editing, pre-fill the phone number and priority fields
    if (phoneNumber != null && priority != null) {
      _phoneConn.text = phoneNumber.substring(3, phoneNumber.length);
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
                    IntlPhoneField(
                      initialCountryCode: 'LK',
                      controller: _phoneConn,
                      onChanged: (phone) => {
                        setState(() {
                          supervisorPhoneNo = phone.completeNumber;
                        })
                      },
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: 'Phone Number',
                        suffixIcon: IconButton(
                          onPressed: () {
                            sent = true;
                            _fetchPhoneDetails(supervisorPhoneNo, otp_num);
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
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            activeStatus == 'active' ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: activeStatus == 'active'
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          Switch(
                            value: activeStatus == 'active',
                            activeColor: Colors.blue,
                            onChanged: (bool newValue) async {
                              setState(() {
                                activeStatus = newValue ? 'active' : 'inactive';
                              });
                              print(newValue);
                            },
                          ),
                        ],
                      ),
                    )
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
                    _showSupervisorDialog(otp_num, activeStatus);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSupervisorDialog(int otp_num, String activeStatus) async {
    // String phn = '+94965538195';
    // if (_phoneConn.text != phn) {
    if (true) {
      // if (otp_num.toString() == _otpConn.text) {
      if (supervisorPhoneNo != widget.phNo) {
        // _otpConn.text == otp_num.toString()) {
        String phonetoCheck = supervisorPhoneNo;
        print(phonetoCheck);
        var usersCollection = FirebaseFirestore.instance.collection("users");
        var ownerSnapshot = await usersCollection
            .where('phone_number', isEqualTo: widget.phNo)
            // .where('role', isEqualTo: 'watch wearer')
            .get();
        // await usersCollection.where('phone_number', isEqualTo: phn).get();
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
                'status': activeStatus
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
                  'status': activeStatus
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please enter a different number")));
      }
    }
  }

  Stream<List<Map<String, String>>> _fetchRelationDetails(String phNo) {
    print(phNo);
    return FirebaseFirestore.instance
        .collection('users')
        .where('phone_number', isEqualTo: phNo)
        // .where('phone_number', isEqualTo: '+94965538195')
        .snapshots()
        .map((QuerySnapshot query) {
      List<Map<String, String>> supervisorsList = [];
      // print(query.docs.length);
      for (var doc in query.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        if (data.containsKey('supervisors')) {
          Map<String, dynamic> supervisors =
              data['supervisors'] as Map<String, dynamic>;

          supervisorsList.addAll(supervisors.entries.map((e) {
            String phone = e.key;
            String priority = e.value['priority']?.toString() ?? '0';
            String status = e.value['status']?.toString() ?? 'inactive';
            return {'phone': phone, 'priority': priority, 'status': status};
          }).toList());
        }
      }

      supervisorsList.sort((a, b) {
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
          child: const Icon(
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
          const Padding(
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
              // Row(
              //   children: [
              //     SizedBox(width: width * 0.6),
              //     Text(
              //       "Edit",
              //       style: TextStyle(
              //         fontSize: width * 0.04,
              //         color: Colors.white,
              //       ),
              //     ),
              //     SizedBox(width: width * 0.04),
              //     Text(
              //       "Delete",
              //       style: TextStyle(
              //         fontSize: width * 0.04,
              //         color: Colors.black,
              //       ),
              //     ),
              //     SizedBox(width: width * 0.04),
              //     Text(
              //       "Status",
              //       style: TextStyle(
              //         fontSize: width * 0.04,
              //         color: Colors.black,
              //       ),
              //     )
              //   ],
              // ),
              userData.when(
                data: (data) {
                  return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _fetchRelationDetails(widget.phNo.toString()),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: GradientLoadingIndicator());
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
                                  String userName = '';

                                  // Assuming there's a function to fetch user details from Firebase
                                  // This is a placeholder for the actual implementation
                                  // fetchUserDetails(phone).then((value) {
                                  //   setState(() {
                                  //     userName =
                                  //         value['name'] ?? 'Unknown User';
                                  //   });
                                  // });

                                  return Container(
                                    padding: const EdgeInsets.only(
                                        left: 10.0, top: 10.0, bottom: 10.0),
                                    margin: const EdgeInsets.symmetric(
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
                                            color: const Color.fromRGBO(
                                                0, 83, 188, 1),
                                            size: width * 0.1,
                                          ),
                                        ),
                                        SizedBox(width: width * 0.1),
                                        SizedBox(
                                          width: width * 0.45,
                                          child: Text(
                                            phone,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: width * 0.05),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              supervisorPhoneNo = phone;
                                            });
                                            _showRoleDialog(
                                              phoneNumber: phone,
                                              priority: priority,
                                              status: status,
                                            );
                                          },
                                          child: const Icon(
                                            Icons.edit,
                                            color: Colors.black,
                                          ),
                                        ),
                                        SizedBox(width: width * 0.05),
                                        GestureDetector(
                                          onTap: () {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: const Text(
                                                    "Are You Sure!",
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  content: const Text(
                                                      "you want to Delete this member?"),
                                                  actions: [
                                                    OutlinedButton(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                      style: OutlinedButton
                                                          .styleFrom(
                                                        side: const BorderSide(
                                                            color: Colors.blue),
                                                      ),
                                                      child: const Text(
                                                        "Cancel",
                                                        style: TextStyle(
                                                            color: Colors.blue),
                                                      ),
                                                    ),
                                                    // Delete Button
                                                    OutlinedButton(
                                                      onPressed: () async {
                                                        final data =
                                                            await FirebaseFirestore
                                                                .instance
                                                                .collection(
                                                                    'users')
                                                                .where(
                                                                    'phone_number',
                                                                    isEqualTo:
                                                                        widget
                                                                            .phNo)
                                                                .get();

                                                        if (data
                                                            .docs.isNotEmpty) {
                                                          var docRef = data.docs
                                                              .first.reference;
                                                          var docData = data
                                                              .docs.first
                                                              .data();

                                                          if (docData.containsKey(
                                                              'supervisors')) {
                                                            Map<String, dynamic>
                                                                supervisors =
                                                                Map<String,
                                                                        dynamic>.from(
                                                                    docData[
                                                                        'supervisors']);
                                                            supervisors
                                                                .remove(phone);
                                                            await docRef
                                                                .update({
                                                              'supervisors':
                                                                  supervisors,
                                                            });
                                                          }
                                                        }

                                                        Navigator.of(context)
                                                            .pop(); // Close the dialog after deletion
                                                      },
                                                      style: OutlinedButton
                                                          .styleFrom(
                                                        side: const BorderSide(
                                                            color: Colors
                                                                .red), // Red border
                                                      ),
                                                      child: const Text(
                                                        "Delete",
                                                        style: TextStyle(
                                                            color: Colors.red),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                          child: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
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
                              setState(() {
                                supervisorPhoneNo = '';
                                _phoneConn.text = "";
                              });
                              _showRoleDialog();
                            },
                            child: Container(
                              width: width * 0.9,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              decoration: BoxDecoration(
                                  color: const Color.fromRGBO(0, 83, 188, 1),
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
                  return const GradientLoadingIndicator();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> fetchUserDetails(String phone) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final QuerySnapshot<Map<String, dynamic>> querySnapshot = await _firestore
        .collection('users')
        .where('phone_number', isEqualTo: phone)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.data() as Map<String, dynamic>;
    } else {
      return {};
    }
  }
}

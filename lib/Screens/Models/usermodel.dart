import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserModel {
  String dob;
  String email;
  double height;
  double latitude;
  double longitude;
  Map<String, dynamic> metrics;
  String name;
  double weight;
  List<String> relations;
  int phone_number;
  String role;
  Map<String, dynamic> emergency;
  String gender;
  String device_id;

  UserModel({
    required this.dob,
    required this.email,
    required this.height,
    required this.metrics,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.phone_number,
    required this.relations,
    required this.weight,
    required this.role,
    required this.emergency,
    required this.gender,
    required this.device_id
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    print(data['emergency']);
    return UserModel(
      dob: data['dob'] ?? '',
      email: data['email'] ?? '',
      height: data['height']?.toDouble() ?? 0.0,
      metrics: Map<String, dynamic>.from(data['metrics'] ?? {}),
      name: data['name'] ?? '',
      latitude: data['location'].latitude ?? 0.1,
      longitude: data['location'].longitude ?? 0.1,
      phone_number: data['phone_number'] ?? 0,
      relations: List<String>.from(data['relations']),
      weight: data['weight'].toDouble() ?? 0,
      role: data['role'],
      emergency: Map<String, dynamic>.from(data['emergency']),
      gender: data['gender'],
      device_id: data['device_id']
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dob': dob,
      'email': email,
      'height': height,
      'metrics': metrics,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'phone_number': phone_number,
      'relations': relations,
      'weight': weight,
      'role' : role,
      'emergency' : emergency,
      'gender' : gender,
      'device_id': device_id
    };
  }
}

class FirestoreService {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  Stream<UserModel?> streamCurrentUser(String userId) {
    return auth.authStateChanges().switchMap((user) {
      if (user == null) {
        return Stream.value(null); // User signed out
      } else {
        return db.collection('users').doc(userId).snapshots().map((doc) {
          if (doc.exists) {
            return UserModel.fromFirestore(doc);
          } else {
            return null;
          }
        });
      }
    });
  }
}

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final userModelProvider = StreamProvider.family<UserModel?, String>((ref, userId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamCurrentUser(userId).handleError((error) {
    print('Error streaming user data: $error');
    return null;
  });
});

final supervisorModelProvider = StreamProviderFamily<List<UserModel>?, String>((ref, userId) {
  return FirebaseFirestore.instance.collection('users').where('phone_number', isEqualTo: int.parse(userId))
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
});
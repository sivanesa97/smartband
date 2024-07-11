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
  Map<String, int> metrics;
  String name;
  List<String> relations;
  double weight;
  int phone_number;

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
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      dob: data['dob'] ?? '',
      email: data['email'] ?? '',
      height: data['height']?.toDouble() ?? 0.0,
      metrics: Map<String, int>.from(data['metrics'] ?? {}),
      name: data['name'] ?? '',
      latitude: data['location'].latitude ?? 0.1,
      longitude: data['location'].longitude ?? 0.1,
      phone_number: data['phone_number'] ?? 0,
      relations: List<String>.from(data['relation'] ?? []),
      weight: data['weight'].toDouble() ?? 0,
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
    };
  }
}

class FirestoreService {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  Stream<UserModel?> streamCurrentUser() {
    return auth.authStateChanges().switchMap((user) {
      if (user == null) {
        return Stream.value(null); // User signed out
      } else {
        return db.collection('users').doc(user.uid).snapshots().map((doc) {
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

final userModelProvider = StreamProvider.autoDispose<UserModel?>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamCurrentUser().handleError((error) {
    print('Error streaming user data: $error');
    return null;
  });
});

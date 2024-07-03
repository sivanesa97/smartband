import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserModel {
  String dob;
  String email;
  double height;
  Map<String, int> metrics;
  String name;
  List<String> relations;
  int weight;

  UserModel({
    required this.dob,
    required this.email,
    required this.height,
    required this.metrics,
    required this.name,
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
      relations: List<String>.from(data['relation'] ?? []),
      weight: data['weight'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dob': dob,
      'email': email,
      'height': height,
      'metrics': metrics,
      'name': name,
      'relations': relations,
      'weight': weight,
    };
  }
}


class FirestoreService {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  Stream<UserModel?> streamCurrentUser() {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final currentUser = auth.currentUser;

    if (currentUser == null) {
      return Stream.value(null);
    }

    return db.collection('users').doc(currentUser.uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      } else {
        return null;
      }
    });
  }
}


final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final userModelProvider = StreamProvider<UserModel?>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamCurrentUser().handleError((error) {
    print('Error streaming user data: $error');
    return null;
  });
});

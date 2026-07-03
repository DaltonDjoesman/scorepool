import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_repository.dart';

class Repositories {
  Repositories({FirebaseFirestore? db})
    : firestore = FirestoreRepository(db ?? FirebaseFirestore.instance);

  final FirestoreRepository firestore;
}

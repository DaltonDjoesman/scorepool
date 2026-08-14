import 'package:cloud_firestore/cloud_firestore.dart';

import 'debts_repository.dart';
import 'firestore_client.dart';
import 'groups_repository.dart';
import 'matches_repository.dart';
import 'predictions_repository.dart';
import 'profiles_repository.dart';

class Repositories {
  Repositories({FirebaseFirestore? db, bool skipAuth = false})
    : _client = FirestoreClient(
        db ?? FirebaseFirestore.instance,
        skipAuth: skipAuth,
      ) {
    groups = GroupsRepository(_client);
    matches = MatchesRepository(_client);
    predictions = PredictionsRepository(_client);
    debts = DebtsRepository(_client);
    profiles = ProfilesRepository(_client);
  }

  final FirestoreClient _client;

  late final GroupsRepository groups;
  late final MatchesRepository matches;
  late final PredictionsRepository predictions;
  late final DebtsRepository debts;
  late final ProfilesRepository profiles;
}

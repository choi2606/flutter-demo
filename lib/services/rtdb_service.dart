import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';

class RTDBService {
  final _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://choifoodapp-b15b3-default-rtdb.asia-southeast1.firebasedatabase.app',
  ).ref();

  Future<void> addUser(UserModel user, String? imagePath) async {
    await _db.child(user.id).set({
      'username': user.username,
      'email': user.email,
      'imageUrl': imagePath,
      'password': user.password,
    });
  }

  Stream<List<UserModel>> getUsers() {
    return _db.onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      return data.entries.map((e) {
        return UserModel.fromMap(Map<String, dynamic>.from(e.value), e.key);
      }).toList();
    });
  }

  Future<void> updateUser(UserModel user, String? newImagePath) async {
    await _db.child(user.id).update({
      'username': user.username,
      'email': user.email,
      'imageUrl': newImagePath,
      'password': user.password,
    });
  }

  Future<void> deleteUser(String id, String? imageUrl) async {
    await _db.child(id).remove();
  }
}

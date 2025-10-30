import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadImage(String filePath, String userId) async {
    File file = File(filePath);
    String ref = 'users/$userId.jpg';
    await _storage.ref(ref).putFile(file);
    return await _storage.ref(ref).getDownloadURL();
  }

  Future<void> deleteImage(String imageUrl) async {
    await _storage.refFromURL(imageUrl).delete();
  }
}
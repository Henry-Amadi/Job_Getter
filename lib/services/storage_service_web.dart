import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageServiceWeb {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadFile(String path, Uint8List fileBytes) async {
    try {
      // Create a reference to the location you want to upload to in Firebase Storage
      Reference ref = _storage.ref().child(path);

      // Upload raw data
      UploadTask task = ref.putData(
        fileBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Get download URL
      final snapshot = await task.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print('Error uploading file: $e');
      rethrow;
    }
  }

  Future<void> deleteFile(String path) async {
    try {
      Reference ref = _storage.ref().child(path);
      await ref.delete();
    } catch (e) {
      print('Error deleting file: $e');
      rethrow;
    }
  }
}

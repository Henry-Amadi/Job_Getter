import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'storage_service_web.dart';
import 'dart:html' as html;
import 'dart:js_util';
import 'package:js/js.dart';
import 'dart:async';

@JS('firebaseBridge')
external Object get firebaseBridge;

class StorageService {
  final _uploadProgressController = StreamController<Map<String, double>>.broadcast();
  Stream<Map<String, double>> get uploadProgress => _uploadProgressController.stream;

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final StorageServiceWeb _webStorage = StorageServiceWeb();

  StorageService() {
    html.window.addEventListener('uploadProgress', (html.Event event) {
      if (event is html.CustomEvent) {
        final data = event.detail as Map;
        _uploadProgressController.add({
          data['fileName'] as String: data['progress'] as double,
        });
      }
    });
  }

  Future<String?> uploadFile(String path, html.File file) async {
    if (kIsWeb) {
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoad.first;
      final bytes = reader.result as Uint8List;
      return _webStorage.uploadFile(path, bytes);
    }

    try {
      // Validate file type and size
      if (!_isValidFileType(file)) {
        throw Exception('Invalid file type');
      }

      if (!_isValidFileSize(file)) {
        throw Exception('File size exceeds 5MB limit');
      }

      final result = await promiseToFuture(
        callMethod(firebaseBridge, 'uploadFile', [path, file])
      );

      if (result != null) {
        return result.toString();
      }

      return null;
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  Future<String> uploadFileBytes(String path, Uint8List fileBytes) async {
    if (kIsWeb) {
      return _webStorage.uploadFile(path, fileBytes);
    }

    try {
      Reference ref = _storage.ref().child(path);
      UploadTask task = ref.putData(fileBytes);
      final snapshot = await task.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading file: $e');
      rethrow;
    }
  }

  Future<bool> deleteFile(String path) async {
    if (kIsWeb) {
      try {
        await _webStorage.deleteFile(path);
        return true;
      } catch (e) {
        return false;
      }
    }

    try {
      final result = await promiseToFuture(
        callMethod(firebaseBridge, 'deleteFile', [path])
      );
      return result == true;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  bool _isValidFileType(html.File file) {
    final validTypes = ['image/jpeg', 'image/jpg', 'image/png', 'application/pdf'];
    return validTypes.contains(file.type.toLowerCase());
  }

  bool _isValidFileSize(html.File file) {
    const maxSize = 5 * 1024 * 1024; // 5MB in bytes
    return file.size <= maxSize;
  }

  void dispose() {
    _uploadProgressController.close();
  }
}

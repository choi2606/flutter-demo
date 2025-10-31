import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crypto/crypto.dart'; // ✅ thêm dòng này
import '../models/user_model.dart';
import '../services/rtdb_service.dart';
import '../services/cloudinary_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;

class AddUserScreen extends StatefulWidget {
  @override
  _AddUserScreenState createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  String _username = '', _email = '', _password = '';
  String? _imagePath;
  final picker = ImagePicker();
  Uint8List? _webImage;

  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() => _webImage = bytes);
      } else {
        setState(() => _imagePath = picked.path);
      }
    }
  }

  /// ✅ Hàm mã hóa password bằng SHA-256
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // ✅ Mã hóa mật khẩu trước khi lưu
      final hashedPassword = hashPassword(_password);

      final newUser = UserModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        username: _username,
        email: _email,
        password: hashedPassword, // ✅ lưu hash, không lưu password thô
      );

      String? imageUrl;
      if (kIsWeb && _webImage != null) {
        imageUrl = await CloudinaryService().uploadBytes(_webImage!);
      } else if (_imagePath != null) {
        imageUrl = await CloudinaryService().uploadImage(_imagePath!);
      }

      await RTDBService().addUser(newUser, imageUrl);

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Thêm người dùng"), centerTitle: true,),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            TextFormField(
              decoration: InputDecoration(labelText: "Username"),
              validator: (v) => v!.isEmpty ? "Bắt buộc" : null,
              onSaved: (v) => _username = v!,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: "Email"),
              validator: (v) => v!.contains("@") ? null : "Email không hợp lệ",
              onSaved: (v) => _email = v!,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: "Mật khẩu"),
              obscureText: true,
              validator: (v) => v!.length < 6 ? "Ít nhất 6 ký tự" : null,
              onSaved: (v) => _password = v!,
            ),
            SizedBox(height: 16),
            _webImage != null
                ? Image.memory(_webImage!, height: 120)
                : _imagePath != null
                ? Image.file(File(_imagePath!), height: 120)
                : const Text("Chưa chọn ảnh"),
            ElevatedButton(onPressed: _pickImage, child: Text("Chọn ảnh")),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _save, child: Text("Lưu")),
          ],
        ),
      ),
    );
  }
}

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crypto/crypto.dart';
import '../models/user_model.dart';
import '../services/rtdb_service.dart';
import '../services/cloudinary_service.dart';

class EditUserScreen extends StatefulWidget {
  final UserModel user;
  const EditUserScreen({Key? key, required this.user}) : super(key: key);

  @override
  _EditUserScreenState createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  String? _imagePath;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // ✅ Gán giá trị ban đầu từ user hiện tại
    _usernameController = TextEditingController(text: widget.user.username);
    _emailController = TextEditingController(text: widget.user.email);
    _passwordController = TextEditingController(text: widget.user.password); // mật khẩu không hiển thị
    _imagePath = widget.user.imageUrl; // lưu đường dẫn ảnh hiện tại
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _imagePath = picked.path);
  }

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final username = _usernameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      final hashedPassword =
      password.isNotEmpty ? hashPassword(password) : widget.user.password;

      final updatedUser = UserModel(
        id: widget.user.id, // id can sua
        username: username,
        email: email,
        imageUrl: widget.user.imageUrl, // tạm giữ, có thể thay nếu ảnh mới
        password: hashedPassword,
      );

      String? newImageUrl = _imagePath;
      if (_imagePath != null && _imagePath!.startsWith('/data/')) {
        newImageUrl = await CloudinaryService().uploadImage(_imagePath!);
      }

      await RTDBService().updateUser(updatedUser, newImageUrl);

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sửa người dùng"), centerTitle: true),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: "Username"),
              validator: (v) => v!.isEmpty ? "Bắt buộc" : null,
            ),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(labelText: "Email"),
              validator: (v) => v!.contains("@") ? null : "Email sai",
            ),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: "Mật khẩu mới (để trống nếu không đổi)"),
              obscureText: true,
            ),
            SizedBox(height: 16),
            _imagePath != null
                ? _imagePath!.startsWith('/data/')
                ? Image.file(File(_imagePath!), height: 120)
                : Image.network(_imagePath!, height: 120)
                : Text("Chưa có ảnh"),
            ElevatedButton(onPressed: _pickImage, child: Text("Chọn ảnh mới")),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _save, child: Text("Lưu thay đổi")),
          ],
        ),
      ),
    );
  }
}

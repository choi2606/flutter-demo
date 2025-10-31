import 'dart:io';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/rtdb_service.dart';
import '../services/auth_service.dart';
import 'add_user_screen.dart';
import 'edit_user_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final rtdb = RTDBService();
  String _searchQuery = ''; // 🔍 Dùng để lưu từ khóa tìm kiếm

  String _maskPassword(String password) {
    if (password.isEmpty) return '***';
    return '*' * 8;
  }

  void _confirmDelete(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content:
        Text("Bạn có chắc chắn muốn xóa người dùng '${user.username}' không?"),
        actions: [
          TextButton(
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Xóa"),
            onPressed: () async {
              await rtdb.deleteUser(user.id, user.imageUrl);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Đã xóa người dùng ${user.username}")),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý người dùng"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
              );
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddUserScreen()),
        ),
      ),
      body: Column(
        children: [
          // 🔍 Ô tìm kiếm
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Tìm kiếm người dùng...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),

          // 📜 Danh sách người dùng
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: rtdb.getUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data ?? [];

                // Lọc danh sách theo từ khóa
                final filteredUsers = users.where((user) {
                  final username = user.username?.toLowerCase() ?? '';
                  final email = user.email?.toLowerCase() ?? '';
                  return username.contains(_searchQuery) ||
                      email.contains(_searchQuery);
                }).toList();

                if (filteredUsers.isEmpty) {
                  return const Center(child: Text("Không tìm thấy người dùng nào"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredUsers.length,
                  itemBuilder: (ctx, i) {
                    final user = filteredUsers[i];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundImage: user.imageUrl != null
                              ? FileImage(File(user.imageUrl!))
                              : const AssetImage("assets/avatar.png")
                          as ImageProvider,
                        ),
                        title: Text(
                          "Username: ${user.username}",
                          style:
                          const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Email: ${user.email}"),
                            Text(
                              "Password: ${_maskPassword(user.password ?? '')}",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          onSelected: (value) {
                            if (value == 'edit') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        EditUserScreen(user: user)),
                              );
                            } else if (value == 'delete') {
                              _confirmDelete(context, user);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text("Sửa")),
                            PopupMenuItem(value: 'delete', child: Text("Xóa")),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

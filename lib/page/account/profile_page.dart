import 'package:flutter/material.dart';
import 'package:project_btl/provider/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:project_btl/page/account/favorites_page.dart';
import '../../bloc/account_bloc.dart';
import '../../bloc/history_reading_bloc.dart';
import '../../model/user.dart';
import 'login_page.dart';
import 'change_profile.dart';
import 'reading_history_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AccountBloc _accountBloc = AccountBloc();
  final HistoryReadingBloc _historyBloc = HistoryReadingBloc();

  @override
  void initState() {
    super.initState();
    _accountBloc.event.add(AccountEvent.fetch);
    _historyBloc.event.add(HistoryEvent.fetch);
  }

  @override
  void dispose() {
    _accountBloc.dispose();
    _historyBloc.dispose();
    super.dispose();
  }

  void _logout() async {
    _accountBloc.event.add(AccountEvent.logout);
    // Chuyển về trang đăng nhập
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tài khoản',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Nút chuyển đổi chế độ sáng/tối
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
        ],
      ),
      body: StreamBuilder<AccountState>(
        stream: _accountBloc.state,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final state = snapshot.data!;

          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = state.user;

          if (user == null) {
            // Nếu không có user, chuyển đến trang đăng nhập
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const LoginPage(),
                ),
              );
            });
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Phần thông tin người dùng
                _buildUserInfoSection(user),

                // Phần menu chức năng
                _buildMenuSection(user),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserInfoSection(User user) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.brown.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.brown.shade200,
                child: Text(
                  user.username.isNotEmpty
                      ? user.username[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.username,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.phone,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeProfilePage(user: user),
                    ),
                  );

                  // Nếu có cập nhật user mới
                  if (result != null && result is User) {
                    _accountBloc.event.add(AccountEvent.fetch);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                ),
                child: const Text(
                  'Chỉnh sửa hồ sơ',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text(
                  'Đăng xuất',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Cài đặt & Tiện ích',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.favorite, color: Colors.red),
          title: const Text('Truyện yêu thích'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FavoritesPage(),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.history, color: Colors.blue),
          title: const Text('Lịch sử đọc truyện'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ReadingHistoryPage(),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.notifications, color: Colors.orange),
          title: const Text('Thông báo'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tính năng đang phát triển'),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.download, color: Colors.green),
          title: const Text('Truyện đã tải'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tính năng đang phát triển'),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.settings, color: Colors.grey),
          title: const Text('Cài đặt'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tính năng đang phát triển'),
              ),
            );
          },
        ),
        const Divider(),
      ],
    );
  }
}

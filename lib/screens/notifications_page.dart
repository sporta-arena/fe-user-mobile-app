import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    // TODO: Implement API call to get notifications
    // For now, just show empty state
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _isLoading = false;
        _notifications = [];
      });
    }
  }

  void _markAllAsRead() {
    setState(() {
      for (var notif in _notifications) {
        notif['isRead'] = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Semua notifikasi ditandai sudah dibaca")),
    );
  }

  void _deleteNotification(int id) {
    setState(() {
      _notifications.removeWhere((element) => element['id'] == id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Notifikasi dihapus"),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          systemOverlayStyle: SystemUiOverlayStyle.light,
          title: const Text(
            "Notifikasi",
            style: TextStyle(color: AppColors.onDark, fontWeight: FontWeight.bold)
          ),
          backgroundColor: AppColors.bg,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.onDark),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            TextButton(
              onPressed: _notifications.isEmpty ? null : _markAllAsRead,
              child: Text(
                "Tandai Dibaca",
                style: TextStyle(
                  color: _notifications.isEmpty ? AppColors.onDarkMuted : AppColors.brandYellow,
                  fontWeight: FontWeight.bold
                )
              ),
            )
          ],
          bottom: const TabBar(
            labelColor: AppColors.brandYellow,
            unselectedLabelColor: AppColors.onDarkMuted,
            indicatorColor: AppColors.brandYellow,
            tabs: [
              Tab(text: "Transaksi"),
              Tab(text: "Info & Promo"),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.brandYellow))
            : TabBarView(
                children: [
                  _buildNotificationList("transaction"),
                  _buildNotificationList("other"),
                ],
              ),
      ),
    );
  }

  Widget _buildNotificationList(String filter) {
    List<Map<String, dynamic>> filteredList;
    if (filter == "transaction") {
      filteredList = _notifications.where((n) => n['type'] == 'transaction').toList();
    } else {
      filteredList = _notifications.where((n) => n['type'] != 'transaction').toList();
    }

    if (filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.notifications_off_outlined, size: 80, color: AppColors.surfaceBorder),
            const SizedBox(height: 16),
            const Text(
              "Belum ada notifikasi",
              style: TextStyle(color: AppColors.onDarkMuted)
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredList.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final item = filteredList[index];
        return _buildNotificationItem(item);
      },
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> item) {
    IconData icon;
    Color color;
    switch (item['type']) {
      case 'transaction':
        icon = Icons.receipt_long;
        color = Colors.green;
        break;
      case 'promo':
        icon = Icons.local_offer;
        color = Colors.orange;
        break;
      case 'system':
        icon = Icons.info;
        color = AppColors.brandYellow;
        break;
      default:
        icon = Icons.notifications;
        color = AppColors.onDarkMuted;
    }

    bool isUnread = !item['isRead'];

    return Dismissible(
      key: Key(item['id'].toString()),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _deleteNotification(item['id']);
      },
      child: GestureDetector(
        onTap: () {
          setState(() {
            var originalItem = _notifications.firstWhere((element) => element['id'] == item['id']);
            originalItem['isRead'] = true;
          });
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isUnread ? AppColors.brandYellow.withValues(alpha: 0.15) : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item['title'],
                            style: TextStyle(
                              fontWeight: isUnread ? FontWeight.w900 : FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.onDark
                            )
                          ),
                        ),

                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle
                            ),
                          )
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      item['message'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.onDarkMuted,
                        height: 1.5
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis
                    ),

                    const SizedBox(height: 8),

                    Text(
                      item['time'],
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.onDarkMuted,
                        fontWeight: FontWeight.w500
                      )
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

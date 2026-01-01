import 'package:flutter/material.dart';

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
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            "Notifikasi",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            TextButton(
              onPressed: _notifications.isEmpty ? null : _markAllAsRead,
              child: Text(
                "Tandai Dibaca",
                style: TextStyle(
                  color: _notifications.isEmpty ? Colors.grey : const Color(0xFF0047FF),
                  fontWeight: FontWeight.bold
                )
              ),
            )
          ],
          bottom: const TabBar(
            labelColor: Color(0xFF0047FF),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF0047FF),
            tabs: [
              Tab(text: "Transaksi"),
              Tab(text: "Info & Promo"),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF0047FF)))
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
            Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              "Belum ada notifikasi",
              style: TextStyle(color: Colors.grey[500])
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
        color = Colors.blue;
        break;
      default:
        icon = Icons.notifications;
        color = Colors.grey;
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
            color: isUnread ? const Color(0xFFF0F5FF) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: isUnread ? [] : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4)
              )
            ],
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
                              color: Colors.black87
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
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.5
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis
                    ),

                    const SizedBox(height: 8),

                    Text(
                      item['time'],
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[400],
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

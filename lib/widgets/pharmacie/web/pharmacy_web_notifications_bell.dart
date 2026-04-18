import 'dart:async';

import 'package:flutter/material.dart';

import '../../../services/api_service.dart';

class PharmacyWebNotificationsBell extends StatefulWidget {
  const PharmacyWebNotificationsBell({super.key});

  @override
  State<PharmacyWebNotificationsBell> createState() => _PharmacyWebNotificationsBellState();
}

class _PharmacyWebNotificationsBellState extends State<PharmacyWebNotificationsBell> {
  int _unreadCount = 0;
  Timer? _timer;
  final GlobalKey _buttonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _refreshUnreadCount();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _refreshUnreadCount());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refreshUnreadCount() async {
    try {
      final res = await ApiService.getUnreadNotificationsCount();
      final count = (res['unreadCount'] as num?)?.toInt() ?? 0;
      if (!mounted) return;
      setState(() => _unreadCount = count);
    } catch (_) {
      // Ignore: likely not logged in yet.
    }
  }

  Future<void> _openNotificationsDialog() async {
    // Kept for backward compatibility; now opens a compact dropdown menu.
    await _openNotificationsMenu();
  }

  Future<void> _openNotificationsMenu() async {
    List<Map<String, dynamic>> notifications = const [];
    try {
      notifications = await ApiService.getNotifications(limit: 5);
    } catch (_) {
      // Ignore: likely not logged in yet.
    }

    if (!mounted) return;

    final buttonContext = _buttonKey.currentContext;
    if (buttonContext == null) return;

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final box = buttonContext.findRenderObject() as RenderBox;
    final position = box.localToGlobal(Offset.zero, ancestor: overlay);

    final selectedId = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + box.size.height,
        overlay.size.width - position.dx - box.size.width,
        overlay.size.height - position.dy,
      ),
      items: [
        if (notifications.isEmpty)
          const PopupMenuItem<String>(
            enabled: false,
            child: SizedBox(
              width: 320,
              child: Text('Aucune notification'),
            ),
          )
        else
          for (final n in notifications)
            PopupMenuItem<String>(
              value: (n['id'] ?? n['_id'] ?? '').toString(),
              child: SizedBox(
                width: 320,
                child: _NotificationMenuRow(notification: n),
              ),
            ),
      ],
    );

    if (selectedId != null && selectedId.isNotEmpty) {
      final selected = notifications.firstWhere(
        (n) => (n['id'] ?? n['_id'] ?? '').toString() == selectedId,
        orElse: () => const {},
      );
      final isRead = (selected['isRead'] as bool?) ?? false;

      if (!isRead) {
        try {
          await ApiService.markNotificationAsRead(selectedId);
        } catch (_) {}
      }
    }

    await _refreshUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: _buttonKey,
      tooltip: 'Notifications',
      onPressed: _openNotificationsMenu,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_outlined),
          if (_unreadCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationMenuRow extends StatelessWidget {
  const _NotificationMenuRow({required this.notification});

  final Map<String, dynamic> notification;

  @override
  Widget build(BuildContext context) {
    final title = (notification['title'] ?? '').toString();
    final message = (notification['message'] ?? '').toString();
    final isRead = (notification['isRead'] as bool?) ?? false;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isRead)
          const Padding(
            padding: EdgeInsets.only(top: 6, right: 8),
            child: Icon(Icons.circle, size: 10, color: Colors.redAccent),
          )
        else
          const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.isEmpty ? 'Notification' : title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

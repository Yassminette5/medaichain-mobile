import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/api_service.dart';

class PharmacyMobileNotificationsBell extends StatefulWidget {
  const PharmacyMobileNotificationsBell({
    super.key,
    this.useFilledContainer = false,
  });

  /// When true, renders with the same filled container style as other
  /// dashboard header icon buttons.
  final bool useFilledContainer;

  @override
  State<PharmacyMobileNotificationsBell> createState() =>
      _PharmacyMobileNotificationsBellState();
}

class _PharmacyMobileNotificationsBellState
    extends State<PharmacyMobileNotificationsBell> {
  int _unreadCount = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refreshUnreadCount();
    _timer = Timer.periodic(const Duration(seconds: 12), (_) {
      _refreshUnreadCount();
    });
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
      // Ignore (not logged in / network)
    }
  }

  Future<void> _openNotificationsSheet() async {
    List<Map<String, dynamic>> notifications = const [];
    try {
      notifications = await ApiService.getNotifications(limit: 5);
    } catch (_) {
      notifications = const [];
    }

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                if (notifications.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Text(
                      'Aucune notification',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const Divider(height: 18),
                      itemBuilder: (context, index) {
                        final n = notifications[index];
                        final id = (n['id'] ?? n['_id'] ?? '').toString();
                        final title = (n['title'] ?? 'Notification').toString();
                        final message = (n['message'] ?? '').toString();
                        final isRead = (n['isRead'] as bool?) ?? false;

                        return InkWell(
                          onTap: () async {
                            if (id.isNotEmpty && !isRead) {
                              try {
                                await ApiService.markNotificationAsRead(id);
                              } catch (_) {}
                            }
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isRead)
                                const Padding(
                                  padding: EdgeInsets.only(top: 6, right: 10),
                                  child: Icon(
                                    Icons.circle,
                                    size: 10,
                                    color: Colors.redAccent,
                                  ),
                                )
                              else
                                const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight:
                                            isRead ? FontWeight.w600 : FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    if (message.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        message,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                          height: 1.25,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );

    await _refreshUnreadCount();
  }

  Widget _buildIconWithBadge({required Widget icon}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        if (_unreadCount > 0)
          Positioned(
            right: -4,
            top: -4,
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
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.useFilledContainer) {
      return IconButton(
        tooltip: 'Notifications',
        onPressed: _openNotificationsSheet,
        icon: _buildIconWithBadge(
          icon: const Icon(Icons.notifications_outlined),
        ),
      );
    }

    return GestureDetector(
      onTap: _openNotificationsSheet,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _buildIconWithBadge(
          icon: const Icon(
            Icons.notifications_outlined,
            color: AppColors.textSecondary,
            size: 22,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/remote/supabase_sync_service.dart';

class SyncIssueListener extends StatefulWidget {
  final Widget child;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;

  const SyncIssueListener({
    super.key,
    required this.child,
    required this.scaffoldMessengerKey,
  });

  @override
  State<SyncIssueListener> createState() => _SyncIssueListenerState();
}

class _SyncIssueListenerState extends State<SyncIssueListener> {
  SupabaseSyncService? _syncService;
  int? _lastShownIssueId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final service = context.read<SupabaseSyncService>();
    if (identical(service, _syncService)) return;
    _syncService?.removeListener(_handleIssueChanged);
    _syncService = service;
    _syncService?.addListener(_handleIssueChanged);
  }

  @override
  void dispose() {
    _syncService?.removeListener(_handleIssueChanged);
    super.dispose();
  }

  void _handleIssueChanged() {
    final issue = _syncService?.pendingIssue;
    if (issue == null || issue.id == _lastShownIssueId) return;

    _lastShownIssueId = issue.id;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final messenger =
          widget.scaffoldMessengerKey.currentState ??
          ScaffoldMessenger.maybeOf(context);
      if (messenger == null) return;

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(_buildSnackBar(issue));
      _syncService?.clearPendingIssue(issue.id);
    });
  }

  SnackBar _buildSnackBar(SyncIssue issue) {
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 7),
      backgroundColor: const Color(0xFF18221C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.warning_amber_rounded, color: Color(0xFFFFC857)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue.title,
                  style: const TextStyle(
                    fontFamily: 'DotGothic',
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Причина:\n${issue.reason}',
                  style: const TextStyle(
                    fontFamily: 'DotGothic',
                    color: Color(0xFFE3E7E4),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  issue.details,
                  style: const TextStyle(
                    fontFamily: 'DotGothic',
                    color: Color(0xFFB7C3BC),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

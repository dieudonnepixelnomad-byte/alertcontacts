import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/community_alert.dart';
import '../../../shared/widgets/offline_banner.dart';
import '../../../theme/colors.dart';
import '../providers/alert_provider.dart';
import 'alert_creation_flow.dart';
import 'alert_detail_page.dart';

enum _AlertFilter { all, contacts, zones, community }

class AlertesPage extends StatefulWidget {
  const AlertesPage({super.key});

  @override
  State<AlertesPage> createState() => _AlertesPageState();
}

class _AlertesPageState extends State<AlertesPage> {
  _AlertFilter _filter = _AlertFilter.all;
  List<ConnectivityResult> _connectivity = const [ConnectivityResult.wifi];

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlertProvider>().fetchNearbyAlerts();
    });
  }

  Future<void> _initConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    if (mounted) setState(() => _connectivity = result);
    Connectivity().onConnectivityChanged.listen((result) {
      if (mounted) setState(() => _connectivity = result);
    });
  }

  bool get _isOffline =>
      _connectivity.every((r) => r == ConnectivityResult.none);

  List<Map<String, dynamic>> _communityToMap(
      List<CommunityAlert> alerts, AlertProvider provider) {
    return alerts.map((a) {
      final diff = DateTime.now().difference(a.createdAt);
      final timeLabel = diff.inMinutes < 60
          ? 'il y a ${diff.inMinutes}min'
          : diff.inHours < 24
              ? 'il y a ${diff.inHours}h'
              : 'hier';
      final dateLabel = diff.inDays == 0 ? "Aujourd'hui" : "Hier";
      final gravityStr = switch (a.gravity) {
        AlertGravity.high   => 'high',
        AlertGravity.medium => 'medium',
        AlertGravity.low    => 'low',
      };
      return {
        'id': a.id,
        'type': 'community',
        'title': '${a.typeLabel} signalé',
        'subtitle': '${a.gravityLabel} · $timeLabel',
        'gravity': gravityStr,
        'read': provider.isRead(a.id),
        'date': dateLabel,
        'filter': _AlertFilter.community,
        'alert_data': {
          'gravity': gravityStr,
          'type': a.type.toString().split('.').last,
          'confirmations': a.confirmations,
        },
      };
    }).toList();
  }

  List<Map<String, dynamic>> _buildAllAlerts(AlertProvider provider) {
    return _communityToMap(provider.alerts, provider);
  }

  List<Map<String, dynamic>> _filtered(AlertProvider provider) {
    final all = _buildAllAlerts(provider);
    if (_filter == _AlertFilter.all) return all;
    return all.where((a) => a['filter'] == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Consumer<AlertProvider>(
      builder: (context, provider, _) {
        final filtered = _filtered(provider);
        final all = _buildAllAlerts(provider);
        final unread = all.where((a) => a['read'] == false).length;
        final groups = _groupByDate(filtered);

        return Scaffold(
          backgroundColor: AppColors.gray50,
          body: RefreshIndicator(
            onRefresh: () => provider.fetchNearbyAlerts(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        20, MediaQuery.of(context).padding.top + 16, 20, 8),
                    child: Row(
                      children: [
                        Expanded(child: Text('Alertes', style: tt.titleLarge)),
                        if (unread > 0)
                          TextButton(
                            onPressed: () => _markAllRead(provider),
                            child: Text(
                              'Tout lire',
                              style: tt.bodySmall?.copyWith(color: AppColors.primary),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Offline banner
                if (_isOffline)
                  SliverToBoxAdapter(
                    child: OfflineBanner(
                      onRetry: () => provider.fetchNearbyAlerts(),
                    ),
                  ),

                // Filter chips
                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      children: _AlertFilter.values.map((f) {
                        final selected = _filter == f;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _filter = f),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.primary
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.gray200,
                                ),
                              ),
                              child: Text(
                                _filterLabel(f),
                                style: tt.bodySmall?.copyWith(
                                  color: selected
                                      ? Colors.white
                                      : AppColors.gray600,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // Loading state
                if (provider.status == AlertStatus.loading)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),

                // Error state — visible pour debug
                if (provider.status == AlertStatus.error &&
                    provider.errorMessage != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                provider.errorMessage!,
                                style: tt.bodySmall?.copyWith(color: AppColors.danger),
                              ),
                            ),
                            TextButton(
                              onPressed: () => provider.fetchNearbyAlerts(),
                              child: Text('Retry', style: tt.bodySmall?.copyWith(color: AppColors.danger, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                if (filtered.isEmpty && provider.status != AlertStatus.loading)
                  const SliverFillRemaining(child: _EmptyState())
                else
                  ...groups.entries.expand((entry) => [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(20, 8, 20, 6),
                            child: Text(
                              entry.key,
                              style: tt.labelSmall?.copyWith(
                                color: AppColors.gray400,
                                letterSpacing: 0.06,
                              ),
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (_, i) => Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 8),
                                child: _AlertTile(
                                  data: entry.value[i],
                                  onTap: () =>
                                      _openDetail(entry.value[i], provider),
                                  onMarkRead: () => _markRead(
                                      entry.value[i]['id'] as String,
                                      provider),
                                ),
                              ),
                              childCount: entry.value.length,
                            ),
                          ),
                        ),
                      ]),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _openCreation,
            backgroundColor: AppColors.danger,
            child: const Icon(Icons.add_alert_outlined, color: Colors.white),
          ),
        );
      },
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupByDate(
      List<Map<String, dynamic>> alerts) {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final a in alerts) {
      final date = a['date'] as String;
      map.putIfAbsent(date, () => []).add(a);
    }
    return map;
  }

  String _filterLabel(_AlertFilter f) => switch (f) {
        _AlertFilter.all => 'Tout',
        _AlertFilter.contacts => 'Proches',
        _AlertFilter.zones => 'Zones',
        _AlertFilter.community => 'Communauté',
      };

  void _markRead(String id, AlertProvider provider) {
    provider.markRead(id);
  }

  void _markAllRead(AlertProvider provider) {
    provider.markAllRead();
  }

  void _openDetail(Map<String, dynamic> data, AlertProvider provider) {
    _markRead(data['id'] as String, provider);
    if (data['alert_data'] != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AlertDetailPage(
              alert: data['alert_data'] as Map<String, dynamic>),
        ),
      );
    }
  }

  void _openCreation() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.96,
        minChildSize: 0.5,
        builder: (_, controller) => const AlertCreationFlow(),
      ),
    );
  }
}

// ─── Alert Tile ──────────────────────────────────────────────────────────────

class _AlertTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  final VoidCallback onMarkRead;

  const _AlertTile(
      {required this.data, required this.onTap, required this.onMarkRead});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isRead = data['read'] as bool;
    final gravity = data['gravity'] as String?;
    final type = data['type'] as String;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isRead
                ? AppColors.gray200
                : AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AlertIcon(type: type, gravity: gravity),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title'] as String,
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: isRead
                          ? FontWeight.w400
                          : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data['subtitle'] as String,
                    style: tt.labelMedium
                        ?.copyWith(color: AppColors.gray400),
                  ),
                ],
              ),
            ),
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4, left: 6),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AlertIcon extends StatelessWidget {
  final String type;
  final String? gravity;

  const _AlertIcon({required this.type, this.gravity});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (type) {
      'zone' => (AppColors.success, Icons.location_on_outlined),
      'contact' => (AppColors.primary, Icons.person_outlined),
      'community' => (
          _gravityColor(gravity ?? 'low'),
          Icons.warning_amber_outlined
        ),
      _ => (AppColors.gray400, Icons.notifications_outlined),
    };

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }

  Color _gravityColor(String g) => switch (g) {
        'high' => AppColors.gravityHigh,
        'medium' => AppColors.gravityMid,
        _ => AppColors.gravityLow,
      };
}

// ─── Empty State ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                  color: AppColors.primaryLight, shape: BoxShape.circle),
              child: const Icon(Icons.notifications_none_outlined,
                  size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text('Aucune alerte', style: tt.titleSmall),
            const SizedBox(height: 8),
            Text(
              'Tes alertes de zone et les signalements communautaires apparaîtront ici.',
              textAlign: TextAlign.center,
              style: tt.bodySmall?.copyWith(color: AppColors.gray400),
            ),
          ],
        ),
      ),
    );
  }
}

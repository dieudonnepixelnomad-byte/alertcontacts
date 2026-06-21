import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../theme/colors.dart';
import '../../../core/services/api_auth_service.dart';
import '../../../core/services/api_location_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/revenuecat_service.dart';
import '../../auth/providers/auth_notifier.dart';
import '../../home_map/presentation/invisible_mode_sheet.dart';
import '../../paywall/presentation/paywall_page.dart';
import '../../../router/app_router.dart';
import 'notification_settings_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _tier; // null = gratuit
  bool _tierLoaded = false;

  bool _invisibleActive = false;
  DateTime? _invisibleUntil;

  @override
  void initState() {
    super.initState();
    _loadTier();
  }

  Future<void> _loadTier() async {
    final tier = await RevenueCatService.instance.getSubscriptionTier();
    if (mounted) setState(() { _tier = tier; _tierLoaded = true; });
  }

  String get _tierLabel {
    switch (_tier) {
      case 'solo': return 'Solo';
      case 'famille': return 'Famille';
      default: return 'Gratuit';
    }
  }

  // ─── Mode invisible ───────────────────────────────────────────────────────

  void _showInvisibleSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => InvisibleModeSheet(
        isActive: _invisibleActive,
        invisibleUntil: _invisibleUntil,
        onActivate: _activateInvisible,
        onResume: _resumeLocation,
      ),
    );
  }

  Future<bool> _activateInvisible(int? durationMinutes) async {
    final svc = context.read<ApiLocationService>();
    final locSvc = context.read<LocationService>();
    try {
      await svc.pauseLocation(durationMinutes: durationMinutes);
      await locSvc.setInvisibleMode(true);
      if (mounted) {
        setState(() {
          _invisibleActive = true;
          _invisibleUntil = durationMinutes != null && durationMinutes > 0
              ? DateTime.now().add(Duration(minutes: durationMinutes))
              : null;
        });
      }
      return true;
    } catch (e) {
      log('settings: activate invisible error: $e');
      return false;
    }
  }

  Future<bool> _resumeLocation() async {
    final svc = context.read<ApiLocationService>();
    final locSvc = context.read<LocationService>();
    try {
      await svc.resumeLocation();
      await locSvc.setInvisibleMode(false);
      if (mounted) setState(() { _invisibleActive = false; _invisibleUntil = null; });
      return true;
    } catch (e) {
      log('settings: resume location error: $e');
      return false;
    }
  }

  // ─── Exporter données ─────────────────────────────────────────────────────

  Future<void> _exportData() async {
    final apiAuth = context.read<ApiAuthService>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await apiAuth.exportData();
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Demande envoyée — tu recevras un email avec tes données.')),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Erreur lors de la demande d\'export.')),
        );
      }
    }
  }

  // ─── URL légales ──────────────────────────────────────────────────────────

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir le lien.')),
        );
      }
    }
  }

  // ─── Déconnexion ──────────────────────────────────────────────────────────

  void _signOut() {
    showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text('Tu devras te reconnecter pour accéder à AlertContacts.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    ).then((ok) async {
      if (ok == true && mounted) {
        await context.read<AuthNotifier>().signOut();
        if (mounted) context.go(AppRoutes.auth);
      }
    });
  }

  // ─── Suppression compte ───────────────────────────────────────────────────

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer mon compte ?'),
        content: const Text(
          'Cette action est irréversible. Toutes tes données seront supprimées définitivement.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmDeleteAccount();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final apiAuth = context.read<ApiAuthService>();
    final authNotifier = context.read<AuthNotifier>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await apiAuth.deleteAccount();
      if (mounted) {
        await authNotifier.signOut();
        if (mounted) context.go(AppRoutes.auth);
      }
    } catch (e) {
      log('settings: delete account error: $e');
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Erreur lors de la suppression du compte.')),
        );
      }
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final auth = context.watch<AuthNotifier>();
    final user = auth.user;
    final displayName = user?.name ?? 'Mon compte';
    final email = user?.email ?? '';
    final photoUrl = user?.photoUrl;

    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 8),
              child: Text('Paramètres', style: tt.titleLarge),
            ),
          ),

          // ── Avatar header ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.gray200),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primaryLight,
                      backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                      child: photoUrl == null
                          ? Text(
                              displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 20),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(displayName, style: tt.titleSmall),
                          const SizedBox(height: 2),
                          Text(email, style: tt.bodySmall?.copyWith(color: AppColors.gray400)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Section Confidentialité ──────────────────────────────────────
          SliverToBoxAdapter(child: _SectionLabel(label: 'CONFIDENTIALITÉ')),
          SliverToBoxAdapter(
            child: _SettingsGroup(
              children: [
                _SettingsTile(
                  icon: Icons.visibility_off_outlined,
                  label: 'Mode invisible',
                  subtitle: _invisibleActive
                      ? 'Actif${_invisibleUntil != null ? ' jusqu\'à ${_invisibleUntil!.hour.toString().padLeft(2, '0')}h${_invisibleUntil!.minute.toString().padLeft(2, '0')}' : ''}'
                      : 'Masquer temporairement ta position',
                  color: _invisibleActive ? AppColors.warning : null,
                  onTap: _showInvisibleSheet,
                ),
                _SettingsTile(
                  icon: Icons.tune_outlined,
                  label: 'Paramètres de partage',
                  subtitle: 'Gérer ce que voient tes proches',
                  onTap: () {},
                ),
              ],
            ),
          ),

          // ── Section App ──────────────────────────────────────────────────
          SliverToBoxAdapter(child: _SectionLabel(label: 'APPLICATION')),
          SliverToBoxAdapter(
            child: _SettingsGroup(
              children: [
                _SettingsTile(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationSettingsPage()),
                  ),
                ),
                _SettingsTile(
                  icon: Icons.language_outlined,
                  label: 'Langue',
                  trailing: Text('Français', style: tt.bodySmall?.copyWith(color: AppColors.gray400)),
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.description_outlined,
                  label: 'Conditions d\'utilisation',
                  onTap: () => _openUrl('https://alertcontacts.app/cgu'),
                ),
                _SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Politique de confidentialité',
                  onTap: () => _openUrl('https://alertcontacts.app/politique-de-confidentialite'),
                ),
              ],
            ),
          ),

          // ── Section Compte ───────────────────────────────────────────────
          SliverToBoxAdapter(child: _SectionLabel(label: 'COMPTE')),
          SliverToBoxAdapter(
            child: _SettingsGroup(
              children: [
                _SettingsTile(
                  icon: Icons.workspace_premium_outlined,
                  label: 'Mon abonnement',
                  trailing: _tierLoaded
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _tierLabel,
                            style: tt.labelMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                        )
                      : const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PaywallPage(trigger: 'settings')),
                  ),
                ),
                _SettingsTile(
                  icon: Icons.download_outlined,
                  label: 'Exporter mes données',
                  onTap: _exportData,
                ),
                _SettingsTile(
                  icon: Icons.logout_outlined,
                  label: 'Se déconnecter',
                  onTap: _signOut,
                ),
              ],
            ),
          ),

          // ── Danger zone ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _SettingsGroup(
                children: [
                  _SettingsTile(
                    icon: Icons.delete_outline,
                    label: 'Supprimer mon compte',
                    color: AppColors.danger,
                    onTap: _deleteAccount,
                  ),
                ],
              ),
            ),
          ),

          // ── Section Debug (dev only) ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Builder(builder: (context) {
              bool isDebug = false;
              assert(() { isDebug = true; return true; }());
              if (!isDebug) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel(label: 'DEBUG'),
                  _SettingsGroup(
                    children: [
                      _SettingsTile(
                        icon: Icons.bug_report_outlined,
                        label: 'Permissions & disclosure',
                        subtitle: 'Tester le dialog background location',
                        onTap: () => context.go(AppRoutes.permissionBackgroundLocation),
                      ),
                      _SettingsTile(
                        icon: Icons.notification_important_outlined,
                        label: 'Debug permissions',
                        subtitle: 'Statut FCM, notifications',
                        onTap: () => context.go(AppRoutes.debugPermissions),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

// ─── Components ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.gray400,
          letterSpacing: 0.08,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Column(
          children: List.generate(children.length * 2 - 1, (i) {
            if (i.isOdd) return const Divider(height: 1, indent: 16);
            return children[i ~/ 2];
          }),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color? color;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.color,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final c = color ?? AppColors.gray900;

    return ListTile(
      tileColor: Colors.transparent,
      leading: Icon(icon, color: c, size: 22),
      title: Text(label, style: tt.bodyMedium?.copyWith(color: c)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: tt.labelMedium?.copyWith(color: color != null ? color!.withValues(alpha: 0.7) : AppColors.gray400))
          : null,
      trailing: trailing ?? const Icon(Icons.chevron_right, color: AppColors.gray400, size: 20),
      minLeadingWidth: 28,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
    );
  }
}

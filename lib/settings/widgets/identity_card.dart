import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uniun/common/locator.dart';
import 'package:uniun/core/router/app_routes.dart';
import 'package:uniun/core/theme/app_theme.dart';
import 'package:uniun/domain/repositories/user_repository.dart';
import 'package:uniun/settings/cubit/settings_cubit.dart';

class IdentityCard extends StatelessWidget {
  const IdentityCard({super.key, required this.state});

  final SettingsState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              'This is your login & recovery method.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
          IdentityRow(
            icon: Icons.key_rounded,
            label: 'Keys',
            trailing: Icons.chevron_right_rounded,
            onTap: () => _showKeysSheet(context),
          ),
          IdentityRow(
            icon: Icons.cell_tower_rounded,
            label: 'Relays',
            trailing: Icons.chevron_right_rounded,
            onTap: () => _showRelaysSheet(context),
          ),
          IdentityRow(
            icon: Icons.backup_rounded,
            label: 'Export Backup',
            trailing: Icons.download_rounded,
            onTap: () {
              // TODO: export backup
            },
          ),
          IdentityRow(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy & Policy',
            trailing: Icons.chevron_right_rounded,
            onTap: () => Navigator.pushNamed(context, AppRoutes.privacyPolicy),
          ),
        ],
      ),
    );
  }

  void _showKeysSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _KeysSheet(npub: state.npub ?? ''),
    );
  }

  void _showRelaysSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _RelaysSheet(),
    );
  }
}

// ── Combined Keys Sheet ────────────────────────────────────────────────────────

class _KeysSheet extends StatefulWidget {
  const _KeysSheet({required this.npub});
  final String npub;

  @override
  State<_KeysSheet> createState() => _KeysSheetState();
}

class _KeysSheetState extends State<_KeysSheet> {
  bool _nsecVisible = false;
  String? _nsec;
  bool _nsecLoading = false;

  Future<void> _revealNsec() async {
    if (_nsecVisible) {
      setState(() => _nsecVisible = false);
      return;
    }
    setState(() => _nsecLoading = true);
    try {
      final result = await getIt<UserRepository>().getActiveUser();
      final nsec = result.fold((_) => null, (u) => u.nsec);
      if (mounted) setState(() {
        _nsec = nsec;
        _nsecVisible = true;
        _nsecLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _nsecLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Your Keys',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Never share your private key with anyone.',
            style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
          ),

          // ── Public Key ─────────────────────────────────────────────────
          const SizedBox(height: 24),
          _KeySectionLabel(
            icon: Icons.lock_open_rounded,
            label: 'Public Key (npub)',
            color: AppColors.primary,
          ),
          const SizedBox(height: 8),
          _KeyBox(
            text: widget.npub,
            onCopy: () => _copy(context, widget.npub, 'Public key copied'),
          ),

          // ── Private Key ────────────────────────────────────────────────
          const SizedBox(height: 20),
          _KeySectionLabel(
            icon: Icons.lock_rounded,
            label: 'Private Key (nsec)',
            color: const Color(0xFFBA1A1A),
          ),
          const SizedBox(height: 8),

          if (!_nsecVisible)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _nsecLoading ? null : _revealNsec,
                icon: _nsecLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : const Icon(Icons.visibility_rounded, size: 18),
                label: const Text('Reveal Private Key'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            )
          else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFDAD6).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_rounded,
                          size: 15, color: Color(0xFFBA1A1A)),
                      SizedBox(width: 6),
                      Text(
                        'Never share this key',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFBA1A1A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    _nsec ?? '',
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _copy(
                            context, _nsec ?? '', 'Private key copied — keep it safe!'),
                        child: const Text(
                          'Tap to copy',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _revealNsec,
                        child: const Text(
                          'Hide',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _copy(BuildContext context, String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _KeySectionLabel extends StatelessWidget {
  const _KeySectionLabel({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _KeyBox extends StatelessWidget {
  const _KeyBox({required this.text, required this.onCopy});
  final String text;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: AppColors.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onCopy,
            child: const Icon(Icons.copy_rounded,
                size: 18, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

// ── Relays Sheet ───────────────────────────────────────────────────────────────

class _RelaysSheet extends StatelessWidget {
  const _RelaysSheet();

  static const _defaultRelays = [
    'wss://relay.damus.io',
    'wss://relay.nostr.band',
    'wss://nos.lol',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Relays',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Nostr relays your client connects to.',
            style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          ..._defaultRelays.map(
            (relay) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      relay,
                      style: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'monospace',
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 15, color: AppColors.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Custom relay management coming soon.',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared row widget ──────────────────────────────────────────────────────────

class IdentityRow extends StatelessWidget {
  const IdentityRow({
    super.key,
    required this.icon,
    required this.label,
    required this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final IconData trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            Icon(trailing, size: 20, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

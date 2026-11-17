import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../services/update_controller.dart';
import '../theme/app_theme.dart';
import 'update_sheet.dart';

/// Hoja de ajustes: tema, actualizaciones y, al pie, los créditos.
Future<void> showSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _SettingsSheet(),
  );
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: ListenableBuilder(
        listenable: appSettings,
        builder: (context, _) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ajustes',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: p.textPrimary,
              ),
            ),
            const _SectionLabel('Apariencia'),
            SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: p.accentSoft,
                selectedForegroundColor: p.accent,
                foregroundColor: p.textSecondary,
                side: BorderSide(color: p.border),
                textStyle: const TextStyle(
                  fontFamily: kFontFamily,
                  fontWeight: FontWeight.w600,
                ),
              ),
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto_outlined, size: 18),
                  label: Text('Sistema'),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_outlined, size: 18),
                  label: Text('Claro'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_outlined, size: 18),
                  label: Text('Oscuro'),
                ),
              ],
              selected: {appSettings.themeMode},
              onSelectionChanged: (s) => appSettings.setThemeMode(s.first),
            ),
            const _SectionLabel('Actualizaciones'),
            const _UpdatesRow(),
            const SizedBox(height: 28),
            Divider(color: p.border),
            const SizedBox(height: 8),
            const _Credits(),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: context.palette.textTertiary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

/// Versión instalada y botón para buscar una nueva.
class _UpdatesRow extends StatefulWidget {
  const _UpdatesRow();

  @override
  State<_UpdatesRow> createState() => _UpdatesRowState();
}

class _UpdatesRowState extends State<_UpdatesRow> {
  bool _checking = false;

  Future<void> _checkUpdates() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    void say(String text) => messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));

    if (!updateController.enabled) {
      say('Las actualizaciones solo funcionan en la versión instalada.');
      return;
    }
    setState(() => _checking = true);
    try {
      final release = await updateController.check(force: true);
      if (!mounted) return;
      if (release == null) {
        say(
          'Ya tienes la última versión (${updateController.currentVersion}).',
        );
        return;
      }
      final homeContext = navigator.context;
      navigator.pop();
      if (!homeContext.mounted) return;
      await showUpdateSheet(homeContext, updateController, release);
    } on UpdateException catch (e) {
      say(e.message);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: p.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Versión instalada',
                  style: TextStyle(color: p.textSecondary, fontSize: 13),
                ),
                Text(
                  updateController.currentVersion,
                  style: TextStyle(
                    color: p.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: TextButton.icon(
              onPressed: _checking ? null : _checkUpdates,
              icon: _checking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.system_update_rounded, size: 18),
              label: const Text(
                'Buscar actualizaciones',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pie de la hoja: autor y enlace a GitHub.
class _Credits extends StatelessWidget {
  const _Credits();

  static const _githubUrl = 'https://github.com/jshvargsdev';

  Future<void> _openGithub(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await launchUrl(
      Uri.parse(_githubUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      children: [
        Text(
          'Desarrollado por Joshua Vargas',
          style: TextStyle(
            color: p.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        TextButton.icon(
          onPressed: () => _openGithub(context),
          icon: const Icon(Icons.code_rounded, size: 16),
          label: const Text('github.com/jshvargsdev'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../services/update_controller.dart';
import '../theme/app_theme.dart';
import 'update_sheet.dart';

/// Ícono que representa el modo de tema actual.
IconData themeModeIcon(ThemeMode mode) => switch (mode) {
  ThemeMode.system => Icons.brightness_auto_outlined,
  ThemeMode.light => Icons.light_mode_outlined,
  ThemeMode.dark => Icons.dark_mode_outlined,
};

/// Hoja con el selector de tema y los créditos de la app.
Future<void> showAppearanceSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (_) => const _AppearanceSheet(),
  );
}

class _AppearanceSheet extends StatelessWidget {
  const _AppearanceSheet();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: ListenableBuilder(
          listenable: appSettings,
          builder: (context, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Apariencia',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: p.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                style: _segmentStyle(p),
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
              const SizedBox(height: 28),
              const _Footer(),
            ],
          ),
        ),
      ),
    );
  }

  ButtonStyle _segmentStyle(AppPalette p) => SegmentedButton.styleFrom(
    selectedBackgroundColor: p.accentSoft,
    selectedForegroundColor: p.accent,
    foregroundColor: p.textSecondary,
    side: BorderSide(color: p.border),
    textStyle: const TextStyle(
      fontFamily: kFontFamily,
      fontWeight: FontWeight.w600,
    ),
  );
}

class _Footer extends StatefulWidget {
  const _Footer();

  @override
  State<_Footer> createState() => _FooterState();
}

class _FooterState extends State<_Footer> {
  static const _githubUrl = 'https://github.com/jshvargsdev';
  String? _version;
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
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _version = info.version);
  }

  Future<void> _openGithub() async {
    final ok = await launchUrl(
      Uri.parse(_githubUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
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
          onPressed: _openGithub,
          icon: const Icon(Icons.code_rounded, size: 16),
          label: const Text('github.com/jshvargsdev'),
        ),
        if (_version != null)
          Text(
            'v$_version',
            style: TextStyle(color: p.textTertiary, fontSize: 12),
          ),
        TextButton.icon(
          onPressed: _checking ? null : _checkUpdates,
          icon: _checking
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.system_update_rounded, size: 16),
          label: const Text('Buscar actualizaciones'),
        ),
      ],
    );
  }
}

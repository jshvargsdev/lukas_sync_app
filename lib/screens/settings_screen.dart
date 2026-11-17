import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: AnimatedBuilder(
        animation: appSettings,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              const _SectionHeader('Apariencia'),
              _Card(
                padding: const EdgeInsets.all(12),
                child: SegmentedButton<ThemeMode>(
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
              ),
              const SizedBox(height: 32),
              const _Footer(),
            ],
          );
        },
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

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

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

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _Card({required this.child, this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: padding,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: p.border),
      ),
      child: child,
    );
  }
}

class _Footer extends StatefulWidget {
  const _Footer();

  @override
  State<_Footer> createState() => _FooterState();
}

class _FooterState extends State<_Footer> {
  static const _githubUrl = 'https://github.com/jshvargsdev';
  String? _version;

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
      ],
    );
  }
}

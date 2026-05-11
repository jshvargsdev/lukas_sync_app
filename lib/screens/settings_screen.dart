import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../services/app_settings.dart';
import 'reorder_rates_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Ajustes',
          style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
        ),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([appSettings, customRatesStore]),
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _SectionHeader(text: 'Apariencia', isDark: isDark),
              RadioGroup<ThemeMode>(
                groupValue: appSettings.themeMode,
                onChanged: (v) {
                  if (v != null) appSettings.setThemeMode(v);
                },
                child: _SettingsCard(
                  isDark: isDark,
                  children: [
                    for (final mode in ThemeMode.values)
                      _RadioRow<ThemeMode>(
                        isDark: isDark,
                        value: mode,
                        title: _themeLabel(mode),
                        onSelected: () => appSettings.setThemeMode(mode),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionHeader(
                text: 'Actualización automática',
                isDark: isDark,
              ),
              RadioGroup<int>(
                groupValue: appSettings.refreshIntervalMinutes,
                onChanged: (v) {
                  if (v != null) appSettings.setRefreshIntervalMinutes(v);
                },
                child: _SettingsCard(
                  isDark: isDark,
                  children: [
                    for (final m in kRefreshIntervalChoices)
                      _RadioRow<int>(
                        isDark: isDark,
                        value: m,
                        title: 'Cada $m minutos',
                        onSelected: () =>
                            appSettings.setRefreshIntervalMinutes(m),
                      ),
                  ],
                ),
              ),
              if (customRatesStore.rates.length >= 2) ...[
                const SizedBox(height: 16),
                _SectionHeader(
                  text: 'Tasas personalizadas',
                  isDark: isDark,
                ),
                _SettingsCard(
                  isDark: isDark,
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.swap_vert,
                        color: isDark
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFF475569),
                      ),
                      title: Text(
                        'Reordenar tasas',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Arrastra para cambiar el orden de las tasas',
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ReorderRatesScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              const _Footer(),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Sistema';
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Oscuro';
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  final bool isDark;
  const _SectionHeader({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: isDark
              ? const Color(0xFF94A3B8)
              : const Color(0xFF64748B),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;
  const _SettingsCard({required this.children, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _RadioRow<T> extends StatelessWidget {
  final T value;
  final String title;
  final VoidCallback onSelected;
  final bool isDark;

  const _RadioRow({
    required this.value,
    required this.title,
    required this.onSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    return InkWell(
      onTap: onSelected,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Radio<T>(
              value: value,
              activeColor: const Color(0xFF16A34A),
            ),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
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
    final uri = Uri.parse(_githubUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final accent =
        isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Desarrollado por Joshua Vargas',
          style: TextStyle(
            color: subColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: _openGithub,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.code, size: 14, color: accent),
                const SizedBox(width: 6),
                Text(
                  'github.com/jshvargsdev',
                  style: TextStyle(
                    color: accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _version != null ? 'v$_version' : '',
          style: TextStyle(
            color: subColor.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

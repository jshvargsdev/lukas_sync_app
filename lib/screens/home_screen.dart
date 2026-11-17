import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/converter.dart';
import '../domain/currency.dart';
import '../domain/time_format.dart';
import '../main.dart';
import '../models/custom_rate.dart';
import '../theme/app_theme.dart';
import '../widgets/add_rate_card.dart';
import '../widgets/add_rate_modal.dart';
import '../widgets/appearance_sheet.dart';
import '../widgets/amount_hero.dart';
import '../widgets/currency_tile.dart';
import '../widgets/custom_keypad.dart';

const _kLongPressHintKey = '@lukas_longpress_hint_shown';

/// Ancho a partir del cual el teclado pasa a la derecha.
const double _kWideLayout = 720;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _activeId = kVesId;
  String _input = '0';

  /// Refresca el texto "hace X min" aunque no lleguen datos nuevos.
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    ratesController.addListener(_rebuild);
    customRatesStore.addListener(_onCustomRatesChanged);
    _clock = Timer.periodic(const Duration(minutes: 1), (_) => _rebuild());
  }

  @override
  void dispose() {
    ratesController.removeListener(_rebuild);
    customRatesStore.removeListener(_onCustomRatesChanged);
    _clock?.cancel();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _onCustomRatesChanged() {
    if (!mounted) return;
    setState(() {
      final exists =
          kOfficialIds.contains(_activeId) ||
          customRatesStore.rates.any((r) => r.id == _activeId);
      if (!exists) {
        _activeId = kVesId;
        _input = '0';
      }
    });
  }

  List<CurrencyOption> get _options => buildCurrencyOptions(
    rates: ratesController.rates,
    customRates: customRatesStore.rates,
  );

  // --- Teclado -------------------------------------------------------------

  void _handleKeyPress(String key) {
    setState(() {
      if (_input == '0' && key == '0') return;
      final next = _input == '0' ? key : _input + key;
      if (next.length > 12) return;
      _input = next;
    });
  }

  void _handleBackspace() {
    setState(() {
      _input = _input.length <= 1
          ? '0'
          : _input.substring(0, _input.length - 1);
    });
  }

  void _handleReset() => setState(() => _input = '0');

  void _select(String id) {
    if (id == _activeId) return;
    setState(() {
      _activeId = id;
      _input = '0';
    });
  }

  // --- Tasas personalizadas ------------------------------------------------

  Future<void> _openRateSheet({CustomRate? editing}) {
    return showAddRateModal(
      context: context,
      initialData: editing,
      onSave: (r) => _saveCustomRate(editing: editing, result: r),
      onDelete: () => _deleteCustomRate(editing),
    );
  }

  Future<void> _saveCustomRate({
    required CustomRate? editing,
    required AddRateModalResult result,
  }) async {
    final id = await customRatesStore.upsert(
      editing: editing,
      name: result.name,
      value: result.value,
      icon: result.icon,
    );
    if (!mounted) return;
    setState(() {
      _activeId = id;
      _input = '0';
    });
    Navigator.of(context).maybePop();
    if (editing == null) await _maybeShowLongPressHint();
  }

  Future<void> _deleteCustomRate(CustomRate? editing) async {
    if (editing == null) return;
    await customRatesStore.delete(editing.id);
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  Future<void> _maybeShowLongPressHint() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_kLongPressHintKey) == true) return;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tip: mantén presionada una tasa para copiarla o editarla.',
          ),
          duration: Duration(seconds: 5),
        ),
      );
      await prefs.setBool(_kLongPressHintKey, true);
    } catch (e) {
      debugPrint('Error guardando hint flag: $e');
    }
  }

  // --- Copiar ----------------------------------------------------------------

  Future<void> _copy(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$label copiado: $text'),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  /// Menú al mantener presionada una moneda: copiar tasa y editar.
  Future<void> _showTileActions(CurrencyOption o) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!o.isVes && o.rateInVes > 0)
              ListTile(
                leading: const Icon(Icons.percent_rounded),
                title: Text('Copiar tasa ${formatVes(o.rateInVes)}'),
                onTap: () {
                  Navigator.pop(ctx);
                  _copy(formatVes(o.rateInVes), 'Tasa');
                },
              ),
            if (o.isCustom)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Editar tasa'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openRateSheet(editing: o.custom);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // --- UI ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final options = _options;
    final active = options.firstWhere(
      (o) => o.id == _activeId,
      orElse: () => options.first,
    );
    final amount = centsInputToAmount(_input);

    final screenHeight = MediaQuery.sizeOf(context).height;
    final keypadHeight = screenHeight < 700
        ? 42.0
        : (screenHeight < 900 ? 48.0 : 54.0);
    final keypad = CustomKeypad(
      onKeyPress: _handleKeyPress,
      onBackspace: _handleBackspace,
      onReset: _handleReset,
      keyHeight: keypadHeight,
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= _kWideLayout;
            final content = Column(
              children: [
                _Header(onAppearance: () => showAppearanceSheet(context)),
                _NoticeBanner(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: AmountHero(
                    icon: active.icon,
                    name: active.name,
                    amount: formatVes(amount),
                    caption: _rateCaption(active),
                  ),
                ),
                Expanded(child: _buildList(options, active, amount)),
              ],
            );

            if (isWide) {
              return Row(
                children: [
                  Expanded(child: content),
                  SizedBox(
                    width: 380,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: SafeArea(top: false, child: keypad),
                    ),
                  ),
                ],
              );
            }
            return Column(
              children: [
                Expanded(child: content),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: SafeArea(top: false, child: keypad),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTile(CurrencyOption o, CurrencyOption active, double amount) {
    final converted = formatVes(
      convertAmount(
        amount: amount,
        fromRateInVes: active.rateInVes,
        toRateInVes: o.rateInVes,
      ),
    );
    return CurrencyTile(
      key: ValueKey('tile-${o.id}'),
      icon: o.icon,
      name: o.name,
      subtitle: o.isVes ? 'Moneda nacional' : 'Tasa ${formatVes(o.rateInVes)}',
      amount: converted,
      onTap: () => _select(o.id),
      onCopy: () => _copy(converted, 'Monto'),
      onLongPress: o.isVes ? null : () => _showTileActions(o),
    );
  }

  String _rateCaption(CurrencyOption o) {
    if (o.isVes) return 'Moneda nacional';
    if (o.rateInVes <= 0) return 'Tasa no disponible';
    return '1 ${o.name} = ${formatVes(o.rateInVes)} Bs';
  }

  Widget _buildList(
    List<CurrencyOption> options,
    CurrencyOption active,
    double amount,
  ) {
    final p = context.palette;
    final others = options.where((o) => o.id != active.id).toList();

    return RefreshIndicator(
      onRefresh: ratesController.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(
              'EQUIVALE A',
              style: TextStyle(
                color: p.textTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: p.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < others.length; i++) ...[
                  if (i > 0) const Divider(indent: 68),
                  _buildTile(others[i], active, amount),
                ],
              ],
            ),
          ),
          if (active.isCustom) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: () => _openRateSheet(editing: active.custom),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text('Editar ${active.name}'),
              ),
            ),
          ],
          const SizedBox(height: 12),
          AddRateTile(onPress: () => _openRateSheet()),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onAppearance;

  const _Header({required this.onAppearance});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = ratesController;
    final rates = c.rates;
    final String status;
    if (c.isLoading) {
      status = 'Actualizando…';
    } else if (rates != null) {
      status = 'Actualizado ${formatAge(rates.fetchedAt, now: DateTime.now())}';
    } else {
      status = 'Sin tasas todavía';
    }
    final dotColor = c.errorMessage != null || c.isStale
        ? p.warning
        : (rates != null ? p.accent : p.textTertiary);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Image.asset('assets/icon.png', width: 40, height: 40),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lukas Sync',
                  style: TextStyle(
                    color: p.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: p.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Actualizar',
            onPressed: c.isLoading ? null : c.refresh,
            icon: c.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.refresh_rounded, color: p.textSecondary),
          ),
          ListenableBuilder(
            listenable: appSettings,
            builder: (context, _) => IconButton(
              tooltip: 'Apariencia',
              onPressed: onAppearance,
              icon: Icon(
                themeModeIcon(appSettings.themeMode),
                color: p.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Aviso cuando el último refresco falló o los datos tienen más de 2 horas.
class _NoticeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = ratesController;
    final error = c.errorMessage;
    if (c.isLoading || (error == null && !c.isStale)) {
      return const SizedBox.shrink();
    }

    final noData = !c.hasRates;
    final fg = noData ? p.danger : p.warning;
    final bg = noData ? p.dangerSoft : p.warningSoft;
    final message = noData
        ? '$error'
        : (error != null
              ? 'No se pudo actualizar. Mostrando datos del '
                    '${formatDateTime(c.rates!.fetchedAt)}.'
              : 'Las tasas tienen más de 2 horas.');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
        child: Row(
          children: [
            Icon(Icons.cloud_off_rounded, size: 18, color: fg),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: fg,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: c.refresh,
              style: TextButton.styleFrom(foregroundColor: fg),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

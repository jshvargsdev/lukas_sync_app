import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../models/custom_rate.dart';
import '../services/rate_service.dart';
import '../widgets/add_rate_card.dart';
import '../widgets/add_rate_modal.dart';
import '../widgets/currency_card.dart';
import '../widgets/custom_keypad.dart';
import 'settings_screen.dart';

const _kRatesCacheKey = '@lukas_rates_cache';
const _kLongPressHintKey = '@lukas_longpress_hint_shown';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RateService _service = RateService();

  String _dolarBcv = '0.00';
  String _euroBcv = '0.00';
  String _usdtBinance = '0.00';
  DateTime _lastUpdated = DateTime.now();
  bool _hasRates = false;
  String _activeCurrency = 'VES';
  String _inputValue = '0';
  bool _isLoading = true;

  Timer? _ratesTimer;

  List<CustomRate> get _customRates => customRatesStore.rates;

  static final NumberFormat _veFormat = NumberFormat.decimalPatternDigits(
    locale: 'es_VE',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _bootstrap();
    _scheduleRatesTimer();
    appSettings.addListener(_onSettingsChanged);
    customRatesStore.addListener(_onCustomRatesChanged);
  }

  Future<void> _bootstrap() async {
    await _loadCachedRates();
    await _loadAllData();
  }

  @override
  void dispose() {
    appSettings.removeListener(_onSettingsChanged);
    customRatesStore.removeListener(_onCustomRatesChanged);
    _ratesTimer?.cancel();
    super.dispose();
  }

  void _onCustomRatesChanged() {
    if (!mounted) return;
    setState(() {
      if (_activeCurrency != 'VES' &&
          _activeCurrency != 'USD' &&
          _activeCurrency != 'EUR' &&
          _activeCurrency != 'USDT' &&
          !customRatesStore.rates.any((r) => r.id == _activeCurrency)) {
        _activeCurrency = 'VES';
        _inputValue = '0';
      }
    });
  }

  void _scheduleRatesTimer() {
    _ratesTimer?.cancel();
    _ratesTimer = Timer.periodic(
        appSettings.refreshInterval, (_) => _fetchRates());
  }

  void _onSettingsChanged() {
    _scheduleRatesTimer();
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  Future<void> _loadCachedRates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kRatesCacheKey);
      if (raw == null) return;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _dolarBcv = json['dolarBcv'] as String? ?? _dolarBcv;
        _euroBcv = json['euroBcv'] as String? ?? _euroBcv;
        _usdtBinance = json['usdtBinance'] as String? ?? _usdtBinance;
        final ts = json['fetchedAt'] as String?;
        if (ts != null) {
          _lastUpdated = DateTime.tryParse(ts)?.toLocal() ?? _lastUpdated;
        }
        _hasRates = true;
      });
    } catch (e) {
      debugPrint('Error cargando cache de tasas: $e');
    }
  }

  Future<void> _persistRatesCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kRatesCacheKey,
        jsonEncode({
          'dolarBcv': _dolarBcv,
          'euroBcv': _euroBcv,
          'usdtBinance': _usdtBinance,
          'fetchedAt': _lastUpdated.toUtc().toIso8601String(),
        }),
      );
    } catch (e) {
      debugPrint('Error guardando cache de tasas: $e');
    }
  }

  Future<void> _fetchRates() async {
    try {
      final rates = await _service.fetchRates();
      if (!mounted) return;
      setState(() {
        _dolarBcv = rates.dolarBcv;
        _euroBcv = rates.euroBcv;
        _usdtBinance = rates.usdtBinance;
        _lastUpdated = rates.fetchedAt;
        _hasRates = true;
      });
      await _persistRatesCache();
    } catch (e) {
      debugPrint('Error obteniendo tasas: $e');
    }
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    await _fetchRates();
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  void _handleKeyPress(String key) {
    if (key == '.') return;
    setState(() {
      final prev = _inputValue;
      if (prev == '0' && (key == '0' || key == '00')) return;
      final next = prev == '0' ? key : prev + key;
      if (next.length > 12) return;
      _inputValue = next;
    });
  }

  void _handleBackspace() {
    setState(() {
      _inputValue =
          _inputValue.length <= 1 ? '0' : _inputValue.substring(0, _inputValue.length - 1);
    });
  }

  void _handleReset() {
    setState(() => _inputValue = '0');
  }

  String _getCalculatedAmount(String targetCurrency) {
    final inputNum = (int.tryParse(_inputValue) ?? 0) / 100.0;

    if (targetCurrency == _activeCurrency) {
      return _veFormat.format(inputNum);
    }

    final Map<String, double> rates = {
      'USD': double.tryParse(_dolarBcv) ?? 1,
      'EUR': double.tryParse(_euroBcv) ?? 1,
      'USDT': double.tryParse(_usdtBinance) ?? 1,
    };
    for (final r in _customRates) {
      rates[r.id] = double.tryParse(r.value) ?? 0;
    }

    double amountInVES = 0;
    if (_activeCurrency == 'VES') {
      amountInVES = inputNum;
    } else if (rates.containsKey(_activeCurrency)) {
      amountInVES = inputNum * rates[_activeCurrency]!;
    }

    double finalAmount = 0;
    if (targetCurrency == 'VES') {
      finalAmount = amountInVES;
    } else if (rates.containsKey(targetCurrency)) {
      final r = rates[targetCurrency]!;
      if (r != 0) finalAmount = amountInVES / r;
    }

    return _veFormat.format(finalAmount);
  }

  void _onSelectCurrency(String id) {
    setState(() {
      _activeCurrency = id;
      _inputValue = '0';
    });
  }

  Future<void> _openAddRateModal({CustomRate? editing}) async {
    await showAddRateModal(
      context: context,
      initialData: editing,
      onSave: (r) => _handleSaveCustomRate(editing: editing, result: r),
      onDelete: () => _handleDeleteCustomRate(editing: editing),
    );
  }

  Future<void> _handleSaveCustomRate({
    required CustomRate? editing,
    required AddRateModalResult result,
  }) async {
    final newActiveId = await customRatesStore.upsert(
      editing: editing,
      name: result.name,
      value: result.value,
      icon: result.icon,
    );
    if (!mounted) return;
    setState(() {
      _activeCurrency = newActiveId;
      _inputValue = '0';
    });
    Navigator.of(context).maybePop();
    if (editing == null) {
      await _maybeShowLongPressHint();
    }
  }

  Future<void> _maybeShowLongPressHint() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_kLongPressHintKey) == true) return;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tip: mantén presionada una tasa para editarla o eliminarla.',
          ),
          duration: Duration(seconds: 5),
        ),
      );
      await prefs.setBool(_kLongPressHintKey, true);
    } catch (e) {
      debugPrint('Error guardando hint flag: $e');
    }
  }

  Future<void> _handleDeleteCustomRate({required CustomRate? editing}) async {
    if (editing == null) return;
    await customRatesStore.delete(editing.id);
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  String _formatLastUpdated(DateTime dt) {
    final formatter = DateFormat("d MMM, h:mm a", 'es_VE');
    return formatter.format(dt);
  }

  bool get _isStale =>
      _hasRates &&
      !_isLoading &&
      DateTime.now().difference(_lastUpdated) > const Duration(hours: 2);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isWide = width >= 720;
            return Column(
              children: [
                const SizedBox(height: 12),
                _buildHeader(isDark),
                const SizedBox(height: 12),
                if (_isStale)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                    child: _StaleBanner(
                      isDark: isDark,
                      lastUpdated: _formatLastUpdated(_lastUpdated),
                      onRefresh: _loadAllData,
                    ),
                  ),
                if (isWide)
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _buildCardsArea(isDark)),
                        SizedBox(
                          width: 380,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: CustomKeypad(
                              onKeyPress: _handleKeyPress,
                              onBackspace: _handleBackspace,
                              onReset: _handleReset,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  Expanded(child: _buildCardsArea(isDark)),
                  _buildBoundedKeypad(width),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lukas Sync',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _hasRates
                            ? _formatLastUpdated(_lastUpdated)
                            : (_isLoading
                                ? 'Cargando tasas…'
                                : 'Sin conexión'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _RefreshChip(
                        isLoading: _isLoading,
                        isDark: isDark,
                        onPressed: _loadAllData,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _BrandSettingsButton(isDark: isDark, onTap: _openSettings),
        ],
      ),
    );
  }

  Widget _buildCardsArea(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const horizontalPadding = 24.0;
        const spacing = 12.0;
        const targetWidth = 170.0;
        final available = constraints.maxWidth - horizontalPadding * 2;
        final columns =
            (available / targetWidth).floor().clamp(2, 6).toInt();
        final cardWidth =
            (available - spacing * (columns - 1)) / columns;
        return RefreshIndicator(
          onRefresh: _loadAllData,
          color: const Color(0xFF16A34A),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
                horizontalPadding, 0, horizontalPadding, 24),
            child: Wrap(
              spacing: spacing,
              runSpacing: 16,
              children: [
                CurrencyCard(
                  width: cardWidth,
                  title: 'Bolívares',
                  amount: _getCalculatedAmount('VES'),
                  variation: 'Moneda Nacional',
                  icon: '🇻🇪',
                  isActive: _activeCurrency == 'VES',
                  onPress: () => _onSelectCurrency('VES'),
                ),
                CurrencyCard(
                  width: cardWidth,
                  title: 'Dólar BCV',
                  amount: _getCalculatedAmount('USD'),
                  variation: 'Tasa: $_dolarBcv',
                  icon: '🇺🇸',
                  isActive: _activeCurrency == 'USD',
                  onPress: () => _onSelectCurrency('USD'),
                ),
                CurrencyCard(
                  width: cardWidth,
                  title: 'Euro BCV',
                  amount: _getCalculatedAmount('EUR'),
                  variation: 'Tasa: $_euroBcv',
                  icon: '🇪🇺',
                  isActive: _activeCurrency == 'EUR',
                  onPress: () => _onSelectCurrency('EUR'),
                ),
                CurrencyCard(
                  width: cardWidth,
                  title: 'USDT Binance',
                  amount: _getCalculatedAmount('USDT'),
                  variation: 'Tasa: $_usdtBinance',
                  icon: '₮',
                  isActive: _activeCurrency == 'USDT',
                  onPress: () => _onSelectCurrency('USDT'),
                ),
                ..._customRates.map((rate) {
                  final rateNum = double.tryParse(rate.value) ?? 0;
                  return _AnimatedAppearance(
                    key: ValueKey('custom-${rate.id}'),
                    child: CurrencyCard(
                      width: cardWidth,
                      title: rate.name,
                      amount: _getCalculatedAmount(rate.id),
                      variation:
                          'Tasa: ${_veFormat.format(rateNum)}',
                      icon: rate.icon,
                      isActive: _activeCurrency == rate.id,
                      onPress: () => _onSelectCurrency(rate.id),
                      onLongPress: () =>
                          _openAddRateModal(editing: rate),
                    ),
                  );
                }),
                AddRateCard(
                  width: cardWidth,
                  onPress: () => _openAddRateModal(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBoundedKeypad(double width) {
    final keypad = CustomKeypad(
      onKeyPress: _handleKeyPress,
      onBackspace: _handleBackspace,
      onReset: _handleReset,
    );
    if (width < 560) return keypad;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: keypad,
      ),
    );
  }
}

class _AnimatedAppearance extends StatelessWidget {
  final Widget child;
  const _AnimatedAppearance({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      builder: (context, t, c) {
        final scale = 0.85 + (0.15 * t.clamp(0.0, 1.0));
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.scale(scale: scale, child: c),
        );
      },
      child: child,
    );
  }
}

class _BrandSettingsButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _BrandSettingsButton({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final badgeBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final badgeIcon =
        isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);
    final badgeBorder =
        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Tooltip(
      message: 'Ajustes',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 2,
                  top: 2,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/icon.png',
                      width: 56,
                      height: 56,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: badgeBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: badgeBorder, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.settings,
                      size: 12,
                      color: badgeIcon,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StaleBanner extends StatelessWidget {
  final bool isDark;
  final String lastUpdated;
  final VoidCallback onRefresh;

  const _StaleBanner({
    required this.isDark,
    required this.lastUpdated,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0x33713F12) : const Color(0xFFFFFBEB);
    final borderColor =
        isDark ? const Color(0xFFB45309) : const Color(0xFFFDE68A);
    final fg = isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.cloud_off_outlined, size: 18, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Datos del $lastUpdated',
              maxLines: 2,
              style: TextStyle(
                color: fg,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onRefresh,
            style: TextButton.styleFrom(
              foregroundColor: fg,
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Reintentar',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _RefreshChip extends StatelessWidget {
  final bool isLoading;
  final bool isDark;
  final VoidCallback onPressed;

  const _RefreshChip({
    required this.isLoading,
    required this.isDark,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg =
        isDark ? const Color(0x3314532D) : const Color(0xFFDCFCE7);
    final Color borderColor =
        isDark ? const Color(0xFF15803D) : const Color(0xFFBBF7D0);
    final Color fg =
        isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor),
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: isLoading
                    ? CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(fg),
                      )
                    : Icon(Icons.refresh, size: 16, color: fg),
              ),
              const SizedBox(width: 6),
              Text(
                isLoading ? 'Cargando' : 'Actualizar',
                style: TextStyle(
                  color: fg,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/converter.dart';
import '../models/bcv_publication.dart';
import '../services/rate_source.dart';
import '../services/v1_rates_api.dart';
import '../theme/app_theme.dart';
import '../widgets/copy_to_clipboard.dart';

/// Primera fecha que se puede elegir en el calendario.
final DateTime kHistoryFirstDate = DateTime(2020);

/// Publicaciones que se piden por página.
const int kHistoryPageSize = 30;

/// Historial del BCV: un card por publicación, de la más reciente a la más
/// antigua, con carga al bajar y un calendario para saltar a una fecha.
class HistoryScreen extends StatefulWidget {
  final RateHistorySource source;
  final DateTime Function() now;

  const HistoryScreen({super.key, required this.source, this.now = _now});

  static DateTime _now() => DateTime.now();

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _scroll = ScrollController();
  final List<BcvPublication> _items = [];
  DateTime? _nextBefore;
  bool _hasMore = true;
  bool _loading = false;
  String? _error;

  /// Fecha elegida en el calendario; null = desde la más reciente.
  DateTime? _jumpedTo;

  /// Descarta respuestas de una consulta anterior (p. ej. tras saltar).
  int _generation = 0;

  DateTime get _today {
    final n = widget.now();
    return DateTime(n.year, n.month, n.day);
  }

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _restart();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < 400) _loadMore();
  }

  /// Vacía la lista y carga desde [_jumpedTo] (o desde la más reciente).
  Future<void> _restart() async {
    _generation++;
    setState(() {
      _items.clear();
      _hasMore = true;
      _error = null;
      _loading = false;
      // La vigente en una fecha es la de mayor fecha valor <= esa fecha, así
      // que se piden las anteriores al día siguiente.
      _nextBefore = _jumpedTo?.add(const Duration(days: 1));
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    final gen = _generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await widget.source.bcvHistory(
        before: _nextBefore,
        limit: kHistoryPageSize,
      );
      if (!mounted || gen != _generation) return;
      setState(() {
        _items.addAll(page.items);
        _nextBefore = page.nextBefore;
        _hasMore = page.nextBefore != null && page.items.isNotEmpty;
      });
    } on RateFetchException catch (e) {
      if (!mounted || gen != _generation) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted || gen != _generation) return;
      setState(() => _error = 'No se pudo cargar el historial.');
    } finally {
      if (mounted && gen == _generation) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _jumpedTo ?? _today,
      firstDate: kHistoryFirstDate,
      lastDate: _today,
      helpText: 'Ir a una fecha',
    );
    if (picked == null) return;
    _jumpedTo = picked;
    await _restart();
  }

  void _clearJump() {
    _jumpedTo = null;
    _restart();
  }

  @override
  Widget build(BuildContext context) {
    final rows = _buildRows();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial BCV'),
        actions: [
          IconButton(
            tooltip: 'Ir a una fecha',
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_month_outlined),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _restart,
        child: ListView.builder(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: rows.length,
          itemBuilder: (context, i) => rows[i],
        ),
      ),
    );
  }

  List<Widget> _buildRows() {
    final rows = <Widget>[];
    if (_jumpedTo != null) {
      rows.add(_JumpBanner(date: _jumpedTo!, onClear: _clearJump));
    }

    // La publicación vigente hoy: la de mayor fecha valor <= hoy.
    final today = _today;
    final current = _jumpedTo == null
        ? _items.where((p) => !p.valueDate.isAfter(today)).firstOrNull
        : null;

    String? lastMonth;
    for (final p in _items) {
      final month = DateFormat('MMMM y', 'es_VE').format(p.valueDate);
      if (month != lastMonth) {
        rows.add(_MonthHeader(month));
        lastMonth = month;
      }
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: PublicationCard(
            key: ValueKey(p.valueDate),
            publication: p,
            badge: p.valueDate.isAfter(today)
                ? 'Próxima'
                : (identical(p, current) ? 'Vigente' : null),
          ),
        ),
      );
    }

    if (_loading) {
      rows.add(
        const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    } else if (_error != null) {
      rows.add(_Message(text: _error!, onRetry: _loadMore));
    } else if (_items.isEmpty) {
      rows.add(
        _Message(
          text: _jumpedTo == null
              ? 'Todavía no hay tasas guardadas.'
              : 'No hay tasas guardadas para esa fecha.',
        ),
      );
    } else if (!_hasMore) {
      rows.add(const _Message(text: 'No hay tasas anteriores.', icon: null));
    }
    return rows;
  }
}

/// Card de una publicación, con las tasas en columnas como el widget.
/// Tocar una tasa la copia.
class PublicationCard extends StatelessWidget {
  final BcvPublication publication;
  final String? badge;

  const PublicationCard({super.key, required this.publication, this.badge});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final label = DateFormat(
      "EEE d 'de' MMMM",
      'es_VE',
    ).format(publication.valueDate).replaceAll('.', '');
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: badge == 'Vigente' ? p.accent : p.border),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label[0].toUpperCase() + label.substring(1),
                  style: TextStyle(
                    color: p.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: p.accentSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      color: p.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _RateColumn(
                    label: '🇺🇸 Dólar',
                    rate: publication.usd,
                  ),
                ),
                VerticalDivider(color: p.border, width: 1, thickness: 1),
                Expanded(
                  child: _RateColumn(label: '🇪🇺 Euro', rate: publication.eur),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RateColumn extends StatelessWidget {
  final String label;
  final double rate;

  const _RateColumn({required this.label, required this.rate});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = formatRate(rate);
    return InkWell(
      onTap: () => copyWithFeedback(context, text, label: 'Tasa'),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: p.textSecondary, fontSize: 12)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: text,
                      style: TextStyle(
                        color: p.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFeatures: kTabularFigures,
                      ),
                    ),
                    TextSpan(
                      text: ' Bs',
                      style: TextStyle(color: p.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final String text;
  const _MonthHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
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

class _JumpBanner extends StatelessWidget {
  final DateTime date;
  final VoidCallback onClear;

  const _JumpBanner({required this.date, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
        decoration: BoxDecoration(
          color: p.accentSoft,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Desde el ${DateFormat("d 'de' MMMM 'de' y", 'es_VE').format(date)}',
                style: TextStyle(color: p.accent, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(onPressed: onClear, child: const Text('Ver recientes')),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  final VoidCallback? onRetry;
  final IconData? icon;

  const _Message({
    required this.text,
    this.onRetry,
    this.icon = Icons.event_busy_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      child: Column(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 36, color: p.textTertiary),
            const SizedBox(height: 12),
          ],
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: p.textSecondary, fontSize: 14),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

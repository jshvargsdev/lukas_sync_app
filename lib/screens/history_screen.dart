import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/converter.dart';
import '../models/bcv_historic_rate.dart';
import '../services/rate_source.dart';
import '../services/v1_rates_api.dart';
import '../theme/app_theme.dart';
import '../widgets/copy_to_clipboard.dart';
import '../widgets/currency_tile.dart';

/// Primera fecha que se puede elegir. La API solo tiene datos desde que se
/// desplegó; antes de eso responde 404 y se muestra un aviso.
final DateTime kHistoryFirstDate = DateTime(2020);

/// Consulta la tasa BCV vigente en una fecha pasada.
class HistoryScreen extends StatefulWidget {
  /// null si la app se compiló sin la API v1 configurada.
  final RateHistorySource? source;
  final DateTime Function() now;

  const HistoryScreen({super.key, required this.source, this.now = _now});

  static DateTime _now() => DateTime.now();

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late DateTime _date;
  BcvHistoricRate? _rate;
  String? _error;
  bool _loading = false;

  /// Evita que una respuesta lenta de una fecha anterior pise la actual.
  int _requestId = 0;

  DateTime get _today {
    final n = widget.now();
    return DateTime(n.year, n.month, n.day);
  }

  @override
  void initState() {
    super.initState();
    _date = _today.subtract(const Duration(days: 1));
    _load();
  }

  Future<void> _load() async {
    final source = widget.source;
    if (source == null) {
      setState(() {
        _error =
            'El historial estará disponible cuando la app use el nuevo '
            'servicio de tasas.';
      });
      return;
    }
    final id = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
      _rate = null;
    });
    try {
      final rate = await source.bcvRateOn(_date);
      if (!mounted || id != _requestId) return;
      setState(() => _rate = rate);
    } on RateFetchException catch (e) {
      if (!mounted || id != _requestId) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted || id != _requestId) return;
      setState(() => _error = 'No se pudo consultar la tasa de esa fecha.');
    } finally {
      if (mounted && id == _requestId) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: kHistoryFirstDate,
      lastDate: _today,
      helpText: 'Elige una fecha',
    );
    if (picked == null || picked == _date) return;
    setState(() => _date = picked);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(title: const Text('Historial BCV')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _DateCard(date: _date, onTap: _pickDate),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            _Message(
              text: _error!,
              onRetry: widget.source == null ? null : _load,
            )
          else if (_rate != null) ...[
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: p.border),
              ),
              child: Column(
                children: [
                  _rateTile('🇺🇸', 'Dólar BCV', 'Bs por dólar', _rate!.usd),
                  const Divider(indent: 68),
                  _rateTile('🇪🇺', 'Euro BCV', 'Bs por euro', _rate!.eur),
                ],
              ),
            ),
            if (_rate!.isFromEarlierDay)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
                child: Text(
                  'Ese día no hubo publicación del BCV. Aplica la tasa con '
                  'fecha valor del '
                  '${DateFormat("EEEE d 'de' MMMM", 'es_VE').format(_rate!.valueDate)}.',
                  style: TextStyle(color: p.textSecondary, fontSize: 13),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _rateTile(String icon, String name, String subtitle, double rate) {
    final text = formatRate(rate);
    void copy() => copyWithFeedback(context, text, label: 'Tasa');
    return CurrencyTile(
      icon: icon,
      name: name,
      subtitle: subtitle,
      amount: '$text Bs',
      onTap: copy,
      onCopy: copy,
    );
  }
}

class _DateCard extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;

  const _DateCard({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final label = DateFormat("EEEE, d 'de' MMMM 'de' y", 'es_VE').format(date);
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: p.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FECHA',
                      style: TextStyle(
                        color: p.textTertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label[0].toUpperCase() + label.substring(1),
                      style: TextStyle(
                        color: p.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.calendar_month_outlined, color: p.accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  final VoidCallback? onRetry;

  const _Message({required this.text, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      child: Column(
        children: [
          Icon(Icons.event_busy_outlined, size: 36, color: p.textTertiary),
          const SizedBox(height: 12),
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

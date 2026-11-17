import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/emojis.dart';
import '../domain/converter.dart';
import '../models/custom_rate.dart';
import '../models/rates.dart';
import '../theme/app_theme.dart';

class AddRateModalResult {
  final String name;
  final String value;
  final String icon;
  const AddRateModalResult({
    required this.name,
    required this.value,
    required this.icon,
  });
}

Future<void> showAddRateModal({
  required BuildContext context,
  required CustomRate? initialData,
  required void Function(AddRateModalResult result) onSave,
  required VoidCallback onDelete,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: _AddRateModalContent(
        initialData: initialData,
        onSave: onSave,
        onDelete: onDelete,
      ),
    ),
  );
}

class _AddRateModalContent extends StatefulWidget {
  final CustomRate? initialData;
  final void Function(AddRateModalResult result) onSave;
  final VoidCallback onDelete;

  const _AddRateModalContent({
    required this.initialData,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<_AddRateModalContent> createState() => _AddRateModalContentState();
}

class _AddRateModalContentState extends State<_AddRateModalContent> {
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();
  String _icon = '🇺🇸';
  String _rawValue = '0';
  String? _error;

  bool get _isEditing => widget.initialData != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialData;
    if (initial != null) {
      _nameController.text = initial.name;
      _icon = initial.icon;
      final cents = Rates.parseRate(initial.value) * 100;
      _rawValue = cents.round().toString();
    }
    _valueController.text = _displayValue;
    _valueController.addListener(_handleValueChanged);
  }

  @override
  void dispose() {
    _valueController.removeListener(_handleValueChanged);
    _nameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  double get _numericValue => centsInputToAmount(_rawValue);

  String get _displayValue => formatVes(_numericValue);

  /// El campo se escribe en centavos y se reformatea a 1.234,56 al vuelo.
  void _handleValueChanged() {
    final digitsOnly = _valueController.text.replaceAll(RegExp(r'\D'), '');
    var next = digitsOnly.isEmpty ? '0' : digitsOnly;
    next = next.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (next.length > 12) next = _rawValue;
    if (next != _rawValue) setState(() => _rawValue = next);
    final desired = _displayValue;
    if (_valueController.text != desired) {
      _valueController.value = TextEditingValue(
        text: desired,
        selection: TextSelection.collapsed(offset: desired.length),
      );
    }
  }

  void _handleSave() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Escribe un nombre para la tasa.');
      return;
    }
    if (_numericValue <= 0) {
      setState(() => _error = 'El valor debe ser mayor que 0.');
      return;
    }
    widget.onSave(
      AddRateModalResult(
        name: name,
        value: _numericValue.toString(),
        icon: _icon,
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final name = widget.initialData?.name ?? '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar tasa'),
        content: Text('¿Seguro que quieres eliminar "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: ctx.palette.danger),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) widget.onDelete();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditing ? 'Editar tasa' : 'Nueva tasa',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Define cuántos bolívares vale 1 unidad.',
                      style: TextStyle(fontSize: 14, color: p.textSecondary),
                    ),
                  ],
                ),
              ),
              if (_isEditing)
                IconButton.filledTonal(
                  tooltip: 'Eliminar',
                  onPressed: _confirmDelete,
                  style: IconButton.styleFrom(
                    backgroundColor: p.dangerSoft,
                    foregroundColor: p.danger,
                  ),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _Label('Nombre'),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 30,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            style: TextStyle(color: p.textPrimary, fontSize: 16),
            decoration: const InputDecoration(
              hintText: 'Ej. Dólar paralelo',
              counterText: '',
            ),
          ),
          const SizedBox(height: 16),
          _Label('Valor en bolívares'),
          TextField(
            controller: _valueController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              fontFeatures: kTabularFigures,
            ),
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 16, right: 8),
                child: Text(
                  'Bs',
                  style: TextStyle(
                    color: p.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0),
            ),
          ),
          const SizedBox(height: 16),
          _Label('Ícono'),
          Container(
            height: 132,
            decoration: BoxDecoration(
              color: p.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              scrollDirection: Axis.horizontal,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              itemCount: kAllEmojis.length,
              itemBuilder: (context, i) {
                final e = kAllEmojis[i];
                final selected = e == _icon;
                return InkWell(
                  onTap: () => setState(() => _icon = e),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? p.accentSoft : p.surface,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                        width: 2,
                        color: selected ? p.accent : Colors.transparent,
                      ),
                    ),
                    child: Text(e, style: const TextStyle(fontSize: 24)),
                  ),
                );
              },
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: p.danger, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _handleSave,
            child: Text(_isEditing ? 'Guardar cambios' : 'Agregar tasa'),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            style: TextButton.styleFrom(
              foregroundColor: p.textSecondary,
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: context.palette.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

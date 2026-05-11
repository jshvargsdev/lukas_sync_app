import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../constants/emojis.dart';
import '../models/custom_rate.dart';

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
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(ctx).viewInsets.bottom,
      ),
      child: _AddRateModalContent(
        initialData: initialData,
        onSave: (r) {
          onSave(r);
        },
        onDelete: () {
          onDelete();
        },
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
  late TextEditingController _nameController;
  late TextEditingController _valueController;
  String _icon = '🇺🇸';
  String _rawValue = '0';
  bool _dropdownOpen = false;

  static final NumberFormat _veFormat = NumberFormat.decimalPatternDigits(
    locale: 'es_VE',
    decimalDigits: 2,
  );

  bool get _isEditing => widget.initialData != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _valueController = TextEditingController();

    final initial = widget.initialData;
    if (initial != null) {
      _nameController.text = initial.name;
      _icon = initial.icon;
      final cents = (double.tryParse(initial.value) ?? 0) * 100;
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

  double get _numericValue => (int.tryParse(_rawValue) ?? 0) / 100;

  String get _displayValue => _veFormat.format(_numericValue);

  void _handleValueChanged() {
    final digitsOnly = _valueController.text.replaceAll(RegExp(r'\D'), '');
    final next = digitsOnly.isEmpty ? '0' : digitsOnly;
    if (next == _rawValue) {
      final desired = _displayValue;
      if (_valueController.text != desired) {
        _valueController.value = TextEditingValue(
          text: desired,
          selection: TextSelection.collapsed(offset: desired.length),
        );
      }
      return;
    }
    setState(() {
      _rawValue = next;
    });
    final desired = _displayValue;
    _valueController.value = TextEditingValue(
      text: desired,
      selection: TextSelection.collapsed(offset: desired.length),
    );
  }

  void _handleSave() {
    final name = _nameController.text.trim();
    if (name.isEmpty || _numericValue <= 0) return;
    widget.onSave(AddRateModalResult(
      name: name,
      value: _numericValue.toString(),
      icon: _icon,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color sheetBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final Color fieldBg =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final Color fieldBorder =
        isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0);
    final Color labelColor =
        isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155);
    final Color textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final Color subTextColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return GestureDetector(
      onVerticalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) > 200) {
          Navigator.of(context).maybePop();
        }
      },
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 56,
                    height: 5,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF475569)
                          : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditing
                                ? 'Editar Tasa'
                                : 'Agregar Nueva Tasa',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isEditing
                                ? 'Actualiza el valor de tu referencia de mercado.'
                                : 'Personaliza tu propia referencia de mercado.',
                            maxLines: 2,
                            style: TextStyle(
                              fontSize: 13,
                              color: subTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isEditing) ...[
                      const SizedBox(width: 16),
                      InkWell(
                        onTap: widget.onDelete,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0x4D7F1D1D)
                                : const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF991B1B)
                                  : const Color(0xFFFEE2E2),
                            ),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                _Label(text: 'Nombre de la Moneda', color: labelColor),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  onTap: () => setState(() => _dropdownOpen = false),
                  style: TextStyle(color: textColor),
                  decoration: _inputDecoration(
                    fieldBg: fieldBg,
                    fieldBorder: fieldBorder,
                    hint: 'Ej. Dólar Paralelo',
                    hintColor: const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 16),
                _Label(text: 'Valor (VES)', color: labelColor),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: fieldBg,
                    border: Border.all(color: fieldBorder),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        'Bs',
                        style: TextStyle(
                          color: subTextColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _valueController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onTap: () => setState(() => _dropdownOpen = false),
                          style: TextStyle(fontSize: 18, color: textColor),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isCollapsed: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _Label(text: 'Seleccionar Ícono/Bandera', color: labelColor),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    setState(() => _dropdownOpen = !_dropdownOpen);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: fieldBg,
                      border: Border.all(
                        color: _dropdownOpen
                            ? const Color(0xFF16A34A)
                            : fieldBorder,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(_icon, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Cambiar ícono...',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: subTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(
                          _dropdownOpen
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 18,
                          color: const Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_dropdownOpen) ...[
                  const SizedBox(height: 8),
                  Container(
                    height: 160,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: fieldBg,
                      border: Border.all(color: fieldBorder),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: kAllEmojis.map((e) {
                          final selected = e == _icon;
                          return InkWell(
                            onTap: () => setState(() {
                              _icon = e;
                              _dropdownOpen = false;
                            }),
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selected
                                    ? (isDark
                                        ? const Color(0x6614532D)
                                        : const Color(0xFFDCFCE7))
                                    : (isDark
                                        ? const Color(0xFF334155)
                                        : Colors.white),
                                border: Border.all(
                                  width: 2,
                                  color: selected
                                      ? (isDark
                                          ? const Color(0xFF22C55E)
                                          : const Color(0xFF16A34A))
                                      : Colors.transparent,
                                ),
                              ),
                              child: Text(
                                e,
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _isEditing ? 'Actualizar Tasa' : 'Guardar Tasa',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFF1F5F9),
                      foregroundColor: isDark
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF475569),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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

  InputDecoration _inputDecoration({
    required Color fieldBg,
    required Color fieldBorder,
    required String hint,
    required Color hintColor,
  }) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color),
        );
    return InputDecoration(
      filled: true,
      fillColor: fieldBg,
      hintText: hint,
      hintStyle: TextStyle(color: hintColor),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: border(fieldBorder),
      enabledBorder: border(fieldBorder),
      focusedBorder: border(const Color(0xFF16A34A)),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final Color color;
  const _Label({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

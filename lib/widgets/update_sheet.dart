import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/app_release.dart';
import '../services/update_controller.dart';
import '../theme/app_theme.dart';

/// Aviso en el Home cuando hay una versión nueva.
class UpdateBanner extends StatelessWidget {
  final UpdateController controller;

  const UpdateBanner({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final release = controller.available;
        if (!controller.showBanner || release == null) {
          return const SizedBox.shrink();
        }
        final p = context.palette;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Material(
            color: p.accentSoft,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.md),
              onTap: () => showUpdateSheet(context, controller, release),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.system_update_rounded,
                      size: 20,
                      color: p.accent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Nueva versión ${release.version} disponible',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: p.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          showUpdateSheet(context, controller, release),
                      child: const Text('Actualizar'),
                    ),
                    IconButton(
                      tooltip: 'Ocultar',
                      visualDensity: VisualDensity.compact,
                      onPressed: controller.dismiss,
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: p.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

Future<void> showUpdateSheet(
  BuildContext context,
  UpdateController controller,
  AppRelease release,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _UpdateSheet(controller: controller, release: release),
  );
}

enum _Step { idle, needsPermission, downloading, launched }

class _UpdateSheet extends StatefulWidget {
  final UpdateController controller;
  final AppRelease release;

  const _UpdateSheet({required this.controller, required this.release});

  @override
  State<_UpdateSheet> createState() => _UpdateSheetState();
}

class _UpdateSheetState extends State<_UpdateSheet> {
  _Step _step = _Step.idle;
  double _progress = 0;
  String? _error;
  ReleaseAsset? _asset;

  /// APK ya descargado, para reabrir el instalador sin descargar de nuevo.
  String? _path;

  @override
  void initState() {
    super.initState();
    widget.controller
        .assetFor(widget.release)
        .then((a) {
          if (mounted) setState(() => _asset = a);
        })
        .catchError((Object e) {
          if (mounted) setState(() => _error = '$e');
        });
  }

  Future<void> _start() async {
    setState(() => _error = null);
    try {
      if (!await widget.controller.canInstall()) {
        setState(() => _step = _Step.needsPermission);
        return;
      }
      final asset = _asset ?? await widget.controller.assetFor(widget.release);
      setState(() {
        _step = _Step.downloading;
        _progress = 0;
      });
      final path = await widget.controller.download(
        asset,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      _path = path;
      await widget.controller.install(path);
      if (mounted) setState(() => _step = _Step.launched);
    } on UpdateException catch (e) {
      if (mounted) {
        setState(() {
          _step = _Step.idle;
          _error = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _step = _Step.idle;
          _error = 'No se pudo completar la actualización.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final size = _asset?.size ?? 0;
    final sizeText = size > 0
        ? ' · ${NumberFormat('0.0', 'es_VE').format(size / 1e6)} MB'
        : '';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Versión ${widget.release.version}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: p.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tienes la ${widget.controller.currentVersion}$sizeText',
            style: TextStyle(color: p.textSecondary, fontSize: 14),
          ),
          if (widget.release.notes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              constraints: const BoxConstraints(maxHeight: 240),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: p.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: SingleChildScrollView(
                child: Text(
                  widget.release.notes,
                  style: TextStyle(color: p.textPrimary, height: 1.4),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          ..._body(p),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: p.danger, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _body(AppPalette p) {
    switch (_step) {
      case _Step.idle:
        return [
          FilledButton(
            onPressed: _start,
            child: const Text('Descargar e instalar'),
          ),
        ];
      case _Step.needsPermission:
        return [
          Text(
            'Para actualizar, Android necesita que permitas que Lukas Sync '
            'instale apps. Activa el permiso, vuelve y toca "Descargar e '
            'instalar" otra vez. Solo se pide la primera vez.',
            style: TextStyle(color: p.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: widget.controller.openInstallSettings,
            child: const Text('Abrir ajustes'),
          ),
          TextButton(
            onPressed: _start,
            child: const Text('Descargar e instalar'),
          ),
        ];
      case _Step.downloading:
        return [
          LinearProgressIndicator(
            value: _progress > 0 ? _progress : null,
            minHeight: 8,
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 8),
          Text(
            'Descargando… ${(_progress * 100).round()} %',
            textAlign: TextAlign.center,
            style: TextStyle(color: p.textSecondary),
          ),
        ];
      case _Step.launched:
        return [
          Text(
            'Sigue los pasos del instalador de Android para terminar. Tus '
            'tasas y ajustes se conservan.',
            style: TextStyle(color: p.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => widget.controller.install(_path!),
            child: const Text('Abrir el instalador otra vez'),
          ),
        ];
    }
  }
}

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:media_tool/ui/core/themes/app_gradients.dart';
import 'package:media_tool/ui/core/themes/theme.dart';
import 'package:media_tool/ui/features/system/providers/system_monitor/system_monitor_notifier.dart';

/// A rolling line chart of the last minute: [values] oldest first, newest at
/// the right edge. [max] fixes the scale (1 for loads); null scales to the
/// highest value shown. [secondary] draws a second, thinner line (upload).
class const Sparkline({
  super.key,
  required final List<double> values,
  final List<double>? secondary,
  final double? max,
  final double height = 56,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        width: .infinity,
        child: CustomPaint(
          painter: _SparklinePainter(
            values: values,
            secondary: secondary,
            max: max,
            gridColor: colors.outline,
            secondaryColor: colors.secondary,
            fillAlpha: context.isDark ? 0.28 : 0.18,
          ),
        ),
      ),
    );
  }
}

class _SparklinePainter({
  required final List<double> values,
  required final List<double>? secondary,
  required final double? max,
  required final Color gridColor,
  required final Color secondaryColor,
  required final double fillAlpha,
}) extends CustomPainter {
  static const _slots = SystemMonitorNotifier.historyLength;
  static const _stroke = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (final fraction in const [0.5, 1.0]) {
      final y = (size.height - _stroke) * fraction + _stroke / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final secondary = this.secondary;
    final scale = max ?? [...values, ...?secondary].fold<double>(0, math.max<double>);
    if (scale <= 0) {
      return;
    }

    final primary = _path(values, size, scale);
    if (primary != null) {
      final fill = Path.from(primary)
        ..lineTo(size.width, size.height)
        ..lineTo(_x(values.length, 0, size), size.height)
        ..close();
      canvas
        ..drawPath(
          fill,
          Paint()
            ..shader = LinearGradient(
              begin: .topCenter,
              end: .bottomCenter,
              colors: [
                AppGradients.auroraColors.first.withValues(alpha: fillAlpha),
                AppGradients.auroraColors.first.withValues(alpha: 0),
              ],
            ).createShader(rect),
        )
        ..drawPath(
          primary,
          Paint()
            ..shader = const LinearGradient(colors: AppGradients.auroraColors).createShader(rect)
            ..style = .stroke
            ..strokeWidth = _stroke
            ..strokeJoin = .round
            ..strokeCap = .round,
        );
    }

    final secondaryPath = secondary == null ? null : _path(secondary, size, scale);
    if (secondaryPath case final path?) {
      canvas.drawPath(
        path,
        Paint()
          ..color = secondaryColor
          ..style = .stroke
          ..strokeWidth = _stroke * 0.75
          ..strokeJoin = .round
          ..strokeCap = .round,
      );
    }
  }

  Path? _path(List<double> series, Size size, double scale) {
    if (series.length < 2) {
      return null;
    }
    final drawable = size.height - _stroke;
    final path = Path();
    for (final (index, value) in series.indexed) {
      final x = _x(series.length, index, size);
      final y = _stroke / 2 + drawable * (1 - (value / scale).clamp(0, 1));
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    return path;
  }

  /// Newest point at the right edge; a minute fills the width.
  double _x(int length, int index, Size size) => size.width - (length - 1 - index) * size.width / (_slots - 1);

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      !identical(old.values, values) ||
      !identical(old.secondary, secondary) ||
      old.max != max ||
      old.gridColor != gridColor ||
      old.secondaryColor != secondaryColor ||
      old.fillAlpha != fillAlpha;
}

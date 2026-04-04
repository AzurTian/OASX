import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Spacing kept between two visible axis labels.
const double kStatisticsHistoryAxisLabelGap = 8;

/// Horizontal padding applied to each axis label.
const double kStatisticsHistoryAxisLabelPadding = 8;

/// Layout result for one visible history-axis label.
@immutable
class StatisticsHistoryAxisLabelLayout {
  /// Creates a positioned history-axis label layout.
  const StatisticsHistoryAxisLabelLayout({
    required this.tick,
    required this.label,
    required this.left,
    required this.width,
  });

  /// Tick value represented by the label.
  final double tick;

  /// Formatted label text rendered on the axis.
  final String label;

  /// Left offset relative to the axis container.
  final double left;

  /// Reserved width for the rendered label.
  final double width;
}

/// Resolves visible history-axis labels for the current width.
List<StatisticsHistoryAxisLabelLayout> resolveStatisticsHistoryAxisLabels({
  required List<double> ticks,
  required List<String> labels,
  required double axisMax,
  required double availableWidth,
  required TextStyle? style,
  TextDirection textDirection = TextDirection.ltr,
  double minimumGap = kStatisticsHistoryAxisLabelGap,
}) {
  if (ticks.isEmpty ||
      labels.isEmpty ||
      axisMax <= 0 ||
      availableWidth <= 0 ||
      ticks.length != labels.length) {
    return const <StatisticsHistoryAxisLabelLayout>[];
  }
  final measuredLabels = _measureAxisLabels(
    ticks: ticks,
    labels: labels,
    axisMax: axisMax,
    availableWidth: availableWidth,
    style: style,
    textDirection: textDirection,
  );
  if (measuredLabels.length <= 1) {
    return _positionAxisLabels(measuredLabels, availableWidth);
  }
  for (var step = 1; step < measuredLabels.length; step++) {
    final sampledLabels = _sampleAxisLabels(measuredLabels, step);
    final positionedLabels = _positionAxisLabels(sampledLabels, availableWidth);
    if (_axisLabelsDoNotOverlap(positionedLabels, minimumGap)) {
      return positionedLabels;
    }
  }
  return _resolveBoundaryAxisLabels(
    measuredLabels: measuredLabels,
    availableWidth: availableWidth,
    minimumGap: minimumGap,
  );
}

/// Measures the natural label widths used by axis sampling.
List<_MeasuredAxisLabel> _measureAxisLabels({
  required List<double> ticks,
  required List<String> labels,
  required double axisMax,
  required double availableWidth,
  required TextStyle? style,
  required TextDirection textDirection,
}) {
  final measuredLabels = <_MeasuredAxisLabel>[];
  for (var index = 0; index < ticks.length; index++) {
    final center = math.min(
      math.max((ticks[index] / axisMax) * availableWidth, 0),
      availableWidth,
    );
    final labelWidth = math.max(
      _measureTextWidth(labels[index], style, textDirection) +
          (kStatisticsHistoryAxisLabelPadding * 2),
      28,
    );
    measuredLabels.add(
      _MeasuredAxisLabel(
        tick: ticks[index],
        label: labels[index],
        center: center.toDouble(),
        width: labelWidth.toDouble(),
      ),
    );
  }
  return measuredLabels;
}

/// Measures one label with the provided text style.
double _measureTextWidth(
  String label,
  TextStyle? style,
  TextDirection textDirection,
) {
  final textPainter = TextPainter(
    text: TextSpan(text: label, style: style),
    maxLines: 1,
    textDirection: textDirection,
  )..layout();
  return textPainter.width;
}

/// Samples the full axis label list using the provided step.
List<_MeasuredAxisLabel> _sampleAxisLabels(
  List<_MeasuredAxisLabel> labels,
  int step,
) {
  final sampledLabels = <_MeasuredAxisLabel>[];
  final resolvedStep = math.max(step, 1);
  for (var index = 0; index < labels.length; index += resolvedStep) {
    sampledLabels.add(labels[index]);
  }
  if (!identical(sampledLabels.last, labels.last)) {
    sampledLabels.add(labels.last);
  }
  return sampledLabels;
}

/// Converts measured labels into concrete positioned layouts.
List<StatisticsHistoryAxisLabelLayout> _positionAxisLabels(
  List<_MeasuredAxisLabel> labels,
  double availableWidth,
) {
  return labels.map((label) {
    final maxLeft = math.max(availableWidth - label.width, 0);
    final left = math.min(
      math.max(label.center - (label.width / 2), 0),
      maxLeft,
    );
    return StatisticsHistoryAxisLabelLayout(
      tick: label.tick,
      label: label.label,
      left: left.toDouble(),
      width: label.width,
    );
  }).toList(growable: false);
}

/// Returns whether adjacent positioned labels still have free space between them.
bool _axisLabelsDoNotOverlap(
  List<StatisticsHistoryAxisLabelLayout> labels,
  double minimumGap,
) {
  for (var index = 1; index < labels.length; index++) {
    final previousLabel = labels[index - 1];
    final currentLabel = labels[index];
    if (previousLabel.left + previousLabel.width + minimumGap >
        currentLabel.left) {
      return false;
    }
  }
  return true;
}

/// Resolves the final boundary-only fallback for narrow layouts.
List<StatisticsHistoryAxisLabelLayout> _resolveBoundaryAxisLabels({
  required List<_MeasuredAxisLabel> measuredLabels,
  required double availableWidth,
  required double minimumGap,
}) {
  if (measuredLabels.length == 1) {
    return _positionAxisLabels(measuredLabels, availableWidth);
  }
  final maxBoundaryWidth =
      math.max((availableWidth - minimumGap) / 2, 0).toDouble();
  final boundaryLabels = <_MeasuredAxisLabel>[
    measuredLabels.first.capWidth(maxBoundaryWidth),
    measuredLabels.last.capWidth(maxBoundaryWidth),
  ];
  return _positionAxisLabels(boundaryLabels, availableWidth);
}

/// Measured axis label used internally by the sampling algorithm.
@immutable
class _MeasuredAxisLabel {
  /// Creates a measured axis label.
  const _MeasuredAxisLabel({
    required this.tick,
    required this.label,
    required this.center,
    required this.width,
  });

  /// Tick value represented by the label.
  final double tick;

  /// Formatted label text.
  final String label;

  /// Preferred center position for the label.
  final double center;

  /// Preferred label width before clamping.
  final double width;

  /// Returns a copy with a smaller reserved width.
  _MeasuredAxisLabel capWidth(double nextWidth) {
    return _MeasuredAxisLabel(
      tick: tick,
      label: label,
      center: center,
      width: math.min(width, nextWidth).toDouble(),
    );
  }
}

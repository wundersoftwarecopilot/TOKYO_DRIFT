import 'package:flutter/material.dart';

/// Widget for adjustable three-column layout with adjustable SQL Editor/Results height
class AdjustablePanels extends StatefulWidget {
  final double minWidth;
  final double maxWidth;
  final double minHeight;
  final double maxHeight;
  final Widget Function(BuildContext, double, double) sqlEditorBuilder;
  final Widget Function(BuildContext, double, double) resultsBuilder;
  final Widget Function(BuildContext, double, double) databaseStructureBuilder;
  final Widget Function(BuildContext, double, double) browseDataBuilder;

  const AdjustablePanels({
    super.key,
    required this.minWidth,
    required this.maxWidth,
    required this.minHeight,
    required this.maxHeight,
    required this.sqlEditorBuilder,
    required this.resultsBuilder,
    required this.databaseStructureBuilder,
    required this.browseDataBuilder,
  });

  @override
  State<AdjustablePanels> createState() => _AdjustablePanelsState();
}

class _AdjustablePanelsState extends State<AdjustablePanels> {
  // Initial widths: all equal (33.3%)
  double leftWidthRatio = 1 / 3;
  double middleWidthRatio = 1 / 3;
  double rightWidthRatio = 1 / 3;
  // Initial SQL Editor/Results height split (60% editor, 40% results)
  double sqlEditorHeightRatio = 0.6;

  @override
  Widget build(BuildContext context) {
    final totalWidth = widget.maxWidth;
    final totalHeight = widget.maxHeight;
    final minPanelWidth = widget.minWidth;
    
    // Each drag handle is 8 pixels wide, we have 2 of them
    const dragHandleWidth = 8.0;
    const totalDragHandleWidth = dragHandleWidth * 2;
    
    // Available width for panels after accounting for drag handles
    final availableWidth = totalWidth - totalDragHandleWidth;

    double leftWidth = (availableWidth * leftWidthRatio).clamp(minPanelWidth, availableWidth - 2 * minPanelWidth);
    double middleWidth = (availableWidth * middleWidthRatio).clamp(minPanelWidth, availableWidth - leftWidth - minPanelWidth);
    double rightWidth = availableWidth - leftWidth - middleWidth;

    // Clamp ratios if user resizes too far
    if (rightWidth < minPanelWidth) {
      rightWidth = minPanelWidth;
      middleWidth = availableWidth - leftWidth - rightWidth;
      middleWidth = middleWidth.clamp(minPanelWidth, availableWidth - leftWidth - rightWidth);
    }

    return Row(
      children: [
        // SQL Editor + Results (vertical split, both always visible)
        Expanded(
          flex: (leftWidthRatio * 1000).toInt(),
          child: _VerticalSplit(
            height: totalHeight,
            ratio: sqlEditorHeightRatio,
            onRatioChanged: (r) => setState(() => sqlEditorHeightRatio = r),
            top: (h) => widget.sqlEditorBuilder(context, leftWidth, h),
            bottom: (h) => widget.resultsBuilder(context, leftWidth, h),
          ),
        ),
        // Vertical drag handle between left and middle
        _VerticalDragHandle(
          onDrag: (dx) {
            setState(() {
              final deltaRatio = dx / availableWidth;
              leftWidthRatio = (leftWidthRatio + deltaRatio).clamp(0.2, 0.6);
              middleWidthRatio = (middleWidthRatio - deltaRatio).clamp(0.2, 0.6);
              rightWidthRatio = 1 - leftWidthRatio - middleWidthRatio;
            });
          },
        ),
        // Database Structure
        Expanded(
          flex: (middleWidthRatio * 1000).toInt(),
          child: widget.databaseStructureBuilder(context, middleWidth, totalHeight),
        ),
        // Vertical drag handle between middle and right
        _VerticalDragHandle(
          onDrag: (dx) {
            setState(() {
              final deltaRatio = dx / availableWidth;
              middleWidthRatio = (middleWidthRatio + deltaRatio).clamp(0.2, 0.6);
              rightWidthRatio = (rightWidthRatio - deltaRatio).clamp(0.2, 0.6);
              leftWidthRatio = 1 - middleWidthRatio - rightWidthRatio;
            });
          },
        ),
        // Browse Data
        Expanded(
          flex: (rightWidthRatio * 1000).toInt(),
          child: widget.browseDataBuilder(context, rightWidth, totalHeight),
        ),
      ],
    );
  }
}

class _VerticalSplit extends StatelessWidget {
  final double height;
  final double ratio;
  final ValueChanged<double> onRatioChanged;
  final Widget Function(double) top;
  final Widget Function(double) bottom;

  const _VerticalSplit({
    required this.height,
    required this.ratio,
    required this.onRatioChanged,
    required this.top,
    required this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final topHeight = (height * ratio).clamp(80.0, height - 80.0);
    final bottomHeight = height - topHeight;
    return Column(
      children: [
        Expanded(
          flex: (ratio * 1000).toInt(),
          child: top(topHeight),
        ),
        _HorizontalDragHandle(
          onDrag: (dy) {
            final newRatio = ((topHeight + dy) / height).clamp(0.15, 0.85);
            onRatioChanged(newRatio);
          },
        ),
        Expanded(
          flex: ((1 - ratio) * 1000).toInt(),
          child: bottom(bottomHeight),
        ),
      ],
    );
  }
}

class _VerticalDragHandle extends StatelessWidget {
  final ValueChanged<double> onDrag;
  const _VerticalDragHandle({required this.onDrag});
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: (details) => onDrag(details.delta.dx),
        child: Container(
          width: 8,
          color: Colors.transparent,
          child: Center(
            child: Container(
              width: 2,
              height: 32,
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
        ),
      ),
    );
  }
}

class _HorizontalDragHandle extends StatelessWidget {
  final ValueChanged<double> onDrag;
  const _HorizontalDragHandle({required this.onDrag});
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeUpDown,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragUpdate: (details) => onDrag(details.delta.dy),
        child: Container(
          height: 8,
          color: Colors.transparent,
          child: Center(
            child: Container(
              height: 2,
              width: 32,
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
        ),
      ),
    );
  }
}
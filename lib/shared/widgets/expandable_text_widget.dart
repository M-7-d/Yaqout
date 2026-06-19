import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ExpandableTextWidget extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int maxLines;

  const ExpandableTextWidget({
    super.key,
    required this.text,
    this.style,
    this.maxLines = 3,
  });

  @override
  State<ExpandableTextWidget> createState() => _ExpandableTextWidgetState();
}

class _ExpandableTextWidgetState extends State<ExpandableTextWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, size) {
        final span = TextSpan(text: widget.text, style: widget.style);
        final tp = TextPainter(
          text: span,
          maxLines: widget.maxLines,
          textDirection: TextDirection.ltr,
        );
        tp.layout(maxWidth: size.maxWidth);

        if (tp.didExceedMaxLines) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.text,
                style: widget.style,
                maxLines: _isExpanded ? null : widget.maxLines,
                overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Text(
                  _isExpanded ? 'Show Less' : 'Show More',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        } else {
          return Text(widget.text, style: widget.style);
        }
      },
    );
  }
}

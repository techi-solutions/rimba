import 'package:flutter/cupertino.dart';

class Button extends StatelessWidget {
  final String text;
  final double? minWidth;
  final double? maxWidth;
  final void Function()? onPressed;
  final Color? color;
  final Color? labelColor;
  final Widget? prefix;
  final Widget? suffix;
  final EdgeInsets? padding;

  const Button({
    super.key,
    this.onPressed,
    this.text = '',
    this.minWidth,
    this.maxWidth,
    this.color,
    this.labelColor,
    this.prefix,
    this.suffix,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final primaryColor = theme.primaryColor;
    final screenWidth = MediaQuery.of(context).size.width;

    final double defaultMinWidth = screenWidth < 375
        ? screenWidth * 0.85
        : screenWidth < 411
            ? (screenWidth * 0.5).clamp(180.0, 200.0)
            : 200.0;

    final double effectiveMinWidth = minWidth ?? defaultMinWidth;
    final double effectiveMaxWidth = maxWidth ?? effectiveMinWidth;

    return CupertinoButton(
      color: color ?? primaryColor,
      borderRadius: BorderRadius.circular(effectiveMinWidth / 2),
      onPressed: onPressed,
      padding: padding ?? const EdgeInsets.all(8),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: effectiveMinWidth,
          maxWidth: effectiveMaxWidth,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (prefix != null) prefix!,
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: labelColor ?? CupertinoColors.black,
                ),
              ),
            ),
            if (suffix != null) suffix!,
          ],
        ),
      ),
    );
  }
}

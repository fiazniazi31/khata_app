import 'package:flutter/material.dart';

class CustomNumpad extends StatelessWidget {
  final Function(String) onKeyPressed;
  final VoidCallback onDeletePressed;
  final VoidCallback? onClearPressed;
  final Widget? leftActionButton;

  const CustomNumpad({
    super.key,
    required this.onKeyPressed,
    required this.onDeletePressed,
    this.onClearPressed,
    this.leftActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget buildButton(String label, {VoidCallback? customAction}) {
      return Expanded(
        child: Container(
          margin: const EdgeInsets.all(8),
          child: Material(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9), // Slate 800 or Slate 100
            borderRadius: BorderRadius.circular(100),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: customAction ?? () => onKeyPressed(label),
              child: Container(
                height: 68,
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget buildIconButton(IconData icon, VoidCallback action) {
      return Expanded(
        child: Container(
          margin: const EdgeInsets.all(8),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(100),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: action,
              child: Container(
                height: 68,
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              buildButton('1'),
              buildButton('2'),
              buildButton('3'),
            ],
          ),
          Row(
            children: [
              buildButton('4'),
              buildButton('5'),
              buildButton('6'),
            ],
          ),
          Row(
            children: [
              buildButton('7'),
              buildButton('8'),
              buildButton('9'),
            ],
          ),
          Row(
            children: [
              // Left action (Clear or customized widget)
              if (leftActionButton != null)
                Expanded(child: leftActionButton!)
              else if (onClearPressed != null)
                buildIconButton(Icons.clear_all_rounded, onClearPressed!)
              else
                const Expanded(child: SizedBox()),
                
              buildButton('0'),
              buildIconButton(Icons.backspace_outlined, onDeletePressed),
            ],
          ),
        ],
      ),
    );
  }
}

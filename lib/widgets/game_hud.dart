import 'package:flutter/material.dart';

import '../services/table_look_controller.dart';
import 'table_theme.dart';

/// Верхняя полоса стола: назад и меню, без баллов.
class GameHud extends StatelessWidget {
  const GameHud({
    super.key,
    required this.onBack,
    required this.onMenu,
    required this.backTooltip,
    required this.menuTooltip,
  });

  final VoidCallback onBack;
  final VoidCallback onMenu;
  final String backTooltip;
  final String menuTooltip;

  static const copperHi = Color(0xFFE09A4A);
  static const copperMid = Color(0xFFB46828);
  static const copperLo = Color(0xFF7A3A12);
  static const copperRim = Color(0xFFF0C888);

  static const buttonSize = 40.0;
  static const chromeAsset = 'assets/ui/button_chrome.png';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            GameHudCircleButton(
              icon: Icons.arrow_back_rounded,
              iconSize: 22,
              tooltip: backTooltip,
              onPressed: onBack,
            ),
            const Spacer(),
            GameHudCircleButton(
              icon: Icons.menu_rounded,
              iconSize: 22,
              tooltip: menuTooltip,
              onPressed: onMenu,
            ),
          ],
        ),
      ),
    );
  }
}

class GameHudCircleButton extends StatelessWidget {
  const GameHudCircleButton({
    super.key,
    this.icon,
    this.child,
    required this.tooltip,
    this.semanticLabel,
    this.onPressed,
    this.iconSize = 18,
    this.size = GameHud.buttonSize,
    this.enabled = true,
  }) : assert(icon != null || child != null);

  final IconData? icon;
  final Widget? child;
  final String tooltip;
  final String? semanticLabel;
  final VoidCallback? onPressed;
  final double iconSize;
  final double size;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final dimmed = !enabled;
    final label = semanticLabel ?? tooltip;
    final casual = TableLookScope.lookOf(context).isCasual;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Tooltip(
        message: tooltip,
        excludeFromSemantics: true,
        child: Opacity(
          opacity: dimmed ? 0.55 : 1,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: enabled ? onPressed : null,
              customBorder: const CircleBorder(),
              child: casual
                  ? _CasualCircleButton(
                      size: size,
                      iconSize: iconSize,
                      icon: icon,
                      child: child,
                    )
                  : Ink(
                      width: size,
                      height: size,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            GameHud.copperHi,
                            GameHud.copperMid,
                            GameHud.copperLo,
                          ],
                          stops: [0.0, 0.45, 1.0],
                        ),
                        border: Border.fromBorderSide(
                          BorderSide(color: GameHud.copperRim, width: 1.6),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x66000000),
                            offset: Offset(0, 2),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      child: ExcludeSemantics(
                        child: Center(
                          child:
                              child ??
                              Icon(icon!, size: iconSize, color: Colors.white),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// PNG-хром с мокапа: иконка и бейдж рисуются сверху.
class _CasualCircleButton extends StatelessWidget {
  const _CasualCircleButton({
    required this.size,
    required this.iconSize,
    this.icon,
    this.child,
  });

  final double size;
  final double iconSize;
  final IconData? icon;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            GameHud.chromeAsset,
            width: size,
            height: size,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stack) => SizedBox(
              width: size,
              height: size,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: TableUi.buttonTop,
                  border: Border.fromBorderSide(
                    BorderSide(color: TableUi.goldRing, width: 4),
                  ),
                ),
              ),
            ),
          ),
          ExcludeSemantics(
            child:
                child ??
                Icon(
                  icon!,
                  size: iconSize,
                  color: TableUi.ivory,
                  shadows: const [
                    Shadow(
                      color: Color(0x66000000),
                      offset: Offset(0, 1),
                      blurRadius: 1.2,
                    ),
                  ],
                ),
          ),
        ],
      ),
    );
  }
}

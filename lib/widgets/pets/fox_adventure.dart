import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/pet.dart';
import '../../services/fox_adventure_store.dart';
import 'pet_portrait.dart';

String foxTitle(AppLocalizations l) => l.foxTitle;

String foxGoal(AppLocalizations l, int stage) => l.foxGoal(stage);

class FoxAdventureBanner extends StatelessWidget {
  const FoxAdventureBanner({
    super.key,
    required this.store,
    required this.onTap,
  });
  final FoxAdventureStore store;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Material(
      color: const Color(0xFF3A291D),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              const SizedBox(
                width: 44,
                height: 44,
                child: PetPortrait(kind: PetKind.fox),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      foxTitle(l),
                      style: const TextStyle(
                        color: Color(0xFFFFDB91),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      store.pending
                          ? l.foxSeeWhatChanged
                          : store.started
                          ? foxGoal(l, store.stage)
                          : l.foxHelpSettle,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                '${store.stage}/3',
                style: const TextStyle(color: Color(0xFFFFDB91)),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFFFFDB91)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared by the world and story scenes, so chosen decorations stay visible.
class FoxCorner extends StatefulWidget {
  const FoxCorner({
    super.key,
    required this.stage,
    this.blueBed = false,
    this.plushToy = false,
    this.showPet = true,
    this.onTap,
  });
  final int stage;
  final bool blueBed;
  final bool plushToy;
  final bool showPet;
  final VoidCallback? onTap;

  @override
  State<FoxCorner> createState() => _FoxCornerState();
}

class _FoxCornerState extends State<FoxCorner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!MediaQuery.disableAnimationsOf(context)) _motion.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant FoxCorner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stage != widget.stage &&
        !MediaQuery.disableAnimationsOf(context)) {
      _motion.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: foxTitle(AppLocalizations.of(context)),
    child: GestureDetector(
      onTap: () {
        if (!MediaQuery.disableAnimationsOf(context)) _motion.forward(from: 0);
        widget.onTap?.call();
      },
      child: LayoutBuilder(
        builder: (context, box) => AnimatedBuilder(
          animation: _motion,
          builder: (context, _) {
            final hop = TweenSequence<double>([
              TweenSequenceItem(tween: Tween(begin: 0, end: -12), weight: 20),
              TweenSequenceItem(tween: Tween(begin: -12, end: 0), weight: 20),
              TweenSequenceItem(tween: Tween(begin: 0, end: -6), weight: 15),
              TweenSequenceItem(tween: Tween(begin: -6, end: 0), weight: 15),
              TweenSequenceItem(tween: ConstantTween(0), weight: 30),
            ]).transform(_motion.value);
            return Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  bottom: 4,
                  child: Container(
                    width: box.maxWidth * .95,
                    height: box.maxHeight * .32,
                    decoration: BoxDecoration(
                      color: widget.stage > 0
                          ? const Color(0xFF9BA36A)
                          : const Color(0xFF626B3F),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: const Color(0xFFDAC694),
                        width: 3,
                      ),
                    ),
                  ),
                ),
                if (widget.stage >= 2)
                  Positioned(
                    bottom: 10,
                    child: Container(
                      key: const ValueKey('fox-bed'),
                      width: box.maxWidth * .67,
                      height: box.maxHeight * .25,
                      decoration: BoxDecoration(
                        color: widget.blueBed
                            ? const Color(0xFF7BAFC1)
                            : const Color(0xFFE5AD6B),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: const Color(0xFFF9E4BB),
                          width: 4,
                        ),
                      ),
                    ),
                  ),
                if (widget.showPet)
                  Positioned(
                    bottom: box.maxHeight * .14,
                    child: Transform.translate(
                      offset: Offset(0, hop),
                      child: SizedBox(
                        width: box.maxWidth * .64,
                        height: box.maxHeight * .72,
                        child: const PetPortrait(kind: PetKind.fox),
                      ),
                    ),
                  ),
                if (widget.stage == 0) ...[
                  const Positioned(
                    left: 12,
                    bottom: 12,
                    child: Icon(Icons.eco, color: Color(0xFFD4A054)),
                  ),
                  const Positioned(
                    right: 12,
                    bottom: 22,
                    child: Icon(Icons.eco, color: Color(0xFFBE8049)),
                  ),
                ],
                if (widget.stage >= 3)
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Icon(
                      widget.plushToy
                          ? Icons.smart_toy_rounded
                          : Icons.sports_baseball,
                      key: const ValueKey('fox-toy'),
                      color: const Color(0xFFFFD478),
                      size: box.maxWidth * .2,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

Future<void> showFoxAdventure(BuildContext context, FoxAdventureStore store) =>
    showDialog<void>(
      context: context,
      builder: (_) => _FoxStoryDialog(store: store),
    );

class _FoxStoryDialog extends StatefulWidget {
  const _FoxStoryDialog({required this.store});
  final FoxAdventureStore store;
  @override
  State<_FoxStoryDialog> createState() => _FoxStoryDialogState();
}

class _FoxStoryDialogState extends State<_FoxStoryDialog> {
  late bool blue = widget.store.blueBed;
  late bool plush = widget.store.plushToy;
  bool busy = false;
  String? error;

  Future<void> _save() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (!widget.store.started) {
        await widget.store.start();
      } else if (widget.store.pending) {
        await widget.store.finishScene(blueBed: blue, plushToy: plush);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          busy = false;
          error = AppLocalizations.of(context).foxSaveFailed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final store = widget.store;
    final stage = store.stage;
    final story = !store.started
        ? l.foxIntro
        : switch (stage) {
            0 => l.foxStage0,
            1 => l.foxStage1,
            2 => l.foxStage2,
            _ => l.foxStageDone,
          };
    return PopScope(
      canPop: !busy,
      child: AlertDialog(
        backgroundColor: const Color(0xFF3A291D),
        title: Text(
          foxTitle(l),
          style: const TextStyle(color: Color(0xFFFFDB91)),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 230,
                height: 160,
                child: FoxCorner(stage: stage, blueBed: blue, plushToy: plush),
              ),
              const SizedBox(height: 12),
              Text(story, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 12),
              Text(
                '$stage / 3',
                style: const TextStyle(color: Color(0xFFFFDB91)),
              ),
              if (stage == 2 && store.pending)
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(l.foxHoney),
                      selected: !blue,
                      onSelected: busy
                          ? null
                          : (_) => setState(() => blue = false),
                    ),
                    ChoiceChip(
                      label: Text(l.foxSkyBlue),
                      selected: blue,
                      onSelected: busy
                          ? null
                          : (_) => setState(() => blue = true),
                    ),
                  ],
                ),
              if (stage == 3 && store.pending)
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(l.foxBall),
                      selected: !plush,
                      onSelected: busy
                          ? null
                          : (_) => setState(() => plush = false),
                    ),
                    ChoiceChip(
                      label: Text(
                        l.foxPlushToy,
                      ),
                      selected: plush,
                      onSelected: busy
                          ? null
                          : (_) => setState(() => plush = true),
                    ),
                  ],
                ),
              if (error != null)
                Text(
                  error!,
                  style: const TextStyle(color: Colors.orangeAccent),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: busy ? null : () => Navigator.of(context).pop(),
            child: Text(l.later),
          ),
          FilledButton(
            onPressed: busy ? null : _save,
            child: Text(
              !store.started
                  ? l.foxHelpStages
                  : store.complete
                  ? l.foxLovely
                  : l.continueGame,
            ),
          ),
        ],
      ),
    );
  }
}

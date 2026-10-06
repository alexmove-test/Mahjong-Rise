import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/seed_batch.dart';
import '../../models/seed_catalog.dart';
import '../../services/points_controller.dart';
import 'seed_glyph.dart';

const _ivory = Color(0xFFF8F1DE);
const _goldSoft = Color(0xFFE8C96A);
const _gold = Color(0xFFD4AF37);
const _wood = Color(0xFF3A2012);

/// Хранилище семян. Возвращает true, если нужно открыть дом.
Future<bool> showSeedStorage(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.38),
    builder: (ctx) {
      return SeedStorageSheet(height: MediaQuery.sizeOf(ctx).height * 0.78);
    },
  ).then((value) => value ?? false);
}

class SeedStorageSheet extends StatefulWidget {
  const SeedStorageSheet({super.key, required this.height});

  final double height;

  @override
  State<SeedStorageSheet> createState() => _SeedStorageSheetState();
}

class _SeedStorageSheetState extends State<SeedStorageSheet> {
  var _sort = SeedSort.received;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final points = PointsScope.of(context);
    return ListenableBuilder(
      listenable: points,
      builder: (context, _) {
        final seeds = points.seeds.inventory;
        final stacks = stackSeeds(seeds, sort: _sort);
        return Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: _wood,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            child: SizedBox(
              height: widget.height,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _gold.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Text(
                      l10n.seedsHeading,
                      key: const ValueKey('seed-storage-title'),
                      style: const TextStyle(
                        color: _goldSoft,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                    child: Text(
                      '${seeds.length}',
                      key: const ValueKey('seed-storage-count'),
                      style: const TextStyle(
                        color: _ivory,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (seeds.isEmpty)
                    Expanded(
                      child: _EmptySeeds(
                        onProduce: () => Navigator.of(context).pop(true),
                      ),
                    )
                  else ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          _SortChip(
                            label: l10n.seedSortTime,
                            selected: _sort == SeedSort.received,
                            onTap: () =>
                                setState(() => _sort = SeedSort.received),
                          ),
                          _SortChip(
                            label: l10n.seedSortPower,
                            selected: _sort == SeedSort.power,
                            onTap: () => setState(() => _sort = SeedSort.power),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 0.92,
                            ),
                        itemCount: stacks.length,
                        itemBuilder: (context, index) {
                          final stack = stacks[index];
                          return _SeedStackCard(
                            stack: stack,
                            onTap: () => _showDetails(context, stack),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showDetails(BuildContext context, SeedStack stack) {
    final l10n = AppLocalizations.of(context);
    final local = stack.receivedAt.toLocal();
    final material = MaterialLocalizations.of(context);
    final date =
        '${material.formatShortDate(local)} ${material.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
    return showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          key: const ValueKey('seed-details'),
          backgroundColor: _wood,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: _gold.withValues(alpha: 0.7)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SeedGlyph(size: 72, species: stack.species),
              const SizedBox(height: 8),
              Text(
                l10n.seedName(stack.species),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _ivory,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.seedBlurb(stack.species),
                textAlign: TextAlign.center,
                style: const TextStyle(color: _goldSoft, height: 1.3),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.seedClassName(stack.species.seedClass),
                style: const TextStyle(color: _ivory),
              ),
              Text(
                l10n.seedPowerLabel(SeedCatalog.foodFor(stack.species)),
                style: const TextStyle(color: _ivory),
              ),
              Text(
                l10n.seedHouseLevel(stack.houseLevel),
                key: const ValueKey('seed-detail-house'),
                style: const TextStyle(color: _ivory),
              ),
              Text(
                l10n.seedReceived(date),
                key: const ValueKey('seed-detail-date'),
                style: const TextStyle(color: _ivory),
              ),
              if (stack.count > 1)
                Text(
                  l10n.seedGroupCount(stack.count),
                  style: const TextStyle(color: _goldSoft),
                ),
              const SizedBox(height: 10),
              Text(
                l10n.seedPurpose,
                key: const ValueKey('seed-purpose'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: _goldSoft, height: 1.3),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptySeeds extends StatelessWidget {
  const _EmptySeeds({required this.onProduce});

  final VoidCallback onProduce;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SeedGlyph(size: 72, unknown: true),
          const SizedBox(height: 12),
          Text(
            l10n.seedsEmptyBody,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _ivory, height: 1.3),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const ValueKey('seed-produce-first'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6B3E24),
              foregroundColor: _goldSoft,
              minimumSize: const Size.fromHeight(44),
            ),
            onPressed: onProduce,
            child: Text(
              l10n.produceFirstSeed,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: const Color(0xFF6B3E24),
        backgroundColor: const Color(0xFF2A160C),
        labelStyle: TextStyle(
          color: selected ? _goldSoft : _ivory,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide(color: _gold.withValues(alpha: selected ? 0.9 : 0.35)),
      ),
    );
  }
}

class _SeedStackCard extends StatelessWidget {
  const _SeedStackCard({required this.stack, required this.onTap});

  final SeedStack stack;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = l10n.seedName(stack.species);
    return Semantics(
      button: true,
      label: l10n.seedStackLabel(
        name,
        SeedCatalog.foodFor(stack.species),
        stack.count,
      ),
      child: Material(
        color: const Color(0xFF2A160C),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          key: ValueKey('seed-stack-${stack.species.name}-${stack.power}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _gold.withValues(alpha: 0.45)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: SeedGlyph(size: 52, species: stack.species)),
                  const Spacer(),
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ivory,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    l10n.seedPowerLabel(SeedCatalog.foodFor(stack.species)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _goldSoft, fontSize: 12),
                  ),
                  Text(
                    l10n.seedGroupCount(stack.count),
                    style: const TextStyle(
                      color: _ivory,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

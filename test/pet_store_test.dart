import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/models/pet.dart';
import 'package:mahjong/services/pet_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final t0 = DateTime(2026, 8, 30, 10);

  test('fullness decays to zero across the cycle', () {
    expect(
      PetNeeds.fullness(
        lastSatisfied: t0,
        need: PetNeed.hunger,
        now: t0,
      ),
      1,
    );
    expect(
      PetNeeds.fullness(
        lastSatisfied: t0,
        need: PetNeed.hunger,
        now: t0.add(const Duration(hours: 5)),
      ),
      closeTo(0.5, 0.001),
    );
    expect(
      PetNeeds.fullness(
        lastSatisfied: t0,
        need: PetNeed.hunger,
        now: t0.add(PetNeeds.hungerCycle),
      ),
      0,
    );
    expect(
      PetNeeds.fullness(
        lastSatisfied: t0,
        need: PetNeed.hunger,
        now: t0.add(const Duration(hours: 40)),
      ),
      0,
    );
  });

  test('most urgent prefers hunger on a tie', () {
    expect(
      PetNeeds.mostUrgent({
        PetNeed.hunger: 0.2,
        PetNeed.play: 0.2,
        PetNeed.rest: 0.2,
      }),
      PetNeed.hunger,
    );
    expect(
      PetNeeds.mostUrgent({
        PetNeed.hunger: 0.8,
        PetNeed.play: 0.1,
        PetNeed.rest: 0.4,
      }),
      PetNeed.play,
    );
  });

  test('mood is starving only when hunger is empty', () {
    expect(
      PetNeeds.mood(hunger: 0, play: 1, rest: 1),
      PetMood.starving,
    );
    expect(
      PetNeeds.mood(hunger: 0.2, play: 1, rest: 1),
      PetMood.asking,
    );
    expect(
      PetNeeds.mood(hunger: 0.9, play: 0.9, rest: 0.9),
      PetMood.content,
    );
  });

  test('nextThreshold is null after the cutoff has passed', () {
    expect(
      PetNeeds.nextThreshold(
        lastSatisfied: t0,
        need: PetNeed.hunger,
        threshold: PetNeeds.askThreshold,
        now: t0.add(const Duration(hours: 9)),
      ),
      isNull,
    );
    final askAt = PetNeeds.nextThreshold(
      lastSatisfied: t0,
      need: PetNeed.hunger,
      threshold: PetNeeds.askThreshold,
      now: t0,
    );
    expect(askAt, isNotNull);
    expect(askAt!.isAfter(t0), isTrue);
  });

  test('adopt adds a pet without resetting the others', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await PetStore.open();
    expect(store.hasPet, isFalse);

    await store.adopt(PetKind.cat, now: t0);
    expect(store.kind, PetKind.cat);
    expect(store.owned, [PetKind.cat]);
    expect(store.care(now: t0)!.of(PetNeed.hunger), 1);

    await store.adopt(PetKind.fox, now: t0.add(const Duration(hours: 5)));
    expect(store.owned, [PetKind.cat, PetKind.fox]);
    expect(store.owns(PetKind.cat), isTrue);
    expect(store.owns(PetKind.fox), isTrue);
    expect(
      store.care(kind: PetKind.cat, now: t0.add(const Duration(hours: 5)))!
          .of(PetNeed.hunger),
      closeTo(0.5, 0.001),
    );
    expect(
      store.care(kind: PetKind.fox, now: t0.add(const Duration(hours: 5)))!
          .of(PetNeed.hunger),
      1,
    );
  });

  test('adopt ignores a duplicate and stops at five', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await PetStore.open();
    for (final kind in PetKind.values) {
      await store.adopt(kind, now: t0);
    }
    expect(store.owned, PetKind.values);
    expect(store.canAdoptMore, isFalse);

    await store.adopt(PetKind.cat, now: t0);
    expect(store.owned.length, 5);
  });

  test('a win fills the emptiest need of the neediest pet', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await PetStore.open();
    await store.adopt(PetKind.cat, now: t0);
    await store.adopt(PetKind.dog, now: t0.add(const Duration(hours: 4)));

    final later = t0.add(const Duration(hours: 10));
    expect(store.care(kind: PetKind.cat, now: later)!.starving, isTrue);
    expect(store.care(kind: PetKind.dog, now: later)!.starving, isFalse);

    final filled = await store.satisfyMostUrgent(now: later);
    expect(filled, isNotNull);
    expect(filled!.kind, PetKind.cat);
    expect(filled.need, PetNeed.hunger);
    expect(store.owned, [PetKind.cat, PetKind.dog]);
    expect(store.care(kind: PetKind.cat, now: later)!.of(PetNeed.hunger), 1);
    expect(store.care(kind: PetKind.cat, now: later)!.of(PetNeed.play), lessThan(1));
    expect(
      store.care(kind: PetKind.dog, now: later)!.of(PetNeed.hunger),
      lessThan(1),
    );
  });

  test('legacy single pet.kind still loads as owned', () async {
    SharedPreferences.setMockInitialValues({
      'pet.kind': 'fox',
      'pet.hungerAt': t0.millisecondsSinceEpoch,
      'pet.playAt': t0.millisecondsSinceEpoch,
      'pet.restAt': t0.millisecondsSinceEpoch,
    });
    final store = await PetStore.open();
    expect(store.owned, [PetKind.fox]);
    expect(store.care(now: t0.add(const Duration(hours: 5)))!.of(PetNeed.hunger),
        closeTo(0.5, 0.001));
  });

  test('memory store ignores writes', () async {
    final store = PetStore.memory();
    await store.adopt(PetKind.hamster);
    expect(store.hasPet, isFalse);
    expect(await store.satisfyMostUrgent(), isNull);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/models/tutorial_step.dart';
import 'package:mahjong/services/tutorial_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TutorialStore', () {
    test('starts with nothing done', () async {
      final store = await TutorialStore.open();

      expect(store.skipped, isFalse);
      expect(store.forceReplay, isFalse);
      expect(store.anyStepDone, isFalse);
      for (final step in TutorialStep.values) {
        expect(store.isDone(step), isFalse);
      }
    });

    test('complete persists a step and clears replay when all done', () async {
      SharedPreferences.setMockInitialValues({'tutorial.forceReplay': true});
      final store = await TutorialStore.open();
      expect(store.forceReplay, isTrue);

      for (final step in TutorialStep.values) {
        await store.complete(step);
      }

      expect(store.anyStepDone, isTrue);
      expect(store.forceReplay, isFalse);
      expect(TutorialStep.values.every(store.isDone), isTrue);

      final reopened = await TutorialStore.open();
      expect(reopened.isDone(TutorialStep.match), isTrue);
      expect(reopened.forceReplay, isFalse);
    });

    test('skipAll marks every step done', () async {
      final store = await TutorialStore.open();
      await store.complete(TutorialStep.collect);
      await store.skipAll();

      expect(store.skipped, isTrue);
      expect(store.forceReplay, isFalse);
      expect(TutorialStep.values.every(store.isDone), isTrue);

      final reopened = await TutorialStore.open();
      expect(reopened.skipped, isTrue);
      expect(reopened.isDone(TutorialStep.boosts), isTrue);
    });

    test('reset clears flags and forces replay', () async {
      final store = await TutorialStore.open();
      await store.skipAll();
      await store.reset();

      expect(store.skipped, isFalse);
      expect(store.forceReplay, isTrue);
      expect(store.anyStepDone, isFalse);

      final reopened = await TutorialStore.open();
      expect(reopened.forceReplay, isTrue);
      expect(reopened.skipped, isFalse);
    });
  });

  group('TutorialGuide', () {
    const fresh = TutorialSnapshot.empty();

    test('level 1 empty tray shows collect', () {
      expect(
        TutorialGuide.current(
          levelId: 1,
          progress: fresh,
          level1Completed: false,
          trayEmpty: true,
          blockedTap: false,
        )?.step,
        TutorialStep.collect,
      );
    });

    test('after collect, empty or not, shows match', () {
      const afterCollect = TutorialSnapshot(
        collectDone: true,
        matchDone: false,
        layersDone: false,
        boostsDone: false,
        skipped: false,
        forceReplay: false,
      );

      expect(
        TutorialGuide.current(
          levelId: 1,
          progress: afterCollect,
          level1Completed: false,
          trayEmpty: false,
          blockedTap: false,
        )?.step,
        TutorialStep.match,
      );
    });

    test('blocked tap shows layers over collect', () {
      expect(
        TutorialGuide.current(
          levelId: 1,
          progress: fresh,
          level1Completed: false,
          trayEmpty: true,
          blockedTap: true,
        )?.step,
        TutorialStep.layers,
      );
    });

    test('level 1 after collect and match hides the coach', () {
      const afterMatch = TutorialSnapshot(
        collectDone: true,
        matchDone: true,
        layersDone: false,
        boostsDone: false,
        skipped: false,
        forceReplay: false,
      );

      expect(
        TutorialGuide.current(
          levelId: 1,
          progress: afterMatch,
          level1Completed: false,
          trayEmpty: true,
          blockedTap: false,
        ),
        isNull,
      );
    });

    test('level 2 after collect and match shows boosts', () {
      const afterMatch = TutorialSnapshot(
        collectDone: true,
        matchDone: true,
        layersDone: false,
        boostsDone: false,
        skipped: false,
        forceReplay: false,
      );

      expect(
        TutorialGuide.current(
          levelId: 2,
          progress: afterMatch,
          level1Completed: true,
          trayEmpty: true,
          blockedTap: false,
        )?.step,
        TutorialStep.boosts,
      );
    });

    test('skipped shows nothing', () {
      const skipped = TutorialSnapshot(
        collectDone: true,
        matchDone: true,
        layersDone: true,
        boostsDone: true,
        skipped: true,
        forceReplay: false,
      );

      expect(
        TutorialGuide.current(
          levelId: 1,
          progress: skipped,
          level1Completed: false,
          trayEmpty: true,
          blockedTap: true,
        ),
        isNull,
      );
    });

    test('veteran who finished level 1 sees nothing until replay', () {
      expect(
        TutorialGuide.current(
          levelId: 1,
          progress: fresh,
          level1Completed: true,
          trayEmpty: true,
          blockedTap: false,
        ),
        isNull,
      );

      const replay = TutorialSnapshot(
        collectDone: false,
        matchDone: false,
        layersDone: false,
        boostsDone: false,
        skipped: false,
        forceReplay: true,
      );
      expect(
        TutorialGuide.current(
          levelId: 1,
          progress: replay,
          level1Completed: true,
          trayEmpty: true,
          blockedTap: false,
        )?.step,
        TutorialStep.collect,
      );
    });

    test('does not auto-show on level 4 unless replaying', () {
      expect(
        TutorialGuide.current(
          levelId: 4,
          progress: fresh,
          level1Completed: false,
          trayEmpty: true,
          blockedTap: false,
        ),
        isNull,
      );

      const replay = TutorialSnapshot(
        collectDone: false,
        matchDone: false,
        layersDone: false,
        boostsDone: false,
        skipped: false,
        forceReplay: true,
      );
      expect(
        TutorialGuide.current(
          levelId: 4,
          progress: replay,
          level1Completed: true,
          trayEmpty: true,
          blockedTap: false,
        )?.step,
        TutorialStep.collect,
      );
    });
  });
}

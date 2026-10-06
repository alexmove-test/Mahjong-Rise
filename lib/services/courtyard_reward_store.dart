import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/courtyard_reward.dart';
import '../models/pet_story.dart';
import '../models/table_look.dart';

/// Three short build series. Every three new campaign clears unlock one choice.
class CourtyardRewardStore {
  CourtyardRewardStore._(this._prefs);

  static const storageKey = 'courtyard.rewards.v1';
  static const winsPerReward = 3;
  static const _looksKey = 'looks';
  static const _legacyLooksKey = 'legacyLooks';

  static int get progressCap =>
      (CourtyardReward.values.length +
          PetStories.all.length * PetStories.chapters +
          TableLook.giftLooks.length) *
      winsPerReward;

  int get maxChoices =>
      CourtyardReward.values.length +
      PetStories.all.length * PetStories.chapters +
      TableLook.giftLooks.length -
      legacyLooks.length;
  static Future<void>? _writes;

  final SharedPreferences _prefs;

  static Future<CourtyardRewardStore> open() async =>
      CourtyardRewardStore._(await SharedPreferences.getInstance());

  Map<String, dynamic> get _data {
    try {
      final decoded = jsonDecode(_prefs.getString(storageKey) ?? '{}');
      return decoded is Map<String, dynamic> ? decoded : {};
    } on FormatException {
      return {};
    }
  }

  List<int> get creditedLevels => (_data['levels'] is List)
      ? (_data['levels'] as List).whereType<int>().take(progressCap).toList()
      : [];

  Set<CourtyardReward> get owned {
    final names = (_data['owned'] is List)
        ? (_data['owned'] as List).whereType<String>().toSet()
        : const <String>{};
    return {
      for (final reward in CourtyardReward.values)
        if (names.contains(reward.name)) reward,
    };
  }

  int get adventureChoices {
    final value = _data['adventures'];
    return value is int
        ? value.clamp(0, PetStories.all.length * PetStories.chapters)
        : 0;
  }

  Set<TableLook> get ownedLooks => _looksAt(_looksKey);

  Set<TableLook> get legacyLooks => _looksAt(_legacyLooksKey);

  Set<TableLook> _looksAt(String key) {
    final raw = _data[key];
    return raw is List ? TableLook.giftsFrom(raw) : const {};
  }

  bool isLookUnlocked(TableLook look) {
    if (!look.isGift) return true;
    return ownedLooks.contains(look) || legacyLooks.contains(look);
  }

  List<TableLook> get giftableLooks => TableLook.giftLooks
      .where((look) => !isLookUnlocked(look))
      .toList(growable: false);

  int get spentChoices => owned.length + adventureChoices + ownedLooks.length;

  int get seriesProgress =>
      (creditedLevels.length - spentChoices * winsPerReward).clamp(
        0,
        winsPerReward,
      );
  int get remaining => (winsPerReward - seriesProgress).clamp(0, winsPerReward);
  bool get pendingChoice => !complete && seriesProgress >= winsPerReward;
  bool get complete => spentChoices >= maxChoices;

  Future<void> _change(void Function(Map<String, dynamic>) update) {
    final next = (_writes ?? Future<void>.value()).then((_) async {
      final data = _data;
      update(data);
      if (!await _prefs.setString(storageKey, jsonEncode(data))) {
        throw StateError('Could not save courtyard rewards');
      }
    });
    final tail = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    _writes = tail;
    tail.then((_) {
      if (identical(_writes, tail)) _writes = null;
    });
    return next;
  }

  Future<void> recordFirstClear(int levelId) => _change((data) {
    if (levelId <= 0 || complete || pendingChoice) return;
    final levels = creditedLevels;
    if (levels.contains(levelId)) return;
    data['levels'] = [...levels, levelId];
  });

  /// Credits old campaign progress once when this feature reaches an existing save.
  Future<void> bootstrapCompleted(Iterable<int> levelIds) => _change((data) {
    if (creditedLevels.isNotEmpty || owned.isNotEmpty) return;
    final unique = <int>[];
    for (final levelId in levelIds) {
      if (levelId > 0 && !unique.contains(levelId)) unique.add(levelId);
      if (unique.length == progressCap) break;
    }
    data['levels'] = unique;
  });

  Future<bool> choose(CourtyardReward reward) async {
    var granted = false;
    await _change((data) {
      if (!pendingChoice || owned.contains(reward)) return;
      data['owned'] = [...owned.map((item) => item.name), reward.name];
      granted = true;
    });
    return granted;
  }

  Future<bool> chooseAdventure() async {
    var granted = false;
    await _change((data) {
      if (!pendingChoice) return;
      data['adventures'] = adventureChoices + 1;
      granted = true;
    });
    return granted;
  }

  /// Keep a look the player already uses, without spending a gift token.
  Future<void> grandfatherLook(TableLook look) => _change((data) {
    if (!look.isGift) return;
    if (ownedLooks.contains(look) || legacyLooks.contains(look)) return;
    data[_legacyLooksKey] = [...legacyLooks.map((item) => item.id), look.id];
  });

  Future<bool> chooseLook(TableLook look) async {
    var granted = false;
    await _change((data) {
      if (!look.isGift || !pendingChoice || isLookUnlocked(look)) return;
      data[_looksKey] = [...ownedLooks.map((item) => item.id), look.id];
      granted = true;
    });
    return granted;
  }
}

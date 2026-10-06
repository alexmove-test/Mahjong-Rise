import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/pet.dart';
import '../models/pet_story.dart';

class PetStoryStore {
  PetStoryStore._(this._prefs);

  static const storageKey = 'pet.stories.v1';
  static const _legacyFoxKey = 'adventure.fox.v1';
  static Future<void>? _writes;
  final SharedPreferences _prefs;

  static Future<PetStoryStore> open() async {
    final store = PetStoryStore._(await SharedPreferences.getInstance());
    await store._migrateFox();
    return store;
  }

  Map<String, dynamic> get _data {
    try {
      final value = jsonDecode(_prefs.getString(storageKey) ?? '{}');
      return value is Map<String, dynamic> ? value : {};
    } on FormatException {
      return {};
    }
  }

  Map<String, int> get _progress => _intMap(_data['progress']);
  Map<String, int> get _seen => _intMap(_data['seen']);
  String? get activeId => _data['active'] as String?;
  PetStoryDef? get active => PetStories.byId(activeId);
  int progress(PetStoryDef story) => (_progress[story.id] ?? 0).clamp(0, 3);
  int seen(PetStoryDef story) =>
      (_seen[story.id] ?? 0).clamp(0, progress(story));
  bool isComplete(PetStoryDef story) => progress(story) >= 3;
  bool isStarted(PetStoryDef story) => _progress.containsKey(story.id);
  bool get hasPendingMoment {
    final story = active;
    return story != null && seen(story) < progress(story);
  }

  int completedFor(PetKind pet) =>
      PetStories.forPet(pet).where(isComplete).length;

  bool isUnlocked(PetStoryDef story) {
    final stories = PetStories.forPet(story.pet);
    final index = stories.indexWhere((item) => item.id == story.id);
    return index == 0 || (index > 0 && isComplete(stories[index - 1]));
  }

  PetStoryDef? currentFor(PetKind pet) {
    final current = active;
    if (current?.pet == pet) return current;
    for (final story in PetStories.forPet(pet)) {
      if (!isComplete(story) && isUnlocked(story)) return story;
    }
    final stories = PetStories.forPet(pet);
    return stories.isEmpty ? null : stories.last;
  }

  /// Next chapter a courtyard gift can unlock for each companion.
  List<PetStoryDef> get offers => [
    for (final pet in PetKind.values)
      if (currentFor(pet) case final story?
          when isUnlocked(story) && !isComplete(story))
        story,
  ];

  Future<void> _change(void Function(Map<String, dynamic>) update) {
    final next = (_writes ?? Future<void>.value()).then((_) async {
      final data = _data;
      update(data);
      if (!await _prefs.setString(storageKey, jsonEncode(data))) {
        throw StateError('Could not save pet stories');
      }
    });
    final tail = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    _writes = tail;
    tail.then((_) {
      if (identical(_writes, tail)) _writes = null;
    });
    return next;
  }

  Future<bool> start(PetStoryDef story) async {
    var started = false;
    await _change((data) {
      if (!isUnlocked(story) || isComplete(story)) return;
      final progress = _progress;
      final seen = _seen;
      progress.putIfAbsent(story.id, () => 0);
      seen.putIfAbsent(story.id, () => 0);
      data['progress'] = progress;
      data['seen'] = seen;
      data['active'] = story.id;
      started = true;
    });
    return started;
  }

  /// Starts the story if needed and reveals the next chapter as a gift.
  Future<bool> grantChapter(PetStoryDef story) async {
    var granted = false;
    await _change((data) {
      if (!isUnlocked(story) || isComplete(story) || hasPendingMoment) return;
      final progress = Map<String, int>.from(_progress);
      final seen = Map<String, int>.from(_seen);
      progress.putIfAbsent(story.id, () => 0);
      seen.putIfAbsent(story.id, () => 0);
      final stage = (progress[story.id] ?? 0).clamp(0, 3);
      if (stage >= 3) return;
      progress[story.id] = stage + 1;
      data['progress'] = progress;
      data['seen'] = seen;
      data['active'] = story.id;
      granted = true;
    });
    return granted;
  }

  Future<void> creditCampaignWin(String victoryId) => _change((data) {
    final story = active;
    if (story == null ||
        victoryId.isEmpty ||
        hasPendingMoment ||
        isComplete(story)) {
      return;
    }
    final wins = (_data['wins'] is List)
        ? (_data['wins'] as List).whereType<String>().toList()
        : <String>[];
    if (wins.contains(victoryId)) return;
    final progress = _progress;
    progress[story.id] = (progress[story.id] ?? 0) + 1;
    data['progress'] = progress;
    data['wins'] = [...wins, victoryId].take(75).toList();
  });

  Future<void> acknowledgeMoment() => _change((data) {
    final story = active;
    if (story == null || !hasPendingMoment) return;
    final seen = _seen;
    seen[story.id] = progress(story);
    data['seen'] = seen;
    if (isComplete(story)) data.remove('active');
  });

  Future<void> _migrateFox() async {
    if (_data['foxMigrated'] == true) return;
    Map<String, dynamic> legacy = {};
    try {
      final value = jsonDecode(_prefs.getString(_legacyFoxKey) ?? '{}');
      if (value is Map<String, dynamic>) legacy = value;
    } on FormatException {
      // A damaged optional legacy story should not block the pet section.
    }
    await _change((data) {
      if (legacy['started'] == true) {
        final wins = legacy['wins'] is List
            ? (legacy['wins'] as List).whereType<String>().take(3).toList()
            : const <String>[];
        final stage = wins.length;
        final progress = _intMap(data['progress']);
        final seen = _intMap(data['seen']);
        progress['fox_cozy'] = stage;
        seen['fox_cozy'] = legacy['seen'] is int
            ? (legacy['seen'] as int).clamp(0, stage)
            : 0;
        data['progress'] = progress;
        data['seen'] = seen;
        if (stage < 3) data['active'] = 'fox_cozy';
      }
      data['foxMigrated'] = true;
    });
  }

  static Map<String, int> _intMap(Object? value) {
    if (value is! Map) return {};
    return {
      for (final entry in value.entries)
        if (entry.key is String && entry.value is int)
          entry.key as String: entry.value as int,
    };
  }
}

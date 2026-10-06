import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../models/pet.dart';
import 'pet_store.dart';

/// One permanent courtyard story. Victory IDs and rewards commit together.
class FoxAdventureStore {
  FoxAdventureStore._(this._prefs);

  static const storageKey = 'adventure.fox.v1';
  static Future<void>? _writes;
  final SharedPreferences _prefs;

  static Future<FoxAdventureStore> open() async =>
      FoxAdventureStore._(await SharedPreferences.getInstance());

  Map<String, dynamic> get _data {
    try {
      final raw = jsonDecode(_prefs.getString(storageKey) ?? '{}');
      return raw is Map<String, dynamic> ? raw : {};
    } on FormatException {
      return {};
    }
  }

  bool get started => _data['started'] == true;
  List<String> get _wins => (_data['wins'] is List)
      ? (_data['wins'] as List).whereType<String>().take(3).toList()
      : [];
  int get stage => _wins.length;
  int get seen =>
      (_data['seen'] is int) ? (_data['seen'] as int).clamp(0, stage) : 0;
  bool get pending => seen < stage;
  bool get complete => stage == 3;
  bool get blueBed => _data['blueBed'] == true;
  bool get plushToy => _data['plushToy'] == true;

  /// Earlier versions allowed a courtyard visitor to start this story.
  /// Keep that companion and its story together when upgrading.
  Future<void> attachExistingCompanion(PetStore pets) async {
    if (started && !pets.owns(PetKind.fox)) await pets.adopt(PetKind.fox);
  }

  Future<void> _change(void Function(Map<String, dynamic>) update) {
    final next = (_writes ?? Future<void>.value()).then((_) async {
      final data = _data;
      update(data);
      if (!await _prefs.setString(storageKey, jsonEncode(data))) {
        throw StateError('Could not save fox adventure');
      }
    });
    final tail = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    _writes = tail;
    tail.then((_) {
      if (identical(_writes, tail)) _writes = null;
    });
    return next;
  }

  Future<void> start() => _change((data) => data['started'] = true);

  Future<void> creditCampaignWin(String victoryId) => _change((data) {
    if (!started || complete || pending || victoryId.isEmpty) return;
    final wins = _wins;
    if (wins.contains(victoryId)) return;
    data['wins'] = [...wins, victoryId];
  });

  Future<void> finishScene({bool? blueBed, bool? plushToy}) => _change((data) {
    if (!pending) return;
    if (stage == 2 && blueBed != null) data['blueBed'] = blueBed;
    if (stage == 3 && plushToy != null) data['plushToy'] = plushToy;
    data['seen'] = stage;
  });
}

import 'package:shared_preferences/shared_preferences.dart';

abstract class IReviewGateStore {
  Future<DateTime?> getInstallAt();
  Future<void> setInstallAt(DateTime dt);
  Future<int> getSessionCount();
  Future<void> setSessionCount(int v);
  Future<DateTime?> getLastAskedAt();
  Future<void> setLastAskedAt(DateTime dt);
  Future<String?> getLastOutcome();
  Future<void> setLastOutcome(String v);
  Future<Map<String, int>> getEventCounts();
  Future<void> setEventCounts(Map<String, int> map);
}

class SharedPrefsReviewGateStore implements IReviewGateStore {
  static const _kInstallAt = 'rg_installAt';
  static const _kSessionCount = 'rg_sessionCount';
  static const _kLastAskedAt = 'rg_lastAskedAt';
  static const _kLastOutcome = 'rg_lastOutcome';
  static const _kEventCounts = 'rg_eventCounts';

  @override
  Future<DateTime?> getInstallAt() async {
    final sp = await SharedPreferences.getInstance();
    final ms = sp.getInt(_kInstallAt);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  @override
  Future<void> setInstallAt(DateTime dt) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kInstallAt, dt.millisecondsSinceEpoch);
  }

  @override
  Future<int> getSessionCount() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kSessionCount) ?? 0;
  }

  @override
  Future<void> setSessionCount(int v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kSessionCount, v);
  }

  @override
  Future<DateTime?> getLastAskedAt() async {
    final sp = await SharedPreferences.getInstance();
    final ms = sp.getInt(_kLastAskedAt);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  @override
  Future<void> setLastAskedAt(DateTime dt) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kLastAskedAt, dt.millisecondsSinceEpoch);
  }

  @override
  Future<String?> getLastOutcome() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kLastOutcome);
  }

  @override
  Future<void> setLastOutcome(String v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kLastOutcome, v);
  }

  @override
  Future<Map<String, int>> getEventCounts() async {
    final sp = await SharedPreferences.getInstance();
    final keys =
        sp.getKeys().where((k) => k.startsWith('$_kEventCounts:')).toList();
    final map = <String, int>{};
    for (final k in keys) {
      map[k.substring(_kEventCounts.length + 1)] = sp.getInt(k) ?? 0;
    }
    return map;
  }

  @override
  Future<void> setEventCounts(Map<String, int> map) async {
    final sp = await SharedPreferences.getInstance();
    final keys =
        sp.getKeys().where((k) => k.startsWith('$_kEventCounts:')).toList();
    for (final k in keys) {
      await sp.remove(k);
    }
    for (final e in map.entries) {
      await sp.setInt('$_kEventCounts:${e.key}', e.value);
    }
  }
}

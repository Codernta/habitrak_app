import 'package:hive/hive.dart';
import '../../../../core/storage/hive_registrar.dart';

class ReflectionsRepository {
  final Box<Map> _box = Hive.box<Map>(HiveRegistrar.reflectionsBoxName);

  final List<Map<String, dynamic>> _initialReflections = [
    {
      'id': 'seed_1',
      'date': 'Yesterday',
      'text':
          'A quiet cup of tea in the morning before looking at any screens. Peaceful start.',
      'createdAt': DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String(),
    },
    {
      'id': 'seed_2',
      'date': 'Oct 21',
      'text':
          '"A walk in the park reminded me that nature doesn\'t hurry, yet everything is accomplished."',
      'createdAt': DateTime.now()
          .subtract(const Duration(days: 4))
          .toIso8601String(),
    },
  ];

  Future<void> ensureInitialized() async {
    if (_box.isEmpty) {
      for (var ref in _initialReflections) {
        await _box.put(ref['id'], ref);
      }
    }
  }

  List<Map<String, dynamic>> getReflections() {
    if (_box.isEmpty) {
      return List<Map<String, dynamic>>.from(_initialReflections);
    }
    final items = _box.values.map((v) => Map<String, dynamic>.from(v)).toList();
    // Sort descending by createdAt
    items.sort((a, b) {
      final aDate = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime(2000);
      final bDate = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });
    return items;
  }

  String getLastEntryTime() {
    final reflections = getReflections();
    if (reflections.isEmpty) return 'Never';
    return reflections.first['date'] as String? ?? 'Today';
  }

  Future<Map<String, dynamic>> addReflection(String text) async {
    final now = DateTime.now();
    final id = now.millisecondsSinceEpoch.toString();
    final entry = {
      'id': id,
      'date': 'Today',
      'text': text,
      'createdAt': now.toIso8601String(),
    };
    await _box.put(id, entry);
    return entry;
  }

  Future<void> deleteReflection(String id) async {
    await _box.delete(id);
  }
}

import 'package:hive/hive.dart';
import '../../../../core/security/secure_data_manager.dart';
import '../../../../core/storage/hive_registrar.dart';

class ReflectionsRepository {
  final Box<Map> _box = Hive.box<Map>(HiveRegistrar.reflectionsBoxName);

  List<Map<String, dynamic>> _getInitialReflections() {
    final now = DateTime.now();
    return [
      {
        'id': 'seed_1',
        'date': 'Yesterday',
        'text':
            'A quiet cup of tea in the morning before looking at any screens. Peaceful start.',
        'createdAt': now.subtract(const Duration(days: 1)).toIso8601String(),
      },
      {
        'id': 'seed_2',
        'date': '4 days ago',
        'text':
            '"A walk in the park reminded me that nature doesn\'t hurry, yet everything is accomplished."',
        'createdAt': now.subtract(const Duration(days: 4)).toIso8601String(),
      },
    ];
  }

  Future<void> ensureInitialized() async {
    if (_box.isEmpty) {
      for (var ref in _getInitialReflections()) {
        await _box.put(ref['id'], ref);
      }
    }
  }

  List<Map<String, dynamic>> getReflections() {
    if (_box.isEmpty) {
      return _getInitialReflections();
    }
    final items = _box.values.map((v) => Map<String, dynamic>.from(v)).toList();

    // Sort descending by createdAt
    items.sort((a, b) {
      final aDate = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime(2000);
      final bDate = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });

    // Dynamically update the human-readable relative date for every entry based on current day
    return items.map((item) {
      final createdStr = item['createdAt'] as String?;
      if (createdStr != null) {
        final parsed = DateTime.tryParse(createdStr);
        if (parsed != null) {
          final updated = Map<String, dynamic>.from(item);
          updated['date'] = _formatDynamicRelativeDate(parsed);
          return updated;
        }
      }
      return item;
    }).toList();
  }

  String _formatDynamicRelativeDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDate = DateTime(dt.year, dt.month, dt.day);
    final diffDays = today.difference(itemDate).inDays;

    if (diffDays == 0) return 'Today';
    if (diffDays == 1) return 'Yesterday';
    if (diffDays >= 2 && diffDays <= 6) {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[dt.weekday - 1];
    }
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  String getLastEntryTime() {
    final reflections = getReflections();
    if (reflections.isEmpty) return 'Never';
    return reflections.first['date'] as String? ?? 'Today';
  }

  Future<Map<String, dynamic>> addReflection(String text) async {
    final safeText = SecureDataManager().sanitizeText(text, maxLength: 2000);
    final now = DateTime.now();
    final id = now.millisecondsSinceEpoch.toString();
    final entry = {
      'id': id,
      'date': 'Today',
      'text': safeText,
      'createdAt': now.toIso8601String(),
    };
    await _box.put(id, entry);
    return entry;
  }

  Future<void> deleteReflection(String id) async {
    await _box.delete(id);
  }
}

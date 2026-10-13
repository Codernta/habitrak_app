import 'package:flutter_test/flutter_test.dart';
import 'package:habitrak/core/services/connectivity_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConnectivityService Tests', () {
    final service = ConnectivityService();

    test('ConnectivityService initializes with boolean online status', () {
      expect(service.isOnline, isA<bool>());
    });

    test('isOnlineStream emits boolean stream events', () {
      expect(service.isOnlineStream, isA<Stream<bool>>());
    });
  });
}

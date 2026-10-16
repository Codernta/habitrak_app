import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

void main() {
  test(
    'offline_habitrak.json is valid Lottie json and decodes properly',
    () async {
      final file = File('assets/lottie/offline_habitrak.json');
      expect(file.existsSync(), isTrue);

      final jsonString = await file.readAsString();
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      expect(jsonMap['v'], isNotNull);
      expect(jsonMap['layers'], isNotEmpty);

      final bytes = utf8.encode(jsonString);
      final composition = await LottieComposition.fromBytes(bytes);
      expect(composition, isNotNull);
      expect(composition.duration.inMilliseconds, greaterThan(0));
    },
  );
}

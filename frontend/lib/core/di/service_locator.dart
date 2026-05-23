import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<void> setupServiceLocator() async {
  // Initialize any singletons / caches here
  // In a real app this would use get_it or similar
  const FlutterSecureStorage();
}

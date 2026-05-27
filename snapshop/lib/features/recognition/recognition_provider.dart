import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../home/home_provider.dart';

final recognitionStatusProvider = Provider<RecognitionStatus>((ref) {
  return ref.watch(homeProvider).recognitionStatus;
});

final recognitionResultProvider = Provider((ref) {
  return ref.watch(homeProvider).recognitionResult;
});

final productsProvider = Provider((ref) {
  return ref.watch(homeProvider).products;
});

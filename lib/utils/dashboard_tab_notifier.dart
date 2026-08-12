import 'package:flutter/foundation.dart';

class DashboardTabNotifier {
  DashboardTabNotifier._();
  static final ValueNotifier<int?> requestedIndex = ValueNotifier<int?>(null);
}
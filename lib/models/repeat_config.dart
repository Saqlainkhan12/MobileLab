import 'dart:convert';

enum RepeatType {
  none,
  daily,
  weekly,
  monthly;

  String get displayName {
    switch (this) {
      case RepeatType.none:
        return 'Does not repeat';
      case RepeatType.daily:
        return 'Daily';
      case RepeatType.weekly:
        return 'Weekly';
      case RepeatType.monthly:
        return 'Monthly';
    }
  }

  static RepeatType fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'daily':
        return RepeatType.daily;
      case 'weekly':
        return RepeatType.weekly;
      case 'monthly':
        return RepeatType.monthly;
      default:
        return RepeatType.none;
    }
  }
}

class RepeatConfig {
  final RepeatType type;
  /// For weekly repeat: 1 = Monday, 2 = Tuesday, ..., 7 = Sunday
  final List<int> selectedDays;

  const RepeatConfig({
    this.type = RepeatType.none,
    this.selectedDays = const [],
  });

  bool get isRepeated => type != RepeatType.none;

  String get daysJson => jsonEncode(selectedDays);

  static List<int> parseDaysJson(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        return decoded.map((e) => (e as num).toInt()).toList();
      }
    } catch (_) {}
    return [];
  }

  String get summaryText {
    if (type == RepeatType.none) return 'No repeat';
    if (type == RepeatType.daily) return 'Repeats every day';
    if (type == RepeatType.monthly) return 'Repeats every month';
    if (type == RepeatType.weekly) {
      if (selectedDays.isEmpty) return 'Repeats weekly';
      const dayNames = {
        1: 'Mon',
        2: 'Tue',
        3: 'Wed',
        4: 'Thu',
        5: 'Fri',
        6: 'Sat',
        7: 'Sun',
      };
      final names = selectedDays.map((d) => dayNames[d] ?? '').where((s) => s.isNotEmpty).join(', ');
      return 'Repeats on: $names';
    }
    return '';
  }

  RepeatConfig copyWith({
    RepeatType? type,
    List<int>? selectedDays,
  }) {
    return RepeatConfig(
      type: type ?? this.type,
      selectedDays: selectedDays ?? List.from(this.selectedDays),
    );
  }
}


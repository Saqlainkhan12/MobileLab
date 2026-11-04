import 'package:flutter/material.dart';
import '../models/repeat_config.dart';

class RepeatSelectorDialog extends StatefulWidget {
  final RepeatConfig initialConfig;

  const RepeatSelectorDialog({
    super.key,
    required this.initialConfig,
  });

  @override
  State<RepeatSelectorDialog> createState() => _RepeatSelectorDialogState();
}

class _RepeatSelectorDialogState extends State<RepeatSelectorDialog> {
  late RepeatType _selectedType;
  late List<int> _selectedDays;

  static const List<Map<String, dynamic>> _weekDays = [
    {'day': 1, 'label': 'M', 'name': 'Mon'},
    {'day': 2, 'label': 'T', 'name': 'Tue'},
    {'day': 3, 'label': 'W', 'name': 'Wed'},
    {'day': 4, 'label': 'T', 'name': 'Thu'},
    {'day': 5, 'label': 'F', 'name': 'Fri'},
    {'day': 6, 'label': 'S', 'name': 'Sat'},
    {'day': 7, 'label': 'S', 'name': 'Sun'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialConfig.type;
    _selectedDays = List.from(widget.initialConfig.selectedDays);
  }

  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
        _selectedDays.sort();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.repeat_rounded, color: primary, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  'Repeat Settings',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Repeat Options with custom styled cards
            ...RepeatType.values.map((type) {
              final isSelected = _selectedType == type;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primary.withValues(alpha: 0.1)
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? primary : theme.dividerColor.withValues(alpha: 0.4),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                    color: isSelected ? primary : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  title: Text(
                    type.displayName,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? primary : theme.colorScheme.onSurface,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedType = type;
                      if (_selectedType == RepeatType.weekly && _selectedDays.isEmpty) {
                        _selectedDays = [DateTime.now().weekday];
                      }
                    });
                  },
                ),
              );
            }),

            // If Weekly selected, show day selectors
            if (_selectedType == RepeatType.weekly) ...[
              const SizedBox(height: 12),
              Text(
                'Repeat on:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _weekDays.map((d) {
                  final dayNum = d['day'] as int;
                  final label = d['label'] as String;
                  final isDaySelected = _selectedDays.contains(dayNum);

                  return InkWell(
                    onTap: () => _toggleDay(dayNum),
                    borderRadius: BorderRadius.circular(50),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDaySelected ? primary : primary.withValues(alpha: 0.08),
                        border: Border.all(
                          color: isDaySelected ? primary : theme.dividerColor,
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isDaySelected ? Colors.white : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    final config = RepeatConfig(
                      type: _selectedType,
                      selectedDays: _selectedType == RepeatType.weekly ? _selectedDays : [],
                    );
                    Navigator.of(context).pop(config);
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

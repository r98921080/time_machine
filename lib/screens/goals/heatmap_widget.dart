import 'package:flutter/material.dart';
import '../../services/database_service.dart';

class GoalHeatmap extends StatefulWidget {
  final String profileId;
  final int days;

  const GoalHeatmap({super.key, required this.profileId, this.days = 90});

  @override
  State<GoalHeatmap> createState() => _GoalHeatmapState();
}

class _GoalHeatmapState extends State<GoalHeatmap> {
  Map<String, int> _data = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data =
        await DatabaseService.getGoalHeatmapData(widget.profileId, widget.days);
    setState(() => _data = data);
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final cells = <DateTime>[];
    for (var i = widget.days - 1; i >= 0; i--) {
      cells.add(today.subtract(Duration(days: i)));
    }

    // Group by weeks
    final weeks = <List<DateTime>>[];
    var week = <DateTime>[];
    for (final day in cells) {
      week.add(day);
      if (week.length == 7) {
        weeks.add(week);
        week = [];
      }
    }
    if (week.isNotEmpty) weeks.add(week);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: weeks.map((w) {
          return Column(
            children: w.map((day) {
              final key =
                  '${day.year}-${day.month}-${day.day}';
              final score = _data[key] ?? 0;
              return _Cell(score: score, day: day);
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final int score;
  final DateTime day;

  const _Cell({required this.score, required this.day});

  Color _color(int score, BuildContext context) {
    if (score == 0) return Theme.of(context).colorScheme.surfaceContainerHighest;
    if (score <= 2) return const Color(0xFFBBF7D0);
    if (score <= 5) return const Color(0xFF4ADE80);
    if (score <= 9) return const Color(0xFF16A34A);
    return const Color(0xFF052E16);
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message:
          '${day.month}/${day.day}: $score 點',
      child: Container(
        width: 10,
        height: 10,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: _color(score, context),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

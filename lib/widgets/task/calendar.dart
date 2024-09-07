import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/task.dart';
import '../../utilities/task.dart';
import 'list.dart';

class TaskCalendar extends StatefulWidget {
  const TaskCalendar({
    super.key,
    required this.tasks,
    this.onToggle,
    this.onNavigate,
  });

  final Iterable<Task> tasks;
  final TaskListItemToggle? onToggle;
  final TaskListItemNavigate? onNavigate;

  @override
  State<StatefulWidget> createState() => TaskCalendarState();
}

final currentDate = DateTime.now();
// FIXME: Limited to 6 months range
// Find a way to make it infinite
final firstDay =
    DateTime(currentDate.year, currentDate.month - 3, currentDate.day);
final lastDay =
    DateTime(currentDate.year, currentDate.month + 3, currentDate.day);

class TaskCalendarState extends State<TaskCalendar> {
  DateTime _focusedDay = currentDate;
  DateTime _selectedDay = currentDate;
  final ValueNotifier<Iterable<Task>> _todayTasks = ValueNotifier([]);

  @override
  void initState() {
    super.initState();

    _todayTasks.value = filterTasksByDay(widget.tasks, _selectedDay);
  }

  @override
  void didUpdateWidget(TaskCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);

    _todayTasks.value = filterTasksByDay(widget.tasks, _selectedDay);
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _focusedDay = focusedDay;
        _selectedDay = selectedDay;
        _todayTasks.value = filterTasksByDay(widget.tasks, _selectedDay);
      });
    }
  }

  void _onPageChanged(DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return [
      TableCalendar(
        focusedDay: _focusedDay,
        firstDay: firstDay,
        lastDay: lastDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: _onDaySelected,
        onPageChanged: _onPageChanged,
        calendarFormat: CalendarFormat.week,
        startingDayOfWeek: StartingDayOfWeek.monday,
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            border: Border.fromBorderSide(
              BorderSide(
                color: theme.primaryColor,
                width: 1,
              ),
            ),
            shape: BoxShape.circle,
          ),
          todayTextStyle: TextStyle(
            color: theme.primaryColor,
          ),
          selectedDecoration: BoxDecoration(
            color: theme.primaryColor,
            shape: BoxShape.circle,
          ),
        ),
      ),
      Expanded(
        child: ValueListenableBuilder(
          valueListenable: _todayTasks,
          builder: ((context, value, child) {
            return TaskList(
              tasks: value,
              onToggle: widget.onToggle,
              onNavigate: widget.onNavigate,
              noTaskMessage: 'task_list.no_task'.tr(),
            );
          }),
        ),
      ),
    ].toColumn();
  }
}

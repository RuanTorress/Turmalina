import 'package:flutter/material.dart';

class WeekView extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const WeekView({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<WeekView> createState() => _WeekViewState();
}

class _WeekViewState extends State<WeekView> {
  late DateTime _currentWeekStart;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _currentWeekStart = _getWeekStart(widget.selectedDate);
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  DateTime _getWeekStart(DateTime date) {
    // Get the Monday of the week containing the given date
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - daysFromMonday);
  }

  List<DateTime> _getWeekDays(DateTime weekStart) {
    return List.generate(7, (index) => 
        DateTime(weekStart.year, weekStart.month, weekStart.day + index));
  }

  void _navigateWeek(bool forward) {
    setState(() {
      _currentWeekStart = DateTime(
        _currentWeekStart.year,
        _currentWeekStart.month,
        _currentWeekStart.day + (forward ? 7 : -7),
      );
    });
  }

  String _getWeekRangeString(DateTime weekStart) {
    final weekEnd = DateTime(weekStart.year, weekStart.month, weekStart.day + 6);
    const months = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    
    if (weekStart.month == weekEnd.month) {
      return '${weekStart.day}-${weekEnd.day} ${months[weekStart.month - 1]} ${weekStart.year}';
    } else {
      return '${weekStart.day} ${months[weekStart.month - 1]} - ${weekEnd.day} ${months[weekEnd.month - 1]} ${weekStart.year}';
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isToday(DateTime date) {
    final today = DateTime.now();
    return _isSameDay(date, today);
  }

  List<MockEvent> _getEventsForDay(DateTime date) {
    // Mock events - replace with real data
    if (date.day % 3 == 0) {
      return [
        MockEvent('Reunião de equipe', TimeOfDay(hour: 9, minute: 0), TimeOfDay(hour: 10, minute: 30)),
        MockEvent('Consulta cliente', TimeOfDay(hour: 14, minute: 0), TimeOfDay(hour: 15, minute: 0)),
      ];
    } else if (date.day % 2 == 0) {
      return [
        MockEvent('Procedimento estético', TimeOfDay(hour: 11, minute: 0), TimeOfDay(hour: 12, minute: 30)),
      ];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final weekDays = _getWeekDays(_currentWeekStart);
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Week navigation header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _navigateWeek(false),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    _getWeekRangeString(_currentWeekStart),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _navigateWeek(true),
              ),
            ],
          ),
        ),
        
        // Days header
        Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: weekDays.map((date) {
              final isSelected = _isSameDay(date, widget.selectedDate);
              final isToday = _isToday(date);
              
              return Expanded(
                child: GestureDetector(
                  onTap: () => widget.onDateSelected(date),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : isToday
                              ? theme.colorScheme.primaryContainer
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isToday && !isSelected
                          ? Border.all(
                              color: theme.colorScheme.primary,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'][date.weekday % 7],
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${date.day}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        
        const Divider(height: 1),
        
        // Schedule view with proper ScrollView
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Time grid
                ...List.generate(24, (hour) => _buildHourRow(hour, weekDays)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHourRow(int hour, List<DateTime> weekDays) {
    final theme = Theme.of(context);
    
    return Container(
      height: 60,
      child: Row(
        children: [
          // Time label
          SizedBox(
            width: 60,
            child: Text(
              '${hour.toString().padLeft(2, '0')}:00',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Days grid
          Expanded(
            child: Row(
              children: weekDays.map((date) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.1),
                      ),
                      bottom: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.1),
                      ),
                    ),
                  ),
                  child: _buildEventSlot(date, hour),
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventSlot(DateTime date, int hour) {
    final events = _getEventsForDay(date);
    final hourEvents = events.where((event) => event.startTime.hour == hour).toList();
    
    if (hourEvents.isEmpty) {
      return const SizedBox.expand();
    }
    
    return Container(
      padding: const EdgeInsets.all(2),
      child: Column(
        children: hourEvents.map((event) => Expanded(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 1),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
            ),
            child: Text(
              event.title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )).toList(),
      ),
    );
  }
}

class MockEvent {
  final String title;
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  MockEvent(this.title, this.startTime, this.endTime);
}
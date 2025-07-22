import 'package:flutter/material.dart';

class MonthView extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const MonthView({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<MonthView> createState() => _MonthViewState();
}

class _MonthViewState extends State<MonthView> {
  late DateTime _currentMonth;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month);
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<DateTime> _getDaysInMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final daysInMonth = lastDay.day;
    
    // Get first day of week (0 = Sunday, 1 = Monday, etc.)
    final firstWeekday = firstDay.weekday % 7;
    
    List<DateTime> days = [];
    
    // Add previous month's trailing days
    for (int i = firstWeekday - 1; i >= 0; i--) {
      days.add(firstDay.subtract(Duration(days: i + 1)));
    }
    
    // Add current month's days
    for (int i = 1; i <= daysInMonth; i++) {
      days.add(DateTime(month.year, month.month, i));
    }
    
    // Add next month's leading days to complete the grid
    final remainingCells = 42 - days.length; // 6 rows × 7 days = 42
    for (int i = 1; i <= remainingCells; i++) {
      days.add(DateTime(month.year, month.month + 1, i));
    }
    
    return days;
  }

  void _navigateMonth(bool forward) {
    setState(() {
      if (forward) {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      } else {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      }
    });
  }

  String _getMonthYearString(DateTime date) {
    const months = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril',
      'Maio', 'Junho', 'Julho', 'Agosto',
      'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isToday(DateTime date) {
    final today = DateTime.now();
    return _isSameDay(date, today);
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDaysInMonth(_currentMonth);
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month navigation header
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _navigateMonth(false),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      _getMonthYearString(_currentMonth),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _navigateMonth(true),
                ),
              ],
            ),
          ),
          
          // Days of week header - this fixes the "calendário sumido" issue
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                'Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'
              ].map((day) => Expanded(
                child: Container(
                  height: 32,
                  alignment: Alignment.center,
                  child: Text(
                    day,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
              )).toList(),
            ),
          ),
          
          // Calendar grid
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: List.generate(6, (weekIndex) {
                return Row(
                  children: List.generate(7, (dayIndex) {
                    final dayIdx = weekIndex * 7 + dayIndex;
                    if (dayIdx >= days.length) return const SizedBox();
                    
                    final date = days[dayIdx];
                    final isCurrentMonth = date.month == _currentMonth.month;
                    final isSelected = _isSameDay(date, widget.selectedDate);
                    final isToday = _isToday(date);
                    
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => widget.onDateSelected(date),
                        child: Container(
                          height: 48,
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : isToday
                                    ? theme.colorScheme.primaryContainer
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: isToday && !isSelected
                                ? Border.all(
                                    color: theme.colorScheme.primary,
                                    width: 2,
                                  )
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${date.day}',
                            style: TextStyle(
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                  : isCurrentMonth
                                      ? theme.colorScheme.onSurface
                                      : theme.colorScheme.onSurface.withOpacity(0.4),
                              fontWeight: isToday || isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              }),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Events section
          if (_hasEventsOnSelectedDate())
            _buildEventsSection(),
        ],
      ),
    );
  }

  bool _hasEventsOnSelectedDate() {
    // This would check your events data source
    return widget.selectedDate.day % 3 == 0; // Mock data for demonstration
  }

  Widget _buildEventsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Eventos de ${widget.selectedDate.day}/${widget.selectedDate.month}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        // Mock events - replace with real data
        ...List.generate(2, (index) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Evento ${index + 1}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${9 + index * 2}:00 - ${10 + index * 2}:00',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}
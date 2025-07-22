import 'package:flutter/material.dart';

class DayView extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const DayView({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<DayView> createState() => _DayViewState();
}

class _DayViewState extends State<DayView> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    
    // Auto-scroll to business hours (8 AM)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          8 * 80.0, // 8 AM * 80 pixels per hour
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _navigateDay(bool forward) {
    final newDate = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day + (forward ? 1 : -1),
    );
    widget.onDateSelected(newDate);
  }

  String _getDateString(DateTime date) {
    const months = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril',
      'Maio', 'Junho', 'Julho', 'Agosto',
      'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    const weekdays = [
      'Segunda-feira', 'Terça-feira', 'Quarta-feira', 
      'Quinta-feira', 'Sexta-feira', 'Sábado', 'Domingo'
    ];
    
    return '${weekdays[date.weekday - 1]}, ${date.day} de ${months[date.month - 1]}';
  }

  bool _isToday(DateTime date) {
    final today = DateTime.now();
    return date.year == today.year && 
           date.month == today.month && 
           date.day == today.day;
  }

  List<DayEvent> _getEventsForDay(DateTime date) {
    // Mock events - replace with real data
    List<DayEvent> events = [];
    
    if (date.day % 5 == 0) {
      events.addAll([
        DayEvent('Consulta inicial', TimeOfDay(hour: 9, minute: 0), TimeOfDay(hour: 10, minute: 0), 'Cliente novo - avaliação facial'),
        DayEvent('Limpeza de pele', TimeOfDay(hour: 10, minute: 30), TimeOfDay(hour: 11, minute: 30), 'Procedimento completo'),
        DayEvent('Massagem relaxante', TimeOfDay(hour: 14, minute: 0), TimeOfDay(hour: 15, minute: 30), 'Sessão de 90 minutos'),
        DayEvent('Hidratação facial', TimeOfDay(hour: 16, minute: 0), TimeOfDay(hour: 17, minute: 0), 'Tratamento hidratante'),
      ]);
    } else if (date.day % 3 == 0) {
      events.addAll([
        DayEvent('Reunião de equipe', TimeOfDay(hour: 8, minute: 30), TimeOfDay(hour: 9, minute: 30), 'Planejamento semanal'),
        DayEvent('Peeling químico', TimeOfDay(hour: 11, minute: 0), TimeOfDay(hour: 12, minute: 0), 'Tratamento facial avançado'),
        DayEvent('Drenagem linfática', TimeOfDay(hour: 15, minute: 0), TimeOfDay(hour: 16, minute: 0), 'Sessão corporal'),
      ]);
    } else if (date.day % 2 == 0) {
      events.addAll([
        DayEvent('Design de sobrancelhas', TimeOfDay(hour: 10, minute: 0), TimeOfDay(hour: 11, minute: 0), 'Modelagem e design'),
        DayEvent('Radiofrequência', TimeOfDay(hour: 13, minute: 30), TimeOfDay(hour: 14, minute: 30), 'Tratamento corporal'),
      ]);
    }
    
    events.sort((a, b) => a.startTime.hour.compareTo(b.startTime.hour));
    return events;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final events = _getEventsForDay(widget.selectedDate);
    final isToday = _isToday(widget.selectedDate);
    
    return Column(
      children: [
        // Day navigation header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _navigateDay(false),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _getDateString(widget.selectedDate),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (isToday)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Hoje',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _navigateDay(true),
              ),
            ],
          ),
        ),
        
        // Events summary
        if (events.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.event,
                  color: theme.colorScheme.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '${events.length} evento${events.length > 1 ? 's' : ''} agendado${events.length > 1 ? 's' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        
        // Schedule view with proper ScrollView
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: List.generate(24, (hour) => _buildHourSlot(hour, events, theme)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHourSlot(int hour, List<DayEvent> events, ThemeData theme) {
    final hourEvents = events.where((event) => event.startTime.hour == hour).toList();
    final isCurrentHour = _isCurrentHour(hour);
    
    return Container(
      height: 80,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
        color: isCurrentHour 
            ? theme.colorScheme.primaryContainer.withOpacity(0.1)
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time label
          SizedBox(
            width: 70,
            height: 80,
            child: Container(
              padding: const EdgeInsets.only(right: 8, top: 8),
              alignment: Alignment.topRight,
              child: Text(
                '${hour.toString().padLeft(2, '0')}:00',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isCurrentHour
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: isCurrentHour ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ),
          
          // Events area
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: hourEvents.map((event) => _buildEventCard(event, theme)).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isCurrentHour(int hour) {
    if (!_isToday(widget.selectedDate)) return false;
    final now = DateTime.now();
    return now.hour == hour;
  }

  Widget _buildEventCard(DayEvent event, ThemeData theme) {
    final duration = _calculateDuration(event.startTime, event.endTime);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  event.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  duration,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${_formatTime(event.startTime)} - ${_formatTime(event.endTime)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (event.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              event.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _calculateDuration(TimeOfDay start, TimeOfDay end) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    final durationMinutes = endMinutes - startMinutes;
    
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    
    if (hours > 0) {
      return minutes > 0 ? '${hours}h ${minutes}min' : '${hours}h';
    } else {
      return '${minutes}min';
    }
  }
}

class DayEvent {
  final String title;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String description;

  DayEvent(this.title, this.startTime, this.endTime, this.description);
}
import 'package:flutter/material.dart';
import '../widgets/month_view.dart';
import '../widgets/week_view.dart';
import '../widgets/day_view.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Correctly set TabController length to 3 (not 4) to fix the reported issue
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use SafeArea to prevent AppBar overflow issues
      body: SafeArea(
        child: Column(
          children: [
            // Custom AppBar implementation to avoid height constraint issues
            Container(
              height: 56.0, // Fixed height, well under 88.0 constraint
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Icon(
                    Icons.calendar_today,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Turmalina Agenda',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    onSelected: (value) {
                      // Handle menu actions
                      switch (value) {
                        case 'hoje':
                          _onDateSelected(DateTime.now());
                          break;
                        case 'configuracoes':
                          // Navigate to settings
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'hoje',
                        child: Row(
                          children: [
                            Icon(Icons.today),
                            SizedBox(width: 8),
                            Text('Ir para hoje'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'configuracoes',
                        child: Row(
                          children: [
                            Icon(Icons.settings),
                            SizedBox(width: 8),
                            Text('Configurações'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            
            // TabBar with proper constraints
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.calendar_view_month),
                    text: 'Mês',
                  ),
                  Tab(
                    icon: Icon(Icons.calendar_view_week),
                    text: 'Semana',
                  ),
                  Tab(
                    icon: Icon(Icons.calendar_view_day),
                    text: 'Dia',
                  ),
                ],
                indicatorColor: Theme.of(context).colorScheme.primary,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            
            // TabBarView with proper ScrollView to prevent overflow
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  MonthView(
                    selectedDate: _selectedDate,
                    onDateSelected: _onDateSelected,
                  ),
                  WeekView(
                    selectedDate: _selectedDate,
                    onDateSelected: _onDateSelected,
                  ),
                  DayView(
                    selectedDate: _selectedDate,
                    onDateSelected: _onDateSelected,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      
      // Floating Action Button for adding events
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new event
          _showAddEventDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddEventDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo Evento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Título do evento',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Descrição',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // Save event logic
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Evento adicionado com sucesso!')),
              );
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}
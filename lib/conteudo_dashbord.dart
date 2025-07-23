import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'negociacao_database.dart';

class ConteudoDashboard extends StatefulWidget {
  @override
  _ConteudoDashboardState createState() => _ConteudoDashboardState();
}

class _ConteudoDashboardState extends State<ConteudoDashboard> {
  Map<String, dynamic>? stats;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      developer.log('Loading dashboard stats', name: 'ConteudoDashboard');
      final data = await NegociacaoDatabase.getStats();
      setState(() {
        stats = data;
        isLoading = false;
      });
      developer.log('Stats loaded successfully', name: 'ConteudoDashboard');
    } catch (e) {
      developer.log('Error loading stats: $e', name: 'ConteudoDashboard');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard Turmalina'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : stats == null
              ? Center(child: Text('Erro ao carregar dados'))
              : RefreshIndicator(
                  onRefresh: _loadStats,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMetricasCards(context, stats!),
                        SizedBox(height: 20),
                        _buildStatusChart(context, stats!),
                        SizedBox(height: 20),
                        _buildValoresChart(context, stats!),
                        SizedBox(height: 20),
                        _buildTopClientes(context, stats!),
                        SizedBox(height: 20),
                        _buildEvolutionChart(context, stats!),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildMetricasCards(BuildContext context, Map<String, dynamic> stats) {
    developer.log('Building metrics cards', name: 'ConteudoDashboard');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Métricas Principais',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade700,
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total de Negociações',
                '${stats['totalNegociacoes'] ?? 0}',
                Icons.business_center,
                Colors.blue,
                'Todas as negociações',
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                'Valor Total',
                'R\$ ${_formatCurrency(stats['valorTotal'] ?? 0)}',
                Icons.attach_money,
                Colors.green,
                'Valor acumulado',
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Abertas',
                '${stats['negociacoesAbertas'] ?? 0}',
                Icons.hourglass_empty,
                Colors.orange,
                'Em processo',
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                'Fechadas',
                '${stats['negociacoesFechadas'] ?? 0}',
                Icons.check_circle,
                Colors.teal,
                'Concluídas',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, String subtitle) {
    developer.log('Building metric card: $title', name: 'ConteudoDashboard');
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChart(BuildContext context, Map<String, dynamic> stats) {
    developer.log('Building status chart', name: 'ConteudoDashboard');
    
    final statusData = stats['statusDistribution'] as Map<String, dynamic>? ?? {};
    final colors = [Colors.blue, Colors.orange, Colors.green, Colors.red];
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distribuição por Status',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade700,
              ),
            ),
            SizedBox(height: 16),
            Container(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Gráfico de Status\n(Placeholder)',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: statusData.entries.map((entry) {
                        final index = statusData.keys.toList().indexOf(entry.key);
                        final color = colors[index % colors.length];
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${entry.key}: ${entry.value}',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValoresChart(BuildContext context, Map<String, dynamic> stats) {
    developer.log('Building valores chart', name: 'ConteudoDashboard');
    
    final valoresData = stats['valoresChart'] as List<dynamic>? ?? [];
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Evolução de Valores por Mês',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade700,
              ),
            ),
            SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Gráfico de Barras\n(Placeholder)',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Dados: ${valoresData.length} meses',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: valoresData.map<Widget>((item) {
                return Chip(
                  label: Text(
                    '${item['mes']}: R\$ ${_formatCurrency(item['valor'])}',
                    style: TextStyle(fontSize: 10),
                  ),
                  backgroundColor: Colors.teal.shade50,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopClientes(BuildContext context, Map<String, dynamic> stats) {
    developer.log('Building top clientes', name: 'ConteudoDashboard');
    
    final topClientes = stats['topClientes'] as List<dynamic>? ?? [];
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Clientes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade700,
              ),
            ),
            SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: topClientes.length,
              separatorBuilder: (context, index) => Divider(height: 1),
              itemBuilder: (context, index) {
                final cliente = topClientes[index];
                return ListTile(
                  contentPadding: EdgeInsets.symmetric(vertical: 4),
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.shade100,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: Colors.teal.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    cliente['nome'] ?? 'Cliente',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${cliente['negociacoes'] ?? 0} negociações',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  trailing: Text(
                    'R\$ ${_formatCurrency(cliente['valor'] ?? 0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvolutionChart(BuildContext context, Map<String, dynamic> stats) {
    developer.log('Building evolution chart', name: 'ConteudoDashboard');
    
    final evolutionData = stats['evolutionData'] as List<dynamic>? ?? [];
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Evolução Trimestral',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade700,
              ),
            ),
            SizedBox(height: 16),
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Gráfico de Linha\n(Placeholder)',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: evolutionData.map<Widget>((item) {
                        return Column(
                          children: [
                            Text(
                              item['periodo'] ?? '',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade700,
                              ),
                            ),
                            Text(
                              'R\$ ${_formatCurrency(item['valor'] ?? 0)}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return '0,00';
    double amount = value is num ? value.toDouble() : 0.0;
    return amount.toStringAsFixed(2).replaceAll('.', ',');
  }
}
import 'dart:developer' as developer;

class NegociacaoDatabase {
  static Future<Map<String, dynamic>> getStats() async {
    developer.log('NegociacaoDatabase.getStats() called', name: 'NegociacaoDatabase');
    
    // Simulate async database call
    await Future.delayed(Duration(milliseconds: 100));
    
    // Return mock data for dashboard
    return {
      'totalNegociacoes': 45,
      'valorTotal': 125000.50,
      'negociacoesAbertas': 12,
      'negociacoesFechadas': 33,
      'mediaValor': 2777.78,
      'statusDistribution': {
        'Aberta': 12,
        'Em Andamento': 8,
        'Fechada': 25,
        'Cancelada': 0
      },
      'valoresChart': [
        {'mes': 'Jan', 'valor': 10000},
        {'mes': 'Fev', 'valor': 15000},
        {'mes': 'Mar', 'valor': 20000},
        {'mes': 'Abr', 'valor': 18000},
        {'mes': 'Mai', 'valor': 25000},
        {'mes': 'Jun', 'valor': 37000.50}
      ],
      'topClientes': [
        {'nome': 'Cliente A', 'valor': 25000, 'negociacoes': 5},
        {'nome': 'Cliente B', 'valor': 18000, 'negociacoes': 3},
        {'nome': 'Cliente C', 'valor': 15000, 'negociacoes': 4},
        {'nome': 'Cliente D', 'valor': 12000, 'negociacoes': 2},
        {'nome': 'Cliente E', 'valor': 10000, 'negociacoes': 3}
      ],
      'evolutionData': [
        {'periodo': 'Q1', 'valor': 45000},
        {'periodo': 'Q2', 'valor': 80000.50}
      ]
    };
  }
}
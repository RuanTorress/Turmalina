import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'dialog/mod/negociaca_model.dart';
import 'dialog/editar_neg.dart';

class TabelaClientes extends StatefulWidget {
  const TabelaClientes({super.key});

  @override
  State<TabelaClientes> createState() => _TabelaClientesState();
}

class _TabelaClientesState extends State<TabelaClientes> {
  List<Map<String, dynamic>> _clientes = [];
  List<Map<String, dynamic>> _negociacoes = [];
  bool _isLoading = false;
  Map<String, dynamic>? _clienteSelecionado;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    
    try {
      await _carregarClientes();
      await _inicializarDadosExemplo();
    } catch (e) {
      developer.log('Erro ao carregar dados: $e', name: 'TabelaClientes');
      _mostrarErro('Erro ao carregar dados: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _carregarClientes() async {
    try {
      final db = await NegociacaoModel.database;
      final result = await db.query(
        'clientes',
        orderBy: 'nome ASC',
      );
      
      setState(() {
        _clientes = result;
      });
      
      developer.log('Carregados ${result.length} clientes', name: 'TabelaClientes');
    } catch (e) {
      developer.log('Erro ao carregar clientes: $e', name: 'TabelaClientes');
      throw Exception('Falha ao carregar clientes');
    }
  }

  Future<void> _carregarNegociacoesPorCliente(int clienteId) async {
    try {
      final negociacoes = await NegociacaoModel.listarNegociacoesPorCliente(clienteId);
      setState(() {
        _negociacoes = negociacoes;
      });
      
      developer.log('Carregadas ${negociacoes.length} negociações para cliente $clienteId', name: 'TabelaClientes');
    } catch (e) {
      developer.log('Erro ao carregar negociações: $e', name: 'TabelaClientes');
      _mostrarErro('Erro ao carregar negociações: ${e.toString()}');
    }
  }

  Future<void> _inicializarDadosExemplo() async {
    final db = await NegociacaoModel.database;
    
    // Verificar se já existem dados
    final clientesExistentes = await db.query('clientes');
    if (clientesExistentes.isNotEmpty) return;

    try {
      final agora = DateTime.now().toIso8601String();
      
      // Inserir clientes de exemplo
      int cliente1Id = await db.insert('clientes', {
        'nome': 'Maria Silva',
        'telefone': '(11) 99999-1111',
        'email': 'maria@email.com',
        'endereco': 'Rua das Flores, 123',
        'data_criacao': agora,
        'data_atualizacao': agora,
      });

      int cliente2Id = await db.insert('clientes', {
        'nome': 'João Santos',
        'telefone': '(11) 99999-2222',
        'email': 'joao@email.com',
        'endereco': 'Av. Principal, 456',
        'data_criacao': agora,
        'data_atualizacao': agora,
      });

      // Inserir procedimentos de exemplo
      int proc1Id = await db.insert('procedimentos', {
        'nome': 'Limpeza Dental',
        'valor_padrao': 80.0,
        'descricao': 'Limpeza completa dos dentes',
        'ativo': 1,
        'data_criacao': agora,
        'data_atualizacao': agora,
      });

      int proc2Id = await db.insert('procedimentos', {
        'nome': 'Restauração',
        'valor_padrao': 150.0,
        'descricao': 'Restauração com resina',
        'ativo': 1,
        'data_criacao': agora,
        'data_atualizacao': agora,
      });

      int proc3Id = await db.insert('procedimentos', {
        'nome': 'Canal',
        'valor_padrao': 300.0,
        'descricao': 'Tratamento de canal',
        'ativo': 1,
        'data_criacao': agora,
        'data_atualizacao': agora,
      });

      // Recarregar clientes
      await _carregarClientes();
      
      developer.log('Dados de exemplo criados com sucesso', name: 'TabelaClientes');
    } catch (e) {
      developer.log('Erro ao criar dados de exemplo: $e', name: 'TabelaClientes');
    }
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarSucesso(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _abrirNegociacao({int? negociacaoId, required int clienteId, required String clienteNome}) async {
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => EditarNegociacao(
          negociacaoId: negociacaoId,
          clienteId: clienteId,
          clienteNome: clienteNome,
        ),
      ),
    );

    if (resultado == true) {
      // Recarregar dados se houve mudança
      if (_clienteSelecionado != null) {
        await _carregarNegociacoesPorCliente(_clienteSelecionado!['id']);
      }
    }
  }

  Future<void> _excluirNegociacao(int negociacaoId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar Exclusão'),
        content: Text('Deseja realmente excluir esta negociação? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        final sucesso = await NegociacaoModel.excluirNegociacao(negociacaoId);
        
        if (sucesso) {
          _mostrarSucesso('Negociação excluída com sucesso!');
          // Recarregar lista
          if (_clienteSelecionado != null) {
            await _carregarNegociacoesPorCliente(_clienteSelecionado!['id']);
          }
        } else {
          _mostrarErro('Falha ao excluir negociação');
        }
      } catch (e) {
        developer.log('Erro ao excluir negociação: $e', name: 'TabelaClientes');
        _mostrarErro('Erro ao excluir negociação: ${e.toString()}');
      }
    }
  }

  String _formatarData(String dataIso) {
    try {
      final data = DateTime.parse(dataIso);
      return '${data.day}/${data.month}/${data.year}';
    } catch (e) {
      return dataIso;
    }
  }

  String _formatarValor(dynamic valor) {
    if (valor == null) return 'R\$ 0,00';
    double valorDouble = valor is String ? double.tryParse(valor) ?? 0.0 : valor.toDouble();
    return 'R\$ ${valorDouble.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ativa':
        return Colors.green;
      case 'concluida':
        return Colors.blue;
      case 'cancelada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sistema Turmalina - Gestão de Negociações'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Lista de clientes (lado esquerdo)
                Expanded(
                  flex: 1,
                  child: Card(
                    margin: EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Clientes',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        Divider(),
                        Expanded(
                          child: _clientes.isEmpty
                              ? Center(
                                  child: Text(
                                    'Nenhum cliente cadastrado',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _clientes.length,
                                  itemBuilder: (context, index) {
                                    final cliente = _clientes[index];
                                    final isSelected = _clienteSelecionado?['id'] == cliente['id'];
                                    
                                    return ListTile(
                                      title: Text(cliente['nome'] ?? 'Nome não informado'),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (cliente['telefone'] != null)
                                            Text(cliente['telefone']),
                                          if (cliente['email'] != null)
                                            Text(cliente['email']),
                                        ],
                                      ),
                                      selected: isSelected,
                                      selectedTileColor: Colors.blue.shade50,
                                      onTap: () {
                                        setState(() {
                                          _clienteSelecionado = cliente;
                                        });
                                        _carregarNegociacoesPorCliente(cliente['id']);
                                      },
                                      trailing: Icon(
                                        isSelected ? Icons.arrow_forward_ios : null,
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Lista de negociações (lado direito)
                Expanded(
                  flex: 2,
                  child: Card(
                    margin: EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Text(
                                _clienteSelecionado != null
                                    ? 'Negociações de ${_clienteSelecionado!['nome']}'
                                    : 'Selecione um cliente',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Spacer(),
                              if (_clienteSelecionado != null)
                                ElevatedButton.icon(
                                  onPressed: () => _abrirNegociacao(
                                    clienteId: _clienteSelecionado!['id'],
                                    clienteNome: _clienteSelecionado!['nome'],
                                  ),
                                  icon: Icon(Icons.add),
                                  label: Text('Nova Negociação'),
                                ),
                            ],
                          ),
                        ),
                        Divider(),
                        Expanded(
                          child: _clienteSelecionado == null
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.person_search,
                                        size: 64,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Selecione um cliente para ver as negociações',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : _negociacoes.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.assignment_outlined,
                                            size: 64,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            'Nenhuma negociação encontrada',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 16,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          ElevatedButton.icon(
                                            onPressed: () => _abrirNegociacao(
                                              clienteId: _clienteSelecionado!['id'],
                                              clienteNome: _clienteSelecionado!['nome'],
                                            ),
                                            icon: Icon(Icons.add),
                                            label: Text('Criar primeira negociação'),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: _negociacoes.length,
                                      itemBuilder: (context, index) {
                                        final negociacao = _negociacoes[index];
                                        
                                        return Card(
                                          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                          child: ListTile(
                                            title: Row(
                                              children: [
                                                Text('Negociação #${negociacao['id']}'),
                                                Spacer(),
                                                Container(
                                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: _getStatusColor(negociacao['status'] ?? 'ativa'),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    (negociacao['status'] ?? 'ativa').toUpperCase(),
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Text('Valor Total: ${_formatarValor(negociacao['valor_total'])}'),
                                                    SizedBox(width: 16),
                                                    if ((negociacao['desconto'] ?? 0) > 0)
                                                      Text(
                                                        'Desconto: ${_formatarValor(negociacao['desconto'])}',
                                                        style: TextStyle(color: Colors.red),
                                                      ),
                                                  ],
                                                ),
                                                Text(
                                                  'Valor Final: ${_formatarValor(negociacao['valor_final'])}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  'Criado em: ${_formatarData(negociacao['data_criacao'] ?? '')}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                if (negociacao['observacoes'] != null && negociacao['observacoes'].toString().isNotEmpty)
                                                  Text(
                                                    'Obs: ${negociacao['observacoes']}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontStyle: FontStyle.italic,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                              ],
                                            ),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: Icon(Icons.edit, color: Colors.blue),
                                                  onPressed: () => _abrirNegociacao(
                                                    negociacaoId: negociacao['id'],
                                                    clienteId: _clienteSelecionado!['id'],
                                                    clienteNome: _clienteSelecionado!['nome'],
                                                  ),
                                                  tooltip: 'Editar negociação',
                                                ),
                                                IconButton(
                                                  icon: Icon(Icons.delete, color: Colors.red),
                                                  onPressed: () => _excluirNegociacao(negociacao['id']),
                                                  tooltip: 'Excluir negociação',
                                                ),
                                              ],
                                            ),
                                            isThreeLine: true,
                                          ),
                                        );
                                      },
                                    ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: _clienteSelecionado != null
          ? FloatingActionButton(
              onPressed: () => _abrirNegociacao(
                clienteId: _clienteSelecionado!['id'],
                clienteNome: _clienteSelecionado!['nome'],
              ),
              child: Icon(Icons.add),
              tooltip: 'Nova Negociação',
            )
          : null,
    );
  }
}
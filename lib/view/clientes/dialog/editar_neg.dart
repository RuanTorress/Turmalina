import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;
import 'mod/negociaca_model.dart';

class EditarNegociacao extends StatefulWidget {
  final int? negociacaoId;
  final int clienteId;
  final String clienteNome;

  const EditarNegociacao({
    super.key,
    this.negociacaoId,
    required this.clienteId,
    required this.clienteNome,
  });

  @override
  State<EditarNegociacao> createState() => _EditarNegociacaoState();
}

class _EditarNegociacaoState extends State<EditarNegociacao> {
  final _formKey = GlobalKey<FormState>();
  final _observacoesController = TextEditingController();
  final _descontoController = TextEditingController();
  
  List<Map<String, dynamic>> _procedimentos = [];
  List<Map<String, dynamic>> _procedimentosDisponiveis = [];
  bool _isLoading = false;
  bool _isEdit = false;
  String _status = 'ativa';

  @override
  void initState() {
    super.initState();
    _isEdit = widget.negociacaoId != null;
    _carregarDados();
  }

  @override
  void dispose() {
    _observacoesController.dispose();
    _descontoController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    
    try {
      // Carregar procedimentos disponíveis
      await _carregarProcedimentosDisponiveis();
      
      // Se for edição, carregar dados da negociação
      if (_isEdit) {
        await _carregarNegociacao();
      } else {
        // Adicionar um procedimento vazio para começar
        _adicionarProcedimento();
      }
    } catch (e) {
      developer.log('Erro ao carregar dados: $e', name: 'EditarNegociacao');
      _mostrarErro('Erro ao carregar dados: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _carregarProcedimentosDisponiveis() async {
    try {
      final db = await NegociacaoModel.database;
      final result = await db.query(
        'procedimentos',
        where: 'ativo = 1',
        orderBy: 'nome ASC',
      );
      
      setState(() {
        _procedimentosDisponiveis = result;
      });
      
      developer.log('Carregados ${result.length} procedimentos disponíveis', name: 'EditarNegociacao');
    } catch (e) {
      developer.log('Erro ao carregar procedimentos: $e', name: 'EditarNegociacao');
      throw Exception('Falha ao carregar procedimentos disponíveis');
    }
  }

  Future<void> _carregarNegociacao() async {
    try {
      final negociacao = await NegociacaoModel.buscarNegociacao(widget.negociacaoId!);
      
      if (negociacao == null) {
        throw Exception('Negociação não encontrada');
      }

      setState(() {
        _observacoesController.text = negociacao['observacoes'] ?? '';
        _descontoController.text = negociacao['desconto']?.toString() ?? '0';
        _status = negociacao['status'] ?? 'ativa';
        
        // Carregar procedimentos da negociação
        _procedimentos = (negociacao['procedimentos'] as List<Map<String, dynamic>>)
            .map((proc) => {
              'procedimento_id': proc['procedimento_id'],
              'quantidade': proc['quantidade'],
              'valor_unitario': proc['valor_unitario'],
            })
            .toList();
      });
      
      developer.log('Negociação carregada com ${_procedimentos.length} procedimentos', name: 'EditarNegociacao');
    } catch (e) {
      developer.log('Erro ao carregar negociação: $e', name: 'EditarNegociacao');
      throw Exception('Falha ao carregar dados da negociação');
    }
  }

  void _adicionarProcedimento() {
    setState(() {
      _procedimentos.add({
        'procedimento_id': null,
        'quantidade': 1,
        'valor_unitario': 0.0,
      });
    });
  }

  void _removerProcedimento(int index) {
    if (_procedimentos.length > 1) {
      setState(() {
        _procedimentos.removeAt(index);
      });
    } else {
      _mostrarAviso('Deve haver pelo menos um procedimento');
    }
  }

  double _calcularValorTotal() {
    double total = 0.0;
    for (var proc in _procedimentos) {
      if (proc['procedimento_id'] != null) {
        double valorUnitario = proc['valor_unitario']?.toDouble() ?? 0.0;
        int quantidade = proc['quantidade'] ?? 1;
        total += valorUnitario * quantidade;
      }
    }
    return total;
  }

  double _calcularValorFinal() {
    double total = _calcularValorTotal();
    double desconto = double.tryParse(_descontoController.text) ?? 0.0;
    return total - desconto;
  }

  bool _validarFormulario() {
    if (!_formKey.currentState!.validate()) {
      _mostrarErro('Por favor, corrija os erros no formulário');
      return false;
    }

    // Validar se há pelo menos um procedimento selecionado
    bool temProcedimentoValido = _procedimentos.any((proc) => proc['procedimento_id'] != null);
    if (!temProcedimentoValido) {
      _mostrarErro('Selecione pelo menos um procedimento');
      return false;
    }

    // Validar se todos os procedimentos selecionados têm dados válidos
    for (int i = 0; i < _procedimentos.length; i++) {
      var proc = _procedimentos[i];
      if (proc['procedimento_id'] != null) {
        if (proc['quantidade'] == null || proc['quantidade'] <= 0) {
          _mostrarErro('Quantidade deve ser maior que zero (procedimento ${i + 1})');
          return false;
        }
        if (proc['valor_unitario'] == null || proc['valor_unitario'] <= 0) {
          _mostrarErro('Valor unitário deve ser maior que zero (procedimento ${i + 1})');
          return false;
        }
      }
    }

    // Validar desconto
    double desconto = double.tryParse(_descontoController.text) ?? 0.0;
    double valorTotal = _calcularValorTotal();
    if (desconto > valorTotal) {
      _mostrarErro('Desconto não pode ser maior que o valor total');
      return false;
    }

    return true;
  }

  Future<void> _salvar() async {
    if (!_validarFormulario()) return;

    setState(() => _isLoading = true);

    try {
      // Preparar dados dos procedimentos
      List<Map<String, dynamic>> procedimentosParaSalvar = _procedimentos
          .where((proc) => proc['procedimento_id'] != null)
          .map((proc) => {
            'procedimento_id': proc['procedimento_id'],
            'quantidade': proc['quantidade'],
            'valor_unitario': proc['valor_unitario'],
          })
          .toList();

      double desconto = double.tryParse(_descontoController.text) ?? 0.0;

      bool sucesso;
      if (_isEdit) {
        // Atualizar negociação existente
        sucesso = await NegociacaoModel.atualizarNegociacao(
          negociacaoId: widget.negociacaoId!,
          clienteId: widget.clienteId,
          procedimentos: procedimentosParaSalvar,
          desconto: desconto,
          observacoes: _observacoesController.text.trim().isEmpty 
              ? null 
              : _observacoesController.text.trim(),
          status: _status,
        );
      } else {
        // Criar nova negociação
        int? novoId = await NegociacaoModel.inserirNegociacao(
          clienteId: widget.clienteId,
          procedimentos: procedimentosParaSalvar,
          desconto: desconto,
          observacoes: _observacoesController.text.trim().isEmpty 
              ? null 
              : _observacoesController.text.trim(),
          criadoPor: 'usuario_atual', // TODO: Implementar usuário logado
        );
        sucesso = novoId != null;
      }

      if (sucesso) {
        developer.log('Negociação salva com sucesso', name: 'EditarNegociacao');
        _mostrarSucesso(_isEdit ? 'Negociação atualizada com sucesso!' : 'Negociação criada com sucesso!');
        Navigator.of(context).pop(true);
      } else {
        _mostrarErro('Falha ao salvar negociação. Verifique os dados e tente novamente.');
      }
    } catch (e) {
      developer.log('Erro ao salvar negociação: $e', name: 'EditarNegociacao');
      _mostrarErro('Erro inesperado ao salvar: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
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

  void _mostrarAviso(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.orange,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Editar Negociação' : 'Nova Negociação'),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _salvar,
              child: Text(
                'SALVAR',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informações do cliente
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.person, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              'Cliente: ${widget.clienteNome}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Lista de procedimentos
                    Text(
                      'Procedimentos',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 8),
                    
                    Expanded(
                      child: ListView(
                        children: [
                          // Procedimentos
                          ..._procedimentos.asMap().entries.map((entry) {
                            int index = entry.key;
                            Map<String, dynamic> proc = entry.value;
                            
                            return Card(
                              margin: EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text('Procedimento ${index + 1}'),
                                        Spacer(),
                                        if (_procedimentos.length > 1)
                                          IconButton(
                                            icon: Icon(Icons.delete, color: Colors.red),
                                            onPressed: () => _removerProcedimento(index),
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    
                                    // Dropdown de procedimentos
                                    DropdownButtonFormField<int>(
                                      value: proc['procedimento_id'],
                                      decoration: InputDecoration(
                                        labelText: 'Selecione o procedimento',
                                        border: OutlineInputBorder(),
                                      ),
                                      items: _procedimentosDisponiveis.map((p) {
                                        return DropdownMenuItem<int>(
                                          value: p['id'],
                                          child: Text('${p['nome']} - R\$ ${p['valor_padrao']}'),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          proc['procedimento_id'] = value;
                                          // Definir valor padrão
                                          if (value != null) {
                                            var procedimento = _procedimentosDisponiveis
                                                .firstWhere((p) => p['id'] == value);
                                            proc['valor_unitario'] = procedimento['valor_padrao'];
                                          }
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null) {
                                          return 'Selecione um procedimento';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: 8),
                                    
                                    Row(
                                      children: [
                                        // Quantidade
                                        Expanded(
                                          child: TextFormField(
                                            initialValue: proc['quantidade']?.toString() ?? '1',
                                            decoration: InputDecoration(
                                              labelText: 'Quantidade',
                                              border: OutlineInputBorder(),
                                            ),
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                            onChanged: (value) {
                                              proc['quantidade'] = int.tryParse(value) ?? 1;
                                              setState(() {});
                                            },
                                            validator: (value) {
                                              int? quantidade = int.tryParse(value ?? '');
                                              if (quantidade == null || quantidade <= 0) {
                                                return 'Quantidade inválida';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        
                                        // Valor unitário
                                        Expanded(
                                          child: TextFormField(
                                            initialValue: proc['valor_unitario']?.toString() ?? '0',
                                            decoration: InputDecoration(
                                              labelText: 'Valor Unitário',
                                              border: OutlineInputBorder(),
                                              prefixText: 'R\$ ',
                                            ),
                                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                                            onChanged: (value) {
                                              proc['valor_unitario'] = double.tryParse(value) ?? 0.0;
                                              setState(() {});
                                            },
                                            validator: (value) {
                                              double? valor = double.tryParse(value ?? '');
                                              if (valor == null || valor <= 0) {
                                                return 'Valor inválido';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          
                          // Botão adicionar procedimento
                          Card(
                            child: InkWell(
                              onTap: _adicionarProcedimento,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text(
                                      'Adicionar Procedimento',
                                      style: TextStyle(color: Colors.blue),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          SizedBox(height: 16),
                          
                          // Desconto e observações
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _descontoController,
                                  decoration: InputDecoration(
                                    labelText: 'Desconto',
                                    border: OutlineInputBorder(),
                                    prefixText: 'R\$ ',
                                  ),
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  validator: (value) {
                                    double? desconto = double.tryParse(value ?? '');
                                    if (desconto != null && desconto < 0) {
                                      return 'Desconto não pode ser negativo';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) => setState(() {}),
                                ),
                              ),
                              if (_isEdit) ...[
                                SizedBox(width: 8),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _status,
                                    decoration: InputDecoration(
                                      labelText: 'Status',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: [
                                      DropdownMenuItem(value: 'ativa', child: Text('Ativa')),
                                      DropdownMenuItem(value: 'concluida', child: Text('Concluída')),
                                      DropdownMenuItem(value: 'cancelada', child: Text('Cancelada')),
                                    ],
                                    onChanged: (value) {
                                      setState(() => _status = value ?? 'ativa');
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                          
                          SizedBox(height: 8),
                          
                          TextFormField(
                            controller: _observacoesController,
                            decoration: InputDecoration(
                              labelText: 'Observações (opcional)',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                          
                          SizedBox(height: 16),
                          
                          // Resumo financeiro
                          Card(
                            color: Colors.blue.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Resumo Financeiro',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Valor Total:'),
                                      Text(
                                        'R\$ ${_calcularValorTotal().toStringAsFixed(2)}',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Desconto:'),
                                      Text(
                                        'R\$ ${(double.tryParse(_descontoController.text) ?? 0.0).toStringAsFixed(2)}',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                  Divider(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Valor Final:',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'R\$ ${_calcularValorFinal().toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
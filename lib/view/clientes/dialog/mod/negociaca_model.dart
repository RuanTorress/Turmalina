import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:developer' as developer;

class NegociacaoModel {
  static Database? _database;
  
  // Getters para acesso ao banco
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  // Inicialização do banco de dados
  static Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'turmalina.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  // Criação das tabelas
  static Future<void> _createDB(Database db, int version) async {
    // Tabela principal de negociações (SEM procedimento_id obrigatório)
    await db.execute('''
      CREATE TABLE negociacoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cliente_id INTEGER NOT NULL,
        valor_total REAL NOT NULL DEFAULT 0.0,
        desconto REAL DEFAULT 0.0,
        valor_final REAL NOT NULL DEFAULT 0.0,
        status TEXT NOT NULL DEFAULT 'ativa',
        observacoes TEXT,
        criado_por TEXT NOT NULL,
        data_criacao TEXT NOT NULL,
        data_atualizacao TEXT NOT NULL,
        FOREIGN KEY (cliente_id) REFERENCES clientes (id) ON DELETE CASCADE
      )
    ''');

    // Tabela de relacionamento para múltiplos procedimentos por negociação
    await db.execute('''
      CREATE TABLE negociacao_procedimentos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        negociacao_id INTEGER NOT NULL,
        procedimento_id INTEGER NOT NULL,
        quantidade INTEGER NOT NULL DEFAULT 1,
        valor_unitario REAL NOT NULL DEFAULT 0.0,
        valor_total REAL NOT NULL DEFAULT 0.0,
        FOREIGN KEY (negociacao_id) REFERENCES negociacoes (id) ON DELETE CASCADE,
        FOREIGN KEY (procedimento_id) REFERENCES procedimentos (id) ON DELETE CASCADE
      )
    ''');

    // Tabela de clientes (para referência)
    await db.execute('''
      CREATE TABLE clientes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        telefone TEXT,
        email TEXT,
        endereco TEXT,
        data_criacao TEXT NOT NULL,
        data_atualizacao TEXT NOT NULL
      )
    ''');

    // Tabela de procedimentos (para referência)
    await db.execute('''
      CREATE TABLE procedimentos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        valor_padrao REAL NOT NULL DEFAULT 0.0,
        descricao TEXT,
        ativo INTEGER NOT NULL DEFAULT 1,
        data_criacao TEXT NOT NULL,
        data_atualizacao TEXT NOT NULL
      )
    ''');
  }

  // Validar foreign keys antes de inserir
  static Future<bool> _validarForeignKeys(Database db, int clienteId, List<int> procedimentoIds) async {
    try {
      // Verificar se cliente existe
      var clienteResult = await db.query(
        'clientes',
        where: 'id = ?',
        whereArgs: [clienteId],
      );
      
      if (clienteResult.isEmpty) {
        developer.log('Cliente não encontrado: $clienteId', name: 'NegociacaoModel');
        return false;
      }

      // Verificar se todos os procedimentos existem
      for (int procId in procedimentoIds) {
        var procResult = await db.query(
          'procedimentos',
          where: 'id = ? AND ativo = 1',
          whereArgs: [procId],
        );
        
        if (procResult.isEmpty) {
          developer.log('Procedimento não encontrado ou inativo: $procId', name: 'NegociacaoModel');
          return false;
        }
      }

      return true;
    } catch (e) {
      developer.log('Erro ao validar foreign keys: $e', name: 'NegociacaoModel');
      return false;
    }
  }

  // Inserir negociação com múltiplos procedimentos
  static Future<int?> inserirNegociacao({
    required int clienteId,
    required List<Map<String, dynamic>> procedimentos,
    double desconto = 0.0,
    String? observacoes,
    required String criadoPor,
  }) async {
    final db = await database;
    final agora = DateTime.now().toIso8601String();
    
    try {
      // Validar dados antes de inserir
      if (procedimentos.isEmpty) {
        developer.log('Erro: Lista de procedimentos vazia', name: 'NegociacaoModel');
        return null;
      }

      List<int> procedimentoIds = procedimentos.map((p) => p['procedimento_id'] as int).toList();
      
      if (!await _validarForeignKeys(db, clienteId, procedimentoIds)) {
        return null;
      }

      // Calcular valor total
      double valorTotal = 0.0;
      for (var proc in procedimentos) {
        double valorUnitario = proc['valor_unitario']?.toDouble() ?? 0.0;
        int quantidade = proc['quantidade'] ?? 1;
        valorTotal += valorUnitario * quantidade;
      }

      double valorFinal = valorTotal - desconto;

      // Iniciar transação para evitar inconsistências
      return await db.transaction((txn) async {
        try {
          // Inserir negociação principal (SEM procedimento_id)
          int negociacaoId = await txn.insert('negociacoes', {
            'cliente_id': clienteId,
            'valor_total': valorTotal,
            'desconto': desconto,
            'valor_final': valorFinal,
            'status': 'ativa',
            'observacoes': observacoes,
            'criado_por': criadoPor,
            'data_criacao': agora,
            'data_atualizacao': agora,
          });

          // Inserir procedimentos relacionados
          for (var proc in procedimentos) {
            await txn.insert('negociacao_procedimentos', {
              'negociacao_id': negociacaoId,
              'procedimento_id': proc['procedimento_id'],
              'quantidade': proc['quantidade'] ?? 1,
              'valor_unitario': proc['valor_unitario']?.toDouble() ?? 0.0,
              'valor_total': (proc['valor_unitario']?.toDouble() ?? 0.0) * (proc['quantidade'] ?? 1),
            });
          }

          developer.log('Negociação inserida com sucesso: $negociacaoId', name: 'NegociacaoModel');
          return negociacaoId;
        } catch (e) {
          developer.log('Erro na transação de inserção: $e', name: 'NegociacaoModel');
          throw e;
        }
      });
    } catch (e) {
      developer.log('Erro ao inserir negociação: $e', name: 'NegociacaoModel');
      return null;
    }
  }

  // Atualizar negociação existente
  static Future<bool> atualizarNegociacao({
    required int negociacaoId,
    required int clienteId,
    required List<Map<String, dynamic>> procedimentos,
    double desconto = 0.0,
    String? observacoes,
    String? status,
  }) async {
    final db = await database;
    final agora = DateTime.now().toIso8601String();
    
    try {
      // Validar se negociação existe
      var negResult = await db.query(
        'negociacoes',
        where: 'id = ?',
        whereArgs: [negociacaoId],
      );
      
      if (negResult.isEmpty) {
        developer.log('Negociação não encontrada: $negociacaoId', name: 'NegociacaoModel');
        return false;
      }

      // Validar foreign keys
      List<int> procedimentoIds = procedimentos.map((p) => p['procedimento_id'] as int).toList();
      if (!await _validarForeignKeys(db, clienteId, procedimentoIds)) {
        return false;
      }

      // Calcular novo valor total
      double valorTotal = 0.0;
      for (var proc in procedimentos) {
        double valorUnitario = proc['valor_unitario']?.toDouble() ?? 0.0;
        int quantidade = proc['quantidade'] ?? 1;
        valorTotal += valorUnitario * quantidade;
      }

      double valorFinal = valorTotal - desconto;

      // Iniciar transação
      return await db.transaction((txn) async {
        try {
          // Atualizar negociação principal
          await txn.update(
            'negociacoes',
            {
              'cliente_id': clienteId,
              'valor_total': valorTotal,
              'desconto': desconto,
              'valor_final': valorFinal,
              'status': status ?? 'ativa',
              'observacoes': observacoes,
              'data_atualizacao': agora,
            },
            where: 'id = ?',
            whereArgs: [negociacaoId],
          );

          // Remover procedimentos antigos
          await txn.delete(
            'negociacao_procedimentos',
            where: 'negociacao_id = ?',
            whereArgs: [negociacaoId],
          );

          // Inserir novos procedimentos
          for (var proc in procedimentos) {
            await txn.insert('negociacao_procedimentos', {
              'negociacao_id': negociacaoId,
              'procedimento_id': proc['procedimento_id'],
              'quantidade': proc['quantidade'] ?? 1,
              'valor_unitario': proc['valor_unitario']?.toDouble() ?? 0.0,
              'valor_total': (proc['valor_unitario']?.toDouble() ?? 0.0) * (proc['quantidade'] ?? 1),
            });
          }

          developer.log('Negociação atualizada com sucesso: $negociacaoId', name: 'NegociacaoModel');
          return true;
        } catch (e) {
          developer.log('Erro na transação de atualização: $e', name: 'NegociacaoModel');
          throw e;
        }
      });
    } catch (e) {
      developer.log('Erro ao atualizar negociação: $e', name: 'NegociacaoModel');
      return false;
    }
  }

  // Buscar negociação com procedimentos
  static Future<Map<String, dynamic>?> buscarNegociacao(int negociacaoId) async {
    final db = await database;
    
    try {
      // Buscar negociação principal
      var negResult = await db.query(
        'negociacoes',
        where: 'id = ?',
        whereArgs: [negociacaoId],
      );
      
      if (negResult.isEmpty) {
        developer.log('Negociação não encontrada: $negociacaoId', name: 'NegociacaoModel');
        return null;
      }

      Map<String, dynamic> negociacao = Map<String, dynamic>.from(negResult.first);

      // Buscar procedimentos relacionados
      var procResult = await db.rawQuery('''
        SELECT np.*, p.nome as procedimento_nome, p.descricao as procedimento_descricao
        FROM negociacao_procedimentos np
        INNER JOIN procedimentos p ON np.procedimento_id = p.id
        WHERE np.negociacao_id = ?
        ORDER BY p.nome
      ''', [negociacaoId]);

      negociacao['procedimentos'] = procResult;

      developer.log('Negociação encontrada: $negociacaoId', name: 'NegociacaoModel');
      return negociacao;
    } catch (e) {
      developer.log('Erro ao buscar negociação: $e', name: 'NegociacaoModel');
      return null;
    }
  }

  // Excluir negociação e dados relacionados
  static Future<bool> excluirNegociacao(int negociacaoId) async {
    final db = await database;
    
    try {
      return await db.transaction((txn) async {
        try {
          // Excluir procedimentos relacionados (cascade será tratado pelo banco)
          await txn.delete(
            'negociacao_procedimentos',
            where: 'negociacao_id = ?',
            whereArgs: [negociacaoId],
          );

          // Excluir negociação principal
          int deletedRows = await txn.delete(
            'negociacoes',
            where: 'id = ?',
            whereArgs: [negociacaoId],
          );

          if (deletedRows > 0) {
            developer.log('Negociação excluída com sucesso: $negociacaoId', name: 'NegociacaoModel');
            return true;
          } else {
            developer.log('Negociação não encontrada para exclusão: $negociacaoId', name: 'NegociacaoModel');
            return false;
          }
        } catch (e) {
          developer.log('Erro na transação de exclusão: $e', name: 'NegociacaoModel');
          throw e;
        }
      });
    } catch (e) {
      developer.log('Erro ao excluir negociação: $e', name: 'NegociacaoModel');
      return false;
    }
  }

  // Listar negociações por cliente
  static Future<List<Map<String, dynamic>>> listarNegociacoesPorCliente(int clienteId) async {
    final db = await database;
    
    try {
      var result = await db.rawQuery('''
        SELECT n.*, c.nome as cliente_nome
        FROM negociacoes n
        INNER JOIN clientes c ON n.cliente_id = c.id
        WHERE n.cliente_id = ?
        ORDER BY n.data_criacao DESC
      ''', [clienteId]);

      developer.log('Encontradas ${result.length} negociações para cliente: $clienteId', name: 'NegociacaoModel');
      return result;
    } catch (e) {
      developer.log('Erro ao listar negociações por cliente: $e', name: 'NegociacaoModel');
      return [];
    }
  }

  // Método de fallback para campos opcionais
  static Map<String, dynamic> aplicarFallbacks(Map<String, dynamic> dados) {
    return {
      'observacoes': dados['observacoes'] ?? '',
      'desconto': dados['desconto']?.toDouble() ?? 0.0,
      'status': dados['status'] ?? 'ativa',
      ...dados,
    };
  }
}
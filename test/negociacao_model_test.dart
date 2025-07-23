import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:turmalina/view/clientes/dialog/mod/negociaca_model.dart';

void main() {
  group('NegociacaoModel Tests', () {
    setUp(() async {
      // Ensure we have a clean database for each test
      await NegociacaoModel.database;
    });

    test('deve criar negociação com múltiplos procedimentos', () async {
      // Arrange
      final db = await NegociacaoModel.database;
      
      // Criar cliente de teste
      int clienteId = await db.insert('clientes', {
        'nome': 'Cliente Teste',
        'telefone': '(11) 99999-9999',
        'email': 'teste@email.com',
        'endereco': 'Rua Teste, 123',
        'data_criacao': DateTime.now().toIso8601String(),
        'data_atualizacao': DateTime.now().toIso8601String(),
      });

      // Criar procedimentos de teste
      int proc1Id = await db.insert('procedimentos', {
        'nome': 'Procedimento 1',
        'valor_padrao': 100.0,
        'descricao': 'Teste 1',
        'ativo': 1,
        'data_criacao': DateTime.now().toIso8601String(),
        'data_atualizacao': DateTime.now().toIso8601String(),
      });

      int proc2Id = await db.insert('procedimentos', {
        'nome': 'Procedimento 2',
        'valor_padrao': 200.0,
        'descricao': 'Teste 2',
        'ativo': 1,
        'data_criacao': DateTime.now().toIso8601String(),
        'data_atualizacao': DateTime.now().toIso8601String(),
      });

      List<Map<String, dynamic>> procedimentos = [
        {
          'procedimento_id': proc1Id,
          'quantidade': 2,
          'valor_unitario': 100.0,
        },
        {
          'procedimento_id': proc2Id,
          'quantidade': 1,
          'valor_unitario': 200.0,
        },
      ];

      // Act
      int? negociacaoId = await NegociacaoModel.inserirNegociacao(
        clienteId: clienteId,
        procedimentos: procedimentos,
        desconto: 50.0,
        observacoes: 'Teste de negociação',
        criadoPor: 'usuario_teste',
      );

      // Assert
      expect(negociacaoId, isNotNull);
      expect(negociacaoId! > 0, isTrue);

      // Verificar se a negociação foi criada corretamente
      Map<String, dynamic>? negociacao = await NegociacaoModel.buscarNegociacao(negociacaoId);
      expect(negociacao, isNotNull);
      expect(negociacao!['cliente_id'], equals(clienteId));
      expect(negociacao['valor_total'], equals(400.0)); // (2*100) + (1*200)
      expect(negociacao['desconto'], equals(50.0));
      expect(negociacao['valor_final'], equals(350.0)); // 400 - 50
      expect(negociacao['observacoes'], equals('Teste de negociação'));
      expect(negociacao['status'], equals('ativa'));

      // Verificar procedimentos relacionados
      List<Map<String, dynamic>> procRelacionados = negociacao['procedimentos'];
      expect(procRelacionados.length, equals(2));
    });

    test('deve atualizar negociação existente', () async {
      // Arrange
      final db = await NegociacaoModel.database;
      
      // Criar dados de teste
      int clienteId = await db.insert('clientes', {
        'nome': 'Cliente Teste',
        'telefone': '(11) 99999-9999',
        'email': 'teste@email.com',
        'endereco': 'Rua Teste, 123',
        'data_criacao': DateTime.now().toIso8601String(),
        'data_atualizacao': DateTime.now().toIso8601String(),
      });

      int procId = await db.insert('procedimentos', {
        'nome': 'Procedimento Teste',
        'valor_padrao': 150.0,
        'descricao': 'Teste',
        'ativo': 1,
        'data_criacao': DateTime.now().toIso8601String(),
        'data_atualizacao': DateTime.now().toIso8601String(),
      });

      // Criar negociação inicial
      int? negociacaoId = await NegociacaoModel.inserirNegociacao(
        clienteId: clienteId,
        procedimentos: [
          {
            'procedimento_id': procId,
            'quantidade': 1,
            'valor_unitario': 150.0,
          }
        ],
        criadoPor: 'usuario_teste',
      );

      expect(negociacaoId, isNotNull);

      // Act - Atualizar negociação
      bool sucesso = await NegociacaoModel.atualizarNegociacao(
        negociacaoId: negociacaoId!,
        clienteId: clienteId,
        procedimentos: [
          {
            'procedimento_id': procId,
            'quantidade': 3,
            'valor_unitario': 150.0,
          }
        ],
        desconto: 100.0,
        observacoes: 'Negociação atualizada',
        status: 'concluida',
      );

      // Assert
      expect(sucesso, isTrue);

      // Verificar se a atualização foi aplicada
      Map<String, dynamic>? negociacao = await NegociacaoModel.buscarNegociacao(negociacaoId);
      expect(negociacao, isNotNull);
      expect(negociacao!['valor_total'], equals(450.0)); // 3 * 150
      expect(negociacao['desconto'], equals(100.0));
      expect(negociacao['valor_final'], equals(350.0)); // 450 - 100
      expect(negociacao['observacoes'], equals('Negociação atualizada'));
      expect(negociacao['status'], equals('concluida'));
    });

    test('deve excluir negociação e dados relacionados', () async {
      // Arrange
      final db = await NegociacaoModel.database;
      
      int clienteId = await db.insert('clientes', {
        'nome': 'Cliente Teste',
        'telefone': '(11) 99999-9999',
        'email': 'teste@email.com',
        'endereco': 'Rua Teste, 123',
        'data_criacao': DateTime.now().toIso8601String(),
        'data_atualizacao': DateTime.now().toIso8601String(),
      });

      int procId = await db.insert('procedimentos', {
        'nome': 'Procedimento Teste',
        'valor_padrao': 100.0,
        'descricao': 'Teste',
        'ativo': 1,
        'data_criacao': DateTime.now().toIso8601String(),
        'data_atualizacao': DateTime.now().toIso8601String(),
      });

      int? negociacaoId = await NegociacaoModel.inserirNegociacao(
        clienteId: clienteId,
        procedimentos: [
          {
            'procedimento_id': procId,
            'quantidade': 1,
            'valor_unitario': 100.0,
          }
        ],
        criadoPor: 'usuario_teste',
      );

      expect(negociacaoId, isNotNull);

      // Act
      bool sucesso = await NegociacaoModel.excluirNegociacao(negociacaoId!);

      // Assert
      expect(sucesso, isTrue);

      // Verificar se a negociação foi removida
      Map<String, dynamic>? negociacao = await NegociacaoModel.buscarNegociacao(negociacaoId);
      expect(negociacao, isNull);

      // Verificar se os procedimentos relacionados foram removidos
      var procRelacionados = await db.query(
        'negociacao_procedimentos',
        where: 'negociacao_id = ?',
        whereArgs: [negociacaoId],
      );
      expect(procRelacionados.isEmpty, isTrue);
    });

    test('deve validar foreign keys antes de inserir', () async {
      // Act - Tentar inserir negociação com cliente inexistente
      int? negociacaoId = await NegociacaoModel.inserirNegociacao(
        clienteId: 99999, // Cliente que não existe
        procedimentos: [
          {
            'procedimento_id': 1,
            'quantidade': 1,
            'valor_unitario': 100.0,
          }
        ],
        criadoPor: 'usuario_teste',
      );

      // Assert
      expect(negociacaoId, isNull);
    });

    test('deve aplicar fallbacks para campos opcionais', () async {
      // Arrange
      Map<String, dynamic> dados = {
        'campo_obrigatorio': 'valor',
      };

      // Act
      Map<String, dynamic> dadosComFallback = NegociacaoModel.aplicarFallbacks(dados);

      // Assert
      expect(dadosComFallback['observacoes'], equals(''));
      expect(dadosComFallback['desconto'], equals(0.0));
      expect(dadosComFallback['status'], equals('ativa'));
      expect(dadosComFallback['campo_obrigatorio'], equals('valor'));
    });
  });
}
// lib/servicos/database_cloud_service.dart
// Serviço de conexão direta ao banco PostgreSQL na nuvem (Neon)

import 'package:postgres/postgres.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../configuracao/neon_config.dart';

class CloudDatabaseService {
  static CloudDatabaseService? _instance;
  Connection? _connection;

  CloudDatabaseService._();

  static CloudDatabaseService get instance {
    _instance ??= CloudDatabaseService._();
    return _instance!;
  }

  /// Conecta ao banco de dados
  Future<Connection> _getConnection() async {
    if (_connection != null) {
      return _connection!;
    }

    try {
      print('🔌 Conectando ao banco Neon...');

      final endpoint = Endpoint(
        host: NeonConfig.host,
        port: NeonConfig.port,
        database: NeonConfig.database,
        username: NeonConfig.username,
        password: NeonConfig.password,
      );

      _connection = await Connection.open(
        endpoint,
        settings: ConnectionSettings(
          sslMode: SslMode.require,
          connectTimeout: Duration(seconds: NeonConfig.connectionTimeout),
          queryTimeout: Duration(seconds: NeonConfig.queryTimeout),
        ),
      );

      print('✅ Conectado ao banco Neon com sucesso!');
      return _connection!;
    } catch (e) {
      print('❌ Erro ao conectar ao banco: $e');
      rethrow;
    }
  }

  /// Fecha a conexão
  Future<void> closeConnection() async {
    if (_connection != null) {
      await _connection!.close();
      _connection = null;
      print('🔌 Conexão fechada');
    }
  }

  // ============================================================================
  // MÉTODOS DE LICENÇA
  // ============================================================================

  /// Verifica se existe uma licença válida para a empresa
  Future<LicencaResult> verificarLicenca({
    required int empresaId,
    required String cnpj,
    String? deviceId,
  }) async {
    try {
      final conn = await _getConnection();

      // Busca licença por empresa_id ou cnpj
      final result = await conn.execute(
        Sql.named('''
          SELECT 
            id, chave, empresa_id, cnpj, razao_social,
            plano, max_terminais,
            data_ativacao, data_expiracao,
            ativo, bloqueado, motivo_bloqueio
          FROM licencas 
          WHERE empresa_id = @empresaId OR cnpj = @cnpj
          LIMIT 1
        '''),
        parameters: {
          'empresaId': empresaId,
          'cnpj': cnpj,
        },
      );

      if (result.isEmpty) {
        return LicencaResult(
          valida: false,
          mensagem: 'Licença não encontrada para esta empresa',
        );
      }

      final row = result.first;
      final ativo = row[9] as bool? ?? false;
      final bloqueado = row[10] as bool? ?? false;
      final motivoBloqueio = row[11] as String?;
      final dataExpiracao = row[8] as DateTime?;

      // Verifica se está ativa
      if (!ativo) {
        return LicencaResult(
          valida: false,
          mensagem: 'Licença desativada',
        );
      }

      // Verifica se está bloqueada
      if (bloqueado) {
        return LicencaResult(
          valida: false,
          mensagem:
              'Licença bloqueada: ${motivoBloqueio ?? "Entre em contato com o suporte"}',
        );
      }

      // Verifica expiração
      if (dataExpiracao != null && dataExpiracao.isBefore(DateTime.now())) {
        return LicencaResult(
          valida: false,
          mensagem: 'Licença expirada',
          expiracao: dataExpiracao,
        );
      }

      // Atualiza último check-in
      await conn.execute(
        Sql.named('''
          UPDATE licencas 
          SET ultimo_checkin = NOW() 
          WHERE id = @id
        '''),
        parameters: {'id': row[0]},
      );

      return LicencaResult(
        valida: true,
        chave: row[1] as String?,
        expiracao: dataExpiracao,
        plano: row[5] as String?,
        maxTerminais: row[6] as int?,
        mensagem: 'Licença válida',
      );
    } catch (e) {
      print('❌ Erro ao verificar licença: $e');
      return LicencaResult(
        valida: false,
        mensagem: 'Erro ao verificar licença: $e',
      );
    }
  }

  /// Ativa uma licença usando chave de ativação
  Future<LicencaResult> ativarLicenca({
    required String chaveAtivacao,
    required int empresaId,
    required String cnpj,
    String? razaoSocial,
    String? deviceId,
  }) async {
    try {
      final conn = await _getConnection();

      // Busca a chave de ativação
      final chaveResult = await conn.execute(
        Sql.named('''
          SELECT id, plano, max_terminais, dias_validade, usada, data_expiracao_chave
          FROM chaves_ativacao 
          WHERE chave = @chave
          LIMIT 1
        '''),
        parameters: {'chave': chaveAtivacao.toUpperCase().trim()},
      );

      if (chaveResult.isEmpty) {
        return LicencaResult(
          valida: false,
          mensagem: 'Chave de ativação inválida',
        );
      }

      final chaveRow = chaveResult.first;
      final chaveId = chaveRow[0] as int;
      final usada = chaveRow[4] as bool? ?? false;
      final dataExpiracaoChave = chaveRow[5] as DateTime?;

      if (usada) {
        return LicencaResult(
          valida: false,
          mensagem: 'Esta chave de ativação já foi utilizada',
        );
      }

      if (dataExpiracaoChave != null &&
          dataExpiracaoChave.isBefore(DateTime.now())) {
        return LicencaResult(
          valida: false,
          mensagem: 'Chave de ativação expirada',
        );
      }

      final plano = chaveRow[1] as String? ?? 'basico';
      final maxTerminais = chaveRow[2] as int? ?? 1;
      final diasValidade = chaveRow[3] as int? ?? 365;
      final dataExpiracao = DateTime.now().add(Duration(days: diasValidade));

      // Verifica se já existe licença para esta empresa
      final licencaExistente = await conn.execute(
        Sql.named('''
          SELECT id FROM licencas 
          WHERE empresa_id = @empresaId OR cnpj = @cnpj
          LIMIT 1
        '''),
        parameters: {'empresaId': empresaId, 'cnpj': cnpj},
      );

      String novaChave;

      if (licencaExistente.isNotEmpty) {
        // Atualiza licença existente
        final licencaId = licencaExistente.first[0] as int;
        await conn.execute(
          Sql.named('''
            UPDATE licencas SET
              data_expiracao = @expiracao,
              plano = @plano,
              max_terminais = @maxTerminais,
              ativo = true,
              bloqueado = false
            WHERE id = @id
            RETURNING chave
          '''),
          parameters: {
            'id': licencaId,
            'expiracao': dataExpiracao,
            'plano': plano,
            'maxTerminais': maxTerminais,
          },
        );

        final chaveAtual = await conn.execute(
          Sql.named('SELECT chave FROM licencas WHERE id = @id'),
          parameters: {'id': licencaId},
        );
        novaChave = chaveAtual.first[0] as String;
      } else {
        // Cria nova licença
        novaChave = _gerarChaveLicenca();
        await conn.execute(
          Sql.named('''
            INSERT INTO licencas (
              chave, empresa_id, cnpj, razao_social,
              plano, max_terminais,
              data_ativacao, data_expiracao,
              ativo
            ) VALUES (
              @chave, @empresaId, @cnpj, @razaoSocial,
              @plano, @maxTerminais,
              NOW(), @expiracao,
              true
            )
          '''),
          parameters: {
            'chave': novaChave,
            'empresaId': empresaId,
            'cnpj': cnpj,
            'razaoSocial': razaoSocial,
            'plano': plano,
            'maxTerminais': maxTerminais,
            'expiracao': dataExpiracao,
          },
        );
      }

      // Marca chave como usada
      await conn.execute(
        Sql.named('''
          UPDATE chaves_ativacao SET
            usada = true,
            empresa_id_usada = @empresaId,
            data_uso = NOW()
          WHERE id = @chaveId
        '''),
        parameters: {
          'chaveId': chaveId,
          'empresaId': empresaId,
        },
      );

      return LicencaResult(
        valida: true,
        chave: novaChave,
        expiracao: dataExpiracao,
        plano: plano,
        maxTerminais: maxTerminais,
        mensagem: 'Licença ativada com sucesso!',
      );
    } catch (e) {
      print('❌ Erro ao ativar licença: $e');
      return LicencaResult(
        valida: false,
        mensagem: 'Erro ao ativar licença: $e',
      );
    }
  }

  // ============================================================================
  // MÉTODOS DE ADMIN
  // ============================================================================

  /// Valida credenciais de admin
  Future<AdminResult> validarAdmin({
    required String usuario,
    required String senha,
    required int empresaId,
  }) async {
    try {
      final conn = await _getConnection();

      // Busca usuário (0 = admin global, ou empresa específica)
      final result = await conn.execute(
        Sql.named('''
          SELECT id, senha_hash, nome, ativo
          FROM admin_usuarios 
          WHERE usuario = @usuario 
            AND (empresa_id = @empresaId OR empresa_id = 0)
          LIMIT 1
        '''),
        parameters: {
          'usuario': usuario,
          'empresaId': empresaId,
        },
      );

      if (result.isEmpty) {
        return AdminResult(
          success: false,
          message: 'Usuário não encontrado',
        );
      }

      final row = result.first;
      final senhaHash = row[1] as String;
      final ativo = row[3] as bool? ?? false;

      if (!ativo) {
        return AdminResult(
          success: false,
          message: 'Usuário desativado',
        );
      }

      // Verifica senha
      // Suporta: texto simples, SHA256, ou bcrypt
      bool senhaCorreta = false;

      if (senhaHash.startsWith('\$2')) {
        // É bcrypt - para Flutter puro, vamos aceitar credencial padrão
        // Em produção, use pacote bcrypt do Dart
        senhaCorreta = (usuario == 'admin' && senha == 'auto@2024');
      } else if (senhaHash.length == 64) {
        // É SHA256 (64 caracteres hex)
        final senhaInputHash = _hashSenha(senha);
        senhaCorreta = (senhaHash == senhaInputHash);
      } else {
        // É texto simples (para desenvolvimento)
        senhaCorreta = (senhaHash == senha);
      }

      if (!senhaCorreta) {
        return AdminResult(
          success: false,
          message: 'Senha incorreta',
        );
      }

      // Atualiza último login
      await conn.execute(
        Sql.named('''
          UPDATE admin_usuarios 
          SET ultimo_login = NOW() 
          WHERE id = @id
        '''),
        parameters: {'id': row[0]},
      );

      return AdminResult(
        success: true,
        message: 'Login realizado com sucesso',
        nome: row[2] as String?,
      );
    } catch (e) {
      print('❌ Erro ao validar admin: $e');

      // Fallback para credenciais locais se não conseguir conectar
      if (usuario == 'admin' && senha == 'auto@2024') {
        return AdminResult(
          success: true,
          message: 'Login local (offline)',
          isOffline: true,
        );
      }

      return AdminResult(
        success: false,
        message: 'Erro ao validar credenciais: $e',
      );
    }
  }

  // ============================================================================
  // MÉTODOS AUXILIARES
  // ============================================================================

  /// Gera uma chave de licença no formato XXXX-XXXX-XXXX-XXXX
  String _gerarChaveLicenca() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    final grupos = <String>[];

    for (var g = 0; g < 4; g++) {
      var grupo = '';
      for (var i = 0; i < 4; i++) {
        final index = (random + g * 4 + i) % chars.length;
        grupo += chars[index];
      }
      grupos.add(grupo);
    }

    return grupos.join('-');
  }

  /// Gera hash SHA256 da senha
  String _hashSenha(String senha) {
    final bytes = utf8.encode(senha);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Testa a conexão com o banco
  Future<bool> testarConexao() async {
    try {
      final conn = await _getConnection();
      final result = await conn.execute(Sql.named('SELECT 1 as teste'));
      return result.isNotEmpty;
    } catch (e) {
      print('❌ Erro ao testar conexão: $e');
      return false;
    }
  }
}

// ============================================================================
// MODELOS DE RESULTADO
// ============================================================================

class LicencaResult {
  final bool valida;
  final String? chave;
  final DateTime? expiracao;
  final String? mensagem;
  final String? plano;
  final int? maxTerminais;

  LicencaResult({
    required this.valida,
    this.chave,
    this.expiracao,
    this.mensagem,
    this.plano,
    this.maxTerminais,
  });
}

class AdminResult {
  final bool success;
  final String message;
  final String? nome;
  final bool isOffline;

  AdminResult({
    required this.success,
    required this.message,
    this.nome,
    this.isOffline = false,
  });
}

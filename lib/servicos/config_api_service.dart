// lib/servicos/config_api_service.dart
// Serviço de API para configuração inicial
// Gerencia conexões HTTP locais (Sistema Restaurante) e Conexão Direta DB (Licenciamento)

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../modelos/config_models.dart';
import './database_cloud_service.dart';

class ConfigApiService {
  final Duration timeout;
  // Instância do serviço que fala direto com o PostgreSQL (Neon/Cloud)
  final CloudDatabaseService _cloudDb = CloudDatabaseService.instance;

  ConfigApiService({
    this.timeout = const Duration(seconds: 10),
  });

  // Headers padrão para requisições HTTP locais
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // ==========================================================================
  // 1. CONEXÃO COM SERVIDOR LOCAL (SISTEMA DO RESTAURANTE)
  // ==========================================================================

  /// Testa conexão com o servidor local (onde roda o banco do restaurante)
  Future<ConnectionResult> testarConexao(String ip, int porta) async {
    try {
      final url = Uri.parse('http://$ip:$porta/health');
      print('🔌 Testando conexão local: $url');

      final response = await http.get(url).timeout(timeout);

      if (response.statusCode == 200) {
        print('✅ Conexão local bem sucedida!');
        return ConnectionResult(
          success: true,
          message: 'Conexão estabelecida com sucesso!',
        );
      } else {
        return ConnectionResult(
          success: false,
          message: 'Servidor respondeu com erro: ${response.statusCode}',
        );
      }
    } on SocketException catch (e) {
      print('❌ Erro de conexão (Socket): $e');
      return ConnectionResult(
        success: false,
        message:
            'Não foi possível conectar ao servidor. Verifique o IP e a porta.',
      );
    } on http.ClientException catch (e) {
      return ConnectionResult(
        success: false,
        message: 'Erro de cliente HTTP: $e',
      );
    } catch (e) {
      return ConnectionResult(
        success: false,
        message: 'Erro inesperado: $e',
      );
    }
  }

  /// Busca lista de empresas do servidor local
  Future<List<EmpresaConfig>> buscarEmpresas(String ip, int porta) async {
    try {
      final url = Uri.parse('http://$ip:$porta/api/v1/empresas');
      print('🏢 Buscando empresas: $url');

      final response = await http.get(url, headers: _headers).timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List<dynamic> items;
        if (data is List) {
          items = data;
        } else if (data is Map && data['items'] != null) {
          items = data['items'] as List;
        } else {
          items = [];
        }

        final empresas = items.map((e) => EmpresaConfig.fromJson(e)).toList();

        print('✅ ${empresas.length} empresas encontradas');
        return empresas;
      } else {
        print('❌ Erro ao buscar empresas: ${response.statusCode}');
        throw Exception(
            'Erro ao buscar empresas: Código ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Falha na busca de empresas: $e');
      rethrow;
    }
  }

  /// Busca lista de cardápios de uma empresa específica
  Future<List<CardapioConfig>> buscarCardapios(
    String ip,
    int porta,
    int empresaId,
  ) async {
    try {
      final url =
          Uri.parse('http://$ip:$porta/api/v1/cardapios?empresa_id=$empresaId');
      print('📋 Buscando cardápios: $url');

      final response = await http.get(url, headers: _headers).timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List<dynamic> items;
        if (data is List) {
          items = data;
        } else if (data is Map && data['items'] != null) {
          items = data['items'] as List;
        } else {
          items = [];
        }

        final cardapios = items.map((e) => CardapioConfig.fromJson(e)).toList();

        print('✅ ${cardapios.length} cardápios encontrados');
        return cardapios;
      } else {
        print('❌ Erro ao buscar cardápios: ${response.statusCode}');
        throw Exception('Erro HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro ao buscar cardápios: $e');
      rethrow;
    }
  }

  // ==========================================================================
  // 2. SERVIDOR DE LICENÇAS NA NUVEM (CONEXÃO DIRETA POSTGRES)
  // ==========================================================================

  /// Verifica se a licença é válida e se o dispositivo pode operar.
  /// Chama a função SQL 'registrar_terminal' via CloudDatabaseService.
  Future<LicencaInfo> verificarLicenca({
    required int empresaId,
    required String cnpj,
    required String
        deviceId, // DeviceID agora é obrigatório para controle de limite
  }) async {
    try {
      print(
          '🔑 Verificando licença no Cloud DB para empresa $empresaId (Device: $deviceId)');

      // O CloudDatabaseService deve chamar a procedure que verifica o limite de terminais
      final result = await _cloudDb.verificarLicenca(
        empresaId: empresaId,
        cnpj: cnpj,
        deviceId: deviceId,
      );

      return LicencaInfo(
        valida: result.valida,
        chave: result.chave,
        expiracao: result.expiracao,
        mensagem: result.mensagem,
        plano: result.plano,
        maxTerminais: result.maxTerminais,
      );
    } catch (e) {
      print('❌ Erro crítico ao verificar licença: $e');
      // Retorna uma licença inválida genérica em caso de erro de conexão/banco
      return LicencaInfo.invalida(
          'Falha na conexão com servidor de licenças: $e');
    }
  }

  /// Ativa uma nova licença usando uma chave (ex: PROF-XXXX...)
  Future<LicencaInfo> ativarLicenca({
    required String chaveAtivacao,
    required int empresaId,
    required String cnpj,
    String? razaoSocial,
    required String deviceId,
  }) async {
    try {
      print('🔐 Tentando ativar nova licença no Cloud DB...');

      final result = await _cloudDb.ativarLicenca(
        chaveAtivacao: chaveAtivacao,
        empresaId: empresaId,
        cnpj: cnpj,
        razaoSocial: razaoSocial,
        deviceId: deviceId,
      );

      return LicencaInfo(
        valida: result.valida,
        chave: result.chave,
        expiracao: result.expiracao,
        mensagem: result.mensagem,
        plano: result.plano,
        maxTerminais: result.maxTerminais,
      );
    } catch (e) {
      print('❌ Erro ao ativar licença: $e');
      return LicencaInfo.invalida('Erro ao processar ativação: $e');
    }
  }

  // ==========================================================================
  // 3. ADMINISTRAÇÃO E UTILITÁRIOS
  // ==========================================================================

  /// Valida usuário e senha de admin para acessar configurações do Totem
  Future<AuthResult> validarCredenciaisAdmin({
    required String usuario,
    required String senha,
    required int empresaId,
  }) async {
    try {
      print('🛡️ Validando admin no Cloud DB...');

      final result = await _cloudDb.validarAdmin(
        usuario: usuario,
        senha: senha,
        empresaId: empresaId,
      );

      return AuthResult(
        success: result.success,
        message: result.message,
        isOffline: result.isOffline,
      );
    } catch (e) {
      print('⚠️ Erro ao validar admin online: $e');

      // FALLBACK: Senha de emergência local caso esteja sem internet
      if (usuario == 'admin' && senha == 'auto@2024') {
        print('⚠️ Usando credencial de emergência local');
        return AuthResult(
          success: true,
          message: 'Login de emergência (Offline)',
          isOffline: true,
        );
      }

      return AuthResult(
        success: false,
        message: 'Erro na validação: $e',
      );
    }
  }

  /// Verifica se há conexão com a internet/banco na nuvem
  Future<bool> testarConexaoNuvem() async {
    return await _cloudDb.testarConexao();
  }

  /// Fecha conexões pendentes (útil ao fechar o app)
  Future<void> fecharConexaoNuvem() async {
    await _cloudDb.closeConnection();
  }
}

// ==========================================================================
// CLASSES AUXILIARES DE RESPOSTA
// ==========================================================================

/// Resultado simplificado de testes de conexão
class ConnectionResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? serverInfo;

  ConnectionResult({
    required this.success,
    required this.message,
    this.serverInfo,
  });
}

/// Resultado de tentativas de login
class AuthResult {
  final bool success;
  final String message;
  final String? token;
  final bool isOffline;

  AuthResult({
    required this.success,
    required this.message,
    this.token,
    this.isOffline = false,
  });
}

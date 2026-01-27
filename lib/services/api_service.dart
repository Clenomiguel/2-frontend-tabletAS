// lib/services/api_service.dart
// Serviço de comunicação com o backend FastAPI

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../models/produto_models.dart';
import '../models/cardapio_models.dart';
import '../models/cart_models.dart';

/// Exceção customizada para erros de API
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

/// Configuração da API
class ApiConfig {
  final String baseUrl;
  final int empresaId;
  final int? cardapioId; // Cardápio padrão (opcional)
  final Duration timeout;

  const ApiConfig({
    required this.baseUrl,
    required this.empresaId,
    this.cardapioId,
    this.timeout = const Duration(seconds: 30),
  });

  /// Configuração de desenvolvimento
  factory ApiConfig.dev() {
    return const ApiConfig(
      baseUrl: 'http://192.168.3.150:8000',
      empresaId: 26322354,
      cardapioId: null, // Será carregado dinamicamente
    );
  }
}

/// Serviço principal de API
class ApiService {
  final ApiConfig config;
  final http.Client _client;

  ApiService({
    required this.config,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Headers padrão para requisições
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// Monta URL completa
  Uri _buildUrl(String path, [Map<String, dynamic>? queryParams]) {
    final uri = Uri.parse('${config.baseUrl}$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      final cleanParams = <String, String>{};
      queryParams.forEach((key, value) {
        if (value != null) {
          cleanParams[key] = value.toString();
        }
      });
      return uri.replace(queryParameters: cleanParams);
    }
    return uri;
  }

  /// GET request genérico
  Future<dynamic> _get(
    String path, [
    Map<String, dynamic>? queryParams,
  ]) async {
    try {
      final url = _buildUrl(path, queryParams);
      print('🌐 GET: $url');

      final response =
          await _client.get(url, headers: _headers).timeout(config.timeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Sem conexão com o servidor');
    } on http.ClientException catch (e) {
      throw ApiException('Erro de conexão: $e');
    }
  }

  /// POST request genérico
  Future<dynamic> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final url = _buildUrl(path);
      print('🌐 POST: $url');
      print('📦 Body: $body');

      final response = await _client
          .post(
            url,
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(config.timeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Sem conexão com o servidor');
    } on http.ClientException catch (e) {
      throw ApiException('Erro de conexão: $e');
    }
  }

  /// Processa resposta HTTP
  dynamic _handleResponse(http.Response response) {
    print('📥 Status: ${response.statusCode}');

    if (response.body.isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return <String, dynamic>{};
      }
      throw ApiException('Resposta vazia', statusCode: response.statusCode);
    }

    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (e) {
      throw ApiException('Erro ao decodificar resposta: $e');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final message = body is Map
        ? (body['detail'] ?? body['message'] ?? 'Erro desconhecido')
        : 'Erro desconhecido';
    throw ApiException(
      message.toString(),
      statusCode: response.statusCode,
      data: body,
    );
  }

  // ============================================================
  // CARDÁPIOS
  // ============================================================

  /// Lista todos os cardápios da empresa
  Future<List<Cardapio>> getCardapios({int skip = 0, int limit = 100}) async {
    final data = await _get('/api/v1/cardapios', {
      'skip': skip,
      'limit': limit,
    });

    final items = data['items'] as List? ?? [];
    return items.map((e) => Cardapio.fromJson(e)).toList();
  }

  /// Busca cardápio por ID
  Future<Cardapio> getCardapio(int cardapioId) async {
    final data = await _get('/api/v1/cardapios/$cardapioId');
    return Cardapio.fromJson(data);
  }

  /// Busca cardápio completo por ID (com seções e produtos)
  Future<CardapioCompleto> getCardapioCompleto(int cardapioId) async {
    final data = await _get('/api/v1/cardapios/$cardapioId/completo');
    return CardapioCompleto.fromJson(data);
  }

  /// Busca primeiro cardápio disponível (substitui getCardapioAtivo)
  Future<CardapioCompleto?> getCardapioAtivo() async {
    try {
      // Se temos um cardápio configurado, usa ele
      if (config.cardapioId != null) {
        return await getCardapioCompleto(config.cardapioId!);
      }

      // Senão, busca a lista e pega o primeiro
      final cardapios = await getCardapios(limit: 1);
      if (cardapios.isEmpty) {
        return null;
      }

      return await getCardapioCompleto(cardapios.first.grid);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Lista seções de um cardápio
  Future<List<CardapioSecao>> getSecoesCardapio(int cardapioId) async {
    final data = await _get('/api/v1/cardapios/codigo/$cardapioId/secoes');

    if (data is List) {
      return data.map((e) => CardapioSecao.fromJson(e)).toList();
    }
    return [];
  }

  // ============================================================
  // PRODUTOS
  // ============================================================

  /// Busca produto por ID
  Future<Produto> getProduto(int produtoId) async {
    final data = await _get('/api/v1/produtos/$produtoId');
    return Produto.fromJson(data);
  }

  /// Busca produto completo por ID (com imagens, complementos, composição)
  Future<ProdutoCompleto> getProdutoCompleto(int produtoId) async {
    final data = await _get('/api/v1/produtos/$produtoId/completo');
    return ProdutoCompleto.fromJson(data);
  }

  /// Lista produtos paginados
  Future<PaginatedResponse<Produto>> getProdutos({
    int page = 1,
    int perPage = 100,
    String? search,
    int? grupoId,
  }) async {
    final skip = (page - 1) * perPage;
    final params = <String, dynamic>{
      'skip': skip,
      'limit': perPage,
    };
    if (search != null) params['search'] = search;
    if (grupoId != null) params['grupo_grid'] = grupoId;

    final data = await _get('/api/v1/produtos', params);
    return PaginatedResponse.fromJson(data, Produto.fromJson);
  }

  /// Busca preparos de um produto
  Future<PreparosDoProduto> getPreparosProduto(int produtoId) async {
    final data = await _get('/api/v1/produtos/$produtoId/preparo');
    return PreparosDoProduto.fromJson(data);
  }

  /// Busca composição de um produto (com detalhes)
  Future<List<ProdutoComposicao>> getComposicaoProduto(int produtoId) async {
    final data = await _get('/api/v1/produtos/$produtoId/composicao/detalhes');

    if (data is List) {
      return data.map((e) => ProdutoComposicao.fromJson(e)).toList();
    }
    return [];
  }

  /// Busca complementos de um produto (com detalhes)
  Future<List<ProdutoComplemento>> getComplementosProduto(int produtoId) async {
    final data =
        await _get('/api/v1/produtos/$produtoId/complementos/detalhes');

    if (data is List) {
      return data.map((e) => ProdutoComplemento.fromJson(e)).toList();
    }
    return [];
  }

  // ============================================================
  // IMAGENS
  // ============================================================

  /// Monta URL da imagem do produto
  String getProdutoImageUrl(int produtoId, {String size = 'medium'}) {
    // Usando o endpoint de imagens estáticas do backend
    return '${config.baseUrl}/api/v1/static/img/produtos/produto_$produtoId.jpeg';
  }

  /// Monta URL da imagem da seção
  String getSecaoImageUrl(int secaoId, {String size = 'medium'}) {
    return '${config.baseUrl}/api/v1/static/img/cardapio/secao_$secaoId.jpeg';
  }

  // ============================================================
  // COMANDAS
  // ============================================================

  /// Registra comanda/pedido
  Future<ComandaResponse> registrarComanda(Cart cart) async {
    // Gera número único para a comanda baseado na mesa ou timestamp
    final comandaNumeroGerado = cart.mesa?.toString() ??
        'T${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    // Primeiro cria a comanda (sem campos cliente/observacao que não existem na tabela)
    final comandaData = {
      'comanda': comandaNumeroGerado,
      'empresa': config.empresaId,
      'quantidade_pessoas': 1,
    };

    final comanda = await _post('/api/v1/comandas', comandaData);
    final comandaNumero = comanda['comanda'] ?? comanda['id']?.toString();

    if (comandaNumero == null) {
      return ComandaResponse(
        success: false,
        error: 'Falha ao criar comanda',
      );
    }

    // Libera a comanda para uso
    await _post('/api/v1/comandas/$comandaNumero/liberar', {});

    // Adiciona cada item
    for (final item in cart.items) {
      final produtoData = {
        'produto': item.produto.grid,
        'quantidade': item.quantidade,
        'preco': item.precoUnitario,
        'obs': item.observacao,
        'preparacao': item.preparo?.grid,
      };

      final produtoResponse = await _post(
        '/api/v1/comandas/$comandaNumero/produtos',
        produtoData,
      );

      final codigoProduto = produtoResponse['codigo'];

      // Adiciona complementos se houver
      for (final comp in item.complementos) {
        await _post('/api/v1/comandas/produtos/$codigoProduto/complementos', {
          'complemento': comp.produtoGrid,
          'quantidade': comp.quantidade,
        });
      }

      // Adiciona modificações na composição (remoções)
      for (final removida in item.composicoesRemovidas) {
        await _post('/api/v1/comandas/produtos/$codigoProduto/composicao', {
          'materia_prima': removida.materiaPrima,
          'acao': 'R', // R = Remover
        });
      }
    }

    return ComandaResponse(
      success: true,
      comandaId: comandaNumero,
      message: 'Pedido registrado com sucesso!',
    );
  }

  /// Lista comandas abertas
  Future<List<Map<String, dynamic>>> getComandasAbertas() async {
    final data = await _get('/api/v1/comandas/abertas', {
      'empresa_id': config.empresaId,
    });

    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Busca comanda por número
  Future<Map<String, dynamic>> getComanda(String numero) async {
    final data = await _get('/api/v1/comandas/$numero');
    return data as Map<String, dynamic>;
  }

  /// Busca comanda completa com produtos
  Future<Map<String, dynamic>> getComandaCompleta(String numero) async {
    final data = await _get('/api/v1/comandas/$numero/completo');
    return data as Map<String, dynamic>;
  }

  // ============================================================
  // CLIENTES
  // ============================================================

  /// Busca cliente por CPF
  Future<Map<String, dynamic>?> getClienteByCpf(String cpf) async {
    try {
      final data = await _get('/api/v1/clientes/cpf/$cpf');
      return data as Map<String, dynamic>;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Cria novo cliente
  Future<Map<String, dynamic>> criarCliente(Map<String, dynamic> dados) async {
    final data = await _post('/api/v1/clientes', dados);
    return data as Map<String, dynamic>;
  }

  // ============================================================
  // HEALTH CHECK
  // ============================================================

  /// Verifica se o servidor está online
  Future<bool> healthCheck() async {
    try {
      await _get('/health');
      return true;
    } catch (e) {
      print('❌ Health check failed: $e');
      return false;
    }
  }

  /// Obtém informações da API
  Future<Map<String, dynamic>> getInfo() async {
    final data = await _get('/info');
    return data as Map<String, dynamic>;
  }

  /// Fecha conexões
  void dispose() {
    _client.close();
  }
}

/// Singleton para acesso global ao serviço
class Api {
  static ApiService? _instance;

  static void init(ApiConfig config) {
    _instance = ApiService(config: config);
  }

  static ApiService get instance {
    if (_instance == null) {
      throw StateError(
          'ApiService não inicializado. Chame Api.init() primeiro.');
    }
    return _instance!;
  }

  static bool get isInitialized => _instance != null;
}

// lib/services/api_service.dart
// Serviço de comunicação com o backend FastAPI

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
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
  final int? cardapioId;
  final int terminalId; // ID do terminal para comandas
  final Duration timeout;

  const ApiConfig({
    required this.baseUrl,
    required this.empresaId,
    this.cardapioId,
    this.terminalId = 1,
    this.timeout = const Duration(seconds: 30),
  });

  /// Configuração de desenvolvimento
  factory ApiConfig.dev() {
    return const ApiConfig(
      baseUrl: 'http://192.168.3.150:8000',
      empresaId: 26322354,
      terminalId: 1,
      cardapioId: null,
    );
  }
}

/// Serviço principal de API
class ApiService {
  final ApiConfig config;
  final http.Client _client;

  // Cache de imagens base64 decodificadas
  final Map<String, Uint8List> _imageCache = {};

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
    Map<String, dynamic> body, [
    Map<String, dynamic>? queryParams,
  ]) async {
    try {
      final url = _buildUrl(path, queryParams);
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

  /// Busca primeiro cardápio disponível
  Future<CardapioCompleto?> getCardapioAtivo() async {
    try {
      if (config.cardapioId != null) {
        return await getCardapioCompleto(config.cardapioId!);
      }

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
  // IMAGENS BASE64
  // ============================================================

  /// Busca imagem do produto como base64
  Future<Uint8List?> getProdutoImagem(int produtoId) async {
    final cacheKey = 'produto_$produtoId';

    // Verifica cache primeiro
    if (_imageCache.containsKey(cacheKey)) {
      return _imageCache[cacheKey];
    }

    try {
      final data = await _get('/api/v1/produtos/$produtoId/imagens');

      // O backend pode retornar a imagem de várias formas:
      // 1. { "imagem": "base64string" }
      // 2. { "imagens": [{ "imagem": "base64string" }] }
      // 3. Lista direta de imagens

      String? base64String;

      if (data is Map) {
        // Caso 1: campo "imagem" direto
        if (data['imagem'] != null) {
          base64String = data['imagem'] as String?;
        }
        // Caso 2: array "imagens"
        else if (data['imagens'] is List &&
            (data['imagens'] as List).isNotEmpty) {
          final primeiraImagem = (data['imagens'] as List).first;
          base64String = primeiraImagem['imagem'] as String?;
        }
        // Caso 3: campo "foto" ou "image"
        else if (data['foto'] != null) {
          base64String = data['foto'] as String?;
        } else if (data['image'] != null) {
          base64String = data['image'] as String?;
        }
      } else if (data is List && data.isNotEmpty) {
        // Lista direta de imagens
        final primeiraImagem = data.first;
        if (primeiraImagem is Map) {
          base64String = primeiraImagem['imagem'] as String? ??
              primeiraImagem['foto'] as String? ??
              primeiraImagem['image'] as String?;
        } else if (primeiraImagem is String) {
          base64String = primeiraImagem;
        }
      }

      if (base64String != null && base64String.isNotEmpty) {
        final bytes = base64ToBytes(base64String);
        _imageCache[cacheKey] = bytes;
        return bytes;
      }

      return null;
    } catch (e) {
      print('⚠️ Erro ao buscar imagem do produto $produtoId: $e');
      return null;
    }
  }

  /// Busca imagem da seção como base64
  Future<Uint8List?> getSecaoImagem(int secaoId) async {
    final cacheKey = 'secao_$secaoId';

    if (_imageCache.containsKey(cacheKey)) {
      return _imageCache[cacheKey];
    }

    try {
      final data = await _get('/api/v1/cardapios/secoes/$secaoId/imagens');

      String? base64String;

      if (data is Map) {
        base64String = data['imagem'] as String? ??
            data['foto'] as String? ??
            data['image'] as String?;
      } else if (data is List && data.isNotEmpty) {
        final primeira = data.first;
        if (primeira is Map) {
          base64String = primeira['imagem'] as String? ??
              primeira['foto'] as String? ??
              primeira['image'] as String?;
        } else if (primeira is String) {
          base64String = primeira;
        }
      }

      if (base64String != null && base64String.isNotEmpty) {
        final bytes = base64ToBytes(base64String);
        _imageCache[cacheKey] = bytes;
        return bytes;
      }

      return null;
    } catch (e) {
      print('⚠️ Erro ao buscar imagem da seção $secaoId: $e');
      return null;
    }
  }

  /// Converte string base64 para bytes (Uint8List)
  /// Trata prefixos data:image/... se presentes
  Uint8List base64ToBytes(String base64String) {
    String cleanBase64 = base64String;

    // Remove prefixo data:image/xxx;base64, se existir
    if (cleanBase64.contains(',')) {
      cleanBase64 = cleanBase64.split(',').last;
    }

    // Remove espaços e quebras de linha
    cleanBase64 = cleanBase64.replaceAll(RegExp(r'\s'), '');

    // Adiciona padding se necessário
    final padding = cleanBase64.length % 4;
    if (padding > 0) {
      cleanBase64 += '=' * (4 - padding);
    }

    return base64Decode(cleanBase64);
  }

  /// Limpa cache de imagens
  void clearImageCache() {
    _imageCache.clear();
  }

  /// Remove imagem específica do cache
  void removeFromImageCache(String key) {
    _imageCache.remove(key);
  }

  // ============================================================
  // COMANDAS
  // ============================================================

  /// Registra comanda/pedido
  Future<ComandaResponse> registrarComanda(Cart cart) async {
    // Gera número único para a comanda
    final comandaNumeroGerado = cart.mesa?.toString() ??
        'T${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    try {
      // 1. Cria a comanda
      final comandaData = {
        'comanda': comandaNumeroGerado,
        'empresa': config.empresaId,
        'quantidade_pessoas': 1,
        if (cart.clienteNome != null) 'cliente_nome': cart.clienteNome,
      };

      final comanda = await _post('/api/v1/comandas', comandaData);
      final comandaNumero = comanda['comanda'] ?? comanda['id']?.toString();
      final comandaId = comanda['id'];

      if (comandaNumero == null) {
        return ComandaResponse(
          success: false,
          error: 'Falha ao criar comanda',
        );
      }

      // 2. Libera a comanda para uso
      await _post('/api/v1/comandas/$comandaNumero/liberar', {});

      // 3. Adiciona cada item usando query params para terminal/empresa
      for (final item in cart.items) {
        final produtoData = {
          'produto': item.produto.grid,
          'quantidade': item.quantidade,
          'preco_unit': item.precoUnitario, // Campo correto: preco_unit
          'observacao': item.observacao ?? '',
        };

        // Terminal e empresa vão como query params
        final queryParams = {
          'terminal_id': config.terminalId,
          'empresa_id': config.empresaId,
          if (cart.clienteNome != null) 'cliente_nome': cart.clienteNome,
        };

        final produtoResponse = await _post(
          '/api/v1/comandas/$comandaNumero/produtos',
          produtoData,
          queryParams,
        );

        final codigoProduto = produtoResponse['codigo'];

        if (codigoProduto != null) {
          // 4. Adiciona complementos se houver
          for (final comp in item.complementos) {
            await _post(
                '/api/v1/comandas/produtos/$codigoProduto/complementos', {
              'complemento': comp.produtoGrid,
              'quantidade': comp.quantidade,
              'preco': comp.preco,
            });
          }

          // 5. Adiciona modificações na composição (remoções)
          for (final removida in item.composicoesRemovidas) {
            await _post('/api/v1/comandas/produtos/$codigoProduto/composicao', {
              'materia_prima': removida.materiaPrima,
              'acao': 'R', // R = Remover
            });
          }
        }
      }

      return ComandaResponse(
        success: true,
        comandaId: comandaNumero,
        message: 'Pedido registrado com sucesso!',
      );
    } catch (e) {
      print('❌ Erro ao registrar comanda: $e');
      return ComandaResponse(
        success: false,
        error: e.toString(),
      );
    }
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
    _imageCache.clear();
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

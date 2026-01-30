// lib/services/api_service.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import '../models/produto_models.dart';
import '../models/cardapio_models.dart';
import '../models/cart_models.dart';
import 'package:flutter/foundation.dart'; // Para debugPrint

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

class ApiConfig {
  final String baseUrl;
  final int empresaId;
  final int? cardapioId;
  final int terminalId;
  final Duration timeout;

  const ApiConfig({
    required this.baseUrl,
    required this.empresaId,
    this.cardapioId,
    this.terminalId = 1,
    this.timeout = const Duration(seconds: 30),
  });

  factory ApiConfig.dev() {
    return const ApiConfig(
      baseUrl: 'http://192.168.3.150:8000',
      empresaId: 26322354,
      terminalId: 1,
      cardapioId: null,
    );
  }
}

class ApiService {
  final ApiConfig config;
  final http.Client _client;
  final Map<String, Uint8List> _imageCache = {};

  ApiService({
    required this.config,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

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

  Future<dynamic> _get(String path, [Map<String, dynamic>? queryParams]) async {
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

  Future<dynamic> _post(String path, Map<String, dynamic> body,
      [Map<String, dynamic>? queryParams]) async {
    try {
      final url = _buildUrl(path, queryParams);
      print('🌐 POST: $url');
      print('📦 Body: $body');

      final response = await _client
          .post(url, headers: _headers, body: jsonEncode(body))
          .timeout(config.timeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Sem conexão com o servidor');
    } on http.ClientException catch (e) {
      throw ApiException('Erro de conexão: $e');
    }
  }

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
    throw ApiException(message.toString(),
        statusCode: response.statusCode, data: body);
  }

  // ============================================================
  // CARDÁPIOS
  // ============================================================

  Future<List<Cardapio>> getCardapios({int skip = 0, int limit = 100}) async {
    final data =
        await _get('/api/v1/cardapios', {'skip': skip, 'limit': limit});
    final items = data['items'] as List? ?? [];
    return items.map((e) => Cardapio.fromJson(e)).toList();
  }

  Future<Cardapio> getCardapio(int cardapioId) async {
    final data = await _get('/api/v1/cardapios/$cardapioId');
    return Cardapio.fromJson(data);
  }

  Future<CardapioCompleto> getCardapioCompleto(int cardapioId) async {
    final data = await _get('/api/v1/cardapios/$cardapioId/completo');
    return CardapioCompleto.fromJson(data);
  }

  Future<CardapioCompleto?> getCardapioAtivo() async {
    try {
      if (config.cardapioId != null) {
        return await getCardapioCompleto(config.cardapioId!);
      }

      final cardapios = await getCardapios(limit: 1);
      if (cardapios.isEmpty) return null;

      return await getCardapioCompleto(cardapios.first.grid);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

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

  Future<Produto> getProduto(int produtoId) async {
    final data = await _get('/api/v1/produtos/$produtoId');
    return Produto.fromJson(data);
  }

  Future<ProdutoCompleto> getProdutoCompleto(int produtoId) async {
    final data = await _get('/api/v1/produtos/$produtoId/completo');
    return ProdutoCompleto.fromJson(data);
  }

  Future<PaginatedResponse<Produto>> getProdutos({
    int page = 1,
    int perPage = 100,
    String? search,
    int? grupoId,
  }) async {
    final skip = (page - 1) * perPage;
    final params = <String, dynamic>{'skip': skip, 'limit': perPage};
    if (search != null) params['search'] = search;
    if (grupoId != null) params['grupo_grid'] = grupoId;

    final data = await _get('/api/v1/produtos', params);
    return PaginatedResponse.fromJson(data, Produto.fromJson);
  }

  Future<PreparosDoProduto> getPreparosProduto(int produtoId) async {
    final data = await _get('/api/v1/produtos/$produtoId/preparo');
    return PreparosDoProduto.fromJson(data);
  }

  Future<List<ProdutoComposicao>> getComposicaoProduto(int produtoId) async {
    final data = await _get('/api/v1/produtos/$produtoId/composicao/detalhes');
    if (data is List) {
      return data.map((e) => ProdutoComposicao.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<ProdutoComplemento>> getComplementosProduto(int produtoId) async {
    final data =
        await _get('/api/v1/produtos/$produtoId/complementos/detalhes');
    if (data is List) {
      return data.map((e) => ProdutoComplemento.fromJson(e)).toList();
    }
    return [];
  }

  // ============================================================
  // IMAGENS - URLs
  // ============================================================

  /// URL da imagem do produto
  String getProdutoImageUrl(int produtoId, {String? size}) {
    final url = '${config.baseUrl}/api/v1/produtos/$produtoId/imagens';
    if (size != null) {
      return '$url?size=$size';
    }
    return url;
  }

  /// URL da imagem da seção
  String getSecaoImageUrl(int secaoId, {String? size}) {
    final url = '${config.baseUrl}/api/v1/cardapios/secoes/$secaoId/imagens';
    if (size != null) {
      return '$url?size=$size';
    }
    return url;
  }

  // ============================================================
  // IMAGENS - BASE64
  // ============================================================

  Future<Uint8List?> getProdutoImagem(int produtoId) async {
    final cacheKey = 'produto_$produtoId';

    if (_imageCache.containsKey(cacheKey)) {
      return _imageCache[cacheKey];
    }

    try {
      final data = await _get('/api/v1/produtos/$produtoId/imagens');
      String? base64String = _extractBase64(data);

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

  Future<Uint8List?> getSecaoImagem(int secaoId) async {
    final cacheKey = 'secao_$secaoId';

    if (_imageCache.containsKey(cacheKey)) {
      return _imageCache[cacheKey];
    }

    try {
      final data = await _get('/api/v1/cardapios/secoes/$secaoId/imagens');
      String? base64String = _extractBase64(data);

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

  String? _extractBase64(dynamic data) {
    if (data is Map) {
      if (data['imagem'] != null) return data['imagem'] as String?;
      if (data['imagens'] is List && (data['imagens'] as List).isNotEmpty) {
        return (data['imagens'] as List).first['imagem'] as String?;
      }
      if (data['foto'] != null) return data['foto'] as String?;
      if (data['image'] != null) return data['image'] as String?;
    } else if (data is List && data.isNotEmpty) {
      final primeiro = data.first;
      if (primeiro is Map) {
        return primeiro['imagem'] as String? ??
            primeiro['foto'] as String? ??
            primeiro['image'] as String?;
      } else if (primeiro is String) {
        return primeiro;
      }
    }
    return null;
  }

  Uint8List base64ToBytes(String base64String) {
    String cleanBase64 = base64String;
    if (cleanBase64.contains(',')) {
      cleanBase64 = cleanBase64.split(',').last;
    }
    cleanBase64 = cleanBase64.replaceAll(RegExp(r'\s'), '');
    final padding = cleanBase64.length % 4;
    if (padding > 0) {
      cleanBase64 += '=' * (4 - padding);
    }
    return base64Decode(cleanBase64);
  }

  void clearImageCache() => _imageCache.clear();

  // ============================================================
  // COMANDAS
  // ============================================================

  Future<ComandaResponse> registrarComanda(Cart cart) async {
    final comandaNumeroGerado = cart.mesa?.toString() ??
        'T${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    try {
      final comandaData = {
        'comanda': comandaNumeroGerado,
        'empresa': config.empresaId,
        'quantidade_pessoas': 1,
        if (cart.clienteNome != null) 'cliente_nome': cart.clienteNome,
      };

      final comanda = await _post('/api/v1/comandas', comandaData);
      final comandaNumero = comanda['comanda'] ?? comanda['id']?.toString();

      if (comandaNumero == null) {
        return ComandaResponse(success: false, error: 'Falha ao criar comanda');
      }

      await _post('/api/v1/comandas/$comandaNumero/liberar', {});

      for (final item in cart.items) {
        final produtoData = {
          'produto': item.produto.grid,
          'quantidade': item.quantidade,
          'preco_unit': item.precoUnitario,
          'observacao': item.observacao ?? '',
        };

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
          for (final comp in item.complementos) {
            await _post(
                '/api/v1/comandas/produtos/$codigoProduto/complementos', {
              'complemento': comp.produtoGrid,
              'quantidade': comp.quantidade,
              'preco': comp.preco,
            });
          }

          for (final removida in item.composicoesRemovidas) {
            await _post('/api/v1/comandas/produtos/$codigoProduto/composicao', {
              'materia_prima': removida.materiaPrima,
              'acao': 'R',
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
      return ComandaResponse(success: false, error: e.toString());
    }
  }

  Future<List<Map<String, dynamic>>> getComandasAbertas() async {
    final data = await _get(
        '/api/v1/comandas/abertas', {'empresa_id': config.empresaId});
    if (data is List) return data.cast<Map<String, dynamic>>();
    return [];
  }

  Future<Map<String, dynamic>> getComanda(String numero) async {
    final data = await _get('/api/v1/comandas/$numero');
    return data as Map<String, dynamic>;
  }

  /// Busca comanda completa com todos os produtos
  Future<Map<String, dynamic>> getComandaCompleta(String comanda) async {
    final data = await _get('/api/v1/comandas/$comanda/completo');
    return data as Map<String, dynamic>;
  }

  // ============================================================
  // CLIENTES
  // ============================================================

  Future<Map<String, dynamic>?> getClienteByCpf(String cpf) async {
    try {
      final data = await _get('/api/v1/clientes/cpf/$cpf');
      return data as Map<String, dynamic>;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<Map<String, dynamic>> criarCliente(Map<String, dynamic> dados) async {
    final data = await _post('/api/v1/clientes', dados);
    return data as Map<String, dynamic>;
  }

  // ============================================================
  // HEALTH
  // ============================================================

  Future<bool> healthCheck() async {
    try {
      await _get('/health');
      return true;
    } catch (e) {
      print('❌ Health check failed: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getInfo() async {
    final data = await _get('/info');
    return data as Map<String, dynamic>;
  }

  void dispose() {
    _imageCache.clear();
    _client.close();
  }
}

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

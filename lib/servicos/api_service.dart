// lib/services/api_service.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import '../modelos/produto_models.dart';
import '../modelos/cardapio_models.dart';
import '../modelos/cart_models.dart';

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

  Future<dynamic> _put(String path, Map<String, dynamic> body,
      [Map<String, dynamic>? queryParams]) async {
    try {
      final url = _buildUrl(path, queryParams);
      print('🌐 PUT: $url');
      print('📦 Body: $body');

      final response = await _client
          .put(url, headers: _headers, body: jsonEncode(body))
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
    final produtoCompleto = ProdutoCompleto.fromJson(data);

    List<ProdutoComplemento> complementos = produtoCompleto.complementos;
    List<ProdutoComposicao> composicao = produtoCompleto.composicao;
    List<Preparo> preparos = produtoCompleto.preparos;

    // Buscar complementos com detalhes (nome e preço)
    try {
      final complementosDetalhados = await getComplementosProduto(produtoId);
      if (complementosDetalhados.isNotEmpty) {
        complementos = complementosDetalhados;
      }
    } catch (e) {
      print('⚠️ Erro ao buscar complementos detalhados: $e');
    }

    // Buscar composição com detalhes (nome da matéria-prima)
    try {
      final composicaoDetalhada = await getComposicaoProduto(produtoId);
      if (composicaoDetalhada.isNotEmpty) {
        composicao = composicaoDetalhada;
      }
    } catch (e) {
      print('⚠️ Erro ao buscar composição detalhada: $e');
    }

    // Buscar preparos se não veio no completo
    if (preparos.isEmpty) {
      try {
        final preparosData = await getPreparosProduto(produtoId);
        if (preparosData.preparos.isNotEmpty) {
          preparos = preparosData.preparos;
        }
      } catch (e) {
        print('⚠️ Erro ao buscar preparos: $e');
      }
    }

    return ProdutoCompleto(
      produto: produtoCompleto.produto,
      imagens: produtoCompleto.imagens,
      complementos: complementos,
      composicao: composicao,
      preparos: preparos,
    );
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

  String getProdutoImageUrl(int produtoId, {String? size}) {
    final url = '${config.baseUrl}/api/v1/produtos/$produtoId/imagens';
    if (size != null) {
      return '$url?size=$size';
    }
    return url;
  }

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
      print('📷 Imagem do produto $produtoId (cache)');
      return _imageCache[cacheKey];
    }

    try {
      print('📷 Buscando imagem do produto $produtoId...');
      final data = await _get('/api/v1/produtos/$produtoId/imagens');
      print('📷 Resposta: ${data.runtimeType}');

      String? base64String = _extractBase64(data);

      if (base64String != null && base64String.isNotEmpty) {
        print(
            '📷 Imagem encontrada para produto $produtoId (${base64String.length} chars)');
        final bytes = base64ToBytes(base64String);
        _imageCache[cacheKey] = bytes;
        return bytes;
      }
      print('⚠️ Produto $produtoId sem imagem');
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

  /// Adiciona produtos a uma comanda (cria se não existir)
  /// Este é o método principal usado pelo autoatendimento
  ///
  /// Fluxo de status:
  /// - Comanda nova: cria com 'A', adiciona produtos, finaliza com 'P'
  /// - Comanda existente com 'P': muda para 'A', adiciona produtos, volta para 'P'
  Future<ComandaResponse> adicionarProdutosComanda({
    required String comandaNumero,
    required List<CartItem> items,
    String? clienteNome,
    String? clienteTelefone,
    String? clienteCpf,
  }) async {
    print('🚀 Processando pedido para comanda: $comandaNumero');

    try {
      // 1. Verificar se a comanda existe
      bool comandaCriada = false;
      bool comandaEstavaPendente = false; // Flag para saber se estava em 'P'
      Map<String, dynamic>? comanda;

      try {
        comanda = await getComanda(comandaNumero);
        print('✅ Comanda encontrada: $comanda');

        // 2. Verificar status da comanda
        final status = comanda['status']?.toString().toUpperCase() ?? '';
        print('📋 Status atual da comanda: $status');

        // Se estiver com status 'P' (Pendente/Produção), precisa mudar para 'A' antes de adicionar
        if (status == 'P') {
          print(
              '🔄 Comanda em produção (P) - mudando para A para adicionar produtos');
          comandaEstavaPendente = true;

          try {
            await _put('/api/v1/comandas/$comandaNumero', {'status': 'A'});
            print('✅ Status alterado de P para A');
          } catch (e) {
            print('⚠️ Erro ao alterar status para A: $e');
          }
        }
        // Se não estiver em status válido para adicionar produtos
        else if (status != 'L' && status != 'A' && status.isEmpty) {
          print('⚠️ Comanda com status $status - será criada nova');
          comanda = null; // Forçar criação de nova comanda
        }
      } catch (e) {
        print('ℹ️ Comanda $comandaNumero não existe - será criada');
        comanda = null;
      }

      // 3. Se comanda não existe ou não está disponível, criar nova
      if (comanda == null) {
        print('📝 Criando comanda: $comandaNumero');

        final comandaData = {
          'comanda': comandaNumero,
          'empresa': config.empresaId,
          'quantidade_pessoas': 1,
          'status': 'A', // Cria com 'A', depois muda para 'P'
          if (clienteNome != null && clienteNome.isNotEmpty)
            'cliente_nome': clienteNome,
        };

        try {
          comanda = await _post('/api/v1/comandas', comandaData);
          print('✅ Comanda criada: $comanda');
          comandaCriada = true;

          // Liberar a comanda para uso
          await _post('/api/v1/comandas/$comandaNumero/liberar', {});
          print('✅ Comanda liberada');
        } catch (e) {
          print('❌ Erro ao criar comanda: $e');
          return ComandaResponse(
            success: false,
            error: 'Erro ao criar comanda: $e',
          );
        }
      }

      // 4. Adicionar cada produto na comanda
      for (final item in items) {
        final produtoData = {
          'produto': item.produto.grid,
          'quantidade': item.quantidade,
          'preco_unit': item.precoUnitario,
          'observacao': item.observacao ?? '',
        };

        final queryParams = {
          'terminal_id': config.terminalId,
          'empresa_id': config.empresaId,
          if (clienteNome != null && clienteNome.isNotEmpty)
            'cliente_nome': clienteNome,
        };

        print('📦 Adicionando produto: ${item.produto.nome}');

        final produtoResponse = await _post(
          '/api/v1/comandas/$comandaNumero/produtos',
          produtoData,
          queryParams,
        );

        final codigoProduto = produtoResponse['codigo'];
        print('✅ Produto adicionado com código: $codigoProduto');

        // Adicionar complementos usando complementoGrid
        if (codigoProduto != null && item.complementos.isNotEmpty) {
          for (final comp in item.complementos) {
            print(
                '  ➕ Complemento: ${comp.nome} (grid: ${comp.complementoGrid})');
            await _post(
              '/api/v1/comandas/produtos/$codigoProduto/complementos',
              {
                'complemento': comp.complementoGrid,
                'quantidade': comp.quantidade,
                'preco': comp.preco,
              },
            );
          }
        }

        // Registrar composições removidas
        if (codigoProduto != null && item.composicoesRemovidas.isNotEmpty) {
          for (final removida in item.composicoesRemovidas) {
            print('  ➖ Removido: ${removida.materiaPrima}');
            await _post(
              '/api/v1/comandas/produtos/$codigoProduto/composicao',
              {
                'materia_prima': removida.materiaPrima,
                'acao': 'R',
              },
            );
          }
        }
      }

      // 5. Atualizar status da comanda para 'P' (Pendente/Produção)
      // Sempre finaliza com 'P' após adicionar produtos
      try {
        await _put('/api/v1/comandas/$comandaNumero', {
          'status': 'P',
        });
        print('✅ Status da comanda atualizado para P (Pendente/Produção)');
      } catch (e) {
        print('⚠️ Não foi possível atualizar status para P: $e');
      }

      // 6. Registrar cliente se informado
      if (clienteNome != null ||
          clienteTelefone != null ||
          clienteCpf != null) {
        try {
          await _put('/api/v1/comandas/$comandaNumero', {
            if (clienteNome != null) 'cliente_nome': clienteNome,
          });
          print('✅ Dados do cliente registrados');
        } catch (e) {
          print('⚠️ Não foi possível registrar cliente: $e');
        }
      }

      print('🎉 Pedido finalizado com sucesso na comanda $comandaNumero');

      return ComandaResponse(
        success: true,
        comandaId: comandaNumero,
        message: comandaCriada
            ? 'Comanda criada e pedido registrado!'
            : comandaEstavaPendente
                ? 'Novos itens adicionados ao pedido!'
                : 'Pedido registrado com sucesso!',
      );
    } catch (e) {
      print('❌ Erro ao adicionar produtos na comanda: $e');
      return ComandaResponse(success: false, error: e.toString());
    }
  }

  /// Registra uma nova comanda (usado quando não há comanda existente)
  /// Fluxo: cria com 'A', adiciona produtos, finaliza com 'P'
  Future<ComandaResponse> registrarComanda(Cart cart) async {
    String? comandaFinal = cart.comanda?.toString();
    String? clienteFinal = cart.clienteNome;

    // Correção: Se a comanda estiver vazia mas o nome do cliente for numérico
    if ((comandaFinal == null || comandaFinal.isEmpty) &&
        clienteFinal != null &&
        int.tryParse(clienteFinal) != null) {
      print('⚠️ CORREÇÃO: Usando "$clienteFinal" como COMANDA');
      comandaFinal = clienteFinal;
      clienteFinal = null;
    }

    final comandaNumeroParaEnvio = comandaFinal?.isNotEmpty == true
        ? comandaFinal!
        : 'T${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    print('🚀 Criando nova comanda: $comandaNumeroParaEnvio');

    try {
      final comandaData = {
        'comanda': comandaNumeroParaEnvio,
        'empresa': config.empresaId,
        'quantidade_pessoas': 1,
        'status': 'A', // Cria com 'A', depois muda para 'P'
        if (clienteFinal != null && clienteFinal.isNotEmpty)
          'cliente_nome': clienteFinal,
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
          if (clienteFinal != null && clienteFinal.isNotEmpty)
            'cliente_nome': clienteFinal,
        };

        final produtoResponse = await _post(
          '/api/v1/comandas/$comandaNumero/produtos',
          produtoData,
          queryParams,
        );

        final codigoProduto = produtoResponse['codigo'];

        if (codigoProduto != null) {
          // Adicionar complementos usando complementoGrid
          for (final comp in item.complementos) {
            await _post(
                '/api/v1/comandas/produtos/$codigoProduto/complementos', {
              'complemento': comp.complementoGrid,
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

      // Após adicionar todos os produtos, mudar status para 'P' (Pendente/Produção)
      try {
        await _put('/api/v1/comandas/$comandaNumero', {
          'status': 'P',
        });
        print('✅ Status da comanda atualizado para P (Pendente/Produção)');
      } catch (e) {
        print('⚠️ Não foi possível atualizar status para P: $e');
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

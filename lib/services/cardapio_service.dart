// lib/services/cardapio_service.dart
// VERSÃO COM DEBUG MELHORADO E TRATAMENTO DE ERROS

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/cardapio_models.dart';
import '../models/carrinho_models.dart';

class CardapioService {
  static const String baseUrl = 'http://192.168.3.150:8000/api/v1';
  static const String healthUrl = 'http://192.168.3.150:8000';
  static const Duration timeout = Duration(seconds: 30);

  // Cache simples em memória
  static CardapioCompleto? _cardapioCache;
  static DateTime? _cacheTime;
  static const Duration _cacheValidity = Duration(minutes: 10);

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
  };

  static bool get _isCacheValid {
    if (_cardapioCache == null || _cacheTime == null) return false;
    return DateTime.now().difference(_cacheTime!) < _cacheValidity;
  }

  // ✅ MÉTODO COM DEBUG MELHORADO
  static Future<ProdutoCompleto> obterProdutoCompleto(int produtoId) async {
    try {
      final uri = Uri.parse('$baseUrl/produtos/$produtoId/completo');

      if (kDebugMode) {
        debugPrint('🔍 Buscando produto completo $produtoId: $uri');
      }

      final response = await http.get(uri, headers: _headers).timeout(timeout);

      if (kDebugMode) {
        debugPrint('📡 Status Response: ${response.statusCode}');
        debugPrint('📄 Content-Type: ${response.headers['content-type']}');
        debugPrint('📊 Response Length: ${response.body.length} chars');
      }

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);

          if (kDebugMode) {
            debugPrint('✅ JSON decodificado com sucesso');
            debugPrint('🔍 Chaves principais: ${data.keys.toList()}');

            // Debug dos dados do produto
            if (data['produto'] != null) {
              final produtoData = data['produto'];
              debugPrint(
                '💰 Preço bruto: ${produtoData['preco_unit']} (${produtoData['preco_unit'].runtimeType})',
              );
              debugPrint('📋 Nome: ${produtoData['nome']}');
              debugPrint(
                '🆔 ID: ${produtoData['id']} (${produtoData['id'].runtimeType})',
              );
            }

            // Debug da composição
            if (data['composicao'] != null) {
              debugPrint(
                '📋 Composição: ${(data['composicao'] as List).length} itens',
              );
              for (
                int i = 0;
                i < (data['composicao'] as List).length && i < 2;
                i++
              ) {
                final comp = (data['composicao'] as List)[i];
                debugPrint(
                  '   [$i] Composição ID: ${comp['composicao']?['id']} (${comp['composicao']?['id'].runtimeType})',
                );
                debugPrint(
                  '   [$i] Quantidade: ${comp['composicao']?['quantidade']} (${comp['composicao']?['quantidade'].runtimeType})',
                );
                debugPrint(
                  '   [$i] Opcional: ${comp['composicao']?['opcional']} (${comp['composicao']?['opcional'].runtimeType})',
                );
              }
            }
          }

          final produtoCompleto = ProdutoCompleto.fromJson(data);

          if (kDebugMode) {
            debugPrint('✅ ProdutoCompleto criado com sucesso');
            debugPrint(
              '   📋 Composição: ${produtoCompleto.composicao.length} itens',
            );
            debugPrint(
              '   ➕ Complementos: ${produtoCompleto.complementos.length} itens',
            );
            debugPrint(
              '   🍳 Preparos: ${produtoCompleto.preparos.length} opções',
            );
            debugPrint(
              '   🖼️ Imagens: ${produtoCompleto.imagens.length} imagens',
            );
            debugPrint(
              '   🎨 Personalizável: ${produtoCompleto.isPersonalizavel}',
            );
          }

          return produtoCompleto;
        } catch (jsonError) {
          if (kDebugMode) {
            debugPrint('❌ Erro ao processar JSON: $jsonError');
            debugPrint(
              '📄 Response body (primeiros 500 chars): ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}',
            );
          }
          throw Exception('Erro ao processar dados do produto: $jsonError');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Produto não encontrado');
      } else {
        if (kDebugMode) {
          debugPrint('❌ HTTP Error ${response.statusCode}: ${response.body}');
        }
        throw Exception('Erro ao buscar produto: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erro geral ao obter produto completo: $e');
        debugPrint('🔍 Tipo do erro: ${e.runtimeType}');
      }
      rethrow;
    }
  }

  // ✅ MÉTODOS EXISTENTES (sem alteração)
  static Future<CardapioCompleto> recarregarCardapio(int cardapioId) async {
    limparCache();
    return await obterCardapioCompleto(cardapioId, forceRefresh: true);
  }

  static Future<Cardapio> obterCardapioId1() async {
    return obterCardapio(1);
  }

  static Future<CardapioCompleto> obterCardapioCompletoId1({
    bool forceRefresh = false,
  }) async {
    return obterCardapioCompleto(1, forceRefresh: forceRefresh);
  }

  static Future<List<Cardapio>> listarCardapios({
    int page = 1,
    int limit = 100,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{
        'skip': ((page - 1) * limit).toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri = Uri.parse(
        '$baseUrl/cardapios/',
      ).replace(queryParameters: queryParams);

      if (kDebugMode) {
        debugPrint('🔍 Buscando cardápios: $uri');
      }

      final response = await http.get(uri, headers: _headers).timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final paginatedResponse = PaginatedResponse.fromJson(
          data,
          (json) => Cardapio.fromJson(json),
        );

        if (kDebugMode) {
          debugPrint(
            '✅ ${paginatedResponse.items.length} cardápios encontrados',
          );
        }
        return paginatedResponse.items;
      } else {
        throw Exception('Erro ao buscar cardápios: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erro ao listar cardápios: $e');
      }
      rethrow;
    }
  }

  static Future<Cardapio> obterCardapio(int cardapioId) async {
    try {
      final uri = Uri.parse('$baseUrl/cardapios/$cardapioId');

      if (kDebugMode) {
        debugPrint('🔍 Buscando cardápio $cardapioId: $uri');
      }

      final response = await http.get(uri, headers: _headers).timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final cardapio = Cardapio.fromJson(data);

        if (kDebugMode) {
          debugPrint('✅ Cardápio encontrado: ${cardapio.nome}');
        }
        return cardapio;
      } else if (response.statusCode == 404) {
        throw Exception('Cardápio não encontrado');
      } else {
        throw Exception('Erro ao buscar cardápio: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erro ao obter cardápio: $e');
      }
      rethrow;
    }
  }

  static Future<CardapioCompleto> obterCardapioCompleto(
    int cardapioId, {
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh && _isCacheValid) {
        if (kDebugMode) {
          debugPrint('📦 Usando cardápio do cache');
        }
        return _cardapioCache!;
      }

      final uri = Uri.parse('$baseUrl/cardapios/$cardapioId/completo');

      if (kDebugMode) {
        debugPrint('🔍 Buscando cardápio completo $cardapioId: $uri');
      }

      final response = await http.get(uri, headers: _headers).timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final cardapioCompleto = CardapioCompleto.fromJson(data);

        _cardapioCache = cardapioCompleto;
        _cacheTime = DateTime.now();

        if (kDebugMode) {
          debugPrint(
            '✅ Cardápio completo obtido: ${cardapioCompleto.secoes.length} seções',
          );
        }
        return cardapioCompleto;
      } else if (response.statusCode == 404) {
        throw Exception('Cardápio não encontrado');
      } else {
        throw Exception(
          'Erro ao buscar cardápio completo: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erro ao obter cardápio completo: $e');
      }
      rethrow;
    }
  }

  static Future<List<CardapioSecao>> listarSecoes(int cardapioId) async {
    try {
      final uri = Uri.parse('$baseUrl/cardapios/$cardapioId/secoes');

      if (kDebugMode) {
        debugPrint('🔍 Buscando seções do cardápio $cardapioId: $uri');
      }

      final response = await http.get(uri, headers: _headers).timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        final secoes =
            data.map((secao) => CardapioSecao.fromJson(secao)).toList();

        if (kDebugMode) {
          debugPrint('✅ ${secoes.length} seções encontradas');
        }
        return secoes;
      } else if (response.statusCode == 404) {
        throw Exception('Cardápio não encontrado');
      } else {
        throw Exception('Erro ao buscar seções: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erro ao listar seções: $e');
      }
      rethrow;
    }
  }

  static Future<List<ProdutoCardapio>> buscarProdutos({
    String? search,
    int? grupoId,
    String? tipo,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, String>{
        'skip': ((page - 1) * limit).toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      if (grupoId != null) {
        queryParams['grupo_id'] = grupoId.toString();
      }

      if (tipo != null && tipo.isNotEmpty) {
        queryParams['tipo'] = tipo;
      }

      final uri = Uri.parse(
        '$baseUrl/produtos',
      ).replace(queryParameters: queryParams);

      if (kDebugMode) {
        debugPrint('🔍 Buscando produtos: $uri');
      }

      final response = await http.get(uri, headers: _headers).timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final paginatedResponse = PaginatedResponse.fromJson(
          data,
          (json) => ProdutoCardapio.fromJson(json),
        );

        if (kDebugMode) {
          debugPrint(
            '✅ ${paginatedResponse.items.length} produtos encontrados',
          );
        }
        return paginatedResponse.items;
      } else {
        throw Exception('Erro ao buscar produtos: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erro ao buscar produtos: $e');
      }
      rethrow;
    }
  }

  // MÉTODOS DE CONECTIVIDADE
  static Future<bool> testarConexao() async {
    try {
      if (kDebugMode) {
        debugPrint('🔍 Testando conexão: $healthUrl/health');
      }

      final response = await http
          .get(Uri.parse('$healthUrl/health'), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (kDebugMode) {
        debugPrint('📡 Status da resposta: ${response.statusCode}');
      }

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erro ao testar conexão: $e');
      }
      return false;
    }
  }

  static Future<bool> testarInternetBasico() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('✅ Internet conectada');
        }
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Sem internet: $e');
      }
      return false;
    }
  }

  static Future<void> debugConexao() async {
    if (kDebugMode) {
      debugPrint('🐛 === DEBUG CARDÁPIO API ===');
      debugPrint('🌐 URL Base: $baseUrl');
      debugPrint('🏥 URL Health: $healthUrl/health');

      try {
        debugPrint('🧪 Teste 1: Health Check');
        final healthResponse = await http
            .get(Uri.parse('$healthUrl/health'))
            .timeout(const Duration(seconds: 5));
        debugPrint('   Status: ${healthResponse.statusCode}');

        debugPrint('🧪 Teste 2: Cardápio ID=1');
        final cardapioResponse = await http
            .get(Uri.parse('$baseUrl/cardapios/1'))
            .timeout(const Duration(seconds: 5));
        debugPrint('   Status: ${cardapioResponse.statusCode}');

        debugPrint('🧪 Teste 3: Cardápio completo ID=1');
        final cardapioCompletoResponse = await http
            .get(Uri.parse('$baseUrl/cardapios/1/completo'))
            .timeout(const Duration(seconds: 5));
        debugPrint('   Status: ${cardapioCompletoResponse.statusCode}');
      } catch (e) {
        debugPrint('❌ Erro no debug: $e');
      }
      debugPrint('🐛 === FIM DEBUG CARDÁPIO ===');
    }
  }

  // MÉTODOS DE CONVENIÊNCIA
  static void limparCache() {
    _cardapioCache = null;
    _cacheTime = null;
    if (kDebugMode) {
      debugPrint('🗑️ Cache do cardápio limpo');
    }
  }

  static Future<CardapioCompleto> obterPrimeiroCardapio({
    bool forceRefresh = false,
  }) async {
    try {
      return await obterCardapioCompleto(1, forceRefresh: forceRefresh);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erro ao obter cardápio ID=1: $e');
      }
      rethrow;
    }
  }

  static Future<CardapioCompleto> recarregarCardapioId1() async {
    limparCache();
    return await obterCardapioCompleto(1, forceRefresh: true);
  }

  static Future<bool> verificarConexaoCompleta() async {
    if (kDebugMode) {
      debugPrint('🔄 Verificando conexão completa...');
    }

    final temInternet = await testarInternetBasico();
    if (!temInternet) {
      if (kDebugMode) {
        debugPrint('❌ Sem conexão com internet');
      }
      return false;
    }

    await debugConexao();
    final conexao = await testarConexao();

    if (!conexao) {
      if (kDebugMode) {
        debugPrint('❌ Falha na conexão com o servidor');
        debugPrint(
          '💡 Dica: Verifique se a API está rodando em http://127.0.0.1:8000',
        );
        debugPrint('💡 Dica: Para emulador Android use http://10.0.2.2:8000');
      }
    } else {
      if (kDebugMode) {
        debugPrint('✅ Conexão estabelecida com sucesso');
      }
    }

    return conexao;
  }

  static void printDebugInfo() {
    if (kDebugMode) {
      debugPrint('🔧 CardapioService Debug Info:');
      debugPrint('   Base URL: $baseUrl');
      debugPrint('   Health URL: $healthUrl');
      debugPrint('   Cache válido: $_isCacheValid');
      debugPrint('   Cache time: $_cacheTime');
      try {
        debugPrint('   Platform: ${Platform.operatingSystem}');
      } catch (e) {
        debugPrint('   Platform: N/A');
      }
    }
  }

  static Future<Map<String, dynamic>?> debugProdutoCompleto(
    int produtoId,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/produtos/$produtoId/completo');

      if (kDebugMode) {
        debugPrint('🐛 DEBUG: Buscando dados brutos do produto $produtoId');
      }

      final response = await http.get(uri, headers: _headers).timeout(timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (kDebugMode) {
          debugPrint('🐛 DEBUG: Dados completos recebidos:');
          debugPrint('   JSON: ${json.encode(data)}');
        }

        return data;
      } else {
        if (kDebugMode) {
          debugPrint(
            '🐛 DEBUG: Erro HTTP ${response.statusCode}: ${response.body}',
          );
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('🐛 DEBUG: Erro na requisição: $e');
      }
      return null;
    }
  }
}

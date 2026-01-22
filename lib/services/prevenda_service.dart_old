// lib/services/prevenda_service.dart
// ✅ CORRIGIDO: Usando IDs reais, códigos corretos e QUANTIDADES REAIS dos produtos
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/carrinho_models.dart';

class PrevendaService {
  static const String baseUrl = 'http://192.168.3.150:5469';
  static const Duration timeout = Duration(seconds: 30);

  static const String linxUsername = 'felipe';
  static const String linxPassword = '1234';

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
  };

  /// Faz login na API Linx e retorna o token JWT
  static Future<String> _obterTokenLinx() async {
    try {
      if (kDebugMode) {
        debugPrint('🔐 Fazendo login na API Linx...');
      }

      final loginData = {'username': linxUsername, 'password': linxPassword};

      final response = await http
          .post(
            Uri.parse('$baseUrl/auth'),
            headers: _headers,
            body: json.encode(loginData),
          )
          .timeout(const Duration(seconds: 10));

      if (kDebugMode) {
        debugPrint('🔐 Login Linx - Status: ${response.statusCode}');
      }

      if (response.statusCode != 200) {
        if (kDebugMode) {
          debugPrint('❌ Erro no login Linx: ${response.body}');
        }
        throw Exception('Erro de autenticação com sistema Linx');
      }

      final data = json.decode(response.body);
      final token = data['access_token'];

      if (token == null || token.isEmpty) {
        throw Exception('Token não recebido do sistema Linx');
      }

      if (kDebugMode) {
        debugPrint('✅ Token obtido com sucesso');
      }

      return token;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erro ao obter token: $e');
      }
      rethrow;
    }
  }

  /// Registra uma prevenda no PDV Linx Empório
  static Future<Map<String, dynamic>> registrarPrevenda({
    required int pessoaId,
    required String pessoaNome,
    required String pessoaCpf,
    required String pessoaEmail,
    required String? pessoaEndereco,
    required String? pessoaBairro,
    required String? pessoaMunicipio,
    int? pessoaMunicipioCodigo,
    required String? pessoaCep,
    required String? pessoaNumero,
    required String? pessoaComplemento,
    required String? pessoaTelefone,
    required Carrinho carrinho,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('📦 Iniciando registro de prevenda...');
      }

      // 1. FAZER LOGIN E OBTER TOKEN JWT
      final token = await _obterTokenLinx();
      if (kDebugMode) {
        debugPrint('🔐 Token obtido, prosseguindo com registro...');
      }

      // 2. Montar a lista de produtos NO FORMATO EXATO DO LINX
      final produtoList = _montarListaProdutos(carrinho);

      // 3. Montar o JSON da prevenda
      final prevendaJson = {
        'pessoa_bairro': pessoaBairro ?? '',
        'pessoa_cep': pessoaCep ?? '',
        'pessoa_complemento': pessoaComplemento,
        'pessoa_cpf': pessoaCpf,
        'pessoa_email': pessoaEmail,
        'pessoa_endereco': pessoaEndereco ?? '',
        'pessoa_id': pessoaId,
        'pessoa_municipio': pessoaMunicipio ?? 'CAPAO DO LEAO',
        'pessoa_municipio_codigo': pessoaMunicipioCodigo ?? 4304663,
        'pessoa_nome': pessoaNome,
        'pessoa_numero': pessoaNumero ?? '0',
        'pessoa_telefone': pessoaTelefone,
        'produto_list': produtoList,
        'status': 'A',
        'canal': 'local',
        'tipo': 'C',
        'valor': carrinho.subtotal,
        'valor_desconto': carrinho.desconto,
        'valor_pago': carrinho.total,
        'valor_taxa_servico': 0,
        'percentual_taxa_servico': 0,
        'valor_frete': carrinho.taxaEntrega,
      };

      if (kDebugMode) {
        debugPrint('📄 JSON da prevenda:');
        debugPrint(json.encode(prevendaJson));
      }

      // 4. FAZER A REQUISIÇÃO COM AUTENTICAÇÃO JWT
      final uri = Uri.parse('$baseUrl/prevenda/registrar');

      if (kDebugMode) {
        debugPrint('🌐 Enviando para: $uri');
      }

      final headersComAuth = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http
          .post(uri, headers: headersComAuth, body: json.encode(prevendaJson))
          .timeout(timeout);

      if (kDebugMode) {
        debugPrint('📡 Status da resposta: ${response.statusCode}');
        debugPrint('📄 Resposta: ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        if (kDebugMode) {
          debugPrint('✅ Prevenda registrada com sucesso!');
        }

        return {
          'sucesso': true,
          'dados': data,
          'mensagem': 'Prevenda registrada com sucesso!',
        };
      } else if (response.statusCode == 401) {
        throw Exception('Erro de autenticação com sistema Linx');
      } else if (response.statusCode == 502) {
        throw Exception('Sistema Linx indisponível. Tente novamente.');
      } else if (response.statusCode == 504) {
        throw Exception('Timeout na comunicação com o sistema Linx.');
      } else {
        try {
          final data = json.decode(response.body);
          throw Exception(
            data['detail'] ??
                'Erro ao registrar prevenda: ${response.statusCode}',
          );
        } catch (e) {
          throw Exception('Erro ao registrar prevenda: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erro ao registrar prevenda: $e');
      }
      return {
        'sucesso': false,
        'erro': e.toString(),
        'mensagem': 'Erro ao registrar prevenda: $e',
      };
    }
  }

  /// ✅ CORRIGIDO: Monta a lista de produtos usando IDs reais, códigos corretos E QUANTIDADES REAIS
  static List<Map<String, dynamic>> _montarListaProdutos(Carrinho carrinho) {
    final produtoList = <Map<String, dynamic>>[];

    for (final item in carrinho.itens) {
      final temComposicao =
          item.composicaoSelecionada.isNotEmpty ||
          item.complementosSelecionados.isNotEmpty;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final rowId = '$timestamp-${item.produto.id}-${item.id}';

      final produtoPrincipal = <String, dynamic>{
        'row_id': rowId,
        'nome': item.produto.nome ?? 'Produto',
        'produto_nome': item.produto.nome ?? 'Produto',
        'produto_id': item.produto.id,
        'produto_codigo': item.produto.codigo ?? '',
        'produto_tipo': 2,
        'grupo_produto_id': item.produto.grupoId ?? 0,
        'fabricado_venda': temComposicao,
        'quantidade': item.quantidade,
        'unid_med': item.produto.unidMed ?? 'UN',
        'preco_unit': item.produto.precoUnit ?? 0.0,
        'valor': item.produto.precoUnit ?? 0.0,
        'situacao': 'A',
        'tipo_preco': 0,
        'valor_desconto': 0,
        'valor_acrescimo': 0,
        'ref_interna_edicao': true,
        'obs': item.observacoes ?? '',
      };

      if (temComposicao) {
        produtoPrincipal['has_composicao'] = true;

        final produtoComposicao = <String, dynamic>{
          'produto_complemento_list': <Map<String, dynamic>>[],
          'produto_composicao_list': <Map<String, dynamic>>[],
          'produto_preparo_list': <Map<String, dynamic>>[],
        };

        // ✅ COMPLEMENTOS com IDs reais e código de barra correto
        if (item.complementosSelecionados.isNotEmpty) {
          for (final entry in item.complementosSelecionados.entries) {
            if (entry.value > 0) {
              final complementoId = entry.key;
              final quantidade = entry.value;
              final nome = item.complementosNomes[complementoId] ?? '';
              final precoUnit = item.complementosPrecos[complementoId] ?? 0.0;

              // ✅ USAR DADOS REAIS DO PRODUTO
              final produtoIdReal =
                  item.complementoProdutoIds[complementoId] ?? complementoId;
              final codigoBarra =
                  item.complementosCodigoBarra[complementoId] ??
                  complementoId.toString();

              produtoComposicao['produto_complemento_list'].add({
                'codigo': complementoId,
                'codigo_barra': codigoBarra, // ✅ CÓDIGO REAL
                'descricao': nome,
                'descricao_resumida': nome,
                'preco_total': precoUnit * quantidade,
                'preco_unit': precoUnit,
                'produto_codigo': codigoBarra, // ✅ CÓDIGO REAL
                'produto_id': produtoIdReal, // ✅ ID REAL
                'qtd_selecionada': quantidade,
                'quantidade': quantidade,
                'unid_med': 'UN',
              });

              if (kDebugMode) {
                debugPrint(
                  '   ✅ Complemento (detalhes): ID=$produtoIdReal, codigo_barra=$codigoBarra, nome=$nome, qtd=$quantidade',
                );
              }
            }
          }
        }

        // ✅ SABORES com IDs reais, códigos corretos E QUANTIDADE DIRETA DO MAPA
        if (item.composicaoSelecionada.isNotEmpty) {
          for (final entry in item.composicaoSelecionada.entries) {
            final qtdSelecionada = entry.value; // ✅ AGORA É INT DIRETO!

            if (qtdSelecionada > 0) {
              final composicaoId = entry.key;
              final nomeCompleto = item.composicaoNomes[composicaoId] ?? '';

              // ✅ USAR DADOS REAIS DO PRODUTO
              final produtoIdReal =
                  item.composicaoProdutoIds[composicaoId] ?? composicaoId;
              final codigoProduto =
                  item.composicaoCodigoProduto[composicaoId] ??
                  composicaoId.toString();

              // ✅ Quantidade multiplicada: 0.12 * qtd_selecionada
              final quantidadeTotal = 0.12 * qtdSelecionada;

              produtoComposicao['produto_composicao_list'].add({
                'codigo': composicaoId,
                'descricao': nomeCompleto, // Nome completo (ex: "2x AÇAÍ ZERO")
                'descricao_resumida': nomeCompleto,
                'id': composicaoId,
                'is_opcional': true,
                'produto_codigo': codigoProduto, // ✅ CÓDIGO REAL
                'produto_id': produtoIdReal, // ✅ ID REAL
                'qtd_selecionada': qtdSelecionada, // ✅ QUANTIDADE REAL DO MAPA
                'quantidade':
                    quantidadeTotal, // ✅ 0.12 * quantidade (ex: 0.24 para 2x)
                'unid_med': 'KG',
              });

              if (kDebugMode) {
                debugPrint(
                  '   ✅ Composição: ID=$produtoIdReal, codigo=$codigoProduto, nome=$nomeCompleto, qtd_selecionada=$qtdSelecionada, quantidade_kg=$quantidadeTotal',
                );
              }
            }
          }
        }

        produtoPrincipal['produto_composicao'] = produtoComposicao;

        // ✅ Listas duplicadas (para compatibilidade)
        produtoPrincipal['produto_complemento_list'] = List.from(
          produtoComposicao['produto_complemento_list'],
        );
        produtoPrincipal['produto_composicao_list'] = List.from(
          produtoComposicao['produto_composicao_list'],
        );
        produtoPrincipal['produto_preparo_list'] = List.from(
          produtoComposicao['produto_preparo_list'],
        );

        // Campo 'produto' com código
        produtoPrincipal['produto'] = item.produto.codigo ?? '';
      }

      produtoList.add(produtoPrincipal);

      // ✅ COMPLEMENTOS COMO PRODUTOS SEPARADOS (com IDs reais)
      if (item.complementosSelecionados.isNotEmpty) {
        for (final entry in item.complementosSelecionados.entries) {
          if (entry.value > 0) {
            final complementoId = entry.key;
            final quantidade = entry.value;
            final nome = item.complementosNomes[complementoId] ?? '';
            final precoUnit = item.complementosPrecos[complementoId] ?? 0.0;

            // ✅ USAR DADOS REAIS DO PRODUTO
            final produtoIdReal =
                item.complementoProdutoIds[complementoId] ?? complementoId;
            final codigoBarra =
                item.complementosCodigoBarra[complementoId] ??
                complementoId.toString();

            final complementoTimestamp =
                DateTime.now().millisecondsSinceEpoch + complementoId;
            final complementoRowId =
                '$complementoTimestamp-comp-$complementoId-${item.id}';

            produtoList.add({
              'row_id': complementoRowId,
              'nome': item.produto.nome ?? 'Produto',
              'produto_nome': nome,
              'produto_id': produtoIdReal, // ✅ ID REAL
              'produto_codigo': codigoBarra, // ✅ CÓDIGO REAL
              'produto_tipo': 2,
              'grupo_produto_id': item.produto.grupoId ?? 0,
              'fabricado_venda': true,
              'quantidade': quantidade,
              'unid_med': 'UN',
              'preco_unit': precoUnit,
              'valor': precoUnit * quantidade,
              'situacao': 'A',
              'tipo_preco': 0,
              'vendedor_id': null,
              'vendedor_nome': null,
              'valor_desconto': 0,
              'valor_acrescimo': 0,
              'ref_interna_edicao': true,
              'obs': '',
              'bico': '',
              'codigo_barra': codigoBarra, // ✅ CÓDIGO REAL
              'deposito_id': 1,
              'estoque_ok': null,
              'image': null,
              'produto': codigoBarra, // ✅ CÓDIGO REAL
              'produto_kit_id': null,
              'show_comissao': null,
              'usuario_id': null,
              'vendedor': null,
            });

            if (kDebugMode) {
              debugPrint(
                '   ✅ Complemento (separado): ID=$produtoIdReal, codigo_barra=$codigoBarra, nome=$nome, qtd=$quantidade',
              );
            }
          }
        }
      }
    }

    return produtoList;
  }

  /// Testa a conexão com a API de prevenda
  static Future<bool> testarConexao() async {
    try {
      final uri = Uri.parse('$baseUrl/');
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 5));

      if (kDebugMode) {
        debugPrint('🔍 Teste de conexão - Status: ${response.statusCode}');
      }

      return response.statusCode == 200 || response.statusCode == 404;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erro ao testar conexão: $e');
      }
      return false;
    }
  }

  /// Debug - Testa a rota de prevenda do Linx Empório com autenticação
  static Future<void> debugRotas() async {
    if (kDebugMode) {
      debugPrint('🐛 === TESTANDO ROTA DO LINX EMPÓRIO ===');
      debugPrint('🌐 URL Base: $baseUrl');

      try {
        debugPrint('🔐 Obtendo token de autenticação...');
        final token = await _obterTokenLinx();
        debugPrint('✅ Token obtido com sucesso');

        final rotaCompleta = '$baseUrl/prevenda/registrar';
        debugPrint('🧪 Testando POST: $rotaCompleta');

        final testPayload = {
          'pessoa_id': 1,
          'pessoa_nome': 'TESTE',
          'pessoa_cpf': '000.000.000-00',
          'pessoa_email': 'teste@teste.com',
          'status': 'A',
          'canal': 'local',
          'tipo': 'C',
          'valor': 10.0,
          'valor_desconto': 0,
          'valor_pago': 10.0,
          'valor_taxa_servico': 0,
          'percentual_taxa_servico': 0,
          'valor_frete': 0,
          'produto_list': [],
        };

        final headersComAuth = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        };

        final response = await http
            .post(
              Uri.parse(rotaCompleta),
              headers: headersComAuth,
              body: json.encode(testPayload),
            )
            .timeout(const Duration(seconds: 10));

        debugPrint('   📡 Status: ${response.statusCode}');
        debugPrint(
          '   📄 Resposta: ${response.body.length > 200 ? response.body.substring(0, 200) + "..." : response.body}',
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          debugPrint('   ✅ Rota funcionando com autenticação!');
        } else if (response.statusCode == 401) {
          debugPrint('   ❌ Erro de autenticação (401)');
        } else if (response.statusCode == 404) {
          debugPrint('   ❌ Rota não encontrada (404)');
        } else if (response.statusCode == 400) {
          debugPrint(
            '   ⚠️ Bad Request (400) - Rota existe mas payload com problema',
          );
        } else {
          debugPrint('   ⚠️ Status inesperado: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('   ❌ Erro: $e');
      }

      debugPrint('🐛 === FIM DEBUG ROTAS ===');
    }
  }
}

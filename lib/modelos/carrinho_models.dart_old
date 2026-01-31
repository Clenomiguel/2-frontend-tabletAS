// lib/models/carrinho_models.dart
import '../models/cardapio_models.dart';

// ✅ UTILITÁRIO DE PARSING SEGURO
class ParsingUtils {
  /// Converte qualquer valor para double de forma segura
  static double? parseDouble(dynamic value, {double? defaultValue}) {
    if (value == null) return defaultValue;

    try {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value.trim());
        return parsed ?? defaultValue;
      }
      if (value is num) return value.toDouble();
    } catch (e) {
      print(
        '⚠️ Erro ao converter para double: $value (${value.runtimeType}) - $e',
      );
    }

    return defaultValue;
  }

  /// Converte qualquer valor para int de forma segura
  static int? parseInt(dynamic value, {int? defaultValue}) {
    if (value == null) return defaultValue;

    try {
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        return parsed ?? defaultValue;
      }
      if (value is num) return value.toInt();
    } catch (e) {
      print(
        '⚠️ Erro ao converter para int: $value (${value.runtimeType}) - $e',
      );
    }

    return defaultValue;
  }

  /// Converte qualquer valor para bool de forma segura
  static bool? parseBool(dynamic value, {bool? defaultValue}) {
    if (value == null) return defaultValue;

    try {
      if (value is bool) return value;
      if (value is int) return value != 0;
      if (value is double) return value != 0.0;
      if (value is String) {
        final lowerValue = value.trim().toLowerCase();
        if (lowerValue == 'true' || lowerValue == '1') return true;
        if (lowerValue == 'false' || lowerValue == '0') return false;
      }
    } catch (e) {
      print(
        '⚠️ Erro ao converter para bool: $value (${value.runtimeType}) - $e',
      );
    }

    return defaultValue;
  }
}

class ItemCarrinho {
  final String id; // ID único do item no carrinho
  final ProdutoCardapio produto;
  final int quantidade;
  final double precoUnitario;
  final double precoTotal;
  final Map<int, int> composicaoSelecionada;
  final Map<int, int> complementosSelecionados;
  final Set<int> preparosSelecionados;
  final String? observacoes;
  final DateTime criadoEm;

  // ✅ NOMES RESOLVIDOS para exibição
  final Map<int, String> composicaoNomes;
  final Map<int, String> complementosNomes;
  final Map<int, String> preparosNomes;

  // ✅ DADOS DOS COMPLEMENTOS
  final Map<int, double> complementosPrecos;
  final Map<int, int> complementoProdutoIds; // ID do produto real
  final Map<int, String> complementosCodigoBarra; // Código de barra

  // ✅ DADOS DA COMPOSIÇÃO
  final Map<int, int> composicaoProdutoIds; // ID do produto real
  final Map<int, String> composicaoCodigoProduto; // Código do produto

  ItemCarrinho({
    String? id,
    required this.produto,
    required this.quantidade,
    required this.precoUnitario,
    required this.precoTotal,
    required this.composicaoSelecionada,
    required this.complementosSelecionados,
    required this.preparosSelecionados,
    this.observacoes,
    DateTime? criadoEm,
    // Nomes resolvidos
    this.composicaoNomes = const {},
    this.complementosNomes = const {},
    this.preparosNomes = const {},
    // Dados dos complementos
    this.complementosPrecos = const {},
    this.complementoProdutoIds = const {},
    this.complementosCodigoBarra = const {},
    // Dados da composição
    this.composicaoProdutoIds = const {},
    this.composicaoCodigoProduto = const {},
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       criadoEm = criadoEm ?? DateTime.now();

  ItemCarrinho copyWith({
    String? id,
    ProdutoCardapio? produto,
    int? quantidade,
    double? precoUnitario,
    double? precoTotal,
    Map<int, int>? composicaoSelecionada,
    Map<int, int>? complementosSelecionados,
    Set<int>? preparosSelecionados,
    String? observacoes,
    DateTime? criadoEm,
    Map<int, String>? composicaoNomes,
    Map<int, String>? complementosNomes,
    Map<int, String>? preparosNomes,
    Map<int, double>? complementosPrecos,
    Map<int, int>? complementoProdutoIds,
    Map<int, String>? complementosCodigoBarra,
    Map<int, int>? composicaoProdutoIds,
    Map<int, String>? composicaoCodigoProduto,
  }) {
    return ItemCarrinho(
      id: id ?? this.id,
      produto: produto ?? this.produto,
      quantidade: quantidade ?? this.quantidade,
      precoUnitario: precoUnitario ?? this.precoUnitario,
      precoTotal: precoTotal ?? this.precoTotal,
      composicaoSelecionada:
          composicaoSelecionada ?? Map.from(this.composicaoSelecionada),
      complementosSelecionados:
          complementosSelecionados ?? Map.from(this.complementosSelecionados),
      preparosSelecionados:
          preparosSelecionados ?? Set.from(this.preparosSelecionados),
      observacoes: observacoes ?? this.observacoes,
      criadoEm: criadoEm ?? this.criadoEm,
      composicaoNomes: composicaoNomes ?? Map.from(this.composicaoNomes),
      complementosNomes: complementosNomes ?? Map.from(this.complementosNomes),
      preparosNomes: preparosNomes ?? Map.from(this.preparosNomes),
      complementosPrecos:
          complementosPrecos ?? Map.from(this.complementosPrecos),
      complementoProdutoIds:
          complementoProdutoIds ?? Map.from(this.complementoProdutoIds),
      complementosCodigoBarra:
          complementosCodigoBarra ?? Map.from(this.complementosCodigoBarra),
      composicaoProdutoIds:
          composicaoProdutoIds ?? Map.from(this.composicaoProdutoIds),
      composicaoCodigoProduto:
          composicaoCodigoProduto ?? Map.from(this.composicaoCodigoProduto),
    );
  }

  // Método para verificar se dois itens são "iguais" (mesmo produto e personalizações)
  bool temMesmaPersonalizacao(ItemCarrinho outro) {
    return produto.id == outro.produto.id &&
        _mapsAreEqual(composicaoSelecionada, outro.composicaoSelecionada) &&
        _mapsAreEqual(
          complementosSelecionados,
          outro.complementosSelecionados,
        ) &&
        _setsAreEqual(preparosSelecionados, outro.preparosSelecionados) &&
        observacoes == outro.observacoes;
  }

  bool _mapsAreEqual<K, V>(Map<K, V> map1, Map<K, V> map2) {
    if (map1.length != map2.length) return false;
    for (var key in map1.keys) {
      if (map1[key] != map2[key]) return false;
    }
    return true;
  }

  bool _setsAreEqual<T>(Set<T> set1, Set<T> set2) {
    if (set1.length != set2.length) return false;
    return set1.containsAll(set2) && set2.containsAll(set1);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'produto_id': produto.id,
      'produto_nome': produto.nome,
      'produto_preco': produto.precoUnit,
      'quantidade': quantidade,
      'preco_unitario': precoUnitario,
      'preco_total': precoTotal,
      'composicao_selecionada': composicaoSelecionada.map(
        (k, v) => MapEntry(k.toString(), v), // ✅ Agora v é int
      ),
      'complementos_selecionados': complementosSelecionados.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      'preparos_selecionados': preparosSelecionados.toList(),
      'observacoes': observacoes,
      'criado_em': criadoEm.toIso8601String(),
      // Nomes resolvidos
      'composicao_nomes': composicaoNomes.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      'complementos_nomes': complementosNomes.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      'preparos_nomes': preparosNomes.map((k, v) => MapEntry(k.toString(), v)),
      // Dados dos complementos
      'complementos_precos': complementosPrecos.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      'complemento_produto_ids': complementoProdutoIds.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      'complementos_codigo_barra': complementosCodigoBarra.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      // Dados da composição
      'composicao_produto_ids': composicaoProdutoIds.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
      'composicao_codigo_produto': composicaoCodigoProduto.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
    };
  }

  static ItemCarrinho fromJson(
    Map<String, dynamic> json,
    ProdutoCardapio produto,
  ) {
    return ItemCarrinho(
      id: json['id'],
      produto: produto,
      quantidade: json['quantidade'],
      precoUnitario: json['preco_unitario'].toDouble(),
      precoTotal: json['preco_total'].toDouble(),
      composicaoSelecionada: Map<int, int>.from(
        // ✅ ALTERADO
        (json['composicao_selecionada'] as Map).map(
          (k, v) =>
              MapEntry(int.parse(k), v is int ? v : int.parse(v.toString())),
        ),
      ),
      complementosSelecionados: Map<int, int>.from(
        (json['complementos_selecionados'] as Map).map(
          (k, v) => MapEntry(int.parse(k), v),
        ),
      ),
      preparosSelecionados: Set<int>.from(json['preparos_selecionados']),
      observacoes: json['observacoes'],
      criadoEm: DateTime.parse(json['criado_em']),
      // Carregar nomes
      composicaoNomes:
          json['composicao_nomes'] != null
              ? Map<int, String>.from(
                (json['composicao_nomes'] as Map).map(
                  (k, v) => MapEntry(int.parse(k), v),
                ),
              )
              : {},
      complementosNomes:
          json['complementos_nomes'] != null
              ? Map<int, String>.from(
                (json['complementos_nomes'] as Map).map(
                  (k, v) => MapEntry(int.parse(k), v),
                ),
              )
              : {},
      preparosNomes:
          json['preparos_nomes'] != null
              ? Map<int, String>.from(
                (json['preparos_nomes'] as Map).map(
                  (k, v) => MapEntry(int.parse(k), v),
                ),
              )
              : {},
      // Carregar dados dos complementos
      complementosPrecos:
          json['complementos_precos'] != null
              ? Map<int, double>.from(
                (json['complementos_precos'] as Map).map(
                  (k, v) => MapEntry(int.parse(k), v.toDouble()),
                ),
              )
              : {},
      complementoProdutoIds:
          json['complemento_produto_ids'] != null
              ? Map<int, int>.from(
                (json['complemento_produto_ids'] as Map).map(
                  (k, v) => MapEntry(int.parse(k), v),
                ),
              )
              : {},
      complementosCodigoBarra:
          json['complementos_codigo_barra'] != null
              ? Map<int, String>.from(
                (json['complementos_codigo_barra'] as Map).map(
                  (k, v) => MapEntry(int.parse(k), v.toString()),
                ),
              )
              : {},
      // Carregar dados da composição
      composicaoProdutoIds:
          json['composicao_produto_ids'] != null
              ? Map<int, int>.from(
                (json['composicao_produto_ids'] as Map).map(
                  (k, v) => MapEntry(int.parse(k), v),
                ),
              )
              : {},
      composicaoCodigoProduto:
          json['composicao_codigo_produto'] != null
              ? Map<int, String>.from(
                (json['composicao_codigo_produto'] as Map).map(
                  (k, v) => MapEntry(int.parse(k), v.toString()),
                ),
              )
              : {},
    );
  }
}

class Carrinho {
  final List<ItemCarrinho> itens;
  final double subtotal;
  final double desconto;
  final double taxaEntrega;
  final double total;
  final DateTime atualizadoEm;

  Carrinho({
    List<ItemCarrinho>? itens,
    this.desconto = 0.0,
    this.taxaEntrega = 0.0,
    DateTime? atualizadoEm,
  }) : itens = itens ?? [],
       subtotal = (itens ?? []).fold(0.0, (sum, item) => sum + item.precoTotal),
       total =
           (itens ?? []).fold(0.0, (sum, item) => sum + item.precoTotal) -
           (desconto) +
           (taxaEntrega),
       atualizadoEm = atualizadoEm ?? DateTime.now();

  bool get isEmpty => itens.isEmpty;
  bool get isNotEmpty => itens.isNotEmpty;
  int get quantidadeTotal =>
      itens.fold(0, (sum, item) => sum + item.quantidade);

  Carrinho copyWith({
    List<ItemCarrinho>? itens,
    double? desconto,
    double? taxaEntrega,
    DateTime? atualizadoEm,
  }) {
    return Carrinho(
      itens: itens ?? List.from(this.itens),
      desconto: desconto ?? this.desconto,
      taxaEntrega: taxaEntrega ?? this.taxaEntrega,
      atualizadoEm: atualizadoEm ?? DateTime.now(),
    );
  }

  // Método para adicionar item (SEMPRE adiciona novo item para produtos personalizáveis)
  Carrinho adicionarItem(ItemCarrinho novoItem) {
    final itensAtualizados = List<ItemCarrinho>.from(itens);
    itensAtualizados.add(novoItem);
    return copyWith(itens: itensAtualizados);
  }

  // Método para remover item
  Carrinho removerItem(String itemId) {
    final itensAtualizados = itens.where((item) => item.id != itemId).toList();
    return copyWith(itens: itensAtualizados);
  }

  // Método para atualizar quantidade de um item
  Carrinho atualizarQuantidade(String itemId, int novaQuantidade) {
    if (novaQuantidade <= 0) {
      return removerItem(itemId);
    }

    final itensAtualizados =
        itens.map((item) {
          if (item.id == itemId) {
            final precoTotalNovo = novaQuantidade * item.precoUnitario;
            return item.copyWith(
              quantidade: novaQuantidade,
              precoTotal: precoTotalNovo,
            );
          }
          return item;
        }).toList();

    return copyWith(itens: itensAtualizados);
  }

  // Método para limpar carrinho
  Carrinho limpar() {
    return Carrinho();
  }

  Map<String, dynamic> toJson() {
    return {
      'itens': itens.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'desconto': desconto,
      'taxa_entrega': taxaEntrega,
      'total': total,
      'quantidade_total': quantidadeTotal,
      'atualizado_em': atualizadoEm.toIso8601String(),
    };
  }
}

// ✅ MODELOS ATUALIZADOS PARA CORRESPONDER À API REAL COM PARSING SEGURO
class ProdutoComposicaoCompleto {
  final int? composicaoId;
  final ProdutoCardapio? produto;
  final double? quantidade;
  final bool? opcional;

  ProdutoComposicaoCompleto({
    this.composicaoId,
    this.produto,
    this.quantidade,
    this.opcional,
  });

  factory ProdutoComposicaoCompleto.fromJson(Map<String, dynamic> json) {
    try {
      return ProdutoComposicaoCompleto(
        composicaoId: ParsingUtils.parseInt(json['composicao']?['id']),
        produto:
            json['produto'] != null
                ? ProdutoCardapio.fromJson(json['produto'])
                : null,
        quantidade: ParsingUtils.parseDouble(json['composicao']?['quantidade']),
        opcional: ParsingUtils.parseBool(json['composicao']?['opcional']),
      );
    } catch (e) {
      print('❌ Erro ao processar ProdutoComposicaoCompleto: $e');
      print('📄 JSON: $json');
      return ProdutoComposicaoCompleto();
    }
  }
}

class ProdutoComplementoCompleto {
  final int? complementoId;
  final ProdutoCardapio? produto;

  ProdutoComplementoCompleto({this.complementoId, this.produto});

  factory ProdutoComplementoCompleto.fromJson(Map<String, dynamic> json) {
    try {
      return ProdutoComplementoCompleto(
        complementoId: ParsingUtils.parseInt(json['complemento']?['id']),
        produto:
            json['produto'] != null
                ? ProdutoCardapio.fromJson(json['produto'])
                : null,
      );
    } catch (e) {
      print('❌ Erro ao processar ProdutoComplementoCompleto: $e');
      print('📄 JSON: $json');
      return ProdutoComplementoCompleto();
    }
  }

  // Preço adicional baseado no preço do produto complemento
  double get precoAdicional => produto?.precoUnit ?? 0.0;
}

class ProdutoPreparoCompleto {
  final int? produtoPreparoId;
  final int? preparoId;
  final String? preparoDescricao;
  final bool? padrao;
  final String? obsEspecifico;

  ProdutoPreparoCompleto({
    this.produtoPreparoId,
    this.preparoId,
    this.preparoDescricao,
    this.padrao,
    this.obsEspecifico,
  });

  factory ProdutoPreparoCompleto.fromJson(Map<String, dynamic> json) {
    try {
      return ProdutoPreparoCompleto(
        produtoPreparoId: ParsingUtils.parseInt(json['produto_preparo']?['id']),
        preparoId: ParsingUtils.parseInt(json['preparo']?['id']),
        preparoDescricao: json['preparo']?['descricao']?.toString(),
        padrao: ParsingUtils.parseBool(json['produto_preparo']?['padrao']),
        obsEspecifico: json['produto_preparo']?['obs_especifico']?.toString(),
      );
    } catch (e) {
      print('❌ Erro ao processar ProdutoPreparoCompleto: $e');
      print('📄 JSON: $json');
      return ProdutoPreparoCompleto();
    }
  }
}

class ProdutoCompleto {
  final ProdutoCardapio produto;
  final List<ProdutoComposicaoCompleto> composicao;
  final List<ProdutoComplementoCompleto> complementos;
  final List<ProdutoPreparoCompleto> preparos;
  final List<ProdutoImagem> imagens;

  ProdutoCompleto({
    required this.produto,
    this.composicao = const [],
    this.complementos = const [],
    this.preparos = const [],
    this.imagens = const [],
  });

  factory ProdutoCompleto.fromJson(Map<String, dynamic> json) {
    try {
      return ProdutoCompleto(
        produto: ProdutoCardapio.fromJson(json['produto'] ?? {}),
        composicao:
            json['composicao'] != null
                ? (json['composicao'] as List)
                    .map((comp) => ProdutoComposicaoCompleto.fromJson(comp))
                    .toList()
                : [],
        complementos:
            json['complementos'] != null
                ? (json['complementos'] as List)
                    .map((comp) => ProdutoComplementoCompleto.fromJson(comp))
                    .toList()
                : [],
        preparos:
            json['preparos'] != null
                ? (json['preparos'] as List)
                    .map((prep) => ProdutoPreparoCompleto.fromJson(prep))
                    .toList()
                : [],
        imagens:
            json['imagens'] != null
                ? (json['imagens'] as List)
                    .map((img) => ProdutoImagem.fromJson(img))
                    .toList()
                : [],
      );
    } catch (e) {
      print('❌ Erro ao processar ProdutoCompleto: $e');
      print(
        '📄 JSON (primeiros 500 chars): ${json.toString().substring(0, 500)}...',
      );
      rethrow;
    }
  }

  // Verificar se o produto é personalizável
  bool get isPersonalizavel {
    final temComposicaoOpcional = composicao.any(
      (comp) => comp.opcional == true,
    );
    final temComplementos = complementos.isNotEmpty;
    final temPreparos = preparos.length > 1;

    return temComposicaoOpcional || temComplementos || temPreparos;
  }
}

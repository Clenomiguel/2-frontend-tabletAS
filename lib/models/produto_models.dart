// lib/models/produto_models.dart
// Models que correspondem aos schemas do backend FastAPI

import '../utils/parsing_utils.dart';

/// Produto base - corresponde a ProdutoResponse do backend
class Produto {
  final int grid;
  final String? codigo;
  final String? codigoBarra;
  final String nome;
  final String? nomeResumido;
  final double? precoUnit;
  final double? precoPrazo;
  final String? unidMed;
  final bool permiteVenda;
  final int? grupo;
  final int? subgrupo;
  final String? tipo;
  final String? tributacao;
  final double? percImposto;
  final bool? gorjeta;

  Produto({
    required this.grid,
    this.codigo,
    this.codigoBarra,
    required this.nome,
    this.nomeResumido,
    this.precoUnit,
    this.precoPrazo,
    this.unidMed,
    this.permiteVenda = true,
    this.grupo,
    this.subgrupo,
    this.tipo,
    this.tributacao,
    this.percImposto,
    this.gorjeta,
  });

  factory Produto.fromJson(Map<String, dynamic> json) {
    return Produto(
      grid: ParsingUtils.parseInt(json['grid']) ?? 0,
      codigo: json['codigo']?.toString(),
      codigoBarra: json['codigo_barra']?.toString(),
      nome: json['nome'] ?? 'Produto',
      nomeResumido: json['nome_resumido'],
      precoUnit: ParsingUtils.parseDouble(json['preco_unit']),
      precoPrazo: ParsingUtils.parseDouble(json['preco_prazo']),
      unidMed: json['unid_med'],
      permiteVenda: ParsingUtils.parseBool(json['permite_venda']) ?? true,
      grupo: ParsingUtils.parseInt(json['grupo']),
      subgrupo: ParsingUtils.parseInt(json['subgrupo']),
      tipo: json['tipo'],
      tributacao: json['tributacao'],
      percImposto: ParsingUtils.parseDouble(json['perc_imposto']),
      gorjeta: ParsingUtils.parseBool(json['gorjeta']),
    );
  }

  Map<String, dynamic> toJson() => {
    'grid': grid,
    'codigo': codigo,
    'codigo_barra': codigoBarra,
    'nome': nome,
    'nome_resumido': nomeResumido,
    'preco_unit': precoUnit,
    'preco_prazo': precoPrazo,
    'unid_med': unidMed,
    'permite_venda': permiteVenda,
    'grupo': grupo,
    'subgrupo': subgrupo,
    'tipo': tipo,
    'tributacao': tributacao,
    'perc_imposto': percImposto,
    'gorjeta': gorjeta,
  };

  String get precoFormatado {
    if (precoUnit == null) return 'R\$ 0,00';
    return 'R\$ ${precoUnit!.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String get nomeExibicao => nomeResumido ?? nome;
}

/// Imagem do produto
class ProdutoImagem {
  final int grid;
  final int produto;
  final String? ext;
  final DateTime? ts;

  ProdutoImagem({
    required this.grid,
    required this.produto,
    this.ext,
    this.ts,
  });

  factory ProdutoImagem.fromJson(Map<String, dynamic> json) {
    return ProdutoImagem(
      grid: ParsingUtils.parseInt(json['grid']) ?? 0,
      produto: ParsingUtils.parseInt(json['produto']) ?? 0,
      ext: json['ext'],
      ts: json['ts'] != null ? DateTime.tryParse(json['ts'].toString()) : null,
    );
  }
}

/// Complemento do produto - corresponde a ProdutoComplementoWithDetails
class ProdutoComplemento {
  final int grid;
  final int produto;
  final int complemento;
  final String? produtoNome;
  final String? complementoNome;

  ProdutoComplemento({
    required this.grid,
    required this.produto,
    required this.complemento,
    this.produtoNome,
    this.complementoNome,
  });

  factory ProdutoComplemento.fromJson(Map<String, dynamic> json) {
    return ProdutoComplemento(
      grid: ParsingUtils.parseInt(json['grid']) ?? 0,
      produto: ParsingUtils.parseInt(json['produto']) ?? 0,
      complemento: ParsingUtils.parseInt(json['complemento']) ?? 0,
      produtoNome: json['produto_nome'],
      complementoNome: json['complemento_nome'],
    );
  }
}

/// Composição do produto (matéria-prima) - corresponde a ProdutoComposicaoWithDetails
class ProdutoComposicao {
  final int grid;
  final int produto;
  final int materiaPrima;
  final double? quantidade;
  final bool opcional;
  final int? parent;
  final int? empresa;
  final String? materiaPrimaNome;
  final String? materiaPrimaCodigo;
  final String? materiaPrimaUnidade;

  ProdutoComposicao({
    required this.grid,
    required this.produto,
    required this.materiaPrima,
    this.quantidade,
    this.opcional = false,
    this.parent,
    this.empresa,
    this.materiaPrimaNome,
    this.materiaPrimaCodigo,
    this.materiaPrimaUnidade,
  });

  factory ProdutoComposicao.fromJson(Map<String, dynamic> json) {
    return ProdutoComposicao(
      grid: ParsingUtils.parseInt(json['grid']) ?? 0,
      produto: ParsingUtils.parseInt(json['produto']) ?? 0,
      materiaPrima: ParsingUtils.parseInt(json['materia_prima']) ?? 0,
      quantidade: ParsingUtils.parseDouble(json['quantidade']),
      opcional: ParsingUtils.parseBool(json['opcional']) ?? false,
      parent: ParsingUtils.parseInt(json['parent']),
      empresa: ParsingUtils.parseInt(json['empresa']),
      materiaPrimaNome: json['materia_prima_nome'],
      materiaPrimaCodigo: json['materia_prima_codigo'],
      materiaPrimaUnidade: json['materia_prima_unidade'],
    );
  }
}

/// Preparo do produto - corresponde a PreparoComPadrao
class ProdutoPreparo {
  final int grid;
  final int? codigo;
  final String? descricao;
  final bool ehPadrao;

  ProdutoPreparo({
    required this.grid,
    this.codigo,
    this.descricao,
    this.ehPadrao = false,
  });

  factory ProdutoPreparo.fromJson(Map<String, dynamic> json) {
    return ProdutoPreparo(
      grid: ParsingUtils.parseInt(json['grid']) ?? 0,
      codigo: ParsingUtils.parseInt(json['codigo']),
      descricao: json['descricao'],
      ehPadrao: ParsingUtils.parseBool(json['eh_padrao']) ?? false,
    );
  }
}

/// Preparos de um produto - corresponde a PreparosDoProdutoResponse
class PreparosDoProduto {
  final int produtoGrid;
  final List<ProdutoPreparo> preparos;

  PreparosDoProduto({
    required this.produtoGrid,
    required this.preparos,
  });

  factory PreparosDoProduto.fromJson(Map<String, dynamic> json) {
    return PreparosDoProduto(
      produtoGrid: ParsingUtils.parseInt(json['produto_grid']) ?? 0,
      preparos: (json['preparos'] as List? ?? [])
          .map((e) => ProdutoPreparo.fromJson(e))
          .toList(),
    );
  }

  ProdutoPreparo? get preparoPadrao {
    try {
      return preparos.firstWhere((p) => p.ehPadrao);
    } catch (_) {
      return preparos.isNotEmpty ? preparos.first : null;
    }
  }
}

/// Produto completo com todas as relações
class ProdutoCompleto {
  final Produto produto;
  final List<ProdutoImagem> imagens;
  final List<ProdutoComplemento> complementos;
  final List<ProdutoComposicao> composicao;
  final List<ProdutoPreparo> preparos;

  ProdutoCompleto({
    required this.produto,
    this.imagens = const [],
    this.complementos = const [],
    this.composicao = const [],
    this.preparos = const [],
  });

  factory ProdutoCompleto.fromJson(Map<String, dynamic> json) {
    // Extrair preparos do formato correto
    List<ProdutoPreparo> preparosList = [];
    if (json['preparos'] != null) {
      final preparosData = json['preparos'];
      if (preparosData is Map && preparosData['preparos'] != null) {
        preparosList = (preparosData['preparos'] as List)
            .map((e) => ProdutoPreparo.fromJson(e))
            .toList();
      } else if (preparosData is List) {
        preparosList = preparosData
            .map((e) => ProdutoPreparo.fromJson(e))
            .toList();
      }
    }

    return ProdutoCompleto(
      produto: Produto.fromJson(json['produto'] ?? json),
      imagens: (json['imagens'] as List? ?? [])
          .map((e) => ProdutoImagem.fromJson(e))
          .toList(),
      complementos: (json['complementos'] as List? ?? [])
          .map((e) => ProdutoComplemento.fromJson(e))
          .toList(),
      composicao: (json['composicao'] as List? ?? [])
          .map((e) => ProdutoComposicao.fromJson(e))
          .toList(),
      preparos: preparosList,
    );
  }

  /// Verifica se o produto é personalizável
  bool get isPersonalizavel {
    final temComposicaoOpcional = composicao.any((c) => c.opcional);
    final temComplementos = complementos.isNotEmpty;
    final temPreparos = preparos.length > 1;
    return temComposicaoOpcional || temComplementos || temPreparos;
  }

  /// Lista apenas composições opcionais (sabores escolhíveis)
  List<ProdutoComposicao> get composicoesOpcionais =>
      composicao.where((c) => c.opcional).toList();

  /// Lista composições obrigatórias
  List<ProdutoComposicao> get composicoesObrigatorias =>
      composicao.where((c) => !c.opcional).toList();
}

/// Resposta paginada genérica
class PaginatedResponse<T> {
  final List<T> items;
  final int total;
  final int page;
  final int perPage;
  final int totalPages;

  PaginatedResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.perPage,
    required this.totalPages,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PaginatedResponse(
      items: (json['items'] as List? ?? [])
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(),
      total: ParsingUtils.parseInt(json['total']) ?? 0,
      page: ParsingUtils.parseInt(json['page']) ?? 1,
      perPage: ParsingUtils.parseInt(json['per_page']) ?? 100,
      totalPages: ParsingUtils.parseInt(json['total_pages']) ?? 1,
    );
  }
}

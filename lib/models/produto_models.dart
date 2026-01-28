// lib/models/produto_models.dart
// Modelos de produto, complementos, composição e preparos

/// Produto principal
class Produto {
  final int grid;
  final String nome;
  final String? descricao;
  final double preco;
  final double? precoPromocional;
  final int? grupoGrid;
  final String? grupoNome;
  final bool ativo;
  final bool controlaEstoque;
  final double? estoque;
  final String? unidade;
  final String? codigoBarra;
  final String? imagemBase64;

  Produto({
    required this.grid,
    required this.nome,
    this.descricao,
    required this.preco,
    this.precoPromocional,
    this.grupoGrid,
    this.grupoNome,
    this.ativo = true,
    this.controlaEstoque = false,
    this.estoque,
    this.unidade,
    this.codigoBarra,
    this.imagemBase64,
  });

  factory Produto.fromJson(Map<String, dynamic> json) {
    return Produto(
      grid: _toInt(json['grid']),
      nome: json['nome'] ?? '',
      descricao: json['descricao'],
      preco: _toDouble(
          json['preco'] ?? json['preco_venda'] ?? json['preco_unit'] ?? 0),
      precoPromocional: json['preco_promocional'] != null
          ? _toDouble(json['preco_promocional'])
          : null,
      grupoGrid: json['grupo_grid'] != null ? _toInt(json['grupo_grid']) : null,
      grupoNome: json['grupo_nome'],
      ativo:
          json['ativo'] ?? json['situacao'] == 'A' || json['situacao'] == true,
      controlaEstoque: json['controla_estoque'] ?? false,
      estoque: json['estoque'] != null ? _toDouble(json['estoque']) : null,
      unidade: json['unidade'],
      codigoBarra: json['codigo_barra'],
      imagemBase64: json['imagem'] ?? json['foto'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'grid': grid,
      'nome': nome,
      'descricao': descricao,
      'preco': preco,
      'preco_promocional': precoPromocional,
      'grupo_grid': grupoGrid,
      'grupo_nome': grupoNome,
      'ativo': ativo,
      'controla_estoque': controlaEstoque,
      'estoque': estoque,
      'unidade': unidade,
      'codigo_barra': codigoBarra,
    };
  }

  /// Nome para exibição
  String get nomeExibicao => nome;

  /// Preço unitário (alias para preco)
  double get precoUnit => preco;

  /// Preço efetivo (promocional se houver, senão normal)
  double get precoEfetivo => precoPromocional ?? preco;

  /// Verifica se tem promoção
  bool get temPromocao => precoPromocional != null && precoPromocional! < preco;
}

/// Produto completo com imagens, complementos e composição
class ProdutoCompleto {
  final Produto produto;
  final List<ProdutoImagem> imagens;
  final List<ProdutoComplemento> complementos;
  final List<ProdutoComposicao> composicao;
  final List<Preparo> preparos;

  ProdutoCompleto({
    required this.produto,
    this.imagens = const [],
    this.complementos = const [],
    this.composicao = const [],
    this.preparos = const [],
  });

  factory ProdutoCompleto.fromJson(Map<String, dynamic> json) {
    final produto = Produto.fromJson(json);

    List<ProdutoImagem> imagens = [];
    if (json['imagens'] is List) {
      imagens = (json['imagens'] as List)
          .map((e) => ProdutoImagem.fromJson(e))
          .toList();
    }

    List<ProdutoComplemento> complementos = [];
    if (json['complementos'] is List) {
      complementos = (json['complementos'] as List)
          .map((e) => ProdutoComplemento.fromJson(e))
          .toList();
    }

    List<ProdutoComposicao> composicao = [];
    if (json['composicao'] is List) {
      composicao = (json['composicao'] as List)
          .map((e) => ProdutoComposicao.fromJson(e))
          .toList();
    }

    List<Preparo> preparos = [];
    if (json['preparos'] is List) {
      preparos =
          (json['preparos'] as List).map((e) => Preparo.fromJson(e)).toList();
    }

    return ProdutoCompleto(
      produto: produto,
      imagens: imagens,
      complementos: complementos,
      composicao: composicao,
      preparos: preparos,
    );
  }

  int get grid => produto.grid;
  String get nome => produto.nome;
  String get nomeExibicao => produto.nomeExibicao;
  String? get descricao => produto.descricao;
  double get preco => produto.preco;

  String? get primeiraImagem =>
      imagens.isNotEmpty ? imagens.first.imagemBase64 : null;

  /// Composições que podem ser removidas pelo cliente
  List<ProdutoComposicao> get composicoesOpcionais =>
      composicao.where((c) => c.removivel).toList();
}

/// Imagem do produto
class ProdutoImagem {
  final int? grid;
  final int produtoGrid;
  final String? imagemBase64;
  final int? ordem;
  final bool principal;

  ProdutoImagem({
    this.grid,
    required this.produtoGrid,
    this.imagemBase64,
    this.ordem,
    this.principal = false,
  });

  factory ProdutoImagem.fromJson(Map<String, dynamic> json) {
    return ProdutoImagem(
      grid: json['grid'] != null ? _toInt(json['grid']) : null,
      produtoGrid: _toInt(json['produto_grid'] ?? json['produto'] ?? 0),
      imagemBase64: json['imagem'] ?? json['foto'] ?? json['image'],
      ordem: json['ordem'] != null ? _toInt(json['ordem']) : null,
      principal: json['principal'] ?? false,
    );
  }
}

/// Complemento do produto
class ProdutoComplemento {
  final int grid;
  final int produtoGrid;
  final int complementoGrid;
  final String? nome;
  final double preco;
  final double? precoAdicional;
  final int? quantidadeMinima;
  final int? quantidadeMaxima;
  final bool obrigatorio;
  final int? grupoGrid;
  final String? grupoNome;

  ProdutoComplemento({
    required this.grid,
    required this.produtoGrid,
    required this.complementoGrid,
    this.nome,
    required this.preco,
    this.precoAdicional,
    this.quantidadeMinima,
    this.quantidadeMaxima,
    this.obrigatorio = false,
    this.grupoGrid,
    this.grupoNome,
  });

  factory ProdutoComplemento.fromJson(Map<String, dynamic> json) {
    return ProdutoComplemento(
      grid: _toInt(json['grid'] ?? json['id'] ?? 0),
      produtoGrid: _toInt(json['produto_grid'] ?? json['produto'] ?? 0),
      complementoGrid: _toInt(json['complemento_grid'] ??
          json['complemento'] ??
          json['produto_complemento'] ??
          0),
      nome: json['nome'] ?? json['complemento_nome'],
      preco: _toDouble(json['preco'] ?? json['preco_adicional'] ?? 0),
      precoAdicional: json['preco_adicional'] != null
          ? _toDouble(json['preco_adicional'])
          : null,
      quantidadeMinima: json['quantidade_minima'] != null
          ? _toInt(json['quantidade_minima'])
          : null,
      quantidadeMaxima: json['quantidade_maxima'] != null
          ? _toInt(json['quantidade_maxima'])
          : null,
      obrigatorio: json['obrigatorio'] ?? false,
      grupoGrid: json['grupo_grid'] != null ? _toInt(json['grupo_grid']) : null,
      grupoNome: json['grupo_nome'],
    );
  }

  /// Alias para complementoGrid (compatibilidade)
  int get complemento => complementoGrid;

  /// Alias para nome (compatibilidade)
  String? get complementoNome => nome;
}

/// Item da composição do produto (ingredientes)
class ProdutoComposicao {
  final int grid;
  final int produtoGrid;
  final int materiaPrima;
  final String? nome;
  final double quantidade;
  final String? unidade;
  final bool removivel;
  final bool padrao;

  ProdutoComposicao({
    required this.grid,
    required this.produtoGrid,
    required this.materiaPrima,
    this.nome,
    required this.quantidade,
    this.unidade,
    this.removivel = true,
    this.padrao = true,
  });

  factory ProdutoComposicao.fromJson(Map<String, dynamic> json) {
    return ProdutoComposicao(
      grid: _toInt(json['grid'] ?? json['id'] ?? 0),
      produtoGrid: _toInt(json['produto_grid'] ?? json['produto'] ?? 0),
      materiaPrima: _toInt(json['materia_prima'] ?? json['ingrediente'] ?? 0),
      nome: json['nome'] ??
          json['materia_prima_nome'] ??
          json['ingrediente_nome'],
      quantidade: _toDouble(json['quantidade'] ?? 1),
      unidade: json['unidade'],
      removivel: json['removivel'] ?? json['pode_remover'] ?? true,
      padrao: json['padrao'] ?? true,
    );
  }

  /// Alias para nome (compatibilidade)
  String? get materiaPrimaNome => nome;
}

/// Preparo/Sabor do produto
class Preparo {
  final int grid;
  final int? produtoGrid;
  final String nome;
  final String? descricao;
  final double? preco;
  final double? acrescimo;
  final int? ordem;
  final bool ativo;
  final bool ehPadrao;
  final int? codigo;

  Preparo({
    required this.grid,
    this.produtoGrid,
    required this.nome,
    this.descricao,
    this.preco,
    this.acrescimo,
    this.ordem,
    this.ativo = true,
    this.ehPadrao = false,
    this.codigo,
  });

  factory Preparo.fromJson(Map<String, dynamic> json) {
    return Preparo(
      grid: _toInt(json['grid'] ?? json['id'] ?? 0),
      produtoGrid:
          json['produto_grid'] != null ? _toInt(json['produto_grid']) : null,
      nome: json['nome'] ?? json['descricao'] ?? '',
      descricao: json['descricao'] ?? json['nome'],
      preco: json['preco'] != null ? _toDouble(json['preco']) : null,
      acrescimo:
          json['acrescimo'] != null ? _toDouble(json['acrescimo']) : null,
      ordem: json['ordem'] != null ? _toInt(json['ordem']) : null,
      ativo: json['ativo'] ?? true,
      ehPadrao: json['eh_padrao'] ?? json['padrao'] ?? json['default'] ?? false,
      codigo: json['codigo'] != null ? _toInt(json['codigo']) : null,
    );
  }

  double get precoEfetivo => preco ?? acrescimo ?? 0;
}

/// Alias para Preparo (compatibilidade)
typedef ProdutoPreparo = Preparo;

/// Resposta de preparos de um produto
class PreparosDoProduto {
  final int produtoGrid;
  final List<Preparo> preparos;
  final bool obrigatorio;
  final int? minimoSelecao;
  final int? maximoSelecao;

  PreparosDoProduto({
    required this.produtoGrid,
    required this.preparos,
    this.obrigatorio = false,
    this.minimoSelecao,
    this.maximoSelecao,
  });

  factory PreparosDoProduto.fromJson(Map<String, dynamic> json) {
    List<Preparo> preparos = [];
    if (json['preparos'] is List) {
      preparos =
          (json['preparos'] as List).map((e) => Preparo.fromJson(e)).toList();
    } else if (json['items'] is List) {
      preparos =
          (json['items'] as List).map((e) => Preparo.fromJson(e)).toList();
    }

    return PreparosDoProduto(
      produtoGrid: _toInt(json['produto_grid'] ?? json['produto'] ?? 0),
      preparos: preparos,
      obrigatorio: json['obrigatorio'] ?? false,
      minimoSelecao: json['minimo_selecao'] != null
          ? _toInt(json['minimo_selecao'])
          : null,
      maximoSelecao: json['maximo_selecao'] != null
          ? _toInt(json['maximo_selecao'])
          : null,
    );
  }
}

/// Grupo de complementos
class GrupoComplemento {
  final int grid;
  final String nome;
  final int? quantidadeMinima;
  final int? quantidadeMaxima;
  final bool obrigatorio;
  final List<ProdutoComplemento> complementos;

  GrupoComplemento({
    required this.grid,
    required this.nome,
    this.quantidadeMinima,
    this.quantidadeMaxima,
    this.obrigatorio = false,
    this.complementos = const [],
  });

  factory GrupoComplemento.fromJson(Map<String, dynamic> json) {
    List<ProdutoComplemento> complementos = [];
    if (json['complementos'] is List) {
      complementos = (json['complementos'] as List)
          .map((e) => ProdutoComplemento.fromJson(e))
          .toList();
    }

    return GrupoComplemento(
      grid: _toInt(json['grid'] ?? json['id'] ?? 0),
      nome: json['nome'] ?? '',
      quantidadeMinima: json['quantidade_minima'] != null
          ? _toInt(json['quantidade_minima'])
          : null,
      quantidadeMaxima: json['quantidade_maxima'] != null
          ? _toInt(json['quantidade_maxima'])
          : null,
      obrigatorio: json['obrigatorio'] ?? false,
      complementos: complementos,
    );
  }
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
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final items = (json['items'] as List? ?? [])
        .map((e) => fromJson(e as Map<String, dynamic>))
        .toList();

    final total = _toInt(json['total'] ?? items.length);
    final page = _toInt(json['page'] ?? 1);
    final perPage = _toInt(json['per_page'] ?? json['limit'] ?? items.length);
    final totalPages = perPage > 0 ? (total / perPage).ceil() : 1;

    return PaginatedResponse(
      items: items,
      total: total,
      page: page,
      perPage: perPage,
      totalPages: totalPages,
    );
  }

  bool get hasNext => page < totalPages;
  bool get hasPrevious => page > 1;
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
}

// Helpers
int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

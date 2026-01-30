// lib/models/produto_models.dart
// Modelos para produtos

/// Produto base
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
    // grupo pode ser int ou Map
    int? grupoGrid;
    final grupoData = json['grupo'];
    if (grupoData is int) {
      grupoGrid = grupoData;
    } else if (grupoData is Map) {
      grupoGrid = _toInt(grupoData['grid'] ?? grupoData['id'] ?? 0);
    }

    return Produto(
      grid: _toInt(json['grid'] ?? json['id'] ?? 0),
      nome: json['nome'] ?? json['descricao'] ?? '',
      descricao: json['nome_resumido'] ?? json['descricao'],
      preco: _toDouble(
          json['preco_unit'] ?? json['preco'] ?? json['preco_venda'] ?? 0),
      precoPromocional: json['preco_promocional'] != null
          ? _toDouble(json['preco_promocional'])
          : null,
      grupoGrid: grupoGrid,
      grupoNome: null, // API não retorna nome do grupo
      ativo: json['flag'] == 'A' ||
          json['ativo'] == true ||
          json['permite_venda'] == true,
      controlaEstoque: json['controla_estoque'] ?? false,
      estoque: json['estoque'] != null ? _toDouble(json['estoque']) : null,
      unidade: json['unid_med'] ?? json['unidade'],
      codigoBarra: json['codigo_barra']?.toString(),
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
  String get nomeExibicao => nome.isNotEmpty ? nome : 'Produto #$grid';

  /// Alias para preco (compatibilidade)
  double get precoUnit => preco;

  /// Preço efetivo (promocional ou normal)
  double get precoEfetivo => precoPromocional ?? preco;

  /// Verifica se tem promoção
  bool get temPromocao => precoPromocional != null && precoPromocional! < preco;
}

/// Produto completo com relacionamentos
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

  /// Composições que podem ser removidas
  List<ProdutoComposicao> get composicoesOpcionais =>
      composicao.where((c) => c.removivel).toList();
}

/// Imagem do produto
class ProdutoImagem {
  final int grid;
  final int produtoGrid;
  final String? imagem;
  final int? ordem;

  ProdutoImagem({
    required this.grid,
    required this.produtoGrid,
    this.imagem,
    this.ordem,
  });

  factory ProdutoImagem.fromJson(Map<String, dynamic> json) {
    return ProdutoImagem(
      grid: _toInt(json['grid'] ?? json['id'] ?? 0),
      produtoGrid: _toInt(json['produto_grid'] ?? json['produto'] ?? 0),
      imagem: json['imagem'] ?? json['foto'],
      ordem: json['ordem'] != null ? _toInt(json['ordem']) : null,
    );
  }
}

/// Complemento do produto
class ProdutoComplemento {
  final int grid;
  final int produtoGrid;
  final int complementoGrid;
  final String? nome;
  final int? quantidade;
  final int? quantidadeMinima;
  final int? quantidadeMaxima;
  final double? preco;
  final bool ativo;

  ProdutoComplemento({
    required this.grid,
    required this.produtoGrid,
    required this.complementoGrid,
    this.nome,
    this.quantidade,
    this.quantidadeMinima,
    this.quantidadeMaxima,
    this.preco,
    this.ativo = true,
  });

  factory ProdutoComplemento.fromJson(Map<String, dynamic> json) {
    return ProdutoComplemento(
      grid: _toInt(json['grid'] ?? json['id'] ?? 0),
      produtoGrid: _toInt(json['produto_grid'] ?? json['produto'] ?? 0),
      complementoGrid:
          _toInt(json['complemento_grid'] ?? json['complemento'] ?? 0),
      nome: json['nome'] ?? json['complemento_nome'],
      quantidade:
          json['quantidade'] != null ? _toInt(json['quantidade']) : null,
      quantidadeMinima: json['quantidade_minima'] != null
          ? _toInt(json['quantidade_minima'])
          : null,
      quantidadeMaxima: json['quantidade_maxima'] != null
          ? _toInt(json['quantidade_maxima'])
          : null,
      preco: json['preco_unit'] != null ? _toDouble(json['preco_unit']) : null,
      ativo: json['ativo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'grid': grid,
      'produto_grid': produtoGrid,
      'complemento_grid': complementoGrid,
      'nome': nome,
      'quantidade': quantidade,
      'quantidade_minima': quantidadeMinima,
      'quantidade_maxima': quantidadeMaxima,
      'preco': preco,
      'ativo': ativo,
    };
  }

  /// Alias para complementoGrid (compatibilidade)
  int get complemento => complementoGrid;

  /// Nome do complemento
  String? get complementoNome => nome;
}

/// Composição do produto (ingredientes)
class ProdutoComposicao {
  final int grid;
  final int produtoGrid;
  final int materiaPrima;
  final String? nome;
  final double quantidade;
  final String? unidade;
  final bool removivel;

  ProdutoComposicao({
    required this.grid,
    required this.produtoGrid,
    required this.materiaPrima,
    this.nome,
    this.quantidade = 1,
    this.unidade,
    this.removivel = true,
  });

  factory ProdutoComposicao.fromJson(Map<String, dynamic> json) {
    return ProdutoComposicao(
      grid: _toInt(json['grid'] ?? json['id'] ?? 0),
      produtoGrid: _toInt(json['produto_grid'] ?? json['produto'] ?? 0),
      materiaPrima:
          _toInt(json['materia_prima'] ?? json['materia_prima_grid'] ?? 0),
      nome: json['nome'] ?? json['materia_prima_nome'],
      quantidade: _toDouble(json['quantidade'] ?? 1),
      unidade: json['unidade'],
      removivel: json['removivel'] ?? json['opcional'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'grid': grid,
      'produto_grid': produtoGrid,
      'materia_prima': materiaPrima,
      'nome': nome,
      'quantidade': quantidade,
      'unidade': unidade,
      'removivel': removivel,
    };
  }

  /// Nome da matéria prima
  String? get materiaPrimaNome => nome;
}

/// Preparo do produto
class Preparo {
  final int grid;
  final int? codigo;
  final String? descricao;
  final bool ehPadrao;

  Preparo({
    required this.grid,
    this.codigo,
    this.descricao,
    this.ehPadrao = false,
  });

  factory Preparo.fromJson(Map<String, dynamic> json) {
    return Preparo(
      grid: _toInt(json['grid'] ?? json['id'] ?? 0),
      codigo: json['codigo'] != null ? _toInt(json['codigo']) : null,
      descricao: json['descricao'] ?? json['nome'],
      ehPadrao: json['padrao'] ?? json['eh_padrao'] ?? json['default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'grid': grid,
      'codigo': codigo,
      'descricao': descricao,
      'padrao': ehPadrao,
    };
  }
}

/// Alias para compatibilidade
typedef ProdutoPreparo = Preparo;

/// Preparos do produto (resposta da API)
class PreparosDoProduto {
  final int produtoGrid;
  final List<Preparo> preparos;

  PreparosDoProduto({
    required this.produtoGrid,
    this.preparos = const [],
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
    );
  }
}

/// Grupo de complementos
class GrupoComplemento {
  final int grid;
  final String nome;
  final int? quantidadeMinima;
  final int? quantidadeMaxima;
  final List<ProdutoComplemento> complementos;

  GrupoComplemento({
    required this.grid,
    required this.nome,
    this.quantidadeMinima,
    this.quantidadeMaxima,
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
      complementos: complementos,
    );
  }
}

/// Resposta paginada
class PaginatedResponse<T> {
  final List<T> items;
  final int total;
  final int page;
  final int perPage;
  final int totalPages;

  PaginatedResponse({
    required this.items,
    required this.total,
    this.page = 1,
    this.perPage = 100,
    int? totalPages,
  }) : totalPages = totalPages ?? ((total + perPage - 1) ~/ perPage);

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final itemsList = json['items'] as List? ?? [];
    return PaginatedResponse<T>(
      items: itemsList.map((e) => fromJson(e as Map<String, dynamic>)).toList(),
      total: _toInt(json['total'] ?? itemsList.length),
      page: _toInt(json['page'] ?? 1),
      perPage: _toInt(json['per_page'] ?? json['limit'] ?? 100),
    );
  }

  bool get hasMore => page < totalPages;
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

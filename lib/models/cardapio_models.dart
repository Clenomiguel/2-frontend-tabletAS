// lib/models/cardapio_models.dart
// VERSÃO ATUALIZADA COM SUPORTE MELHORADO PARA IMAGENS

class Cardapio {
  final int id;
  final String? codigo;
  final String? nome;

  Cardapio({required this.id, this.codigo, this.nome});

  factory Cardapio.fromJson(Map<String, dynamic> json) {
    return Cardapio(
      id: json['id'] ?? 0,
      codigo: json['codigo']?.toString(),
      nome: json['nome']?.toString(),
    );
  }
}

class CardapioSecao {
  final int id;
  final String? nome;
  final int? sequencia;
  final int? cardapioId;
  final List<CardapioSecaoImagem> imagens;
  final List<ProdutoCardapio> produtos;

  CardapioSecao({
    required this.id,
    this.nome,
    this.sequencia,
    this.cardapioId,
    this.imagens = const [],
    this.produtos = const [],
  });

  factory CardapioSecao.fromJson(Map<String, dynamic> json) {
    return CardapioSecao(
      id: json['id'] ?? 0,
      nome: json['nome']?.toString(),
      sequencia: json['sequencia'],
      cardapioId: json['cardapio_id'],
      imagens:
          json['imagens'] != null
              ? (json['imagens'] as List)
                  .map((img) => CardapioSecaoImagem.fromJson(img))
                  .toList()
              : [],
      produtos:
          json['produtos'] != null
              ? (json['produtos'] as List)
                  .map((prod) => ProdutoCardapio.fromJson(prod['produto']))
                  .toList()
              : [],
    );
  }

  // Getter para primeira imagem disponível
  String? get primeiraImagem {
    if (imagens.isNotEmpty && imagens.first.imageUrl != null) {
      return imagens.first.imageUrl;
    }
    return null;
  }

  // Getter para ícone baseado no nome da seção
  String get iconeAsset {
    final nomeNormalizado = (nome ?? '').toLowerCase();

    if (nomeNormalizado.contains('promo')) {
      return 'assets/images/icons/promo.png';
    } else if (nomeNormalizado.contains('açaí') ||
        nomeNormalizado.contains('acai')) {
      return 'assets/images/icons/acai.png';
    } else if (nomeNormalizado.contains('crie') ||
        nomeNormalizado.contains('monte')) {
      return 'assets/images/icons/crie.png';
    } else if (nomeNormalizado.contains('mônica') ||
        nomeNormalizado.contains('monica')) {
      return 'assets/images/icons/turma.png';
    } else if (nomeNormalizado.contains('pote')) {
      return 'assets/images/icons/potes.png';
    } else if (nomeNormalizado.contains('cascão') ||
        nomeNormalizado.contains('cascao')) {
      return 'assets/images/icons/cascao.png';
    } else if (nomeNormalizado.contains('smoothie')) {
      return 'assets/images/icons/smoothies.png';
    } else {
      return 'assets/images/icons/promo.png'; // Ícone padrão
    }
  }
}

class CardapioSecaoImagem {
  final int id;
  final int? secaoId;
  final String? image;
  final String? formato;
  final String? filename;

  CardapioSecaoImagem({
    required this.id,
    this.secaoId,
    this.image,
    this.formato,
    this.filename,
  });

  factory CardapioSecaoImagem.fromJson(Map<String, dynamic> json) {
    return CardapioSecaoImagem(
      id: json['id'] ?? 0,
      secaoId: json['secao_id'],
      image: json['image']?.toString(),
      formato: json['formato']?.toString(),
      filename: json['filename']?.toString(),
    );
  }

  // ✅ GETTER ATUALIZADO - USA ENDPOINT DINÂMICO
  String? get imageUrl {
    const String imageBaseUrl = 'http://192.168.3.150:5469'; // IP da sua rede

    // Prioridade 1: Se tem secaoId, usar endpoint dinâmico
    if (secaoId != null) {
      final formato_final = formato ?? 'jpeg';
      return '$imageBaseUrl/static/img/cardapio/secao_$secaoId.$formato_final';
    }

    // Prioridade 2: Se há dados de imagem base64 inline
    if (image != null && image!.isNotEmpty && image!.length > 100) {
      return 'data:image/${formato ?? 'jpeg'};base64,$image';
    }

    // Prioridade 3: Se há filename, usar endpoint dinâmico
    if (filename != null && filename!.isNotEmpty) {
      return '$imageBaseUrl/static/img/cardapio/$filename';
    }

    return null;
  }

  // ✅ GETTER ALTERNATIVO COM BASE URL CUSTOMIZADA
  String? getImageUrl({String? customBaseUrl}) {
    final baseUrl = customBaseUrl ?? 'http://192.168.3.150:5469';

    // Usar endpoint dinâmico sempre que possível
    if (secaoId != null) {
      final formato_final = formato ?? 'jpeg';
      return '$baseUrl/static/img/cardapio/secao_$secaoId.$formato_final';
    }

    if (image != null && image!.isNotEmpty && image!.length > 100) {
      return 'data:image/${formato ?? 'jpeg'};base64,$image';
    }

    if (filename != null && filename!.isNotEmpty) {
      return '$baseUrl/static/img/cardapio/$filename';
    }

    return null;
  }
}

class ProdutoCardapio {
  final int id;
  final String? codigo;
  final String? codigoBarra;
  final String? nome;
  final String? nomeResumido;
  final String? tipo;
  final String? subtipo;
  final double? precoUnit;
  final String? unidMed;
  final int? grupoId;
  final int? subgrupoId;
  final int? qtdMaximaComposicao;
  final List<ProdutoImagem> imagens;

  ProdutoCardapio({
    required this.id,
    this.codigo,
    this.codigoBarra,
    this.nome,
    this.nomeResumido,
    this.tipo,
    this.subtipo,
    this.precoUnit,
    this.unidMed,
    this.grupoId,
    this.subgrupoId,
    this.qtdMaximaComposicao,
    this.imagens = const [],
  });

  factory ProdutoCardapio.fromJson(Map<String, dynamic> json) {
    return ProdutoCardapio(
      id: json['id'] ?? 0,
      codigo: json['codigo']?.toString(),
      codigoBarra: json['codigo_barra']?.toString(),
      nome: json['nome']?.toString(),
      nomeResumido: json['nome_resumido']?.toString(),
      tipo: json['tipo']?.toString(),
      subtipo: json['subtipo']?.toString(),
      precoUnit: _parseDouble(json['preco_unit']),
      unidMed: json['unid_med']?.toString(),
      grupoId: json['grupo_id'],
      subgrupoId: json['subgrupo_id'],
      qtdMaximaComposicao: json['qtd_maxima_composicao'],
      imagens:
          json['imagens'] != null
              ? (json['imagens'] as List)
                  .map((img) => ProdutoImagem.fromJson(img))
                  .toList()
              : [],
    );
  }

  // Getter para primeira imagem disponível (com fallback para assets)
  String get primeiraImagem {
    if (imagens.isNotEmpty && imagens.first.imageUrl != null) {
      return imagens.first.imageUrl!;
    }
    // Imagem padrão local
    return 'assets/images/copo.png';
  }

  // Getter para preço formatado
  String get precoFormatado {
    if (precoUnit != null) {
      return 'R\$ ${precoUnit!.toStringAsFixed(2).replaceAll('.', ',')}';
    }
    return 'R\$ 0,00';
  }

  // Função auxiliar para converter preço
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
}

class ProdutoImagem {
  final int id;
  final int? produtoId;
  final String? image;
  final String? formato;
  final String? nomeArquivo;
  final String? url;

  ProdutoImagem({
    required this.id,
    this.produtoId,
    this.image,
    this.formato,
    this.nomeArquivo,
    this.url,
  });

  factory ProdutoImagem.fromJson(Map<String, dynamic> json) {
    return ProdutoImagem(
      id: json['id'] ?? 0,
      produtoId: json['produto_id'],
      image: json['image']?.toString(),
      formato: json['formato']?.toString(),
      nomeArquivo: json['nome_arquivo']?.toString(),
      url: json['url']?.toString(),
    );
  }

  // Getter para URL da imagem melhorado
  String? get imageUrl {
    const String imageBaseUrl =
        'http://192.168.3.150:5469'; // Para emulador Android

    // Primeiro tenta usar a URL se disponível
    if (url != null && url!.isNotEmpty) {
      return url;
    }

    // Senão, processa a imagem base64 ou path
    if (image != null && image!.isNotEmpty) {
      // Se já é uma URL completa
      if (image!.startsWith('http')) {
        return image;
      }
      // Se é base64, criar data URL
      if (image!.length > 100) {
        return 'data:image/${formato ?? 'jpeg'};base64,$image';
      }
      // Se é um path, construir URL da API
      return '$imageBaseUrl/static/img/produtos/$image';
    }

    return null;
  }
}

// ✅ MODELO CORRIGIDO PARA RESPOSTA COMPLETA DO CARDÁPIO
class CardapioCompleto {
  final Cardapio cardapio;
  final List<CardapioSecao> secoes;

  CardapioCompleto({required this.cardapio, required this.secoes});

  factory CardapioCompleto.fromJson(Map<String, dynamic> json) {
    return CardapioCompleto(
      cardapio: Cardapio.fromJson(json['cardapio'] ?? {}),
      secoes:
          json['secoes'] != null
              ? (json['secoes'] as List).map((secao) {
                // Processar dados da seção
                final secaoData = secao['secao'] ?? {};
                final imagensData = secao['imagens'] ?? [];
                final produtosData = secao['produtos'] ?? [];

                return CardapioSecao(
                  id: secaoData['id'] ?? 0,
                  nome: secaoData['nome']?.toString(),
                  sequencia: secaoData['sequencia'],
                  cardapioId: secaoData['cardapio_id'],
                  imagens:
                      imagensData
                          .map<CardapioSecaoImagem>(
                            (img) => CardapioSecaoImagem.fromJson(img),
                          )
                          .toList(),
                  produtos:
                      produtosData.map<ProdutoCardapio>((prod) {
                        // ✅ CORRIGIDO: Incluir imagens do produto
                        final produtoData = prod['produto'] ?? {};
                        final imagensProduto = prod['imagens'] ?? [];

                        // Criar produto base a partir dos dados
                        final produtoBase = ProdutoCardapio.fromJson(
                          produtoData,
                        );

                        // ✅ Retornar produto com imagens incluídas
                        return ProdutoCardapio(
                          id: produtoBase.id,
                          codigo: produtoBase.codigo,
                          codigoBarra: produtoBase.codigoBarra,
                          nome: produtoBase.nome,
                          nomeResumido: produtoBase.nomeResumido,
                          tipo: produtoBase.tipo,
                          subtipo: produtoBase.subtipo,
                          precoUnit: produtoBase.precoUnit,
                          unidMed: produtoBase.unidMed,
                          grupoId: produtoBase.grupoId,
                          subgrupoId: produtoBase.subgrupoId,
                          qtdMaximaComposicao: produtoBase.qtdMaximaComposicao,
                          imagens:
                              imagensProduto
                                  .map<ProdutoImagem>(
                                    (img) => ProdutoImagem.fromJson(img),
                                  )
                                  .toList(),
                        );
                      }).toList(),
                );
              }).toList()
              : [],
    );
  }
}

// Modelo para resposta paginada (compatível com API existente)
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
      items: (json['items'] as List).map((item) => fromJsonT(item)).toList(),
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      perPage: json['per_page'] ?? 10,
      totalPages: json['total_pages'] ?? 1,
    );
  }
}

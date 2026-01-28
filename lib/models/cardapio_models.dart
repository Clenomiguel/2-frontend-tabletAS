// lib/models/cardapio_models.dart
// Modelos para cardápio, seções e produtos do cardápio

import 'produto_models.dart';

/// Cardápio principal
class Cardapio {
  final int grid;
  final int? codigo;
  final String nome;
  final int empresaId;
  final int? tipo;

  Cardapio({
    required this.grid,
    this.codigo,
    required this.nome,
    required this.empresaId,
    this.tipo,
  });

  factory Cardapio.fromJson(Map<String, dynamic> json) {
    return Cardapio(
      grid: _toInt(json['grid'] ?? json['id'] ?? 0),
      codigo: json['codigo'] != null ? _toInt(json['codigo']) : null,
      nome: json['nome'] ?? '',
      empresaId: _toInt(json['empresa'] ?? json['empresa_id'] ?? 0),
      tipo: json['tipo'] != null ? _toInt(json['tipo']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'grid': grid,
      'codigo': codigo,
      'nome': nome,
      'empresa': empresaId,
      'tipo': tipo,
    };
  }
}

/// Seção do cardápio (categoria)
class CardapioSecao {
  final int grid;
  final String nome;
  final int? seq;
  final int cardapioId;
  final bool ativo;
  final int? parent;
  final bool ativarPrecoPromocao;

  CardapioSecao({
    required this.grid,
    required this.nome,
    this.seq,
    required this.cardapioId,
    this.ativo = true,
    this.parent,
    this.ativarPrecoPromocao = false,
  });

  factory CardapioSecao.fromJson(Map<String, dynamic> json) {
    return CardapioSecao(
      grid: _toInt(json['grid'] ?? json['id'] ?? 0),
      nome: json['nome'] ?? '',
      seq: json['seq'] != null ? _toInt(json['seq']) : null,
      cardapioId: _toInt(json['cardapio'] ?? json['cardapio_id'] ?? 0),
      ativo: json['ativo'] ?? true,
      parent: json['parent'] != null ? _toInt(json['parent']) : null,
      ativarPrecoPromocao: json['ativar_preco_promocao'] ?? false,
    );
  }

  /// Nome para exibição
  String get nomeExibicao => nome.isNotEmpty ? nome : 'Seção';
}

/// Imagem da seção
class SecaoImagem {
  final int grid;
  final int secaoId;
  final String? ext;
  final String? image;
  final String? ts;

  SecaoImagem({
    required this.grid,
    required this.secaoId,
    this.ext,
    this.image,
    this.ts,
  });

  factory SecaoImagem.fromJson(Map<String, dynamic> json) {
    return SecaoImagem(
      grid: _toInt(json['grid'] ?? json['id'] ?? 0),
      secaoId: _toInt(json['secao'] ?? 0),
      ext: json['ext'],
      image: json['image'],
      ts: json['ts'],
    );
  }
}

/// Composição do produto no cardápio (vínculo)
class CardapioComposicao {
  final int grid;
  final int seq;
  final int secaoId;
  final int produtoId;
  final int cardapioId;
  final bool ativo;

  CardapioComposicao({
    required this.grid,
    required this.seq,
    required this.secaoId,
    required this.produtoId,
    required this.cardapioId,
    this.ativo = true,
  });

  factory CardapioComposicao.fromJson(Map<String, dynamic> json) {
    return CardapioComposicao(
      grid: _toInt(json['grid'] ?? json['id'] ?? 0),
      seq: _toInt(json['seq'] ?? 0),
      secaoId: _toInt(json['secao'] ?? 0),
      produtoId: _toInt(json['produto'] ?? 0),
      cardapioId: _toInt(json['cardapio'] ?? 0),
      ativo: json['ativo'] ?? true,
    );
  }
}

/// Produto no cardápio (com composição e produto)
class CardapioProduto {
  final CardapioComposicao composicao;
  final Produto produto;

  CardapioProduto({
    required this.composicao,
    required this.produto,
  });

  factory CardapioProduto.fromJson(Map<String, dynamic> json) {
    return CardapioProduto(
      composicao: CardapioComposicao.fromJson(json['composicao'] ?? {}),
      produto: Produto.fromJson(json['produto'] ?? {}),
    );
  }

  // Getters de conveniência
  int get grid => composicao.grid;
  int get produtoId => produto.grid;
  int get secaoId => composicao.secaoId;
  int? get ordem => composicao.seq;
  double get preco => produto.preco;
  double get precoEfetivo => produto.preco;
}

/// Alias para compatibilidade
typedef ProdutoNoCardapio = CardapioProduto;

/// Seção completa com produtos
class CardapioSecaoCompleta {
  final CardapioSecao secao;
  final List<SecaoImagem> imagensData;
  final List<CardapioProduto> produtos;

  CardapioSecaoCompleta({
    required this.secao,
    this.imagensData = const [],
    this.produtos = const [],
  });

  factory CardapioSecaoCompleta.fromJson(Map<String, dynamic> json) {
    // Seção vem em json['secao']
    final secao = CardapioSecao.fromJson(json['secao'] ?? json);

    // Imagens
    List<SecaoImagem> imagens = [];
    if (json['imagens'] is List) {
      imagens = (json['imagens'] as List)
          .map((e) => SecaoImagem.fromJson(e))
          .toList();
    }

    // Produtos vêm como lista de {composicao, produto}
    List<CardapioProduto> produtos = [];
    if (json['produtos'] is List) {
      produtos = (json['produtos'] as List)
          .map((e) => CardapioProduto.fromJson(e))
          .toList();
    }

    return CardapioSecaoCompleta(
      secao: secao,
      imagensData: imagens,
      produtos: produtos,
    );
  }

  // Getters de conveniência
  int get grid => secao.grid;
  String get nome => secao.nome;
  int? get ordem => secao.seq;

  /// Lista de imagens (retorna lista com base64 se existir)
  List<String> get imagens {
    return imagensData
        .where((img) => img.image != null && img.image!.isNotEmpty)
        .map((img) => img.image!)
        .toList();
  }

  /// Produtos ordenados por seq
  List<CardapioProduto> get produtosOrdenados {
    final lista = List<CardapioProduto>.from(produtos);
    lista.sort((a, b) => (a.ordem ?? 0).compareTo(b.ordem ?? 0));
    return lista;
  }
}

/// Cardápio completo com seções e produtos
class CardapioCompleto {
  final Cardapio cardapio;
  final List<CardapioSecaoCompleta> secoes;

  CardapioCompleto({
    required this.cardapio,
    this.secoes = const [],
  });

  factory CardapioCompleto.fromJson(Map<String, dynamic> json) {
    // Cardápio vem em json['cardapio']
    final cardapio = Cardapio.fromJson(json['cardapio'] ?? json);

    // Seções
    List<CardapioSecaoCompleta> secoes = [];
    if (json['secoes'] is List) {
      secoes = (json['secoes'] as List)
          .map((e) => CardapioSecaoCompleta.fromJson(e))
          .toList();
    }

    return CardapioCompleto(
      cardapio: cardapio,
      secoes: secoes,
    );
  }

  // Getters de conveniência
  int get grid => cardapio.grid;
  String get nome => cardapio.nome;

  /// Seções ordenadas por seq
  List<CardapioSecaoCompleta> get secoesOrdenadas {
    final lista = List<CardapioSecaoCompleta>.from(secoes);
    lista.sort((a, b) => (a.ordem ?? 0).compareTo(b.ordem ?? 0));
    return lista;
  }

  int get totalProdutos =>
      secoes.fold(0, (sum, secao) => sum + secao.produtos.length);
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

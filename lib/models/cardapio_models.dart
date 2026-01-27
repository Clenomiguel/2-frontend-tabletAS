// lib/models/cardapio_models.dart
// Models que correspondem aos schemas de cardápio do backend FastAPI

import '../utils/parsing_utils.dart';
import 'produto_models.dart';

/// Cardápio - corresponde a CardapioResponse
class Cardapio {
  final int grid;
  final int? empresa;
  final int codigo;
  final String nome;
  final int? tipo;

  Cardapio({
    required this.grid,
    this.empresa,
    required this.codigo,
    required this.nome,
    this.tipo,
  });

  factory Cardapio.fromJson(Map<String, dynamic> json) {
    return Cardapio(
      grid: ParsingUtils.parseInt(json['grid']) ?? 0,
      empresa: ParsingUtils.parseInt(json['empresa']),
      codigo: ParsingUtils.parseInt(json['codigo']) ?? 0,
      nome: json['nome'] ?? 'Cardápio',
      tipo: ParsingUtils.parseInt(json['tipo']),
    );
  }

  Map<String, dynamic> toJson() => {
        'grid': grid,
        'empresa': empresa,
        'codigo': codigo,
        'nome': nome,
        'tipo': tipo,
      };
}

/// Seção do cardápio - corresponde a CardapioSecaoResponse
class CardapioSecao {
  final int grid;
  final String? nome;
  final int? seq;
  final int? cardapio;
  final int? parent;
  final bool ativo;
  final bool? ativarPrecoPromocao;

  CardapioSecao({
    required this.grid,
    this.nome,
    this.seq,
    this.cardapio,
    this.parent,
    this.ativo = true,
    this.ativarPrecoPromocao,
  });

  factory CardapioSecao.fromJson(Map<String, dynamic> json) {
    return CardapioSecao(
      grid: ParsingUtils.parseInt(json['grid']) ?? 0,
      nome: json['nome'],
      seq: ParsingUtils.parseInt(json['seq']),
      cardapio: ParsingUtils.parseInt(json['cardapio']),
      parent: ParsingUtils.parseInt(json['parent']),
      ativo: ParsingUtils.parseBool(json['ativo']) ?? true,
      ativarPrecoPromocao:
          ParsingUtils.parseBool(json['ativar_preco_promocao']),
    );
  }

  Map<String, dynamic> toJson() => {
        'grid': grid,
        'nome': nome,
        'seq': seq,
        'cardapio': cardapio,
        'parent': parent,
        'ativo': ativo,
        'ativar_preco_promocao': ativarPrecoPromocao,
      };

  String get nomeExibicao => nome ?? 'Seção';
  int get ordem => seq ?? 999;
}

/// Imagem da seção do cardápio
class CardapioSecaoImagem {
  final int grid;
  final int secao;
  final String? ext;
  final DateTime? ts;

  CardapioSecaoImagem({
    required this.grid,
    required this.secao,
    this.ext,
    this.ts,
  });

  factory CardapioSecaoImagem.fromJson(Map<String, dynamic> json) {
    return CardapioSecaoImagem(
      grid: ParsingUtils.parseInt(json['grid']) ?? 0,
      secao: ParsingUtils.parseInt(json['secao']) ?? 0,
      ext: json['ext'],
      ts: json['ts'] != null ? DateTime.tryParse(json['ts'].toString()) : null,
    );
  }
}

/// Composição do cardápio (produto na seção) - corresponde a CardapioComposicaoResponse
class CardapioComposicao {
  final int grid;
  final int seq;
  final int secao;
  final int produto;
  final bool ativo;
  final int? cardapio;
  final double? ifood;
  final double? ifoodPromocao;

  CardapioComposicao({
    required this.grid,
    required this.seq,
    required this.secao,
    required this.produto,
    this.ativo = true,
    this.cardapio,
    this.ifood,
    this.ifoodPromocao,
  });

  factory CardapioComposicao.fromJson(Map<String, dynamic> json) {
    return CardapioComposicao(
      grid: ParsingUtils.parseInt(json['grid']) ?? 0,
      seq: ParsingUtils.parseInt(json['seq']) ?? 0,
      secao: ParsingUtils.parseInt(json['secao']) ?? 0,
      produto: ParsingUtils.parseInt(json['produto']) ?? 0,
      ativo: ParsingUtils.parseBool(json['ativo']) ?? true,
      cardapio: ParsingUtils.parseInt(json['cardapio']),
      ifood: ParsingUtils.parseDouble(json['ifood']),
      ifoodPromocao: ParsingUtils.parseDouble(json['ifood_promocao']),
    );
  }
}

/// Produto na composição do cardápio (com dados do produto)
class ProdutoNoCardapio {
  final CardapioComposicao composicao;
  final Produto produto;

  ProdutoNoCardapio({
    required this.composicao,
    required this.produto,
  });

  factory ProdutoNoCardapio.fromJson(Map<String, dynamic> json) {
    return ProdutoNoCardapio(
      composicao: CardapioComposicao.fromJson(json['composicao'] ?? {}),
      produto: Produto.fromJson(json['produto'] ?? {}),
    );
  }

  // Atalhos para facilitar acesso
  int get id => produto.grid;
  String get nome => produto.nomeExibicao;
  double get preco => composicao.ifood ?? produto.precoUnit ?? 0.0;
  double? get precoPromocao => composicao.ifoodPromocao;
  String get precoFormatado =>
      'R\$ ${preco.toStringAsFixed(2).replaceAll('.', ',')}';

  bool get temPromocao => precoPromocao != null && precoPromocao! < preco;
  String get precoPromocaoFormatado => temPromocao
      ? 'R\$ ${precoPromocao!.toStringAsFixed(2).replaceAll('.', ',')}'
      : precoFormatado;
}

/// Seção completa com imagens e produtos
class SecaoCompleta {
  final CardapioSecao secao;
  final List<CardapioSecaoImagem> imagens;
  final List<ProdutoNoCardapio> produtos;

  SecaoCompleta({
    required this.secao,
    this.imagens = const [],
    this.produtos = const [],
  });

  factory SecaoCompleta.fromJson(Map<String, dynamic> json) {
    return SecaoCompleta(
      secao: CardapioSecao.fromJson(json['secao'] ?? {}),
      imagens: (json['imagens'] as List? ?? [])
          .map((e) => CardapioSecaoImagem.fromJson(e))
          .toList(),
      produtos: (json['produtos'] as List? ?? [])
          .map((e) => ProdutoNoCardapio.fromJson(e))
          .toList(),
    );
  }

  String get nome => secao.nomeExibicao;
  int get ordem => secao.ordem;
  bool get temImagem => imagens.isNotEmpty;
  bool get temProdutos => produtos.isNotEmpty;
}

/// Cardápio completo com todas as seções
class CardapioCompleto {
  final Cardapio cardapio;
  final List<SecaoCompleta> secoes;

  CardapioCompleto({
    required this.cardapio,
    required this.secoes,
  });

  factory CardapioCompleto.fromJson(Map<String, dynamic> json) {
    final secoesRaw = json['secoes'] as List? ?? [];
    final secoesParsed =
        secoesRaw.map((e) => SecaoCompleta.fromJson(e)).toList();

    // Ordenar por sequência
    secoesParsed.sort((a, b) => a.ordem.compareTo(b.ordem));

    return CardapioCompleto(
      cardapio: Cardapio.fromJson(json['cardapio'] ?? {}),
      secoes: secoesParsed,
    );
  }

  String get nome => cardapio.nome;
  int get totalProdutos => secoes.fold(0, (sum, s) => sum + s.produtos.length);
  bool get isEmpty => secoes.isEmpty;
  bool get isNotEmpty => secoes.isNotEmpty;

  /// Seções ordenadas por sequência (já ordenadas no fromJson)
  List<SecaoCompleta> get secoesOrdenadas => secoes;

  /// Seções ativas ordenadas
  List<SecaoCompleta> get secoesAtivas =>
      secoes.where((s) => s.secao.ativo).toList();
}

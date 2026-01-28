// lib/models/cardapio_models.dart
// Modelos para cardápio, seções e produtos do cardápio

import 'produto_models.dart';

/// Cardápio principal
class Cardapio {
  final int grid;
  final String nome;
  final String? descricao;
  final int empresaId;
  final bool ativo;
  final int? ordem;
  final String? horaInicio;
  final String? horaFim;
  final List<int>? diasSemana;

  Cardapio({
    required this.grid,
    required this.nome,
    this.descricao,
    required this.empresaId,
    this.ativo = true,
    this.ordem,
    this.horaInicio,
    this.horaFim,
    this.diasSemana,
  });

  factory Cardapio.fromJson(Map<String, dynamic> json) {
    List<int>? diasSemana;
    if (json['dias_semana'] is List) {
      diasSemana = (json['dias_semana'] as List).map((e) => _toInt(e)).toList();
    }

    return Cardapio(
      grid: _toInt(json['grid'] ?? json['id'] ?? 0),
      nome: json['nome'] ?? '',
      descricao: json['descricao'],
      empresaId: _toInt(json['empresa_id'] ?? json['empresa'] ?? 0),
      ativo:
          json['ativo'] ?? json['situacao'] == 'A' || json['situacao'] == true,
      ordem: json['ordem'] != null ? _toInt(json['ordem']) : null,
      horaInicio: json['hora_inicio'],
      horaFim: json['hora_fim'],
      diasSemana: diasSemana,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'grid': grid,
      'nome': nome,
      'descricao': descricao,
      'empresa_id': empresaId,
      'ativo': ativo,
      'ordem': ordem,
      'hora_inicio': horaInicio,
      'hora_fim': horaFim,
      'dias_semana': diasSemana,
    };
  }

  bool get isDisponivelAgora {
    if (!ativo) return false;

    final agora = DateTime.now();

    if (diasSemana != null && diasSemana!.isNotEmpty) {
      if (!diasSemana!.contains(agora.weekday % 7)) {
        return false;
      }
    }

    if (horaInicio != null && horaFim != null) {
      final inicio = _parseTime(horaInicio!);
      final fim = _parseTime(horaFim!);
      final agoraMinutos = agora.hour * 60 + agora.minute;

      if (fim > inicio) {
        if (agoraMinutos < inicio || agoraMinutos > fim) {
          return false;
        }
      } else {
        if (agoraMinutos < inicio && agoraMinutos > fim) {
          return false;
        }
      }
    }

    return true;
  }

  int _parseTime(String time) {
    final parts = time.split(':');
    if (parts.length >= 2) {
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    }
    return 0;
  }
}

/// Seção do cardápio (categoria)
class CardapioSecao {
  final int grid;
  final int cardapioId;
  final String nome;
  final String? descricao;
  final int? ordem;
  final bool ativo;
  final String? imagemBase64;
  final String? cor;

  CardapioSecao({
    required this.grid,
    required this.cardapioId,
    required this.nome,
    this.descricao,
    this.ordem,
    this.ativo = true,
    this.imagemBase64,
    this.cor,
  });

  factory CardapioSecao.fromJson(Map<String, dynamic> json) {
    return CardapioSecao(
      grid: _toInt(json['grid'] ?? json['id'] ?? 0),
      cardapioId: _toInt(json['cardapio_id'] ?? json['cardapio'] ?? 0),
      nome: json['nome'] ?? '',
      descricao: json['descricao'],
      ordem: json['ordem'] != null ? _toInt(json['ordem']) : null,
      ativo: json['ativo'] ?? true,
      imagemBase64: json['imagem'] ?? json['foto'],
      cor: json['cor'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'grid': grid,
      'cardapio_id': cardapioId,
      'nome': nome,
      'descricao': descricao,
      'ordem': ordem,
      'ativo': ativo,
      'cor': cor,
    };
  }
}

/// Produto do cardápio (vinculação produto-seção)
class CardapioProduto {
  final int grid;
  final int secaoId;
  final int produtoId;
  final int? ordem;
  final bool destaque;
  final double? precoCardapio;
  final Produto? produto;

  CardapioProduto({
    required this.grid,
    required this.secaoId,
    required this.produtoId,
    this.ordem,
    this.destaque = false,
    this.precoCardapio,
    this.produto,
  });

  factory CardapioProduto.fromJson(Map<String, dynamic> json) {
    Produto? produto;
    if (json['produto'] is Map) {
      produto = Produto.fromJson(json['produto']);
    }

    return CardapioProduto(
      grid: _toInt(json['grid'] ?? json['id'] ?? 0),
      secaoId: _toInt(json['secao_id'] ?? json['secao'] ?? 0),
      produtoId: _toInt(json['produto_id'] ??
          json['produto_grid'] ??
          (json['produto'] is Map ? json['produto']['grid'] : 0)),
      ordem: json['ordem'] != null ? _toInt(json['ordem']) : null,
      destaque: json['destaque'] ?? false,
      precoCardapio: json['preco_cardapio'] != null
          ? _toDouble(json['preco_cardapio'])
          : null,
      produto: produto,
    );
  }

  double get precoEfetivo => precoCardapio ?? produto?.preco ?? 0;
}

/// Alias para compatibilidade
typedef ProdutoNoCardapio = CardapioProduto;

/// Seção completa com produtos
class CardapioSecaoCompleta {
  final CardapioSecao secao;
  final List<CardapioProduto> produtos;

  CardapioSecaoCompleta({
    required this.secao,
    this.produtos = const [],
  });

  factory CardapioSecaoCompleta.fromJson(Map<String, dynamic> json) {
    final secao = CardapioSecao.fromJson(json);

    List<CardapioProduto> produtos = [];
    if (json['produtos'] is List) {
      produtos = (json['produtos'] as List)
          .map((e) => CardapioProduto.fromJson(e))
          .toList();
    } else if (json['items'] is List) {
      produtos = (json['items'] as List)
          .map((e) => CardapioProduto.fromJson(e))
          .toList();
    }

    return CardapioSecaoCompleta(
      secao: secao,
      produtos: produtos,
    );
  }

  int get grid => secao.grid;
  String get nome => secao.nome;
  String? get descricao => secao.descricao;
  String? get imagemBase64 => secao.imagemBase64;
  int? get ordem => secao.ordem;

  /// Produtos ordenados
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
    final cardapio = Cardapio.fromJson(json);

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

  int get grid => cardapio.grid;
  String get nome => cardapio.nome;
  String? get descricao => cardapio.descricao;
  bool get ativo => cardapio.ativo;

  /// Seções ordenadas por ordem
  List<CardapioSecaoCompleta> get secoesOrdenadas {
    final lista = List<CardapioSecaoCompleta>.from(secoes);
    lista.sort((a, b) => (a.ordem ?? 0).compareTo(b.ordem ?? 0));
    return lista;
  }

  int get totalProdutos =>
      secoes.fold(0, (sum, secao) => sum + secao.produtos.length);

  List<CardapioProduto> get todosProdutos =>
      secoes.expand((secao) => secao.produtos).toList();

  CardapioSecaoCompleta? getSecao(int secaoId) {
    try {
      return secoes.firstWhere((s) => s.grid == secaoId);
    } catch (e) {
      return null;
    }
  }

  CardapioProduto? getProduto(int produtoId) {
    for (final secao in secoes) {
      try {
        return secao.produtos.firstWhere((p) => p.produtoId == produtoId);
      } catch (e) {
        continue;
      }
    }
    return null;
  }
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

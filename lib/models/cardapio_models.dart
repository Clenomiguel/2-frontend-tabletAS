// lib/models/cardapio_models.dart

class CardapioCompletoResponse {
  final Cardapio cardapio;
  final List<SecaoCompleta> secoes;

  CardapioCompletoResponse({required this.cardapio, required this.secoes});

  factory CardapioCompletoResponse.fromJson(Map<String, dynamic> json) {
    return CardapioCompletoResponse(
      cardapio: Cardapio.fromJson(json['cardapio']),
      secoes:
          (json['secoes'] as List)
              .map((e) => SecaoCompleta.fromJson(e))
              .toList(),
    );
  }
}

class SecaoCompleta {
  final CardapioSecao secao;
  final List<CardapioSecaoImagem> imagens;
  final List<ProdutoComposto> produtos;

  SecaoCompleta({
    required this.secao,
    required this.imagens,
    required this.produtos,
  });

  factory SecaoCompleta.fromJson(Map<String, dynamic> json) {
    return SecaoCompleta(
      secao: CardapioSecao.fromJson(json['secao']),
      imagens:
          (json['imagens'] as List? ?? [])
              .map((e) => CardapioSecaoImagem.fromJson(e))
              .toList(),
      produtos:
          (json['produtos'] as List? ?? [])
              .map((e) => ProdutoComposto.fromJson(e))
              .toList(),
    );
  }
}

// Representa o objeto { "composicao": {...}, "produto": {...} }
class ProdutoComposto {
  final int id;
  final String nome;
  final String? descricao;
  final double preco;
  final String? imagemUrl;
  final String? unidade;

  ProdutoComposto({
    required this.id,
    required this.nome,
    this.descricao,
    required this.preco,
    this.imagemUrl,
    this.unidade,
  });

  factory ProdutoComposto.fromJson(Map<String, dynamic> json) {
    final prod = json['produto'] ?? {};
    final comp = json['composicao'] ?? {};

    // Tenta pegar o nome reduzido, se não, pega o nome completo
    final nomeFinal =
        prod['nome_reduzido'] != null &&
                prod['nome_reduzido'].toString().isNotEmpty
            ? prod['nome_reduzido']
            : (prod['nome'] ?? 'Produto sem nome');

    // Descrição: tenta descricao_delivery, senao aplicacao, senao vazio
    final descFinal = prod['descricao_delivery'] ?? prod['aplicacao'];

    // Preço vem da composição
    final precoFinal =
        double.tryParse(comp['preco_venda']?.toString() ?? '0') ?? 0.0;

    return ProdutoComposto(
      id: prod['grid'] ?? 0,
      nome: nomeFinal,
      descricao: descFinal,
      preco: precoFinal,
      unidade: prod['unid_med'],
      // Se futuramente o produto tiver imagem no backend, mapeie aqui
      imagemUrl: null,
    );
  }
}

class Cardapio {
  final int id; // grid no banco
  final String nome; // descricao no banco

  Cardapio({required this.id, required this.nome});

  factory Cardapio.fromJson(Map<String, dynamic> json) {
    return Cardapio(
      id: json['grid'] ?? 0,
      nome: json['descricao'] ?? 'Cardápio Digital',
    );
  }
}

class CardapioSecao {
  final int id;
  final String nome;
  final int ordem;

  CardapioSecao({required this.id, required this.nome, required this.ordem});

  factory CardapioSecao.fromJson(Map<String, dynamic> json) {
    return CardapioSecao(
      id: json['grid'] ?? 0,
      nome: json['nome'] ?? 'Seção',
      ordem: json['ordem'] ?? 999,
    );
  }
}

class CardapioSecaoImagem {
  final int id;
  final String caminho;
  final String? descricao;

  CardapioSecaoImagem({
    required this.id,
    required this.caminho,
    this.descricao,
  });

  factory CardapioSecaoImagem.fromJson(Map<String, dynamic> json) {
    return CardapioSecaoImagem(
      id: json['grid'] ?? 0,
      caminho: json['caminho'] ?? '',
      descricao: json['descricao'],
    );
  }
}

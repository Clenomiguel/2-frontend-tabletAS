// lib/models/cart_models.dart
// Modelos para carrinho de compras

import 'produto_models.dart';

/// Status da comanda
enum ComandaStatus {
  pendente,
  enviando,
  confirmada,
  erro,
}

/// Item do carrinho
class CartItem {
  final String id;
  final Produto produto;
  final double precoUnitario;
  int quantidade;
  final Preparo? preparo;
  final List<ProdutoComposicao> composicoesRemovidas;
  final List<ComplementoSelecionado> complementos;
  final String? observacao;

  CartItem({
    required this.id,
    required this.produto,
    required this.precoUnitario,
    this.quantidade = 1,
    this.preparo,
    this.composicoesRemovidas = const [],
    this.complementos = const [],
    this.observacao,
  });

  /// Preço total do item (unitário + complementos) * quantidade
  double get precoTotal {
    double precoComplementos = complementos.fold(
      0.0,
      (sum, c) => sum + (c.preco * c.quantidade),
    );
    return (precoUnitario + precoComplementos) * quantidade;
  }

  /// Descrição da personalização para exibição
  String get descricaoPersonalizacao {
    final partes = <String>[];

    if (preparo != null && preparo!.descricao != null) {
      partes.add(preparo!.descricao!);
    }

    if (composicoesRemovidas.isNotEmpty) {
      final removidos = composicoesRemovidas
          .map((c) => c.materiaPrimaNome ?? 'Item')
          .join(', ');
      partes.add('Sem: $removidos');
    }

    if (complementos.isNotEmpty) {
      final comps = complementos.map((c) {
        if (c.quantidade > 1) {
          return '${c.quantidade}x ${c.nome}';
        }
        return c.nome;
      }).join(', ');
      partes.add('Com: $comps');
    }

    if (observacao != null && observacao!.isNotEmpty) {
      partes.add('Obs: $observacao');
    }

    return partes.join(' • ');
  }

  /// Cria cópia do item
  CartItem copyWith({
    String? id,
    Produto? produto,
    double? precoUnitario,
    int? quantidade,
    Preparo? preparo,
    List<ProdutoComposicao>? composicoesRemovidas,
    List<ComplementoSelecionado>? complementos,
    String? observacao,
  }) {
    return CartItem(
      id: id ?? this.id,
      produto: produto ?? this.produto,
      precoUnitario: precoUnitario ?? this.precoUnitario,
      quantidade: quantidade ?? this.quantidade,
      preparo: preparo ?? this.preparo,
      composicoesRemovidas: composicoesRemovidas ?? this.composicoesRemovidas,
      complementos: complementos ?? this.complementos,
      observacao: observacao ?? this.observacao,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'produto': produto.toJson(),
      'preco_unitario': precoUnitario,
      'quantidade': quantidade,
      'preparo': preparo?.toJson(),
      'composicoes_removidas':
          composicoesRemovidas.map((c) => c.toJson()).toList(),
      'complementos': complementos.map((c) => c.toJson()).toList(),
      'observacao': observacao,
    };
  }
}

/// Complemento selecionado pelo usuário
class ComplementoSelecionado {
  final int produtoGrid;
  final int complementoGrid;
  final String nome;
  final int quantidade;
  final double preco;

  ComplementoSelecionado({
    required this.produtoGrid,
    required this.complementoGrid,
    required this.nome,
    this.quantidade = 1,
    this.preco = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'produto_grid': produtoGrid,
      'complemento_grid': complementoGrid,
      'nome': nome,
      'quantidade': quantidade,
      'preco': preco,
    };
  }

  factory ComplementoSelecionado.fromJson(Map<String, dynamic> json) {
    return ComplementoSelecionado(
      produtoGrid: _toInt(json['produto_grid'] ?? json['produtoGrid'] ?? 0),
      complementoGrid:
          _toInt(json['complemento_grid'] ?? json['complementoGrid'] ?? 0),
      nome: json['nome'] ?? '',
      quantidade: _toInt(json['quantidade'] ?? 1),
      preco: _toDouble(json['preco'] ?? 0.0),
    );
  }
}

/// Carrinho de compras
class Cart {
  final List<CartItem> items;
  final int? mesa;
  final String? clienteNome;
  final String? clienteCpf;

  Cart({
    this.items = const [],
    this.mesa,
    this.clienteNome,
    this.clienteCpf,
  });

  /// Total do carrinho
  double get total => items.fold(0.0, (sum, item) => sum + item.precoTotal);

  /// Quantidade total de itens
  int get quantidadeTotal =>
      items.fold(0, (sum, item) => sum + item.quantidade);

  /// Verifica se está vazio
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  /// Adiciona item ao carrinho
  Cart addItem(CartItem item) {
    return copyWith(items: [...items, item]);
  }

  /// Remove item do carrinho pelo ID
  Cart removeItem(String itemId) {
    return copyWith(items: items.where((i) => i.id != itemId).toList());
  }

  /// Atualiza um item existente
  Cart updateItem(String itemId, CartItem newItem) {
    return copyWith(
      items: items.map((i) => i.id == itemId ? newItem : i).toList(),
    );
  }

  /// Define mesa
  Cart setMesa(int? mesa) {
    return copyWith(mesa: mesa);
  }

  /// Define dados do cliente
  Cart setCliente({String? nome, String? cpf}) {
    return Cart(
      items: items,
      mesa: mesa,
      clienteNome: nome ?? clienteNome,
      clienteCpf: cpf ?? clienteCpf,
    );
  }

  /// Limpa o carrinho
  Cart clear() {
    return Cart(mesa: mesa, clienteNome: clienteNome, clienteCpf: clienteCpf);
  }

  Cart copyWith({
    List<CartItem>? items,
    int? mesa,
    String? clienteNome,
    String? clienteCpf,
  }) {
    return Cart(
      items: items ?? this.items,
      mesa: mesa ?? this.mesa,
      clienteNome: clienteNome ?? this.clienteNome,
      clienteCpf: clienteCpf ?? this.clienteCpf,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((i) => i.toJson()).toList(),
      'mesa': mesa,
      'cliente_nome': clienteNome,
      'cliente_cpf': clienteCpf,
      'total': total,
    };
  }
}

/// Resposta da criação de comanda
class ComandaResponse {
  final bool success;
  final String? comandaId;
  final String? message;
  final String? error;

  ComandaResponse({
    required this.success,
    this.comandaId,
    this.message,
    this.error,
  });

  factory ComandaResponse.fromJson(Map<String, dynamic> json) {
    return ComandaResponse(
      success: json['success'] ?? false,
      comandaId: json['comanda_id']?.toString() ?? json['comanda']?.toString(),
      message: json['message'],
      error: json['error'] ?? json['detail'],
    );
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

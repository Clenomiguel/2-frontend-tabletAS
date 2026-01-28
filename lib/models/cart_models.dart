// lib/models/cart_models.dart
// Modelos para carrinho de compras e pedidos

import 'produto_models.dart';

/// Item do carrinho
class CartItem {
  final Produto produto;
  int quantidade;
  final double precoUnitario;
  String? observacao;
  Preparo? preparo;
  List<ComplementoSelecionado> complementos;
  List<ComposicaoRemovida> composicoesRemovidas;
  final String id;

  CartItem({
    required this.produto,
    this.quantidade = 1,
    double? precoUnitario,
    this.observacao,
    this.preparo,
    List<ComplementoSelecionado>? complementos,
    List<ComposicaoRemovida>? composicoesRemovidas,
    String? id,
  })  : precoUnitario = precoUnitario ?? produto.preco,
        complementos = complementos ?? [],
        composicoesRemovidas = composicoesRemovidas ?? [],
        id = id ?? '${produto.grid}_${DateTime.now().millisecondsSinceEpoch}';

  /// Preço total do item (produto + complementos) * quantidade
  double get precoTotal {
    double precoComplementos = complementos.fold(
      0.0,
      (sum, c) => sum + (c.preco * c.quantidade),
    );
    return (precoUnitario + precoComplementos) * quantidade;
  }

  /// Descrição resumida dos complementos
  String get complementosDescricao {
    if (complementos.isEmpty) return '';
    return complementos.map((c) => c.nome).join(', ');
  }

  /// Descrição resumida das remoções
  String get removidosDescricao {
    if (composicoesRemovidas.isEmpty) return '';
    return 'Sem: ${composicoesRemovidas.map((c) => c.nome).join(', ')}';
  }

  /// Descrição completa da personalização do item
  String get descricaoPersonalizacao {
    final partes = <String>[];

    if (preparo != null) {
      partes.add(preparo!.nome);
    }

    if (complementos.isNotEmpty) {
      partes.add('+ ${complementos.map((c) => c.nome).join(', ')}');
    }

    if (composicoesRemovidas.isNotEmpty) {
      partes.add('Sem: ${composicoesRemovidas.map((c) => c.nome).join(', ')}');
    }

    if (observacao != null && observacao!.isNotEmpty) {
      partes.add('Obs: $observacao');
    }

    return partes.join(' | ');
  }

  /// Cria cópia do item
  CartItem copyWith({
    Produto? produto,
    int? quantidade,
    double? precoUnitario,
    String? observacao,
    Preparo? preparo,
    List<ComplementoSelecionado>? complementos,
    List<ComposicaoRemovida>? composicoesRemovidas,
  }) {
    return CartItem(
      produto: produto ?? this.produto,
      quantidade: quantidade ?? this.quantidade,
      precoUnitario: precoUnitario ?? this.precoUnitario,
      observacao: observacao ?? this.observacao,
      preparo: preparo ?? this.preparo,
      complementos: complementos ?? List.from(this.complementos),
      composicoesRemovidas:
          composicoesRemovidas ?? List.from(this.composicoesRemovidas),
      id: id,
    );
  }
}

/// Complemento selecionado no carrinho
class ComplementoSelecionado {
  final int produtoGrid;
  final String nome;
  final double preco;
  int quantidade;

  ComplementoSelecionado({
    required this.produtoGrid,
    required this.nome,
    required this.preco,
    this.quantidade = 1,
  });

  factory ComplementoSelecionado.fromComplemento(ProdutoComplemento comp) {
    return ComplementoSelecionado(
      produtoGrid: comp.complementoGrid,
      nome: comp.nome ?? 'Complemento',
      preco: comp.preco,
      quantidade: 1,
    );
  }
}

/// Item da composição que foi removido
class ComposicaoRemovida {
  final int materiaPrima;
  final String nome;

  ComposicaoRemovida({
    required this.materiaPrima,
    required this.nome,
  });

  factory ComposicaoRemovida.fromComposicao(ProdutoComposicao comp) {
    return ComposicaoRemovida(
      materiaPrima: comp.materiaPrima,
      nome: comp.nome ?? 'Ingrediente',
    );
  }
}

/// Carrinho de compras
class Cart {
  final List<CartItem> items;
  int? mesa;
  String? clienteNome;
  String? clienteCpf;
  String? observacaoGeral;

  Cart({
    List<CartItem>? items,
    this.mesa,
    this.clienteNome,
    this.clienteCpf,
    this.observacaoGeral,
  }) : items = items ?? [];

  int get totalItens => items.fold(0, (sum, item) => sum + item.quantidade);

  double get valorTotal =>
      items.fold(0.0, (sum, item) => sum + item.precoTotal);

  bool get isEmpty => items.isEmpty;

  bool get isNotEmpty => items.isNotEmpty;

  void addItem(CartItem item) {
    final existingIndex = items.indexWhere((i) =>
        i.produto.grid == item.produto.grid &&
        i.preparo?.grid == item.preparo?.grid &&
        _complementosIguais(i.complementos, item.complementos) &&
        _removidosIguais(i.composicoesRemovidas, item.composicoesRemovidas));

    if (existingIndex >= 0) {
      items[existingIndex].quantidade += item.quantidade;
    } else {
      items.add(item);
    }
  }

  void removeItem(String itemId) {
    items.removeWhere((item) => item.id == itemId);
  }

  void removeItemAt(int index) {
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
    }
  }

  void updateQuantidade(String itemId, int novaQuantidade) {
    final index = items.indexWhere((item) => item.id == itemId);
    if (index >= 0) {
      if (novaQuantidade <= 0) {
        items.removeAt(index);
      } else {
        items[index].quantidade = novaQuantidade;
      }
    }
  }

  void incrementItem(String itemId) {
    final index = items.indexWhere((item) => item.id == itemId);
    if (index >= 0) {
      items[index].quantidade++;
    }
  }

  void decrementItem(String itemId) {
    final index = items.indexWhere((item) => item.id == itemId);
    if (index >= 0) {
      if (items[index].quantidade > 1) {
        items[index].quantidade--;
      } else {
        items.removeAt(index);
      }
    }
  }

  void clear() {
    items.clear();
    mesa = null;
    clienteNome = null;
    clienteCpf = null;
    observacaoGeral = null;
  }

  bool _complementosIguais(
    List<ComplementoSelecionado> a,
    List<ComplementoSelecionado> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].produtoGrid != b[i].produtoGrid) return false;
    }
    return true;
  }

  bool _removidosIguais(
    List<ComposicaoRemovida> a,
    List<ComposicaoRemovida> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].materiaPrima != b[i].materiaPrima) return false;
    }
    return true;
  }

  Cart copyWith({
    List<CartItem>? items,
    int? mesa,
    String? clienteNome,
    String? clienteCpf,
    String? observacaoGeral,
  }) {
    return Cart(
      items: items ?? this.items.map((i) => i.copyWith()).toList(),
      mesa: mesa ?? this.mesa,
      clienteNome: clienteNome ?? this.clienteNome,
      clienteCpf: clienteCpf ?? this.clienteCpf,
      observacaoGeral: observacaoGeral ?? this.observacaoGeral,
    );
  }
}

/// Resposta do registro de comanda
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
      success: json['success'] ?? true,
      comandaId: json['comanda_id']?.toString() ?? json['id']?.toString(),
      message: json['message'],
      error: json['error'] ?? json['detail'],
    );
  }
}

/// Estado do pedido
enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  delivered,
  cancelled,
}

extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pendente';
      case OrderStatus.confirmed:
        return 'Confirmado';
      case OrderStatus.preparing:
        return 'Em Preparo';
      case OrderStatus.ready:
        return 'Pronto';
      case OrderStatus.delivered:
        return 'Entregue';
      case OrderStatus.cancelled:
        return 'Cancelado';
    }
  }

  String get icon {
    switch (this) {
      case OrderStatus.pending:
        return '⏳';
      case OrderStatus.confirmed:
        return '✅';
      case OrderStatus.preparing:
        return '👨‍🍳';
      case OrderStatus.ready:
        return '🔔';
      case OrderStatus.delivered:
        return '✓';
      case OrderStatus.cancelled:
        return '❌';
    }
  }
}

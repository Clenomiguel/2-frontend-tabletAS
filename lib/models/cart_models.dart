// lib/models/cart_models.dart
// Modelos para carrinho e registro de comanda no Linx

import '../utils/parsing_utils.dart';
import 'produto_models.dart';

/// Item do carrinho com personalizações
class CartItem {
  final String id; // UUID local para identificação
  final Produto produto;
  final double precoUnitario;
  final int quantidade;
  final ProdutoPreparo? preparo;
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

  /// Preço total do item (unitário * quantidade + complementos)
  double get precoTotal {
    double total = precoUnitario * quantidade;
    for (final comp in complementos) {
      total += (comp.precoUnitario ?? 0) * comp.quantidade;
    }
    return total;
  }

  /// Descrição resumida das personalizações
  String get descricaoPersonalizacao {
    final partes = <String>[];
    
    if (preparo != null && preparo!.descricao != null) {
      partes.add(preparo!.descricao!);
    }
    
    if (composicoesRemovidas.isNotEmpty) {
      final removidos = composicoesRemovidas
          .map((c) => 'Sem ${c.materiaPrimaNome ?? c.materiaPrima}')
          .join(', ');
      partes.add(removidos);
    }
    
    if (complementos.isNotEmpty) {
      final comps = complementos
          .map((c) => '${c.quantidade}x ${c.nome}')
          .join(', ');
      partes.add(comps);
    }
    
    if (observacao != null && observacao!.isNotEmpty) {
      partes.add('Obs: $observacao');
    }
    
    return partes.join(' | ');
  }

  /// Cria cópia com alterações
  CartItem copyWith({
    int? quantidade,
    ProdutoPreparo? preparo,
    List<ProdutoComposicao>? composicoesRemovidas,
    List<ComplementoSelecionado>? complementos,
    String? observacao,
  }) {
    return CartItem(
      id: id,
      produto: produto,
      precoUnitario: precoUnitario,
      quantidade: quantidade ?? this.quantidade,
      preparo: preparo ?? this.preparo,
      composicoesRemovidas: composicoesRemovidas ?? this.composicoesRemovidas,
      complementos: complementos ?? this.complementos,
      observacao: observacao ?? this.observacao,
    );
  }

  /// Converte para formato do backend (item da comanda)
  Map<String, dynamic> toComandaItem() {
    return {
      'produto_grid': produto.grid,
      'quantidade': quantidade,
      'preco_unitario': precoUnitario,
      'preparo_grid': preparo?.grid,
      'composicoes_removidas': composicoesRemovidas.map((c) => c.grid).toList(),
      'complementos': complementos.map((c) => c.toJson()).toList(),
      'observacao': observacao,
    };
  }
}

/// Complemento selecionado pelo cliente
class ComplementoSelecionado {
  final int produtoGrid;
  final String nome;
  final int quantidade;
  final double? precoUnitario;

  ComplementoSelecionado({
    required this.produtoGrid,
    required this.nome,
    this.quantidade = 1,
    this.precoUnitario,
  });

  Map<String, dynamic> toJson() => {
    'produto_grid': produtoGrid,
    'quantidade': quantidade,
  };
}

/// Carrinho de compras local
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
  double get total => items.fold(0, (sum, item) => sum + item.precoTotal);

  /// Quantidade total de itens
  int get quantidadeTotal => items.fold(0, (sum, item) => sum + item.quantidade);

  /// Verifica se está vazio
  bool get isEmpty => items.isEmpty;

  /// Verifica se tem itens
  bool get isNotEmpty => items.isNotEmpty;

  /// Adiciona item
  Cart addItem(CartItem item) {
    return Cart(
      items: [...items, item],
      mesa: mesa,
      clienteNome: clienteNome,
      clienteCpf: clienteCpf,
    );
  }

  /// Remove item por ID
  Cart removeItem(String itemId) {
    return Cart(
      items: items.where((i) => i.id != itemId).toList(),
      mesa: mesa,
      clienteNome: clienteNome,
      clienteCpf: clienteCpf,
    );
  }

  /// Atualiza item
  Cart updateItem(String itemId, CartItem newItem) {
    return Cart(
      items: items.map((i) => i.id == itemId ? newItem : i).toList(),
      mesa: mesa,
      clienteNome: clienteNome,
      clienteCpf: clienteCpf,
    );
  }

  /// Limpa carrinho
  Cart clear() {
    return Cart(
      mesa: mesa,
      clienteNome: clienteNome,
      clienteCpf: clienteCpf,
    );
  }

  /// Define mesa
  Cart setMesa(int? mesa) {
    return Cart(
      items: items,
      mesa: mesa,
      clienteNome: clienteNome,
      clienteCpf: clienteCpf,
    );
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

  /// Converte para payload de registro de comanda
  Map<String, dynamic> toComandaPayload({
    required int totemId,
    required int empresaId,
  }) {
    return {
      'totem_id': totemId,
      'empresa_id': empresaId,
      'mesa': mesa,
      'cliente_nome': clienteNome,
      'cliente_cpf': clienteCpf,
      'itens': items.map((i) => i.toComandaItem()).toList(),
    };
  }
}

/// Resposta do registro de comanda
class ComandaResponse {
  final bool success;
  final String? comandaId;
  final String? message;
  final String? error;
  final Map<String, dynamic>? linxResponse;

  ComandaResponse({
    required this.success,
    this.comandaId,
    this.message,
    this.error,
    this.linxResponse,
  });

  factory ComandaResponse.fromJson(Map<String, dynamic> json) {
    return ComandaResponse(
      success: ParsingUtils.parseBool(json['success']) ?? false,
      comandaId: json['comanda_id']?.toString(),
      message: json['message'],
      error: json['error'],
      linxResponse: json['linx_response'],
    );
  }
}

/// Status da comanda
enum ComandaStatus {
  pendente,
  enviando,
  confirmada,
  erro,
}

/// Comanda registrada (histórico local)
class ComandaRegistrada {
  final String id;
  final DateTime dataHora;
  final double total;
  final int quantidadeItens;
  final int? mesa;
  final ComandaStatus status;
  final String? linxId;

  ComandaRegistrada({
    required this.id,
    required this.dataHora,
    required this.total,
    required this.quantidadeItens,
    this.mesa,
    this.status = ComandaStatus.pendente,
    this.linxId,
  });
}

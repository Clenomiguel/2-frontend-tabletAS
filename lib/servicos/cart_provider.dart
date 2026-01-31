// lib/services/cart_provider.dart
// Gerenciamento de estado do carrinho usando ChangeNotifier

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../modelos/cart_models.dart';
import '../modelos/produto_models.dart';
import 'api_service.dart';

/// Provider para gerenciamento do carrinho
class CartProvider extends ChangeNotifier {
  Cart _cart = Cart();
  ComandaStatus _status = ComandaStatus.pendente;
  String? _errorMessage;
  bool _isLoading = false;

  final _uuid = const Uuid();

  // Getters
  Cart get cart => _cart;
  List<CartItem> get items => _cart.items;
  double get total => _cart.total;
  int get quantidadeTotal => _cart.quantidadeTotal;
  bool get isEmpty => _cart.isEmpty;
  bool get isNotEmpty => _cart.isNotEmpty;

  // Getter de comanda
  String? get comanda => _cart.comanda;

  ComandaStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  /// Adiciona item ao carrinho
  void addItem({
    required Produto produto,
    required double precoUnitario,
    int quantidade = 1,
    Preparo? preparo, // Usa Preparo (não ProdutoPreparo)
    List<ProdutoComposicao>? composicoesRemovidas,
    List<ComplementoSelecionado>? complementos,
    String? observacao,
  }) {
    // Debug: verificar dados do produto recebido
    print('🛒 CartProvider.addItem:');
    print('   - produto.grid: ${produto.grid}');
    print('   - produto.nome: "${produto.nome}"');
    print('   - produto.nomeExibicao: "${produto.nomeExibicao}"');
    print('   - precoUnitario: $precoUnitario');
    print('   - quantidade: $quantidade');
    if (preparo != null) {
      print('   - preparo: ${preparo.descricao}');
    }
    if (complementos != null && complementos.isNotEmpty) {
      print('   - complementos: ${complementos.length} itens');
      for (final c in complementos) {
        print('     * ${c.quantidade}x ${c.nome} (R\$ ${c.preco})');
      }
    }

    final item = CartItem(
      id: _uuid.v4(),
      produto: produto,
      precoUnitario: precoUnitario,
      quantidade: quantidade,
      preparo: preparo,
      composicoesRemovidas: composicoesRemovidas ?? [],
      complementos: complementos ?? [],
      observacao: observacao,
    );

    _cart = _cart.addItem(item);

    print('   ✅ Item adicionado. Total: ${_cart.items.length} itens');

    notifyListeners();
  }

  /// Remove item do carrinho
  void removeItem(String itemId) {
    _cart = _cart.removeItem(itemId);
    notifyListeners();
  }

  /// Atualiza quantidade de um item
  void updateQuantity(String itemId, int quantidade) {
    if (quantidade <= 0) {
      removeItem(itemId);
      return;
    }

    final item = items.firstWhere(
      (i) => i.id == itemId,
      orElse: () => throw StateError('Item não encontrado'),
    );

    _cart = _cart.updateItem(itemId, item.copyWith(quantidade: quantidade));
    notifyListeners();
  }

  /// Incrementa quantidade
  void incrementQuantity(String itemId) {
    final item = items.firstWhere((i) => i.id == itemId);
    updateQuantity(itemId, item.quantidade + 1);
  }

  /// Decrementa quantidade
  void decrementQuantity(String itemId) {
    final item = items.firstWhere((i) => i.id == itemId);
    updateQuantity(itemId, item.quantidade - 1);
  }

  /// Atualiza quantidade de um complemento dentro de um item
  void updateComplementQuantity(
      String itemId, int complementoGrid, int novaQuantidade) {
    final item = items.firstWhere(
      (i) => i.id == itemId,
      orElse: () => throw StateError('Item não encontrado'),
    );

    List<ComplementoSelecionado> novosComplementos;

    if (novaQuantidade <= 0) {
      // Remove o complemento
      novosComplementos = item.complementos
          .where((c) => c.complementoGrid != complementoGrid)
          .toList();
    } else {
      // Atualiza a quantidade do complemento
      novosComplementos = item.complementos.map((c) {
        if (c.complementoGrid == complementoGrid) {
          return ComplementoSelecionado(
            produtoGrid: c.produtoGrid,
            complementoGrid: c.complementoGrid,
            nome: c.nome,
            quantidade: novaQuantidade,
            preco: c.preco,
          );
        }
        return c;
      }).toList();
    }

    _cart = _cart.updateItem(
      itemId,
      item.copyWith(complementos: novosComplementos),
    );

    print(
        '🔄 Complemento atualizado: grid=$complementoGrid, qtd=$novaQuantidade');
    notifyListeners();
  }

  /// Define a comanda
  void setComanda(String? numeroComanda) {
    _cart = _cart.setComanda(numeroComanda);
    print('🎫 Comanda definida: $numeroComanda');
    notifyListeners();
  }

  /// Define dados do cliente
  void setCliente({String? nome, String? cpf}) {
    _cart = _cart.setCliente(nome: nome, cpf: cpf);
    notifyListeners();
  }

  /// Limpa o carrinho (mantém comanda e cliente)
  void clear() {
    _cart = _cart.clear();
    _status = ComandaStatus.pendente;
    _errorMessage = null;
    notifyListeners();
  }

  /// Reinicia completamente (limpa tudo incluindo comanda)
  void reset() {
    _cart = Cart();
    _status = ComandaStatus.pendente;
    _errorMessage = null;
    _isLoading = false;
    print('🔄 Carrinho resetado completamente');
    notifyListeners();
  }

  /// Registra comanda no backend
  Future<ComandaResponse> registrarComanda() async {
    if (isEmpty) {
      throw StateError('Carrinho vazio');
    }

    _isLoading = true;
    _status = ComandaStatus.enviando;
    _errorMessage = null;
    notifyListeners();

    try {
      print('📤 Enviando comanda para o backend...');
      print('   - Comanda: ${_cart.comanda}');
      print('   - Cliente: ${_cart.clienteNome}');
      print('   - Itens: ${_cart.items.length}');
      print('   - Total: R\$ ${total.toStringAsFixed(2)}');

      final response = await Api.instance.registrarComanda(_cart);

      if (response.success) {
        _status = ComandaStatus.confirmada;
        print('✅ Comanda registrada com sucesso! ID: ${response.comandaId}');
      } else {
        _status = ComandaStatus.erro;
        _errorMessage =
            response.error ?? response.message ?? 'Erro ao registrar comanda';
        print('❌ Erro ao registrar comanda: $_errorMessage');
      }

      notifyListeners();
      return response;
    } catch (e) {
      _status = ComandaStatus.erro;
      _errorMessage = e.toString();
      print('❌ Exceção ao registrar comanda: $e');
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Formata total para exibição
  String get totalFormatado =>
      'R\$ ${total.toStringAsFixed(2).replaceAll('.', ',')}';
}

// lib/services/cart_provider.dart
// Gerenciamento de estado do carrinho usando ChangeNotifier

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/cart_models.dart';
import '../models/produto_models.dart';
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

  // ALTERADO: Getter de comanda
  String? get comanda => _cart.comanda;

  ComandaStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  /// Adiciona item ao carrinho
  void addItem({
    required Produto produto,
    required double precoUnitario,
    int quantidade = 1,
    ProdutoPreparo? preparo,
    List<ProdutoComposicao>? composicoesRemovidas,
    List<ComplementoSelecionado>? complementos,
    String? observacao,
  }) {
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

  // ALTERADO: Método para definir a comanda (Substitui setMesa)
  void setComanda(String? numeroComanda) {
    _cart = _cart.setComanda(numeroComanda);
    notifyListeners();
  }

  /// Define dados do cliente
  void setCliente({String? nome, String? cpf}) {
    _cart = _cart.setCliente(nome: nome, cpf: cpf);
    notifyListeners();
  }

  /// Limpa o carrinho
  void clear() {
    _cart = _cart.clear();
    _status = ComandaStatus.pendente;
    _errorMessage = null;
    notifyListeners();
  }

  /// Reinicia completamente (limpa tudo incluindo comanda)
  void reset() {
    _cart = Cart(); // Isso cria um novo Cart vazio sem comanda
    _status = ComandaStatus.pendente;
    _errorMessage = null;
    _isLoading = false;
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
      final response = await Api.instance.registrarComanda(_cart);

      if (response.success) {
        _status = ComandaStatus.confirmada;
      } else {
        _status = ComandaStatus.erro;
        _errorMessage =
            response.error ?? response.message ?? 'Erro ao registrar comanda';
      }

      notifyListeners();
      return response;
    } catch (e) {
      _status = ComandaStatus.erro;
      _errorMessage = e.toString();
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

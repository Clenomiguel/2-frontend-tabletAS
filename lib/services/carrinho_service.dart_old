// lib/services/carrinho_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/carrinho_models.dart';

class CarrinhoService extends ChangeNotifier {
  static final CarrinhoService _instance = CarrinhoService._internal();
  factory CarrinhoService() => _instance;
  CarrinhoService._internal();

  static CarrinhoService get instance => _instance;

  // Estado do carrinho
  Carrinho _carrinho = Carrinho();
  Carrinho get carrinho => _carrinho;

  // Getters de conveniência
  bool get isEmpty => _carrinho.isEmpty;
  bool get isNotEmpty => _carrinho.isNotEmpty;
  int get quantidadeTotal => _carrinho.quantidadeTotal;
  double get subtotal => _carrinho.subtotal;
  double get total => _carrinho.total;
  List<ItemCarrinho> get itens => _carrinho.itens;

  // Métodos estáticos para facilitar o uso
  static bool get isEmptyStatic => _instance.isEmpty;
  static bool get isNotEmptyStatic => _instance.isNotEmpty;
  static int get quantidadeTotalStatic => _instance.quantidadeTotal;
  static double get subtotalStatic => _instance.subtotal;
  static double get totalStatic => _instance.total;
  static List<ItemCarrinho> get itensStatic => _instance.itens;

  /// Adiciona um item ao carrinho
  static void adicionarItem(ItemCarrinho item) {
    _instance._adicionarItem(item);
  }

  void _adicionarItem(ItemCarrinho item) {
    print(
      '🛒 Adicionando item ao carrinho: ${item.produto.nome} (${item.quantidade}x)',
    );

    _carrinho = _carrinho.adicionarItem(item);
    notifyListeners();

    print(
      '🛒 Carrinho atualizado: ${_carrinho.quantidadeTotal} itens, Total: R\$ ${_carrinho.total.toStringAsFixed(2)}',
    );
    _salvarCarrinho();
  }

  /// Remove um item do carrinho
  static void removerItem(String itemId) {
    _instance._removerItem(itemId);
  }

  void _removerItem(String itemId) {
    final item = _carrinho.itens.firstWhere((i) => i.id == itemId);
    print('🗑️ Removendo item do carrinho: ${item.produto.nome}');

    _carrinho = _carrinho.removerItem(itemId);
    notifyListeners();

    print(
      '🛒 Carrinho atualizado: ${_carrinho.quantidadeTotal} itens, Total: R\$ ${_carrinho.total.toStringAsFixed(2)}',
    );
    _salvarCarrinho();
  }

  /// Atualiza a quantidade de um item
  static void atualizarQuantidade(String itemId, int novaQuantidade) {
    _instance._atualizarQuantidade(itemId, novaQuantidade);
  }

  void _atualizarQuantidade(String itemId, int novaQuantidade) {
    final item = _carrinho.itens.firstWhere((i) => i.id == itemId);
    print(
      '📝 Atualizando quantidade: ${item.produto.nome} para ${novaQuantidade}',
    );

    _carrinho = _carrinho.atualizarQuantidade(itemId, novaQuantidade);
    notifyListeners();

    print(
      '🛒 Carrinho atualizado: ${_carrinho.quantidadeTotal} itens, Total: R\$ ${_carrinho.total.toStringAsFixed(2)}',
    );
    _salvarCarrinho();
  }

  /// Limpa todo o carrinho
  static void limpar() {
    _instance._limpar();
  }

  void _limpar() {
    print('🗑️ Limpando carrinho');
    _carrinho = _carrinho.limpar();
    notifyListeners();
    _salvarCarrinho();
  }

  /// Incrementa a quantidade de um item
  static void incrementarItem(String itemId) {
    final item = _instance._carrinho.itens.firstWhere((i) => i.id == itemId);
    _instance._atualizarQuantidade(itemId, item.quantidade + 1);
  }

  /// Decrementa a quantidade de um item
  static void decrementarItem(String itemId) {
    final item = _instance._carrinho.itens.firstWhere((i) => i.id == itemId);
    if (item.quantidade > 1) {
      _instance._atualizarQuantidade(itemId, item.quantidade - 1);
    } else {
      _instance._removerItem(itemId);
    }
  }

  /// Obtém um item específico por ID
  static ItemCarrinho? obterItem(String itemId) {
    try {
      return _instance._carrinho.itens.firstWhere((i) => i.id == itemId);
    } catch (e) {
      return null;
    }
  }

  /// Verifica se um produto está no carrinho (com personalizações específicas)
  static bool contemItem(ItemCarrinho item) {
    return _instance._carrinho.itens.any((i) => i.temMesmaPersonalizacao(item));
  }

  /// Obtém a quantidade total de um produto específico no carrinho
  static int obterQuantidadeProduto(int produtoId) {
    return _instance._carrinho.itens
        .where((item) => item.produto.id == produtoId)
        .fold(0, (sum, item) => sum + item.quantidade);
  }

  /// Aplica desconto ao carrinho
  static void aplicarDesconto(double desconto) {
    _instance._aplicarDesconto(desconto);
  }

  void _aplicarDesconto(double desconto) {
    print('💰 Aplicando desconto: R\$ ${desconto.toStringAsFixed(2)}');
    _carrinho = _carrinho.copyWith(desconto: desconto);
    notifyListeners();
    _salvarCarrinho();
  }

  /// Define taxa de entrega
  static void definirTaxaEntrega(double taxa) {
    _instance._definirTaxaEntrega(taxa);
  }

  void _definirTaxaEntrega(double taxa) {
    print('🚚 Definindo taxa de entrega: R\$ ${taxa.toStringAsFixed(2)}');
    _carrinho = _carrinho.copyWith(taxaEntrega: taxa);
    notifyListeners();
    _salvarCarrinho();
  }

  /// Salva o carrinho (em produção, você salvaria no SharedPreferences ou banco local)
  void _salvarCarrinho() {
    // Por enquanto, apenas log
    if (kDebugMode) {
      print('💾 Salvando carrinho: ${jsonEncode(_carrinho.toJson())}');
    }

    // Em uma implementação real, você salvaria assim:
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setString('carrinho', jsonEncode(_carrinho.toJson()));
  }

  /// Carrega o carrinho salvo (implementação futura)
  Future<void> carregarCarrinho() async {
    // Em uma implementação real:
    // final prefs = await SharedPreferences.getInstance();
    // final carrinhoJson = prefs.getString('carrinho');
    // if (carrinhoJson != null) {
    //   final dados = jsonDecode(carrinhoJson);
    //   // Reconstruir carrinho a partir dos dados salvos
    // }
    print('📂 Carregando carrinho salvo (implementação futura)');
  }

  /// Finaliza o pedido (limpa o carrinho e retorna os dados do pedido)
  static Map<String, dynamic> finalizarPedido() {
    return _instance._finalizarPedido();
  }

  Map<String, dynamic> _finalizarPedido() {
    final dadosPedido = _carrinho.toJson();
    print('✅ Finalizando pedido: ${dadosPedido}');

    // Limpar carrinho após finalizar pedido
    _limpar();

    return dadosPedido;
  }

  /// Debug - imprime estado atual do carrinho
  static void debug() {
    _instance._debug();
  }

  void _debug() {
    print('🐛 === DEBUG CARRINHO ===');
    print('📊 Quantidade de itens: ${_carrinho.quantidadeTotal}');
    print('💰 Subtotal: R\$ ${_carrinho.subtotal.toStringAsFixed(2)}');
    print('🎁 Desconto: R\$ ${_carrinho.desconto.toStringAsFixed(2)}');
    print('🚚 Taxa entrega: R\$ ${_carrinho.taxaEntrega.toStringAsFixed(2)}');
    print('💵 Total: R\$ ${_carrinho.total.toStringAsFixed(2)}');
    print('📝 Itens:');

    for (int i = 0; i < _carrinho.itens.length; i++) {
      final item = _carrinho.itens[i];
      print(
        '   ${i + 1}. ${item.produto.nome} - ${item.quantidade}x R\$ ${item.precoUnitario.toStringAsFixed(2)} = R\$ ${item.precoTotal.toStringAsFixed(2)}',
      );

      if (item.composicaoSelecionada.isNotEmpty) {
        print('      Composição: ${item.composicaoSelecionada}');
      }

      if (item.complementosSelecionados.isNotEmpty) {
        print('      Complementos: ${item.complementosSelecionados}');
      }

      if (item.preparosSelecionados.isNotEmpty) {
        print('      Preparos: ${item.preparosSelecionados}');
      }

      if (item.observacoes?.isNotEmpty == true) {
        print('      Obs: ${item.observacoes}');
      }
    }
    print('🐛 === FIM DEBUG ===');
  }

  /// Resumo do carrinho para exibição
  static String obterResumo() {
    if (_instance.isEmpty) {
      return 'Carrinho vazio';
    }

    return '${_instance.quantidadeTotal} ${_instance.quantidadeTotal == 1 ? 'item' : 'itens'} • R\$ ${_instance.total.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  /// Lista de produtos únicos no carrinho (para widget de badge)
  static Set<int> obterProdutosUnicos() {
    return _instance._carrinho.itens.map((item) => item.produto.id).toSet();
  }
}

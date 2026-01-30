// lib/screens/cart_screen.dart
// Tela do carrinho de compras - Layout moderno

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/cart_provider.dart';
import '../models/cart_models.dart';
import '../services/api_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isProcessing = false;

  // Dados do cliente (opcional)
  String? _clienteNome;
  String? _clienteTelefone;
  String? _clienteCpf;

  // Comanda
  String? _comandaNumero;

  // Cores do tema
  static const _bgDark = Color(0xFF1A1A1A);
  static const _bgCard = Color(0xFF2D2D2D);
  static const _accentRed = Color(0xFFE53935);
  static const _accentGreen = Color(0xFF4CAF50);
  static const _textWhite = Colors.white;
  static const _textGrey = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: _bgDark,
        foregroundColor: _textWhite,
        title: const Text(
          'MEU PEDIDO',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, _) {
              if (cart.quantidadeTotal == 0) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: () => _showClearCartDialog(context, cart),
                icon: const Icon(Icons.delete_outline, color: _accentRed),
                label:
                    const Text('Limpar', style: TextStyle(color: _accentRed)),
              );
            },
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.quantidadeTotal == 0) {
            return _buildEmptyCart();
          }
          return Column(
            children: [
              // Lista de itens
              Expanded(child: _buildCartItems(cart)),
              // Rodapé com resumo e botão
              _buildFooter(cart),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 120,
            color: _textGrey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          const Text(
            'Seu carrinho está vazio',
            style: TextStyle(
              color: _textWhite,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Adicione produtos para fazer seu pedido',
            style: TextStyle(color: _textGrey, fontSize: 16),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.restaurant_menu),
            label: const Text('VER CARDÁPIO'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentRed,
              foregroundColor: _textWhite,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItems(CartProvider cart) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cart.items.length,
      itemBuilder: (context, index) {
        final item = cart.items[index];
        return _buildCartItem(item, cart);
      },
    );
  }

  Widget _buildCartItem(CartItem item, CartProvider cart) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Item principal
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagem do produto
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: _bgDark,
                    child: item.produto.imagemBase64 != null
                        ? Image.memory(
                            _decodeBase64(item.produto.imagemBase64!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholder(),
                          )
                        : _buildPlaceholder(),
                  ),
                ),
                const SizedBox(width: 16),

                // Detalhes do produto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.produto.nome,
                        style: const TextStyle(
                          color: _textWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'R\$ ${item.precoUnitario.toStringAsFixed(2).replaceAll('.', ',')} un.',
                        style: const TextStyle(color: _textGrey, fontSize: 13),
                      ),
                      // Complementos
                      if (item.complementos.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ...item.complementos.map((comp) => Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                children: [
                                  const Icon(Icons.add_circle_outline,
                                      color: _accentGreen, size: 14),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${comp.quantidade}x ${comp.nome}',
                                      style: const TextStyle(
                                          color: _textGrey, fontSize: 12),
                                    ),
                                  ),
                                  Text(
                                    '+R\$ ${(comp.preco * comp.quantidade).toStringAsFixed(2).replaceAll('.', ',')}',
                                    style: const TextStyle(
                                        color: _accentGreen, fontSize: 12),
                                  ),
                                ],
                              ),
                            )),
                      ],
                      // Observação
                      if (item.observacao != null &&
                          item.observacao!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _bgDark,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.notes,
                                  color: _textGrey, size: 14),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.observacao!,
                                  style: const TextStyle(
                                    color: _textGrey,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Preço total do item
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'R\$ ${item.precoTotal.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: const TextStyle(
                        color: _textWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Botão remover
                    IconButton(
                      onPressed: () => cart.removeItem(item.id),
                      icon: const Icon(Icons.delete_outline, color: _accentRed),
                      tooltip: 'Remover',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Controle de quantidade
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: _bgDark,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Quantidade:',
                  style: TextStyle(color: _textGrey, fontSize: 14),
                ),
                // Controles de quantidade
                Container(
                  decoration: BoxDecoration(
                    color: _bgCard,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      // Botão diminuir
                      IconButton(
                        onPressed: item.quantidade > 1
                            ? () => cart.updateQuantity(
                                item.id, item.quantidade - 1)
                            : null,
                        icon: Icon(
                          Icons.remove,
                          color: item.quantidade > 1 ? _textWhite : _textGrey,
                        ),
                      ),
                      // Quantidade
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '${item.quantidade}',
                          style: const TextStyle(
                            color: _textWhite,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Botão aumentar
                      IconButton(
                        onPressed: () =>
                            cart.updateQuantity(item.id, item.quantidade + 1),
                        icon: const Icon(Icons.add, color: _textWhite),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: _bgCard,
      child: const Center(
        child: Icon(Icons.restaurant, color: _textGrey, size: 32),
      ),
    );
  }

  Widget _buildFooter(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Resumo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${cart.quantidadeTotal} ${cart.quantidadeTotal == 1 ? 'item' : 'itens'}',
                  style: const TextStyle(color: _textGrey, fontSize: 14),
                ),
                const Text(
                  'Subtotal',
                  style: TextStyle(color: _textGrey, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL',
                  style: TextStyle(
                    color: _textWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'R\$ ${cart.total.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: const TextStyle(
                    color: _accentGreen,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Botões
            Row(
              children: [
                // Continuar comprando
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.add),
                    label: const Text('ADICIONAR MAIS'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textWhite,
                      side: const BorderSide(color: _textGrey),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Finalizar pedido
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed:
                        _isProcessing ? null : () => _finalizarPedido(cart),
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _textWhite,
                            ),
                          )
                        : const Icon(Icons.check_circle),
                    label: Text(
                        _isProcessing ? 'ENVIANDO...' : 'FINALIZAR PEDIDO'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentGreen,
                      foregroundColor: _textWhite,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCartDialog(BuildContext context, CartProvider cart) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgCard,
        title:
            const Text('Limpar carrinho?', style: TextStyle(color: _textWhite)),
        content: const Text(
          'Tem certeza que deseja remover todos os itens do carrinho?',
          style: TextStyle(color: _textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR', style: TextStyle(color: _textGrey)),
          ),
          ElevatedButton(
            onPressed: () {
              cart.clear();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: _accentRed),
            child: const Text('LIMPAR', style: TextStyle(color: _textWhite)),
          ),
        ],
      ),
    );
  }

  Future<void> _finalizarPedido(CartProvider cart) async {
    // Passo 1: Ler código de barras da comanda
    final comanda = await _showScanComandaDialog();

    if (comanda == null || comanda.isEmpty) return; // Cancelou

    _comandaNumero = comanda;

    // Passo 2: Verificar se a comanda já tem cliente identificado
    final precisaIdentificar = await _verificarIdentificacaoComanda(comanda);

    if (precisaIdentificar) {
      // Perguntar se quer se identificar
      final querIdentificar = await _showIdentificacaoDialog();

      if (querIdentificar == null) return; // Cancelou

      if (querIdentificar == true) {
        final clienteOk = await _fluxoIdentificacaoCliente();
        if (!clienteOk) return; // Cancelou ou erro
      }
    }

    // Passo 3: Enviar pedido
    await _enviarPedido(cart);
  }

  /// Verifica se a comanda já tem cliente identificado
  /// Retorna true se PRECISA perguntar identificação
  Future<bool> _verificarIdentificacaoComanda(String comandaNumero) async {
    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(color: _accentRed),
        ),
      );

      final comanda = await Api.instance.getComanda(comandaNumero);

      if (mounted) Navigator.pop(context); // Fecha loading

      // Verificar se já tem cliente
      final clienteNome = comanda['cliente_nome']?.toString();
      final clienteCpf = comanda['cliente_cpf']?.toString();

      if (clienteNome != null && clienteNome.isNotEmpty) {
        // Já identificado - guardar dados
        _clienteNome = clienteNome;
        _clienteCpf = clienteCpf;

        print('✅ Cliente já identificado: $_clienteNome');

        // Mostrar mensagem de boas vindas rápida
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Olá, $_clienteNome! 👋'),
              backgroundColor: _accentGreen,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        return false; // Não precisa perguntar
      }

      return true; // Precisa perguntar identificação
    } catch (e) {
      // Comanda não existe - será criada depois
      if (mounted) Navigator.pop(context); // Fecha loading
      print('ℹ️ Comanda nova ou erro: $e');
      return true; // Perguntar identificação para comanda nova
    }
  }

  /// Dialog perguntando se quer se identificar
  Future<bool?> _showIdentificacaoDialog() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _accentRed.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_add, color: _accentRed, size: 48),
            ),
            const SizedBox(height: 24),
            const Text(
              'Deseja se identificar?',
              style: TextStyle(
                color: _textWhite,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Identifique-se para acumular pontos e receber promoções exclusivas!',
              style: TextStyle(color: _textGrey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Botão Me Identificar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(ctx, true),
                icon: const Icon(Icons.person),
                label: const Text('ME IDENTIFICAR'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentGreen,
                  foregroundColor: _textWhite,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Botão Não Obrigado
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _textWhite,
                  side: const BorderSide(color: _textGrey),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('NÃO, OBRIGADO'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Fluxo de identificação: CPF -> Busca -> Cadastro se necessário
  Future<bool> _fluxoIdentificacaoCliente() async {
    // Passo 1: Solicitar CPF
    final cpf = await _showCpfDialog();
    if (cpf == null || cpf.isEmpty) return false;

    _clienteCpf = cpf;

    // Passo 2: Buscar cliente no backend
    final clienteExistente = await _buscarClientePorCpf(cpf);

    if (clienteExistente != null) {
      // Cliente já cadastrado
      _clienteNome =
          clienteExistente['nome'] ?? clienteExistente['cliente_nome'];
      _clienteTelefone =
          clienteExistente['telefone'] ?? clienteExistente['whatsapp'];

      // Mostrar boas vindas
      await _showBoasVindasDialog(_clienteNome ?? 'Cliente');
      return true;
    } else {
      // Cliente não cadastrado - solicitar cadastro
      final cadastrou = await _showCadastroDialog(cpf);
      return cadastrou == true;
    }
  }

  /// Dialog para digitar CPF
  Future<String?> _showCpfDialog() async {
    final cpfController = TextEditingController();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _accentRed.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.badge_outlined, color: _accentRed, size: 48),
            ),
            const SizedBox(height: 24),
            const Text(
              'Digite seu CPF',
              style: TextStyle(
                color: _textWhite,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Vamos verificar seu cadastro',
              style: TextStyle(color: _textGrey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: cpfController,
              autofocus: true,
              style: const TextStyle(color: _textWhite, fontSize: 24),
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _CpfInputFormatter(),
              ],
              decoration: InputDecoration(
                hintText: '000.000.000-00',
                hintStyle: TextStyle(color: _textGrey.withValues(alpha: 0.5)),
                filled: true,
                fillColor: _bgDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textWhite,
                      side: const BorderSide(color: _textGrey),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('CANCELAR'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final cpf =
                          cpfController.text.replaceAll(RegExp(r'\D'), '');
                      if (cpf.length == 11) {
                        Navigator.pop(ctx, cpf);
                      } else {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('CPF deve ter 11 dígitos'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentGreen,
                      foregroundColor: _textWhite,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('CONTINUAR'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Busca cliente por CPF no backend
  Future<Map<String, dynamic>?> _buscarClientePorCpf(String cpf) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(color: _accentRed),
        ),
      );

      final cliente = await Api.instance.getClienteByCpf(cpf);

      if (mounted) Navigator.pop(context);

      return cliente;
    } catch (e) {
      if (mounted) Navigator.pop(context);
      print('⚠️ Erro ao buscar cliente: $e');
      return null;
    }
  }

  /// Dialog de boas vindas para cliente já cadastrado
  Future<void> _showBoasVindasDialog(String nome) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _accentGreen.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.check_circle, color: _accentGreen, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              'Olá, $nome!',
              style: const TextStyle(
                color: _textWhite,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Que bom ter você de volta!',
              style: TextStyle(color: _textGrey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentGreen,
                  foregroundColor: _textWhite,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('CONTINUAR'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Dialog de cadastro do cliente (quando não existe)
  Future<bool?> _showCadastroDialog(String cpf) async {
    final nomeController = TextEditingController();
    final telefoneController = TextEditingController();

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _accentRed.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.person_add, color: _accentRed, size: 48),
              ),
              const SizedBox(height: 24),
              const Text(
                'Complete seu cadastro',
                style: TextStyle(
                  color: _textWhite,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Preencha seus dados para aproveitar benefícios exclusivos!',
                style: TextStyle(color: _textGrey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // CPF (apenas exibição)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _bgDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.badge_outlined, color: _textGrey),
                    const SizedBox(width: 12),
                    Text(
                      _formatCpf(cpf),
                      style: const TextStyle(color: _textWhite, fontSize: 16),
                    ),
                    const Spacer(),
                    const Icon(Icons.check_circle,
                        color: _accentGreen, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Nome
              TextField(
                controller: nomeController,
                style: const TextStyle(color: _textWhite),
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Nome completo *',
                  labelStyle: const TextStyle(color: _textGrey),
                  prefixIcon:
                      const Icon(Icons.person_outline, color: _textGrey),
                  filled: true,
                  fillColor: _bgDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Telefone
              TextField(
                controller: telefoneController,
                style: const TextStyle(color: _textWhite),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _TelefoneInputFormatter(),
                ],
                decoration: InputDecoration(
                  labelText: 'WhatsApp *',
                  labelStyle: const TextStyle(color: _textGrey),
                  prefixIcon: const Icon(Icons.phone, color: _textGrey),
                  filled: true,
                  fillColor: _bgDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  hintText: '(00) 00000-0000',
                  hintStyle: TextStyle(color: _textGrey.withValues(alpha: 0.5)),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _textWhite,
                        side: const BorderSide(color: _textGrey),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('CANCELAR'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final nome = nomeController.text.trim();
                        final telefone = telefoneController.text
                            .replaceAll(RegExp(r'\D'), '');

                        if (nome.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('Nome é obrigatório'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        if (telefone.length < 10) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('WhatsApp inválido'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        final sucesso = await _cadastrarCliente(
                          cpf: cpf,
                          nome: nome,
                          telefone: telefone,
                        );

                        if (sucesso) {
                          _clienteNome = nome;
                          _clienteTelefone = telefone;
                          Navigator.pop(ctx, true);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentGreen,
                        foregroundColor: _textWhite,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('CADASTRAR'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Cadastra novo cliente no backend
  Future<bool> _cadastrarCliente({
    required String cpf,
    required String nome,
    required String telefone,
  }) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(color: _accentRed),
        ),
      );

      await Api.instance.criarCliente({
        'cpf': cpf,
        'nome': nome,
        'telefone': telefone,
        'whatsapp': telefone,
      });

      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cadastro realizado com sucesso!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }

      return true;
    } catch (e) {
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao cadastrar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      return false;
    }
  }

  String _formatCpf(String cpf) {
    if (cpf.length != 11) return cpf;
    return '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.${cpf.substring(6, 9)}-${cpf.substring(9)}';
  }

  /// Dialog para escanear/digitar comanda
  Future<String?> _showScanComandaDialog() async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ScanComandaDialog(),
    );
  }

  /// Envia o pedido para o backend
  Future<void> _enviarPedido(CartProvider cart) async {
    setState(() => _isProcessing = true);

    try {
      // Usar a comanda escaneada/digitada pelo cliente
      final response = await Api.instance.adicionarProdutosComanda(
        comandaNumero: _comandaNumero!,
        items: cart.items,
        clienteNome: _clienteNome,
        clienteTelefone: _clienteTelefone,
        clienteCpf: _clienteCpf,
      );

      if (!mounted) return;

      if (response.success) {
        cart.clear();
        _showSuccessDialog(_comandaNumero!);
      } else {
        _showErrorSnackbar(response.error ?? 'Erro ao enviar pedido');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Erro: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showSuccessDialog(String comandaId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgCard,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: _accentGreen, size: 80),
            const SizedBox(height: 24),
            const Text(
              'Pedido Enviado!',
              style: TextStyle(
                color: _textWhite,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Comanda: $comandaId',
              style: const TextStyle(color: _textGrey, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Aguarde seu pedido ser preparado',
              style: TextStyle(color: _textGrey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx); // Fecha dialog
                Navigator.pop(context); // Volta pro cardápio
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('OK', style: TextStyle(color: _textWhite)),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _accentRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Uint8List _decodeBase64(String base64String) {
    String clean = base64String.replaceAll(RegExp(r'\s'), '');
    if (clean.contains(',')) {
      clean = clean.split(',').last;
    }
    final padding = clean.length % 4;
    if (padding > 0) {
      clean += '=' * (4 - padding);
    }
    return base64Decode(clean);
  }
}

/// Dialog para escanear código de barras da comanda
class _ScanComandaDialog extends StatefulWidget {
  @override
  State<_ScanComandaDialog> createState() => _ScanComandaDialogState();
}

class _ScanComandaDialogState extends State<_ScanComandaDialog> {
  bool _showScanner = true;
  bool _isScanned = false;
  final _comandaController = TextEditingController();

  static const _bgDark = Color(0xFF1A1A1A);
  static const _bgCard = Color(0xFF2D2D2D);
  static const _accentRed = Color(0xFFE53935);
  static const _accentGreen = Color(0xFF4CAF50);
  static const _textWhite = Colors.white;
  static const _textGrey = Color(0xFF9E9E9E);

  @override
  void dispose() {
    _comandaController.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(String code) {
    if (_isScanned) return; // Evita leituras duplicadas

    setState(() {
      _isScanned = true;
      _comandaController.text = code;
      _showScanner = false;
    });

    // Confirma automaticamente após 1 segundo
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _comandaController.text.isNotEmpty) {
        Navigator.pop(context, _comandaController.text);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _accentRed.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.qr_code_scanner,
                      color: _accentRed, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Escanear Comanda',
                        style: TextStyle(
                          color: _textWhite,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Posicione o código de barras',
                        style: TextStyle(color: _textGrey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: _textGrey),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Scanner ou campo manual
            if (_showScanner) ...[
              // Área do scanner
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _accentRed, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    children: [
                      RotatedBox(
                        quarterTurns: 3,
                        child: MobileScanner(
                          controller: MobileScannerController(
                            facing: CameraFacing.front,
                            formats: [
                              BarcodeFormat.code128,
                              BarcodeFormat.code39,
                              BarcodeFormat.code93,
                              BarcodeFormat.codabar,
                              BarcodeFormat.ean13,
                              BarcodeFormat.ean8,
                              BarcodeFormat.itf,
                              BarcodeFormat.upcA,
                              BarcodeFormat.upcE,
                              BarcodeFormat.qrCode,
                            ],
                          ),
                          onDetect: (capture) {
                            for (final barcode in capture.barcodes) {
                              if (barcode.rawValue != null) {
                                _onBarcodeDetected(barcode.rawValue!);
                                break;
                              }
                            }
                          },
                        ),
                      ),
                      // Guia visual
                      Center(
                        child: Container(
                          width: 250,
                          height: 80,
                          decoration: BoxDecoration(
                            border: Border.all(color: _accentRed, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Botão para digitar manualmente
              TextButton.icon(
                onPressed: () => setState(() => _showScanner = false),
                icon: const Icon(Icons.keyboard, color: _textGrey),
                label: const Text(
                  'Digitar manualmente',
                  style: TextStyle(color: _textGrey),
                ),
              ),
            ] else ...[
              // Campo manual
              TextField(
                controller: _comandaController,
                autofocus: true,
                style: const TextStyle(color: _textWhite, fontSize: 24),
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: 'Número da comanda',
                  hintStyle: const TextStyle(color: _textGrey),
                  filled: true,
                  fillColor: _bgDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.receipt_long, color: _textGrey),
                ),
              ),
              const SizedBox(height: 16),

              // Botão para voltar ao scanner
              TextButton.icon(
                onPressed: () => setState(() {
                  _showScanner = true;
                  _isScanned = false;
                }),
                icon: const Icon(Icons.qr_code_scanner, color: _textGrey),
                label: const Text(
                  'Usar câmera',
                  style: TextStyle(color: _textGrey),
                ),
              ),
            ],

            // Comanda detectada
            if (_isScanned) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _accentGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: _accentGreen),
                    const SizedBox(width: 12),
                    Text(
                      'Comanda: ${_comandaController.text}',
                      style: const TextStyle(
                        color: _accentGreen,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Botões
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textWhite,
                      side: const BorderSide(color: _textGrey),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('CANCELAR'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _comandaController.text.isNotEmpty
                        ? () => Navigator.pop(context, _comandaController.text)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentGreen,
                      foregroundColor: _textWhite,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('CONFIRMAR'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Formatter para telefone brasileiro (XX) XXXXX-XXXX
class _TelefoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();

    for (int i = 0; i < digits.length && i < 11; i++) {
      if (i == 0) buffer.write('(');
      if (i == 2) buffer.write(') ');
      if (i == 7) buffer.write('-');
      buffer.write(digits[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

/// Formatter para CPF XXX.XXX.XXX-XX
class _CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();

    for (int i = 0; i < digits.length && i < 11; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');
      buffer.write(digits[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

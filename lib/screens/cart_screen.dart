// lib/screens/cart_screen.dart
// Tela do carrinho de compras - Layout moderno

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    setState(() => _isProcessing = true);

    try {
      // Converter para modelo Cart
      final cartModel = Cart(
        items: cart.items,
        mesa: null, // TODO: Pegar mesa se houver
      );

      final response = await Api.instance.registrarComanda(cartModel);

      if (!mounted) return;

      if (response.success) {
        cart.clear();
        _showSuccessDialog(response.comandaId ?? '');
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

void _showComandaDialog(BuildContext context) {
  final TextEditingController _comandaController = TextEditingController();
  final cartProvider = Provider.of<CartProvider>(context, listen: false);

  showDialog(
    context: context,
    barrierDismissible: false, // Obriga o usuário a digitar ou cancelar
    builder: (context) => AlertDialog(
      title: const Text('Identificação'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Por favor, digite o número da sua comanda física:'),
          const SizedBox(height: 16),
          TextField(
            controller: _comandaController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Número da Comanda',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.confirmation_number),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCELAR'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_comandaController.text.isNotEmpty) {
              // Salva o número da comanda no campo clienteNome do Cart
              cartProvider.setCliente(nome: _comandaController.text);

              Navigator.pop(context); // Fecha o diálogo

              // Inicia o processo de registro no banco
              cartProvider.registrarComanda();
            }
          },
          child: const Text('CONFIRMAR PEDIDO'),
        ),
      ],
    ),
  );
}

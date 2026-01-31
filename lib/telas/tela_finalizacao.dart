// lib/screens/checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as dev; // Import para logs mais limpos

import '../modelos/cart_models.dart';
import '../servicos/cart_provider.dart';
import '../servicos/api_service.dart';
import '../utilitarios/parsing_utils.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _comandaController = TextEditingController();
  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();

  bool _isProcessing = false;
  String? _error;

  @override
  void dispose() {
    _comandaController.dispose();
    _nomeController.dispose();
    _cpfController.dispose();
    super.dispose();
  }

  Future<void> _finalizarPedido() async {
    final cart = context.read<CartProvider>();

    dev.log('Iniciando processo de finalização...', name: 'CHECKOUT');

    // Validações
    if (_comandaController.text.trim().isEmpty) {
      dev.log('Erro de validação: Comanda vazia', name: 'CHECKOUT');
      setState(() => _error = 'Informe o número da comanda');
      return;
    }

    // Atualiza dados no Provider
    cart.setComanda(_comandaController.text.trim());
    if (_nomeController.text.isNotEmpty) {
      cart.setCliente(
        nome: _nomeController.text,
        cpf: _cpfController.text.isNotEmpty ? _cpfController.text : null,
      );
    }

    // ==========================================
    // LOG DOS DADOS QUE SERÃO ENVIADOS
    // ==========================================
    dev.log('--- RESUMO DO ENVIO ---', name: 'CHECKOUT');
    dev.log('Comanda: ${_comandaController.text}', name: 'CHECKOUT');
    dev.log('Cliente: ${_nomeController.text}', name: 'CHECKOUT');
    dev.log('CPF: ${_cpfController.text}', name: 'CHECKOUT');
    dev.log('Total de Itens: ${cart.items.length}', name: 'CHECKOUT');

    for (var i = 0; i < cart.items.length; i++) {
      final item = cart.items[i];
      dev.log('Item [$i]: ${item.produto.nomeExibicao}', name: 'CHECKOUT');
      dev.log('  - ID: ${item.produto.grid}', name: 'CHECKOUT');
      dev.log('  - Qtd: ${item.quantidade}', name: 'CHECKOUT');
      dev.log('  - Preço Unit: ${item.precoUnitario}', name: 'CHECKOUT');

      // Se houver complementos dentro do item (ajuste conforme seu modelo)
      // Como você mencionou que devem ir para a comanda_produto,
      // verifique se o seu provider já os trata como itens individuais.
    }
    dev.log('-----------------------', name: 'CHECKOUT');

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      dev.log('Chamando cart.registrarComanda()...', name: 'CHECKOUT');
      final response = await cart.registrarComanda();

      dev.log('Resposta recebida: Success=${response.success}',
          name: 'CHECKOUT');

      setState(() {
        _isProcessing = false;
      });

      if (response.success) {
        dev.log('Pedido registrado com sucesso. ID: ${response.comandaId}',
            name: 'CHECKOUT');
        if (!mounted) return;
        _showSuccessDialog(response);
      } else {
        dev.log('Erro retornado pelo Backend: ${response.message}',
            name: 'CHECKOUT');
        setState(() {
          _error =
              response.error ?? response.message ?? 'Erro ao enviar pedido';
        });
      }
    } on ApiException catch (e) {
      dev.log('Erro de API: ${e.message}', name: 'CHECKOUT', error: e);
      setState(() {
        _error = e.message;
        _isProcessing = false;
      });
    } catch (e) {
      dev.log('Erro inesperado no Flutter: $e', name: 'CHECKOUT', error: e);
      setState(() {
        _error = 'Erro inesperado: $e';
        _isProcessing = false;
      });
    }
  }

  void _showSuccessDialog(ComandaResponse response) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 24),
            const Text(
              'Pedido Enviado!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Seu pedido foi registrado com sucesso.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            if (response.comandaId != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Comanda: ${response.comandaId}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                ),
              ),
            ],
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                dev.log('Resetando carrinho e voltando ao início.',
                    name: 'CHECKOUT');
                final cart = context.read<CartProvider>();
                cart.reset();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B21A8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Novo Pedido', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Log básico de build para monitorar rebuilds desnecessários
    dev.log('Construindo tela de Checkout', name: 'CHECKOUT_UI');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Finalizar Pedido'),
        backgroundColor: const Color(0xFF6B21A8),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection(
                  title: 'Resumo do Pedido',
                  child: _buildOrderSummary(cart),
                ),
                const SizedBox(height: 24),
                _buildSection(
                  title: 'Identificação',
                  child: _buildIdentificationForm(),
                ),
                const SizedBox(height: 24),
                if (_error != null) _buildErrorContainer(),
                _buildSubmitButton(cart),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widgets auxiliares refatorados para manter o build limpo
  Widget _buildErrorContainer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
              child: Text(_error!, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(CartProvider cart) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _finalizarPedido,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6B21A8),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          disabledBackgroundColor: Colors.grey,
        ),
        child: _isProcessing
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)),
                  SizedBox(width: 12),
                  Text('Enviando...', style: TextStyle(fontSize: 18)),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send),
                  const SizedBox(width: 12),
                  Text('Enviar Pedido  •  ${cart.totalFormatado}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildOrderSummary(CartProvider cart) {
    return Column(
      children: [
        ...cart.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                        color: const Color(0xFF6B21A8).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6)),
                    child: Center(
                        child: Text('${item.quantidade}x',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Color(0xFF6B21A8)))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(item.produto.nomeExibicao,
                          style: const TextStyle(fontSize: 15))),
                  Text(
                      'R\$ ${item.precoTotal.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            )),
        const Divider(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(cart.totalFormatado,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B21A8))),
          ],
        ),
      ],
    );
  }

  Widget _buildIdentificationForm() {
    return Column(
      children: [
        TextField(
          controller: _comandaController,
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: 'Número da Comanda *',
            prefixIcon: const Icon(Icons.confirmation_number),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nomeController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Seu Nome (opcional)',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _cpfController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _CpfInputFormatter()
          ],
          decoration: InputDecoration(
            labelText: 'CPF na Nota (opcional)',
            prefixIcon: const Icon(Icons.badge_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}

class _CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (text.length > 11) return oldValue;
    String formatted = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 3 || i == 6) formatted += '.';
      if (i == 9) formatted += '-';
      formatted += text[i];
    }
    return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length));
  }
}

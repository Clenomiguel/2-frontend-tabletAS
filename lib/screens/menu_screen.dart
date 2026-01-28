// lib/screens/menu_screen.dart
// Tela principal do cardápio com seções e produtos

import 'package:flutter/material.dart';

import '../models/cardapio_models.dart';
import '../services/api_service.dart';
import '../widgets/produto_card.dart';
import '../widgets/secao_header.dart';
import '../widgets/cart_fab.dart';
import 'produto_screen.dart';

class MenuScreen extends StatefulWidget {
  final int? cardapioId;

  const MenuScreen({super.key, this.cardapioId});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  CardapioCompleto? _cardapio;
  bool _isLoading = true;
  String? _error;
  int _selectedSecaoIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadCardapio();
  }

  Future<void> _loadCardapio() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      CardapioCompleto? cardapio;

      if (widget.cardapioId != null) {
        cardapio = await Api.instance.getCardapioCompleto(widget.cardapioId!);
      } else {
        cardapio = await Api.instance.getCardapioAtivo();
      }

      if (cardapio == null) {
        throw ApiException('Nenhum cardápio encontrado');
      }

      setState(() {
        _cardapio = cardapio;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onProdutoTap(ProdutoNoCardapio produto) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProdutoScreen(
          produtoGrid:
              produto.produtoId, // Use produtoId instead of produto.grid
          precoCardapio: produto.preco, // Now works with the preco getter
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(_cardapio?.cardapio.nome ?? 'Cardápio'),
        backgroundColor: const Color(0xFF6B21A8),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCardapio,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: const CartFab(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF6B21A8)),
            SizedBox(height: 16),
            Text('Carregando cardápio...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar cardápio',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadCardapio,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B21A8),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_cardapio == null || _cardapio!.secoes.isEmpty) {
      return const Center(
        child: Text('Nenhum produto disponível'),
      );
    }

    return Row(
      children: [
        // Menu lateral de seções
        _buildSecoesMenu(),
        // Grid de produtos
        Expanded(child: _buildProdutosGrid()),
      ],
    );
  }

  Widget _buildSecoesMenu() {
    final secoes = _cardapio!.secoesOrdenadas;

    return Container(
      width: 200,
      color: Colors.white,
      child: ListView.builder(
        itemCount: secoes.length,
        itemBuilder: (context, index) {
          final secao = secoes[index];
          final isSelected = index == _selectedSecaoIndex;

          return InkWell(
            onTap: () => setState(() => _selectedSecaoIndex = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF6B21A8).withValues(alpha: 0.1)
                    : null,
                border: Border(
                  left: BorderSide(
                    color: isSelected
                        ? const Color(0xFF6B21A8)
                        : Colors.transparent,
                    width: 4,
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (secao.imagens.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        Api.instance
                            .getSecaoImageUrl(secao.secao.grid, size: 'thumb'),
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 40,
                          height: 40,
                          color: Colors.grey[200],
                          child: const Icon(Icons.category, size: 20),
                        ),
                      ),
                    ),
                  if (secao.imagens.isNotEmpty) const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      secao.secao.nomeExibicao,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? const Color(0xFF6B21A8)
                            : Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    '${secao.produtos.length}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProdutosGrid() {
    final secoes = _cardapio!.secoesOrdenadas;
    if (_selectedSecaoIndex >= secoes.length) return const SizedBox();

    final secao = secoes[_selectedSecaoIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SecaoHeader(secao: secao),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: secao.produtos.length,
            itemBuilder: (context, index) {
              final produto = secao.produtos[index];
              return ProdutoCard(
                produtoCardapio:
                    produto, // Changed from 'produto:' to 'produtoCardapio:'
                onTap: () => _onProdutoTap(produto),
              );
            },
          ),
        ),
      ],
    );
  }
}

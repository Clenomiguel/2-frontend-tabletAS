// lib/screens/produto_screen.dart
// Tela de detalhes do produto com personalizações

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/produto_models.dart';
import '../models/cart_models.dart';
import '../services/api_service.dart';
import '../services/cart_provider.dart';
import '../utils/parsing_utils.dart';

class ProdutoScreen extends StatefulWidget {
  final int produtoGrid;
  final double? precoCardapio;

  const ProdutoScreen({
    super.key,
    required this.produtoGrid,
    this.precoCardapio,
  });

  @override
  State<ProdutoScreen> createState() => _ProdutoScreenState();
}

class _ProdutoScreenState extends State<ProdutoScreen> {
  ProdutoCompleto? _produtoCompleto;
  bool _isLoading = true;
  String? _error;

  // Seleções do usuário
  int _quantidade = 1;
  ProdutoPreparo? _preparoSelecionado;
  final Set<int> _composicoesRemovidas = {};
  final Map<int, int> _complementosSelecionados = {}; // grid -> quantidade
  final TextEditingController _observacaoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProduto();
  }

  @override
  void dispose() {
    _observacaoController.dispose();
    super.dispose();
  }

  Future<void> _loadProduto() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final produto = await Api.instance.getProdutoCompleto(widget.produtoGrid);

      setState(() {
        _produtoCompleto = produto;
        _isLoading = false;

        // Seleciona preparo padrão se houver
        if (produto.preparos.isNotEmpty) {
          _preparoSelecionado = produto.preparos.firstWhere(
            (p) => p.ehPadrao,
            orElse: () => produto.preparos.first,
          );
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  double get _precoBase =>
      widget.precoCardapio ?? _produtoCompleto?.produto.precoUnit ?? 0;

  double get _precoTotal {
    double total = _precoBase * _quantidade;

    // Adiciona complementos
    for (final entry in _complementosSelecionados.entries) {
      final comp = _produtoCompleto?.complementos.firstWhere(
        (c) => c.complementoGrid == entry.key,
        orElse: () =>
            ProdutoComplemento(grid: 0, produtoGrid: 0, complementoGrid: 0),
      );
      if (comp != null && comp.preco != null) {
        total += comp.preco! * entry.value;
      }
    }

    return total;
  }

  void _adicionarAoCarrinho() {
    if (_produtoCompleto == null) return;

    final cart = context.read<CartProvider>();

    // Monta lista de complementos selecionados
    final complementos = _complementosSelecionados.entries.map((entry) {
      final comp = _produtoCompleto!.complementos.firstWhere(
        (c) => c.complementoGrid == entry.key,
      );
      return ComplementoSelecionado(
        produtoGrid: _produtoCompleto!.produto.grid,
        complementoGrid: entry.key,
        nome: comp.complementoNome ?? 'Complemento',
        quantidade: entry.value,
        preco: comp.preco ?? 0.0,
      );
    }).toList();

    // Monta lista de composições removidas
    final removidas = _composicoesRemovidas.map((grid) {
      return _produtoCompleto!.composicao.firstWhere((c) => c.grid == grid);
    }).toList();

    cart.addItem(
      produto: _produtoCompleto!.produto,
      precoUnitario: _precoBase,
      quantidade: _quantidade,
      preparo: _preparoSelecionado,
      composicoesRemovidas: removidas,
      complementos: complementos,
      observacao: _observacaoController.text.isNotEmpty
          ? _observacaoController.text
          : null,
    );

    // Mostra feedback e volta
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '${_produtoCompleto!.produto.nomeExibicao} adicionado ao carrinho!'),
        backgroundColor: const Color(0xFF6B21A8),
        duration: const Duration(seconds: 2),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6B21A8)),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Erro ao carregar produto'),
            const SizedBox(height: 8),
            Text(_error!),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadProduto,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_produtoCompleto == null) {
      return const Center(child: Text('Produto não encontrado'));
    }

    final produto = _produtoCompleto!;

    return CustomScrollView(
      slivers: [
        // Imagem do produto
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: const Color(0xFF6B21A8),
          foregroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(
            background: produto.imagens.isNotEmpty
                ? Image.network(
                    Api.instance.getProdutoImageUrl(produto.produto.grid,
                        size: 'large'),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                  )
                : _buildPlaceholderImage(),
          ),
        ),

        // Conteúdo
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nome e preço
                Text(
                  produto.produto.nomeExibicao,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  ParsingUtils.formatCurrency(_precoBase),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B21A8),
                  ),
                ),
                const SizedBox(height: 24),

                // Preparos
                if (produto.preparos.length > 1) ...[
                  _buildSectionTitle('Modo de Preparo'),
                  _buildPreparos(),
                  const SizedBox(height: 24),
                ],

                // Composições opcionais (ingredientes removíveis)
                if (produto.composicoesOpcionais.isNotEmpty) ...[
                  _buildSectionTitle('Ingredientes (toque para remover)'),
                  _buildComposicoes(),
                  const SizedBox(height: 24),
                ],

                // Complementos
                if (produto.complementos.isNotEmpty) ...[
                  _buildSectionTitle('Complementos'),
                  _buildComplementos(),
                  const SizedBox(height: 24),
                ],

                // Observação
                _buildSectionTitle('Observações'),
                TextField(
                  controller: _observacaoController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Ex: Sem gelo, bem gelado...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFF6B21A8), width: 2),
                    ),
                  ),
                ),

                const SizedBox(height: 100), // Espaço para o bottom bar
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.fastfood, size: 100, color: Colors.grey),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildPreparos() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _produtoCompleto!.preparos.map((preparo) {
        final isSelected = _preparoSelecionado?.grid == preparo.grid;
        return ChoiceChip(
          label: Text(preparo.descricao ?? 'Preparo ${preparo.codigo}'),
          selected: isSelected,
          onSelected: (_) => setState(() => _preparoSelecionado = preparo),
          selectedColor: const Color(0xFF6B21A8).withValues(alpha: 0.2),
          labelStyle: TextStyle(
            color: isSelected ? const Color(0xFF6B21A8) : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildComposicoes() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _produtoCompleto!.composicoesOpcionais.map((comp) {
        final isRemoved = _composicoesRemovidas.contains(comp.grid);
        return FilterChip(
          label: Text(comp.materiaPrimaNome ?? 'Item ${comp.materiaPrima}'),
          selected: !isRemoved,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _composicoesRemovidas.remove(comp.grid);
              } else {
                _composicoesRemovidas.add(comp.grid);
              }
            });
          },
          selectedColor: Colors.green.withValues(alpha: 0.2),
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          checkmarkColor: Colors.green,
          labelStyle: TextStyle(
            decoration: isRemoved ? TextDecoration.lineThrough : null,
            color: isRemoved ? Colors.red : Colors.green[700],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildComplementos() {
    return Column(
      children: _produtoCompleto!.complementos.map((comp) {
        final quantidade = _complementosSelecionados[comp.complementoGrid] ?? 0;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comp.complementoNome ?? 'Complemento',
                      style: const TextStyle(fontSize: 16),
                    ),
                    if (comp.preco != null && comp.preco! > 0)
                      Text(
                        '+ ${ParsingUtils.formatCurrency(comp.preco!)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              // Controles de quantidade
              IconButton(
                onPressed: quantidade > 0
                    ? () => setState(() {
                          if (quantidade == 1) {
                            _complementosSelecionados
                                .remove(comp.complementoGrid);
                          } else {
                            _complementosSelecionados[comp.complementoGrid] =
                                quantidade - 1;
                          }
                        })
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: const Color(0xFF6B21A8),
              ),
              Text(
                '$quantidade',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => setState(() {
                  _complementosSelecionados[comp.complementoGrid] =
                      quantidade + 1;
                }),
                icon: const Icon(Icons.add_circle),
                color: const Color(0xFF6B21A8),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Controle de quantidade
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _quantidade > 1
                        ? () => setState(() => _quantidade--)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '$_quantidade',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _quantidade++),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Botão adicionar
            Expanded(
              child: ElevatedButton(
                onPressed:
                    _produtoCompleto != null ? _adicionarAoCarrinho : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B21A8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Adicionar  •  ${ParsingUtils.formatCurrency(_precoTotal)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// lib/screens/produto_screen.dart
// Tela de detalhes do produto - Layout dark moderno

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/produto_models.dart';
import '../models/cart_models.dart';
import '../services/api_service.dart';
import '../services/cart_provider.dart';

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
  Uint8List? _imagemBytes;

  // Seleções do usuário
  int _quantidade = 1;
  ProdutoPreparo? _preparoSelecionado;
  final Set<int> _composicoesRemovidas = {};
  final Map<int, int> _complementosSelecionados = {}; // grid -> quantidade
  final TextEditingController _observacaoController = TextEditingController();

  // Cores do tema
  static const _bgDark = Color(0xFF1A1A1A);
  static const _bgCard = Color(0xFF2D2D2D);
  static const _bgInput = Color(0xFF3D3D3D);
  static const _accentRed = Color(0xFFE53935);
  static const _accentGreen = Color(0xFF4CAF50);
  static const _textWhite = Colors.white;
  static const _textGrey = Color(0xFF9E9E9E);

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

      // Carregar imagem
      Uint8List? imgBytes;
      try {
        imgBytes = await Api.instance.getProdutoImagem(widget.produtoGrid);
      } catch (e) {
        print('⚠️ Erro ao carregar imagem: $e');
      }

      setState(() {
        _produtoCompleto = produto;
        _imagemBytes = imgBytes;
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
    // Começa com o preço base do produto vezes a quantidade selecionada
    double total = _precoBase * _quantidade;

    // Soma os complementos
    // Percorre o mapa de selecionados (Grid -> Quantidade)
    _complementosSelecionados.forEach((gridSelecionado, quantidade) {
      try {
        // Busca o objeto completo do complemento na lista original
        final complemento = _produtoCompleto!.complementos.firstWhere(
          (c) => c.complementoGrid == gridSelecionado,
        );

        // Se tiver preço, soma ao total (Preço * Quantidade do complemento)
        if (complemento.preco != null) {
          total += complemento.preco! * quantidade;
        }
      } catch (e) {
        // Ignora caso não encontre o complemento (segurança)
      }
    });

    return total;
  }

  String _formatCurrency(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
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

    // Mostra feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: _textWhite),
            const SizedBox(width: 12),
            Text('${_produtoCompleto!.produto.nomeExibicao} adicionado!'),
          ],
        ),
        backgroundColor: _accentGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _accentRed),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: _accentRed),
            const SizedBox(height: 16),
            const Text(
              'Erro ao carregar produto',
              style: TextStyle(color: _textWhite, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: _textGrey)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadProduto,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentRed,
                foregroundColor: _textWhite,
              ),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_produtoCompleto == null) {
      return const Center(
        child: Text(
          'Produto não encontrado',
          style: TextStyle(color: _textWhite),
        ),
      );
    }

    return Row(
      children: [
        // Lado esquerdo - Imagem e info básica
        Expanded(
          flex: 4,
          child: _buildLeftPanel(),
        ),
        // Lado direito - Personalizações
        Expanded(
          flex: 6,
          child: _buildRightPanel(),
        ),
      ],
    );
  }

  Widget _buildLeftPanel() {
    final produto = _produtoCompleto!.produto;

    return Container(
      color: _bgCard,
      child: Column(
        children: [
          // Header com botão voltar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: _textWhite),
                    style: IconButton.styleFrom(
                      backgroundColor: _bgDark.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Imagem do produto
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _buildProductImage(),
              ),
            ),
          ),

          // Info do produto
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome
                  Text(
                    _produtoCompleto?.produto.nome ?? 'Carregando...',
                    style: const TextStyle(
                      color: _textWhite,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Descrição
                  if (produto.nomeExibicao != null &&
                      produto.nomeExibicao!.isNotEmpty)
                    Expanded(
                      child: Text(
                        produto.nomeExibicao!,
                        style: const TextStyle(
                          color: _textGrey,
                          fontSize: 14,
                          height: 1.4,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  const Spacer(),

                  // Preço unitário
                  Row(
                    children: [
                      const Text(
                        'Preço unitário: ',
                        style: TextStyle(color: _textGrey, fontSize: 16),
                      ),
                      Text(
                        _formatCurrency(_precoBase),
                        style: const TextStyle(
                          color: _accentGreen,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage() {
    if (_imagemBytes != null) {
      return Image.memory(
        _imagemBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    return Container(
      color: _bgInput,
      child: const Center(
        child: Icon(Icons.fastfood, color: _textGrey, size: 80),
      ),
    );
  }

  Widget _buildRightPanel() {
    return Column(
      children: [
        // Conteúdo scrollável
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // Preparos
                if (_produtoCompleto!.preparos.length > 1) ...[
                  _buildSectionTitle('Modo de Preparo', Icons.restaurant),
                  const SizedBox(height: 12),
                  _buildPreparos(),
                  const SizedBox(height: 24),
                ],

                // Composição (ingredientes)
                if (_produtoCompleto!.composicao.isNotEmpty) ...[
                  _buildSectionTitle('Composição', Icons.list_alt),
                  const SizedBox(height: 12),
                  _buildComposicoes(),
                  const SizedBox(height: 24),
                ],

                // Complementos
                if (_produtoCompleto!.complementos.isNotEmpty) ...[
                  _buildSectionTitle('Complementos', Icons.add_circle_outline),
                  const SizedBox(height: 12),
                  _buildComplementos(),
                  const SizedBox(height: 24),
                ],

                // Observações
                _buildSectionTitle('Observações', Icons.edit_note),
                const SizedBox(height: 12),
                _buildObservacaoField(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        // Bottom bar com quantidade e adicionar
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _accentRed, size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: _textWhite,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPreparos() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _produtoCompleto!.preparos.map((preparo) {
        final isSelected = _preparoSelecionado?.grid == preparo.grid;
        return GestureDetector(
          onTap: () => setState(() => _preparoSelecionado = preparo),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? _accentRed : _bgCard,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isSelected ? _accentRed : _bgInput,
                width: 2,
              ),
            ),
            child: Text(
              preparo.descricao ?? 'Preparo ${preparo.codigo}',
              style: TextStyle(
                color: isSelected ? _textWhite : _textGrey,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildComposicoes() {
    final composicoes = _produtoCompleto!.composicao;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: composicoes.asMap().entries.map((entry) {
          final index = entry.key;
          final comp = entry.value;
          final isRemovivel = comp.removivel;
          final isRemovida = _composicoesRemovidas.contains(comp.grid);

          return Column(
            children: [
              Row(
                children: [
                  // Ícone de status
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isRemovida
                          ? _accentRed.withValues(alpha: 0.2)
                          : _accentGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isRemovida ? Icons.remove : Icons.check,
                      color: isRemovida ? _accentRed : _accentGreen,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Nome do ingrediente
                  Expanded(
                    child: Text(
                      comp.materiaPrimaNome ??
                          'Ingrediente ${comp.materiaPrima}',
                      style: TextStyle(
                        color: isRemovida ? _textGrey : _textWhite,
                        fontSize: 15,
                        decoration:
                            isRemovida ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),

                  // Botão remover (se permitido)
                  if (isRemovivel)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isRemovida) {
                            _composicoesRemovidas.remove(comp.grid);
                          } else {
                            _composicoesRemovidas.add(comp.grid);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isRemovida ? _accentGreen : _accentRed,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isRemovida ? 'ADICIONAR' : 'REMOVER',
                          style: const TextStyle(
                            color: _textWhite,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (index < composicoes.length - 1)
                const Divider(color: _bgInput, height: 24),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildComplementos() {
    return Column(
      children: _produtoCompleto!.complementos.map((comp) {
        final quantidade = _complementosSelecionados[comp.complementoGrid] ?? 0;
        final hasPreco = comp.preco != null && comp.preco! > 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: BorderRadius.circular(16),
            border: quantidade > 0
                ? Border.all(color: _accentGreen, width: 2)
                : null,
          ),
          child: Row(
            children: [
              // Info do complemento
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comp.complementoNome ?? 'Complemento',
                      style: const TextStyle(
                        color: _textWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (hasPreco) ...[
                      const SizedBox(height: 4),
                      Text(
                        '+ ${_formatCurrency(comp.preco!)}',
                        style: const TextStyle(
                          color: _accentGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Controles de quantidade
              Container(
                decoration: BoxDecoration(
                  color: _bgInput,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    // Botão diminuir
                    IconButton(
                      onPressed: quantidade > 0
                          ? () => setState(() {
                                if (quantidade == 1) {
                                  _complementosSelecionados
                                      .remove(comp.complementoGrid);
                                } else {
                                  _complementosSelecionados[
                                      comp.complementoGrid] = quantidade - 1;
                                }
                              })
                          : null,
                      icon: const Icon(Icons.remove),
                      color: quantidade > 0 ? _accentRed : _textGrey,
                      iconSize: 20,
                    ),

                    // Quantidade
                    Container(
                      width: 40,
                      alignment: Alignment.center,
                      child: Text(
                        '$quantidade',
                        style: TextStyle(
                          color: quantidade > 0 ? _textWhite : _textGrey,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Botão aumentar
                    IconButton(
                      onPressed: () => setState(() {
                        _complementosSelecionados[comp.complementoGrid] =
                            quantidade + 1;
                      }),
                      icon: const Icon(Icons.add),
                      color: _accentGreen,
                      iconSize: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildObservacaoField() {
    return Container(
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: _observacaoController,
        maxLines: 3,
        style: const TextStyle(color: _textWhite),
        decoration: InputDecoration(
          hintText: 'Ex: Sem gelo, bem gelado, capricha no açaí...',
          hintStyle: TextStyle(color: _textGrey.withValues(alpha: 0.6)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: _bgCard,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _bgCard,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
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
                color: _bgInput,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _quantidade > 1
                        ? () => setState(() => _quantidade--)
                        : null,
                    icon: const Icon(Icons.remove),
                    color: _quantidade > 1 ? _accentRed : _textGrey,
                    iconSize: 28,
                  ),
                  Container(
                    width: 50,
                    alignment: Alignment.center,
                    child: Text(
                      '$_quantidade',
                      style: const TextStyle(
                        color: _textWhite,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _quantidade++),
                    icon: const Icon(Icons.add),
                    color: _accentGreen,
                    iconSize: 28,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),

            // Botão adicionar
            Expanded(
              child: ElevatedButton(
                onPressed:
                    _produtoCompleto != null ? _adicionarAoCarrinho : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentRed,
                  foregroundColor: _textWhite,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shopping_cart, size: 24),
                    const SizedBox(width: 12),
                    const Text(
                      'ADICIONAR',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _formatCurrency(_precoTotal),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

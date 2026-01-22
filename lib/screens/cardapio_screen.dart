// lib/screens/cardapio_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Adicione intl no pubspec.yaml se não tiver

import '../models/cardapio_models.dart';
import '../services/cardapio_service.dart';
// import '../services/carrinho_service.dart'; // Descomente se tiver
// import '../widgets/animacao_carrinho_widget.dart'; // Descomente se tiver
// import './produto_detalhes_screen.dart'; // Descomente se tiver
// import './carrinho_screen.dart'; // Descomente se tiver

class CardapioScreen extends StatefulWidget {
  final String nomeCliente;
  final Map<String, dynamic>? dadosCliente;

  const CardapioScreen({
    super.key,
    required this.nomeCliente,
    this.dadosCliente,
  });

  @override
  State<CardapioScreen> createState() => _CardapioScreenState();
}

class _CardapioScreenState extends State<CardapioScreen>
    with TickerProviderStateMixin {
  // Cores do projeto
  static const roxo = Color(0xFF4B0082);
  static const cinzaFundo = Color(0xFFF6F6F8);

  // Dados
  CardapioCompletoResponse? _dadosCardapio;
  bool _isLoading = true;
  String _erro = '';

  // Controladores
  late PageController _pageController;
  int _secaoAtualIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _carregarDados();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
      _erro = '';
    });

    // ID 1 é o cardápio padrão, ajuste se necessário
    final resultado = await CardapioService.obterCardapioDigitalCompleto(
      158913789981,
    );

    if (mounted) {
      setState(() {
        if (resultado != null) {
          _dadosCardapio = resultado;
          // Ordena seções pela ordem
          _dadosCardapio!.secoes.sort(
            (a, b) => a.secao.ordem.compareTo(b.secao.ordem),
          );
        } else {
          _erro = 'Não foi possível carregar o cardápio. Verifique a conexão.';
        }
        _isLoading = false;
      });
    }
  }

  void _mudarSecao(int index) {
    setState(() {
      _secaoAtualIndex = index;
    });
    // Rola o PageView principal para a seção selecionada
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cinzaFundo,
      body: _buildBody(),
      // floatingActionButton: ... // Seu carrinho aqui
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: roxo));
    }

    if (_erro.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _erro,
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _carregarDados,
              style: ElevatedButton.styleFrom(backgroundColor: roxo),
              child: const Text(
                "Tentar Novamente",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    if (_dadosCardapio == null || _dadosCardapio!.secoes.isEmpty) {
      return const Center(child: Text("Cardápio vazio."));
    }

    return Row(
      children: [
        // === BARRA LATERAL (ROLETA) ===
        _buildSidebar(),

        // === CONTEÚDO PRINCIPAL ===
        Expanded(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  onPageChanged: (index) {
                    setState(() {
                      _secaoAtualIndex = index;
                    });
                  },
                  itemCount: _dadosCardapio!.secoes.length,
                  itemBuilder: (context, index) {
                    return _buildSecaoContent(_dadosCardapio!.secoes[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildSidebar() {
    return Container(
      width: 100, // Largura da barra lateral
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Logo ou Ícone
          const Icon(Icons.restaurant_menu, color: roxo, size: 40),
          const SizedBox(height: 20),

          Expanded(
            child: ListView.builder(
              itemCount: _dadosCardapio!.secoes.length,
              itemBuilder: (context, index) {
                final secao = _dadosCardapio!.secoes[index];
                final bool isSelected = index == _secaoAtualIndex;

                return GestureDetector(
                  onTap: () => _mudarSecao(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 8,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? roxo : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow:
                          isSelected
                              ? [
                                BoxShadow(
                                  color: roxo.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                              : [],
                    ),
                    child: Column(
                      children: [
                        // Ícone dinâmico baseado no nome da seção
                        Icon(
                          _getIconForSecao(secao.secao.nome),
                          color: isSelected ? Colors.white : Colors.grey,
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          secao.secao.nome,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey,
                            fontSize: 12,
                            fontWeight:
                                isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
      color: cinzaFundo,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Olá, ${widget.nomeCliente}",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Text(
                "O que vamos pedir hoje?",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
          // Botão Carrinho ou Perfil poderia ficar aqui
        ],
      ),
    );
  }

  Widget _buildSecaoContent(SecaoCompleta secaoCompleta) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título da Seção
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              secaoCompleta.secao.nome,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: roxo,
              ),
            ),
          ),

          // Banner da Seção (Se houver imagem)
          if (secaoCompleta.imagens.isNotEmpty) ...[
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  // Substitua pelo seu IP/Caminho correto se for local
                  image: NetworkImage(secaoCompleta.imagens.first.caminho),
                  fit: BoxFit.cover,
                  // Fallback para erro de imagem
                  onError: (obj, stack) {},
                ),
                color: Colors.grey[300], // Cor de fundo se imagem falhar
              ),
              child:
                  secaoCompleta.imagens.first.caminho.isEmpty
                      ? const Icon(
                        Icons.fastfood,
                        size: 50,
                        color: Colors.white,
                      )
                      : null,
            ),
            const SizedBox(height: 24),
          ],

          // Grid de Produtos
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75, // Ajuste para altura do card
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: secaoCompleta.produtos.length,
            itemBuilder: (context, index) {
              return _buildProdutoCard(secaoCompleta.produtos[index]);
            },
          ),

          // Espaço extra no final para não ficar colado
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildProdutoCard(ProdutoComposto produto) {
    final formatadorPreco = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    return GestureDetector(
      onTap: () {
        // Navegar para detalhes
        // Navigator.push(context, MaterialPageRoute(builder: (_) => ProdutoDetalhesScreen(produto: produto)));
        print("Tocou em ${produto.nome}");
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem do Produto
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  color: Colors.grey[100],
                ),
                alignment: Alignment.center,
                child: Icon(
                  _getIconForProduct(produto.nome),
                  size: 40,
                  color: roxo.withOpacity(0.5),
                ),
              ),
            ),

            // Informações
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      produto.nome,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      formatadorPreco.format(produto.preco),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: roxo,
                        fontSize: 16,
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

  // Helpers para Ícones
  IconData _getIconForSecao(String nome) {
    final n = nome.toLowerCase();
    if (n.contains('bebida')) return Icons.local_drink;
    if (n.contains('lanche') || n.contains('burger')) return Icons.lunch_dining;
    if (n.contains('sobremesa') || n.contains('doce')) return Icons.icecream;
    if (n.contains('combo')) return Icons.fastfood;
    return Icons.restaurant;
  }

  IconData _getIconForProduct(String nome) {
    final n = nome.toLowerCase();
    if (n.contains('coca') || n.contains('suco')) return Icons.local_drink;
    if (n.contains('batata')) return Icons.kebab_dining; // Apenas ilustrativo
    return Icons.fastfood;
  }
}

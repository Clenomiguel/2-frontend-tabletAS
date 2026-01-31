// lib/screens/menu_screen.dart

// --- Imports de Bibliotecas do Flutter ---
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// --- Imports de Componentes Modulares (Nossa refatoração) ---
import '../componentes/menu_principal/carrosel_inicial.dart';
import '../componentes/menu_principal/barra_superior.dart';
import '../componentes/comuns/controle_inativacao.dart';
import '../componentes/menu_principal/resultado_pesquisa.dart';
import '../componentes/menu_principal/barra_lateral.dart'; // MenuSidebar
import '../componentes/menu_principal/produto_card.dart';
import '../componentes/comuns/botao_carrinho_flutuante.dart';
import '../componentes/comuns/estado_carregamento.dart';
import '../componentes/comuns/estado_erro.dart';

// --- Imports de Utilitários e Modelos ---
import '../utilitarios/cores_app.dart';
import '../modelos/cardapio_models.dart';

// --- Imports de Serviços ---
import '../servicos/cart_provider.dart';
import '../servicos/api_service.dart';

// --- Imports de Outras Telas ---
import './tela_produto_detalhes.dart';
import './tela_carrinho.dart';
import './tela_minha_conta.dart';

/// Tela Principal do Cardápio (Menu)
/// Gerencia o estado global da navegação, carregamento de dados e inatividade.
class MenuScreen extends StatefulWidget {
  // IDs opcionais caso o cardápio ou mesa sejam forçados via navegação
  final int? cardapioId;
  final int? mesa;

  const MenuScreen({super.key, this.cardapioId, this.mesa});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  // --- Variáveis de Estado de Dados ---
  CardapioCompleto? _cardapio; // Objeto principal com todos os produtos
  bool _isLoading = true; // Controla o spinner de carregamento
  String? _error; // Armazena mensagem de erro se a API falhar

  // --- Variáveis de Estado de UI ---
  int _selectedSecaoIndex = 0; // Índice da categoria selecionada na sidebar
  bool _showCarousel =
      true; // Se true, mostra o descanso de tela (vídeo/imagem)

  // --- Controladores ---
  late InactivityController _inactivityController; // Detecta falta de toque
  final TextEditingController _searchController =
      TextEditingController(); // Input de busca

  // --- Variáveis de Busca ---
  String _searchQuery = ''; // Termo digitado pelo usuário
  List<CardapioProduto> _searchResults = []; // Lista filtrada de produtos

  // --- Constantes ---
  static const int _inactivityTimeoutSeconds =
      90; // Tempo para voltar ao carrossel

  @override
  void initState() {
    super.initState();

    // Inicializa o controlador de inatividade
    _inactivityController = InactivityController(
      timeout: const Duration(seconds: _inactivityTimeoutSeconds),
      onTimeout: _onInactivityTimeout,
    );

    // Busca os dados do cardápio assim que a tela inicia
    _loadCardapio();
  }

  @override
  void dispose() {
    // É crucial descartar os controladores para evitar vazamento de memória
    _inactivityController.stop();
    _searchController.dispose();
    super.dispose();
  }

  // --- Lógica de Inatividade ---

  /// Chamado quando o tempo de inatividade estoura (ex: 90 segundos sem tocar)
  void _onInactivityTimeout() {
    // Se a tela não está mais montada ou o carrossel já está visível, não faz nada
    if (!mounted || _showCarousel) return;

    // Regra de Negócio: Limpa o carrinho ao atingir o tempo de inatividade (segurança)
    context.read<CartProvider>().reset();

    // Volta para o modo "Descanso de Tela" e reseta a seleção
    setState(() {
      _showCarousel = true;
      _selectedSecaoIndex = 0;
    });
  }

  /// Registra que o usuário tocou na tela, resetando o timer
  void _registerUserActivity() {
    if (!_showCarousel) {
      _inactivityController.reset();
    }
  }

  /// Esconde o carrossel e inicia a contagem de inatividade
  void _closeCarousel() {
    setState(() => _showCarousel = false);
    _inactivityController.start();
  }

  /// Força a exibição do carrossel (manualmente)
  void _openCarousel() {
    _inactivityController.stop();
    setState(() => _showCarousel = true);
  }

  // --- Lógica de Busca ---

  /// Filtra os produtos localmente baseado no input do usuário
  void _onSearch(String query) {
    _registerUserActivity(); // Busca conta como atividade

    setState(() {
      _searchQuery = query.trim().toLowerCase();

      // Se a busca estiver vazia, limpa a lista
      if (_searchQuery.isEmpty) {
        _searchResults = [];
        return;
      }

      // Varre todas as seções e produtos procurando correspondência
      _searchResults = [];
      for (final secao in _cardapio?.secoes ?? []) {
        for (final produto in secao.produtos) {
          final nome = produto.produto.nome.toLowerCase();
          final descricao = (produto.produto.descricao ?? '').toLowerCase();

          // Verifica se o termo está no nome OU na descrição
          if (nome.contains(_searchQuery) || descricao.contains(_searchQuery)) {
            _searchResults.add(produto);
          }
        }
      }
    });
  }

  /// Limpa o campo de busca e restaura a visualização normal
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _searchResults = [];
    });
  }

  // --- Lógica de API ---

  /// Carrega o JSON do cardápio do backend
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

  // --- Navegação e Ações ---

  /// Abre a tela de detalhes do produto
  void _onProdutoTap(CardapioProduto produto) {
    _registerUserActivity();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProdutoScreen(
          produtoGrid: produto.produtoId,
          precoCardapio: produto.preco,
        ),
      ),
    ).then((_) => _inactivityController.reset()); // Reseta timer ao voltar
  }

  /// Abre a tela do carrinho
  void _openCart() {
    _registerUserActivity();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartScreen()),
    ).then((_) => _inactivityController.reset());
  }

  /// Simula chamada do garçom
  void _chamarGarcom() {
    _registerUserActivity();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Garçom chamado! Aguarde...'),
        backgroundColor: AppColors.accentRed,
      ),
    );
  }

  /// Abre tela de conta/pedidos
  void _openMinhaConta() {
    _registerUserActivity();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MinhaContaScreen()),
    ).then((_) => _inactivityController.reset());
  }

  // --- Construção da UI (Build) ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      // Listener captura toques em qualquer lugar da tela p/ resetar timer
      body: Listener(
        onPointerDown: (_) => _registerUserActivity(),
        onPointerMove: (_) => _registerUserActivity(),
        child: Stack(
          children: [
            // Camada Principal: Barra Superior + Conteúdo (Sidebar/Grid)
            Column(
              children: [
                MenuTopBar(
                  mesa: widget.mesa,
                  searchController: _searchController,
                  searchQuery: _searchQuery,
                  onOpenCarousel: _openCarousel,
                  onSearch: _onSearch,
                  onClearSearch: _clearSearch,
                  onChamarGarcom: _chamarGarcom,
                  onOpenMinhaConta: _openMinhaConta,
                  onOpenCart: _openCart,
                ),
                Expanded(child: _buildBody()),
              ],
            ),

            // Camada Flutuante: Botão do Carrinho (só aparece se carrossel fechado)
            if (!_showCarousel)
              FloatingCartButton(
                onTap: _openCart,
              ),

            // Camada Superior: Carrossel (Descanso de tela)
            if (_showCarousel && !_isLoading && _error == null)
              _buildCarouselOverlay(),
          ],
        ),
      ),
    );
  }

  /// Gerencia qual conteúdo mostrar no corpo da tela
  Widget _buildBody() {
    // 1. Estado de Carregamento (Componente Modular)
    if (_isLoading) {
      return const EstadoCarregamento(mensagem: 'Carregando cardápio...');
    }

    // 2. Estado de Erro (Componente Modular)
    if (_error != null) {
      return EstadoErro(
        mensagem: _error!,
        onTentarNovamente: _loadCardapio,
      );
    }

    // 3. Estado Vazio (Proteção de nulos)
    if (_cardapio == null || _cardapio!.secoes.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum produto disponível',
          style: TextStyle(color: AppColors.textWhite),
        ),
      );
    }

    // 4. Conteúdo Principal: Sidebar + Grid
    return Row(
      children: [
        // Menu Lateral Modularizado
        MenuSidebar(
          secoes: _cardapio!.secoesOrdenadas,
          selectedIndex: _selectedSecaoIndex,
          onSecaoSelected: (index) {
            _registerUserActivity();
            setState(() => _selectedSecaoIndex = index);
          },
        ),
        // Conteúdo da Direita (Grid ou Busca)
        Expanded(child: _buildMainContent()),
      ],
    );
  }

  /// Overlay do Carrossel em tela cheia
  Widget _buildCarouselOverlay() {
    return GestureDetector(
      onTap: _closeCarousel, // Qualquer toque fecha o carrossel
      child: Container(
        color: Colors.black.withValues(alpha: 0.95),
        child: const CarouselWidget(),
      ),
    );
  }

  /// Decide se mostra a Grid normal ou os Resultados da Busca
  Widget _buildMainContent() {
    // Se tem texto na busca, mostra widget de resultados
    if (_searchQuery.isNotEmpty) {
      return _buildSearchResults();
    }

    // Validação de índice seguro
    final secoes = _cardapio!.secoesOrdenadas;
    if (_selectedSecaoIndex >= secoes.length) return const SizedBox();

    final secao = secoes[_selectedSecaoIndex];
    final produtos = secao.produtos;

    // Se a categoria está vazia
    if (produtos.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum produto nesta categoria',
          style: TextStyle(color: AppColors.textWhite),
        ),
      );
    }

    // Grid padrão da categoria
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título da Seção
        Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Text(
                secao.nome.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),

        // Grid de Cards
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, // 4 colunas
              childAspectRatio: 1.00, // Quadrado
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: produtos.length,
            itemBuilder: (context, index) {
              final produto = produtos[index];
              // Card Modularizado
              return ProdutoCard(
                produto: produto,
                onTap: () => _onProdutoTap(produto),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Widget de Resultados de Busca
  Widget _buildSearchResults() {
    return SearchResultsWidget(
      searchQuery: _searchQuery,
      results: _searchResults,
      onClear: _clearSearch,
      onProductTap: _onProdutoTap,
      // Passamos o construtor do card para o widget de busca reutilizar
      productBuilder: (produto) => ProdutoCard(
        produto: produto,
        onTap: () => _onProdutoTap(produto),
      ),
    );
  }
}

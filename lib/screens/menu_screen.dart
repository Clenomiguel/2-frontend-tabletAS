// lib/screens/menu_screen.dart
// Tela principal do cardápio - Layout moderno estilo totem

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../models/cardapio_models.dart';
import '../services/cart_provider.dart';
import '../services/api_service.dart';
import 'produto_screen.dart';
import 'cart_screen.dart';
import 'minha_conta_screen.dart';

/// Decodifica base64 de forma segura
Uint8List? safeBase64Decode(String base64String) {
  try {
    String clean = base64String.replaceAll(RegExp(r'\s'), '');
    final padding = clean.length % 4;
    if (padding > 0) {
      clean += '=' * (4 - padding);
    }
    return base64Decode(clean);
  } catch (e) {
    return null;
  }
}

class MenuScreen extends StatefulWidget {
  final int? cardapioId;
  final int? mesa;

  const MenuScreen({super.key, this.cardapioId, this.mesa});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  CardapioCompleto? _cardapio;
  bool _isLoading = true;
  String? _error;
  int _selectedSecaoIndex = 0;
  bool _showCarousel = true; // Mostrar carrossel no início

  // Timer de inatividade
  Timer? _inactivityTimer;

  // ============================================================
  // CONFIGURAÇÃO DE TIMEOUT POR INATIVIDADE
  // ============================================================
  // Tempo em segundos para voltar ao carrossel após inatividade
  // Padrão: 90 segundos (1 minuto e 30 segundos)
  // TODO: Mover para tela de configurações
  static const int _inactivityTimeoutSeconds = 90;
  // ============================================================

  // Cores do tema
  static const _bgDark = Color(0xFF1A1A1A);
  static const _bgSidebar = Color(0xFF2D2D2D);
  static const _accentRed = Color(0xFFE53935);
  static const _textWhite = Colors.white;
  static const _textGrey = Color(0xFF9E9E9E);

  @override
  void initState() {
    super.initState();
    _loadCardapio();
    _startInactivityTimer();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  /// Inicia ou reinicia o timer de inatividade
  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();

    // Só inicia o timer se não estiver no carrossel
    if (!_showCarousel) {
      _inactivityTimer = Timer(
        Duration(seconds: _inactivityTimeoutSeconds),
        _onInactivityTimeout,
      );
    }
  }

  /// Chamado quando o timeout de inatividade expira
  void _onInactivityTimeout() {
    if (mounted && !_showCarousel) {
      setState(() {
        _showCarousel = true;
        _selectedSecaoIndex = 0; // Reseta a seção selecionada
      });
    }
  }

  /// Inicia o timer pela primeira vez
  void _startInactivityTimer() {
    _resetInactivityTimer();
  }

  /// Registra atividade do usuário e reseta o timer
  void _registerUserActivity() {
    _resetInactivityTimer();
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

  void _onProdutoTap(CardapioProduto produto) {
    _registerUserActivity();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProdutoScreen(
          produtoGrid: produto.produtoId,
          precoCardapio: produto.preco,
          nomeProduto: produto.produto.nomeExibicao,
        ),
      ),
    ).then((_) => _resetInactivityTimer()); // Reseta ao voltar
  }

  void _openCart() {
    _registerUserActivity();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CartScreen()),
    ).then((_) => _resetInactivityTimer()); // Reseta ao voltar
  }

  void _closeCarousel() {
    setState(() => _showCarousel = false);
    _resetInactivityTimer(); // Inicia timer ao sair do carrossel
  }

  void _openCarousel() {
    _inactivityTimer?.cancel(); // Para o timer ao entrar no carrossel
    setState(() => _showCarousel = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      // Listener detecta qualquer toque na tela para resetar o timer
      body: Listener(
        onPointerDown: (_) => _registerUserActivity(),
        onPointerMove: (_) => _registerUserActivity(),
        child: Stack(
          children: [
            // Conteúdo principal
            Column(
              children: [
                _buildTopBar(),
                Expanded(child: _buildBody()),
              ],
            ),

            // Botão flutuante do carrinho
            if (!_showCarousel) _buildFloatingCartButton(),

            // Carrossel em tela cheia (overlay)
            if (_showCarousel && !_isLoading && _error == null)
              _buildCarouselOverlay(),
          ],
        ),
      ),
    );
  }

  /// Botão flutuante do carrinho
  Widget _buildFloatingCartButton() {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        if (cart.quantidadeTotal == 0) return const SizedBox.shrink();

        return Positioned(
          bottom: 20,
          right: 20,
          child: GestureDetector(
            onTap: _openCart,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: _accentRed,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ícone do carrinho com badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.shopping_cart,
                          color: _textWhite, size: 28),
                      Positioned(
                        top: -8,
                        right: -8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${cart.quantidadeTotal}',
                            style: const TextStyle(
                              color: _accentRed,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Texto e valor
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'VER CARRINHO',
                        style: TextStyle(
                          color: _textWhite,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'R\$ ${cart.total.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: const TextStyle(
                          color: _textWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.arrow_forward_ios,
                      color: _textWhite, size: 18),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Barra superior
  Widget _buildTopBar() {
    return Container(
      height: 70,
      color: _bgDark,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Logo - clicável para abrir carrossel
          GestureDetector(
            onTap: _openCarousel,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _accentRed,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.restaurant_menu,
                  color: _textWhite, size: 28),
            ),
          ),
          const SizedBox(width: 20),

          // Mesa
          if (widget.mesa != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _bgSidebar,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.table_bar, color: _textGrey, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'MESA ${widget.mesa}',
                    style: const TextStyle(
                      color: _textWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 20),

          // Busca
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _bgSidebar,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, color: _textGrey, size: 20),
                  SizedBox(width: 12),
                  Text(
                    'BUSCAR',
                    style: TextStyle(color: _textGrey, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),

          // Botões de ação
          _buildActionButton(
              Icons.room_service_outlined, 'CHAMAR\nGARÇOM', _chamarGarcom),
          const SizedBox(width: 12),
          _buildActionButton(
              Icons.receipt_long_outlined, 'MINHA\nCONTA', _openMinhaConta),
          const SizedBox(width: 12),
          _buildActionButton(
              Icons.shopping_cart_outlined, 'CARRINHO', _openCart),
        ],
      ),
    );
  }

  void _chamarGarcom() {
    _registerUserActivity();
    // TODO: Implementar chamada de garçom
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Garçom chamado! Aguarde...'),
        backgroundColor: Color(0xFFE53935),
      ),
    );
  }

  void _openMinhaConta() {
    _registerUserActivity();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MinhaContaScreen()),
    ).then((_) => _resetInactivityTimer()); // Reseta ao voltar
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _accentRed,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: _textWhite, size: 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: _textWhite,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: _accentRed),
            SizedBox(height: 16),
            Text('Carregando cardápio...', style: TextStyle(color: _textWhite)),
          ],
        ),
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
              'Erro ao carregar cardápio',
              style: TextStyle(color: _textWhite, fontSize: 20),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _textGrey),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadCardapio,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentRed,
                foregroundColor: _textWhite,
              ),
            ),
          ],
        ),
      );
    }

    if (_cardapio == null || _cardapio!.secoes.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum produto disponível',
          style: TextStyle(color: _textWhite),
        ),
      );
    }

    return Row(
      children: [
        _buildSidebar(),
        Expanded(child: _buildMainContent()),
      ],
    );
  }

  /// Carrossel de imagens/vídeos em tela cheia
  Widget _buildCarouselOverlay() {
    return GestureDetector(
      onTap: _closeCarousel,
      child: Container(
        color: Colors.black.withValues(alpha: 0.95),
        child: const _CarouselWidget(),
      ),
    );
  }

  /// Menu lateral com categorias
  Widget _buildSidebar() {
    final secoes = _cardapio!.secoesOrdenadas;

    return Container(
      width: 140,
      color: _bgSidebar,
      child: Column(
        children: [
          // Seções do cardápio
          Expanded(
            child: ListView.separated(
              itemCount: secoes.length,
              separatorBuilder: (_, __) => const Divider(
                color: Color(0xFF404040),
                height: 1,
              ),
              itemBuilder: (context, index) {
                final secao = secoes[index];
                final isSelected = index == _selectedSecaoIndex;

                return _buildSidebarItem(
                  icon: _getSecaoIcon(secao.nome),
                  label: secao.nome.toUpperCase(),
                  isSelected: isSelected,
                  imageBytes: secao.imagens.isNotEmpty
                      ? safeBase64Decode(secao.imagens.first)
                      : null,
                  onTap: () => setState(() => _selectedSecaoIndex = index),
                );
              },
            ),
          ),

          // Links inferiores
          const Divider(color: Color(0xFF404040), height: 1),
          _buildSidebarLink('SOBRE'),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    Uint8List? imageBytes,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? _accentRed.withValues(alpha: 0.2) : null,
          border: isSelected
              ? const Border(
                  left: BorderSide(color: _accentRed, width: 4),
                )
              : null,
        ),
        child: Column(
          children: [
            if (imageBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  imageBytes,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    icon,
                    color: isSelected ? _textWhite : _textGrey,
                    size: 28,
                  ),
                ),
              )
            else
              Icon(
                icon,
                color: isSelected ? _textWhite : _textGrey,
                size: 28,
              ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? _textWhite : _textGrey,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarLink(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Text(
        label,
        style: const TextStyle(
          color: _textGrey,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  IconData _getSecaoIcon(String nome) {
    final lower = nome.toLowerCase();
    if (lower.contains('hambur') || lower.contains('lanche')) {
      return Icons.lunch_dining;
    }
    if (lower.contains('pizza')) return Icons.local_pizza;
    if (lower.contains('bebida') || lower.contains('drink')) {
      return Icons.local_bar;
    }
    if (lower.contains('sobremesa') || lower.contains('doce')) {
      return Icons.cake;
    }
    if (lower.contains('cafe') || lower.contains('café')) {
      return Icons.coffee;
    }
    if (lower.contains('salada')) return Icons.eco;
    if (lower.contains('entrada')) return Icons.restaurant;
    if (lower.contains('prato') || lower.contains('principal')) {
      return Icons.dinner_dining;
    }
    return Icons.fastfood;
  }

  /// Área principal com grid de produtos
  Widget _buildMainContent() {
    final secoes = _cardapio!.secoesOrdenadas;
    if (_selectedSecaoIndex >= secoes.length) return const SizedBox();

    final secao = secoes[_selectedSecaoIndex];
    final produtos = secao.produtos;

    if (produtos.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum produto nesta categoria',
          style: TextStyle(color: _textWhite),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header da seção
        Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Text(
                secao.nome.toUpperCase(),
                style: const TextStyle(
                  color: _textWhite,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _accentRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${produtos.length} itens',
                  style: const TextStyle(
                    color: _textWhite,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Grid de produtos
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: produtos.length,
            itemBuilder: (context, index) {
              final produto = produtos[index];
              return _buildProductCard(produto);
            },
          ),
        ),
      ],
    );
  }

  /// Card de produto melhorado
  Widget _buildProductCard(CardapioProduto produto) {
    return GestureDetector(
      onTap: () => _onProdutoTap(produto),
      child: Container(
        decoration: BoxDecoration(
          color: _bgSidebar,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagem com proporção fixa
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: _ProdutoImageWidget(
                      produtoId: produto.produtoId,
                      imagemBase64: produto.produto.imagemBase64,
                    ),
                  ),
                  // Badge de preço
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _accentRed,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'R\$ ${produto.preco.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: const TextStyle(
                          color: _textWhite,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Info do produto
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      produto.produto.nome,
                      style: const TextStyle(
                        color: _textWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (produto.produto.descricao != null &&
                        produto.produto.descricao!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        produto.produto.descricao!,
                        style: const TextStyle(
                          color: _textGrey,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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

/// Widget para carregar imagem do produto via API
class _ProdutoImageWidget extends StatefulWidget {
  final int produtoId;
  final String? imagemBase64;

  const _ProdutoImageWidget({
    required this.produtoId,
    this.imagemBase64,
  });

  @override
  State<_ProdutoImageWidget> createState() => _ProdutoImageWidgetState();
}

class _ProdutoImageWidgetState extends State<_ProdutoImageWidget> {
  Uint8List? _imageBytes;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    print('🖼️ _ProdutoImageWidget init: produtoId=${widget.produtoId}');
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant _ProdutoImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Se o produtoId mudou, recarregar imagem
    if (oldWidget.produtoId != widget.produtoId) {
      print(
          '🖼️ _ProdutoImageWidget update: ${oldWidget.produtoId} -> ${widget.produtoId}');
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    // Primeiro tenta base64 direto
    if (widget.imagemBase64 != null && widget.imagemBase64!.isNotEmpty) {
      print('🖼️ Produto ${widget.produtoId}: usando base64 direto');
      final bytes = safeBase64Decode(widget.imagemBase64!);
      if (bytes != null) {
        setState(() {
          _imageBytes = bytes;
          _isLoading = false;
        });
        return;
      }
    }

    // Se não tem, busca da API
    try {
      print('🖼️ Produto ${widget.produtoId}: buscando da API...');
      final bytes = await Api.instance.getProdutoImagem(widget.produtoId);
      if (mounted) {
        setState(() {
          _imageBytes = bytes;
          _isLoading = false;
          _hasError = bytes == null;
        });
        print(
            '🖼️ Produto ${widget.produtoId}: ${bytes != null ? "OK" : "sem imagem"}');
      }
    } catch (e) {
      print('🖼️ Produto ${widget.produtoId}: ERRO $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: const Color(0xFF3D3D3D),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: Color(0xFF9E9E9E),
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    if (_hasError || _imageBytes == null) {
      return Container(
        color: const Color(0xFF3D3D3D),
        child: const Center(
          child: Icon(
            Icons.fastfood,
            color: Color(0xFF9E9E9E),
            size: 48,
          ),
        ),
      );
    }

    return Image.memory(
      _imageBytes!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFF3D3D3D),
        child: const Center(
          child: Icon(
            Icons.fastfood,
            color: Color(0xFF9E9E9E),
            size: 48,
          ),
        ),
      ),
    );
  }
}

/// Widget do Carrossel de Imagens/Vídeos
class _CarouselWidget extends StatefulWidget {
  const _CarouselWidget();

  @override
  State<_CarouselWidget> createState() => _CarouselWidgetState();
}

class _CarouselWidgetState extends State<_CarouselWidget> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoPlayTimer;
  List<CarouselSlide> _slides = [];
  bool _isLoading = true;
  bool _isVideoPlaying = false; // Bloqueia avanço durante vídeo
  VideoPlayerController? _videoController;

  // ============================================================
  // CONFIGURAÇÃO DO CARROSSEL
  // ============================================================

  // ✅ ATIVO: Pasta local (assets)
  // Coloque suas imagens em: assets/carousel/
  // Nomeie como: 1.jpg, 2.png, 3.jpg, etc.
  static const String _assetsFolder = 'assets/carousel';

  // Lista de arquivos do carrossel (adicione seus arquivos aqui)
  static const List<String> _carouselFiles = [
    '1.jpg',
    '2.jpg',
    '3.mp4',
    // Adicione mais conforme necessário:
    // '4.png',
    // '5.jpg',
    // '6.mp4',  // Vídeos também são suportados
  ];

  // URLs diretas - DESATIVADO
  static const List<String> _remoteUrls = [];

  // Carregar da API - DESATIVADO
  static const bool _loadFromApi = false;
  static const String _apiEndpoint = '/api/v1/banners';

  // Tempo de exibição de cada slide (em segundos)
  static const int _autoPlaySeconds = 5;

  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadSlides();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadSlides() async {
    List<CarouselSlide> slides = [];

    try {
      // Prioridade 1: Carregar da API
      if (_loadFromApi) {
        slides = await _loadFromApiEndpoint();
      }

      // Prioridade 2: URLs remotas configuradas
      if (slides.isEmpty && _remoteUrls.isNotEmpty) {
        slides = _remoteUrls.map((url) => CarouselSlide.fromUrl(url)).toList();
      }

      // Prioridade 3: Assets locais (pasta carousel)
      if (slides.isEmpty && _carouselFiles.isNotEmpty) {
        slides = _loadFromLocalAssets();
      }

      // Fallback: Slides padrão se não encontrar nada
      if (slides.isEmpty) {
        slides = _getDefaultSlides();
      }
    } catch (e) {
      debugPrint('Erro ao carregar slides: $e');
      slides = _getDefaultSlides();
    }

    if (mounted) {
      setState(() {
        _slides = slides;
        _isLoading = false;
      });
      _startAutoPlay();
    }
  }

  List<CarouselSlide> _loadFromLocalAssets() {
    return _carouselFiles.map((filename) {
      final path = '$_assetsFolder/$filename';
      final lower = filename.toLowerCase();
      final isVideo = lower.endsWith('.mp4') || lower.endsWith('.webm');

      return CarouselSlide(
        type: isVideo ? SlideType.video : SlideType.image,
        assetPath: path,
      );
    }).toList();
  }

  Future<List<CarouselSlide>> _loadFromApiEndpoint() async {
    // Implementar quando usar API
    return [];
  }

  List<CarouselSlide> _getDefaultSlides() {
    return [
      CarouselSlide(
        type: SlideType.promo,
        title: 'BEM-VINDO!',
        subtitle: 'Faça seu pedido pelo totem',
        gradient: [const Color(0xFFE53935), const Color(0xFFFF7043)],
        icon: Icons.restaurant_menu,
      ),
      CarouselSlide(
        type: SlideType.promo,
        title: 'PROMOÇÕES',
        subtitle: 'Confira nossas ofertas especiais',
        gradient: [const Color(0xFF7B1FA2), const Color(0xFFE91E63)],
        icon: Icons.local_offer,
      ),
      CarouselSlide(
        type: SlideType.promo,
        title: 'NOVIDADES',
        subtitle: 'Experimente nossos novos pratos',
        gradient: [const Color(0xFF00897B), const Color(0xFF4CAF50)],
        icon: Icons.new_releases,
      ),
    ];
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer =
        Timer.periodic(Duration(seconds: _autoPlaySeconds), (timer) {
      // Não avança se um vídeo estiver tocando
      if (_isVideoPlaying) return;

      if (_pageController.hasClients && _slides.isNotEmpty) {
        final nextPage = (_currentPage + 1) % _slides.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onPageChanged(int index) {
    // Limpa o vídeo anterior
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;

    setState(() {
      _currentPage = index;
      _isVideoPlaying = _slides[index].type == SlideType.video;
    });

    // Se for vídeo, inicializa o player
    if (_slides[index].type == SlideType.video) {
      _initVideoForSlide(_slides[index]);
    }
  }

  Future<void> _initVideoForSlide(CarouselSlide slide) async {
    try {
      VideoPlayerController controller;

      if (slide.assetPath != null) {
        controller = VideoPlayerController.asset(slide.assetPath!);
      } else if (slide.networkUrl != null) {
        controller =
            VideoPlayerController.networkUrl(Uri.parse(slide.networkUrl!));
      } else {
        return;
      }

      await controller.initialize();

      // Quando o vídeo terminar, avança para o próximo slide
      controller.addListener(() {
        if (controller.value.position >= controller.value.duration &&
            controller.value.duration > Duration.zero) {
          _onVideoFinished();
        }
      });

      if (mounted) {
        setState(() {
          _videoController = controller;
        });
        controller.play();
      }
    } catch (e) {
      debugPrint('Erro ao inicializar vídeo: $e');
      setState(() => _isVideoPlaying = false);
    }
  }

  void _onVideoFinished() {
    if (!mounted) return;

    setState(() => _isVideoPlaying = false);

    // Avança para o próximo slide
    if (_pageController.hasClients && _slides.isNotEmpty) {
      final nextPage = (_currentPage + 1) % _slides.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFFE53935)),
        ),
      );
    }

    if (_slides.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // PageView com slides
        PageView.builder(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          // Permite arrastar mesmo durante vídeo (para pular)
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: _slides.length,
          itemBuilder: (context, index) {
            return _buildSlide(_slides[index], index == _currentPage);
          },
        ),

        // Indicadores de página
        if (_slides.length > 1)
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: _currentPage == index ? 24 : 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(5),
                  ),
                );
              }),
            ),
          ),

        // Botão para fechar/pular
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'TOQUE PARA FAZER SEU PEDIDO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Indicador de tipo (imagem/vídeo)
        Positioned(
          top: 30,
          right: 30,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _slides[_currentPage].type == SlideType.video
                      ? Icons.videocam
                      : Icons.image,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _slides[_currentPage].type == SlideType.video
                      ? 'VÍDEO'
                      : 'IMAGEM',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlide(CarouselSlide slide, bool isActive) {
    switch (slide.type) {
      case SlideType.image:
        return _buildImageSlide(slide);
      case SlideType.video:
        return _buildVideoSlide(slide, isActive);
      case SlideType.promo:
        return _buildPromoSlide(slide);
    }
  }

  Widget _buildImageSlide(CarouselSlide slide) {
    Widget imageWidget;

    if (slide.networkUrl != null) {
      // Imagem da internet
      imageWidget = Image.network(
        slide.networkUrl!,
        fit: BoxFit.cover,
        headers: const {
          'User-Agent': 'Mozilla/5.0',
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFFE53935)),
                  const SizedBox(height: 16),
                  Text(
                    '${((loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)) * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          );
        },
        errorBuilder: (_, error, ___) {
          debugPrint('Erro ao carregar imagem: $error');
          return _buildErrorPlaceholder(slide.networkUrl);
        },
      );
    } else if (slide.assetPath != null) {
      // Imagem local (assets)
      imageWidget = Image.asset(
        slide.assetPath!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildErrorPlaceholder(slide.assetPath),
      );
    } else {
      imageWidget = _buildErrorPlaceholder(null);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        imageWidget,
        // Gradiente escuro na parte inferior para o texto
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 300,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.8),
                ],
              ),
            ),
          ),
        ),
        // Overlay com título se houver
        if (slide.title != null)
          Positioned(
            bottom: 180,
            left: 40,
            right: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slide.title!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(color: Colors.black54, blurRadius: 10),
                    ],
                  ),
                ),
                if (slide.subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    slide.subtitle!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 20,
                      shadows: [
                        Shadow(color: Colors.black54, blurRadius: 8),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildVideoSlide(CarouselSlide slide, bool isActive) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          color: Colors.black,
          child: _videoController != null &&
                  _videoController!.value.isInitialized &&
                  isActive
              ? FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _videoController!.value.size.width,
                    height: _videoController!.value.size.height,
                    child: VideoPlayer(_videoController!),
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          color: Color(0xFFE53935),
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        slide.title ?? 'Carregando vídeo...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
        ),

        // Barra de progresso do vídeo
        if (_videoController != null &&
            _videoController!.value.isInitialized &&
            isActive)
          Positioned(
            bottom: 160,
            left: 40,
            right: 40,
            child: Column(
              children: [
                // Progresso
                VideoProgressIndicator(
                  _videoController!,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: Color(0xFFE53935),
                    bufferedColor: Colors.white24,
                    backgroundColor: Colors.white10,
                  ),
                ),
                const SizedBox(height: 8),
                // Tempo restante
                ValueListenableBuilder(
                  valueListenable: _videoController!,
                  builder: (context, VideoPlayerValue value, child) {
                    final remaining = value.duration - value.position;
                    final minutes = remaining.inMinutes;
                    final seconds =
                        (remaining.inSeconds % 60).toString().padLeft(2, '0');
                    return Text(
                      'Próximo em $minutes:$seconds',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

        // Título do vídeo
        if (slide.title != null)
          Positioned(
            top: 80,
            left: 40,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                slide.title!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPromoSlide(CarouselSlide slide) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: slide.gradient ??
              [const Color(0xFFE53935), const Color(0xFFFF7043)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Padrão de fundo decorativo
          Positioned.fill(
            child: CustomPaint(
              painter: _PatternPainter(),
            ),
          ),

          // Conteúdo central
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ícone grande
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    slide.icon ?? Icons.restaurant_menu,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),

                // Título
                Text(
                  slide.title ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Subtítulo
                Text(
                  slide.subtitle ?? '',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 22,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPlaceholder([String? url]) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D2D2D), Color(0xFF1A1A1A)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.image_not_supported,
              color: Color(0xFF9E9E9E),
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Erro ao carregar imagem',
              style: TextStyle(
                color: Color(0xFF9E9E9E),
                fontSize: 16,
              ),
            ),
            if (url != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  url.length > 50 ? '${url.substring(0, 50)}...' : url,
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum SlideType { image, video, promo }

class CarouselSlide {
  final SlideType type;
  final String? title;
  final String? subtitle;
  final List<Color>? gradient;
  final IconData? icon;
  final String? assetPath; // Caminho local: assets/carousel/1.jpg
  final String? networkUrl; // URL remota: https://...

  CarouselSlide({
    required this.type,
    this.title,
    this.subtitle,
    this.gradient,
    this.icon,
    this.assetPath,
    this.networkUrl,
  });

  /// Cria slide a partir de URL (detecta tipo automaticamente)
  factory CarouselSlide.fromUrl(String url) {
    final lower = url.toLowerCase();
    final isVideo = lower.endsWith('.mp4') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.mov');

    return CarouselSlide(
      type: isVideo ? SlideType.video : SlideType.image,
      networkUrl: url,
    );
  }

  /// Cria slide a partir de JSON (para carregar da API)
  factory CarouselSlide.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'image';
    SlideType type;

    switch (typeStr) {
      case 'video':
        type = SlideType.video;
        break;
      case 'promo':
        type = SlideType.promo;
        break;
      default:
        type = SlideType.image;
    }

    return CarouselSlide(
      type: type,
      title: json['title'],
      subtitle: json['subtitle'],
      networkUrl: json['url'] ?? json['image_url'] ?? json['video_url'],
    );
  }
}

/// Painter para padrão decorativo de fundo
class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    // Círculos decorativos
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.2),
      100,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.7),
      150,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.9),
      80,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

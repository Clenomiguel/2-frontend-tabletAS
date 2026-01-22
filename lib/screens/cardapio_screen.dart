// lib/screens/cardapio_screen.dart
// VERSÃO ROLETA LATERAL INFINITA + CARRINHO INTEGRADO + IMAGENS DE PRODUTOS

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/cardapio_models.dart';
import '../services/cardapio_service.dart';
import '../services/carrinho_service.dart';
import '../widgets/animacao_carrinho_widget.dart';
import './produto_detalhes_screen.dart';
import './carrinho_screen.dart';
import './splash_screen.dart';

class CardapioScreen extends StatefulWidget {
  final String nomeCliente;
  final Map<String, dynamic>? dadosCliente; // ✅ NOVO

  const CardapioScreen({
    super.key,
    required this.nomeCliente,
    this.dadosCliente, // ✅ NOVO
  });

  @override
  State<CardapioScreen> createState() => _CardapioScreenState();
}

class _CardapioScreenState extends State<CardapioScreen>
    with TickerProviderStateMixin {
  // Cores do projeto
  static const roxo = Color(0xFF4B0082);
  static const cinzaFundo = Color(0xFFF6F6F8);

  // Controllers
  late PageController _sidebarController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Estado da tela
  CardapioCompleto? _cardapioCompleto;
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasConnection = false;

  // Controle da roleta lateral
  int _currentSectionIndex = 0;
  int _virtualIndex = 10000; // Índice virtual para scroll infinito

  // ✅ Timer de inatividade (90 segundos = 1min 30s)
  Timer? _inactivityTimer;
  int _inactivitySeconds = 90;
  static const int _maxInactivitySeconds = 90;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _carregarCardapio();

    // Escuta mudanças no carrinho para atualizar badges
    CarrinhoService.instance.addListener(_onCarrinhoChanged);

    // ✅ Iniciar timer de inatividade
    _iniciarTimerInatividade();
  }

  @override
  void dispose() {
    _sidebarController.dispose();
    _fadeController.dispose();
    CarrinhoService.instance.removeListener(_onCarrinhoChanged);
    _inactivityTimer?.cancel(); // ✅ Cancelar timer de inatividade
    super.dispose();
  }

  void _onCarrinhoChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  // ✅ NOVO: Iniciar/Reiniciar timer de inatividade
  void _iniciarTimerInatividade() {
    _inactivityTimer?.cancel();
    setState(() => _inactivitySeconds = _maxInactivitySeconds);

    _inactivityTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _inactivitySeconds--;

          // Quando chegar a zero, volta para tela inicial
          if (_inactivitySeconds <= 0) {
            _voltarParaTelaInicialPorInatividade();
          }
        });
      }
    });
  }

  // ✅ NOVO: Resetar timer quando houver interação
  void _resetarTimerInatividade() {
    _iniciarTimerInatividade();
  }

  // ✅ NOVO: Voltar para tela inicial por inatividade
  void _voltarParaTelaInicialPorInatividade() {
    _inactivityTimer?.cancel();

    // Limpar o carrinho
    if (CarrinhoService.isNotEmptyStatic) {
      CarrinhoService.limpar();
      if (kDebugMode) {
        debugPrint('🗑️ Carrinho limpo por inatividade');
      }
    }

    // Mostrar mensagem
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sessão encerrada por inatividade'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );

      // Limpar tudo e voltar para splash
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const SplashScreen()),
            (route) => false,
          );
        }
      });
    }
  }

  void _initControllers() {
    // Controller para scroll infinito (inicia no meio para permitir scroll em ambas direções)
    _sidebarController = PageController(
      initialPage: _virtualIndex,
      viewportFraction: 0.25, // Mostra partes dos cards adjacentes
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  void _log(String message, {bool isError = false}) {
    if (kDebugMode) {
      if (isError) {
        debugPrint('❌ CardapioScreen: $message');
      } else {
        debugPrint('✅ CardapioScreen: $message');
      }
    }
  }

  Future<void> _carregarCardapio() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _hasConnection = await CardapioService.verificarConexaoCompleta();

      if (!_hasConnection) {
        throw Exception('Não foi possível conectar com o servidor');
      }

      final cardapio = await CardapioService.obterPrimeiroCardapio();

      setState(() {
        _cardapioCompleto = cardapio;
        _isLoading = false;
      });

      _log('Cardápio carregado: ${cardapio.secoes.length} seções');

      // ✅ DEBUG: Verificar se as imagens dos produtos estão chegando
      //  if (kDebugMode) {
      // await CardapioService.debugImagensProdutos();
      // }

      _fadeController.forward();
      _mostrarSnackBar('Cardápio carregado com sucesso!', isError: false);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      _log('Erro ao carregar cardápio: $e', isError: true);
      _mostrarSnackBar('Erro ao carregar cardápio: $e', isError: true);
    }
  }

  Future<void> _recarregarCardapio() async {
    if (_cardapioCompleto != null) {
      try {
        setState(() => _isLoading = true);
        final cardapio = await CardapioService.recarregarCardapio(
          _cardapioCompleto!.cardapio.id,
        );
        setState(() {
          _cardapioCompleto = cardapio;
          _isLoading = false;
        });
        _mostrarSnackBar('Cardápio atualizado!', isError: false);
      } catch (e) {
        setState(() => _isLoading = false);
        _mostrarSnackBar('Erro ao atualizar: $e', isError: true);
      }
    } else {
      _carregarCardapio();
    }
  }

  void _mostrarSnackBar(String mensagem, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _onPageChanged(int virtualIndex) {
    if (_cardapioCompleto == null || _cardapioCompleto!.secoes.isEmpty) return;

    final realIndex = virtualIndex % _cardapioCompleto!.secoes.length;

    if (realIndex != _currentSectionIndex) {
      setState(() {
        _currentSectionIndex = realIndex;
      });
      _resetarTimerInatividade(); // ✅ Reset timer ao trocar de seção
    }

    // Atualizar índice virtual
    _virtualIndex = virtualIndex;
  }

  int _getRealIndex(int virtualIndex) {
    if (_cardapioCompleto == null || _cardapioCompleto!.secoes.isEmpty) {
      return 0;
    }
    return virtualIndex % _cardapioCompleto!.secoes.length;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // ✅ Reset timer ao tocar na tela ou fazer scroll
      onTap: _resetarTimerInatividade,
      onPanDown: (_) => _resetarTimerInatividade(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: cinzaFundo,
        body:
            _isLoading
                ? _buildLoadingScreen()
                : _errorMessage != null
                ? _buildErrorScreen()
                : _buildMainContent(),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [roxo, roxo.withValues(alpha: 0.8)],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
            SizedBox(height: 24),
            Text(
              'Carregando cardápio...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    _hasConnection ? Icons.error : Icons.wifi_off,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _hasConnection
                        ? 'Erro ao carregar cardápio'
                        : 'Sem conexão',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _sairDoApp,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Voltar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: roxo,
                          side: BorderSide(color: roxo),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _carregarCardapio,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar novamente'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: roxo,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Row(
            children: [
              // MENU LATERAL COM ROLETA INFINITA
              _buildSidebarRoleta(),

              // ÁREA PRINCIPAL COM PRODUTOS
              Expanded(child: _buildProductsArea()),
            ],
          ),
        ),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildHeader() {
    // ✅ Calcular minutos e segundos para display
    final minutes = _inactivitySeconds ~/ 60;
    final seconds = _inactivitySeconds % 60;
    final timeDisplay =
        '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';

    // ✅ Definir cor do timer baseado no tempo restante
    Color timerColor;
    Color timerBgColor;
    if (_inactivitySeconds > 60) {
      timerColor = Colors.white;
      timerBgColor = Colors.white.withValues(alpha: 0.2);
    } else if (_inactivitySeconds > 30) {
      timerColor = Colors.orange;
      timerBgColor = Colors.orange.withValues(alpha: 0.2);
    } else {
      timerColor = Colors.red.shade300;
      timerBgColor = Colors.red.withValues(alpha: 0.2);
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [roxo, roxo.withValues(alpha: 0.8)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'POLPANORTE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'Olá, ${widget.nomeCliente.split(' ').first}!',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
              // ✅ TIMER DE INATIVIDADE
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: timerBgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: timerColor.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_outlined, color: timerColor, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      timeDisplay,
                      style: TextStyle(
                        color: timerColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  _recarregarCardapio();
                  _resetarTimerInatividade(); // ✅ Reset timer
                },
                icon: const Icon(Icons.refresh, color: Colors.white),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: () {
                      _abrirCarrinho();
                      _resetarTimerInatividade(); // ✅ Reset timer
                    },
                    icon: const Icon(Icons.shopping_cart, color: Colors.white),
                  ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: BadgeCarrinhoAnimado(
                      quantidade: CarrinhoService.quantidadeTotalStatic,
                      cor: Colors.orange,
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

  Widget _buildSidebarRoleta() {
    if (_cardapioCompleto == null || _cardapioCompleto!.secoes.isEmpty) {
      return Container(
        width: 50,
        color: Colors.white,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header do menu lateral
          Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [roxo.withValues(alpha: 0.1), Colors.transparent],
              ),
            ),
            child: const Center(
              child: Text(
                'Categorias',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: roxo,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          // Roleta infinita
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: PageView.builder(
                controller: _sidebarController,
                scrollDirection: Axis.vertical,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, virtualIndex) {
                  final realIndex = _getRealIndex(virtualIndex);
                  final secao = _cardapioCompleto!.secoes[realIndex];
                  final isSelected = realIndex == _currentSectionIndex;

                  return _buildSidebarCard(secao, realIndex, isSelected);
                },
              ),
            ),
          ),

          // Indicador de scroll
          SizedBox(
            height: 40,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.keyboard_arrow_up,
                  color: Colors.grey.shade400,
                  size: 16,
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.grey.shade400,
                  size: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarCard(CardapioSecao secao, int index, bool isSelected) {
    final colors = _getGradientColors(index);
    final icon = _getIconFromSecaoNome(secao.nome ?? '');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(
        horizontal: isSelected ? 8 : 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isSelected
                  ? colors
                  : [
                    colors[0].withValues(alpha: 0.3),
                    colors[1].withValues(alpha: 0.3),
                  ],
        ),
        boxShadow:
            isSelected
                ? [
                  BoxShadow(
                    color: colors[0].withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: 2,
                  ),
                ]
                : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        border:
            isSelected
                ? Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 2,
                )
                : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background pattern
            if (isSelected)
              Positioned.fill(
                child: CustomPaint(painter: PatternPainter(colors[0])),
              ),

            // Conteúdo do card
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Ícone
                  Container(
                    width: isSelected ? 25 : 40,
                    height: isSelected ? 25 : 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: isSelected ? 0.3 : 0.6,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: isSelected ? 28 : 22,
                      color: isSelected ? Colors.white : colors[0],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Nome da seção
                  Text(
                    secao.nome ?? 'Seção ${index + 1}',
                    style: TextStyle(
                      fontSize: isSelected ? 12 : 10,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? Colors.white : colors[0],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Contador de produtos
                  Text(
                    '${secao.produtos.length} itens',
                    style: TextStyle(
                      fontSize: 8,
                      color:
                          isSelected
                              ? Colors.white.withValues(alpha: 0.8)
                              : colors[0].withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),

            // Shine effect para card selecionado
            if (isSelected)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.center,
                      colors: [
                        Colors.white.withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsArea() {
    if (_cardapioCompleto == null || _cardapioCompleto!.secoes.isEmpty) {
      return const Center(
        child: Text(
          'Carregando produtos...',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    final secao = _cardapioCompleto!.secoes[_currentSectionIndex];
    final produtos = secao.produtos;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Container(
        key: ValueKey(_currentSectionIndex),
        padding: const EdgeInsets.all(16.0),
        child:
            produtos.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.fastfood_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum produto encontrado',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'em ${secao.nome}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header da seção de produtos
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _getGradientColors(_currentSectionIndex)[0],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            secao.nome ?? 'Produtos',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color:
                                  _getGradientColors(_currentSectionIndex)[0],
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getGradientColors(
                              _currentSectionIndex,
                            )[0].withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${produtos.length} produtos',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color:
                                  _getGradientColors(_currentSectionIndex)[0],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Grid de produtos
                    Expanded(
                      child: GridView.builder(
                        itemCount: produtos.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 0.65,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemBuilder: (context, index) {
                          final produto = produtos[index];
                          return _buildProdutoCard(produto, index);
                        },
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildProdutoCard(ProdutoCardapio produto, int index) {
    return GestureDetector(
      onTap: () => _abrirDetalhesProduto(produto),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200 + (index * 30)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 4,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: _buildProdutoImagem(produto),
                  ),
                ),
                // ✅ SEÇÃO CORRIGIDA - INÍCIO
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6.0,
                      vertical: 4.0,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Nome do produto - AJUSTADO PARA TABLET
                        Flexible(
                          child: Text(
                            produto.nome ?? 'Produto',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12, // ✅ Era 18, agora 12
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              height: 1.1, // ✅ Compacto
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 3),
                        // Preço - AJUSTADO PARA TABLET
                        Text(
                          produto.precoFormatado,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15, // ✅ Era 20, agora 15
                            fontWeight: FontWeight.bold,
                            color: _getGradientColors(_currentSectionIndex)[0],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                // ✅ SEÇÃO CORRIGIDA - FIM
              ],
            ),

            // Badge do carrinho (não modificado)
            Positioned(
              top: 8,
              right: 8,
              child: BadgeCarrinhoAnimado(
                quantidade: CarrinhoService.obterQuantidadeProduto(produto.id),
                cor: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NOVO MÉTODO: Widget para carregar imagem do produto
  Widget _buildProdutoImagem(ProdutoCardapio produto) {
    // Log para debug
    if (kDebugMode) {
      debugPrint(
        '🖼️ Verificando imagens do produto ${produto.id} - ${produto.nome}',
      );
      debugPrint('   Total de imagens: ${produto.imagens.length}');
    }

    // Verificar se há imagens disponíveis
    if (produto.imagens.isNotEmpty) {
      final primeiraImagem = produto.imagens.first;
      final imageUrl = primeiraImagem.imageUrl;

      if (kDebugMode) {
        debugPrint('   Primeira imagem - ID: ${primeiraImagem.id}');
        debugPrint('   URL gerada: $imageUrl');
        debugPrint('   Formato: ${primeiraImagem.formato}');
        debugPrint(
          '   Tem dados de imagem: ${primeiraImagem.image != null && primeiraImagem.image!.isNotEmpty}',
        );
      }

      if (imageUrl != null && imageUrl.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('✅ Carregando imagem do produto ${produto.id}: $imageUrl');
        }
        // Deixe a imagem um pouco menor sem distorcer
        const double imageScale = 0.82; // ajuste fino: 0.78 ~ 0.90

        return Center(
          child: FractionallySizedBox(
            widthFactor: imageScale,
            heightFactor: imageScale,
            alignment: Alignment.center,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain, // antes era cover
              // REMOVA width/height infinitos para a escala funcionar
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  if (kDebugMode) {
                    debugPrint(
                      '✅ Imagem carregada com sucesso: produto ${produto.id}',
                    );
                  }
                  return child;
                }
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.grey.shade100, Colors.grey.shade50],
                    ),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 25,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getGradientColors(_currentSectionIndex)[0],
                        ),
                        value:
                            loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                      ),
                    ),
                  ),
                );
              },
              errorBuilder:
                  (context, error, stackTrace) => _buildFallbackIcon(produto),
            ),
          ),
        );
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ URL da imagem está vazia para produto ${produto.id}');
        }
      }
    } else {
      if (kDebugMode) {
        debugPrint('⚠️ Produto ${produto.id} não possui imagens');
      }
    }

    // Fallback para quando não há imagens
    return _buildFallbackIcon(produto);
  }

  // ✅ NOVO MÉTODO: Ícone de fallback
  Widget _buildFallbackIcon(ProdutoCardapio produto) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey.shade100, Colors.grey.shade50],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fastfood,
              color: _getGradientColors(
                _currentSectionIndex,
              )[0].withValues(alpha: 0.6),
              size: 32,
            ),
            const SizedBox(height: 4),
            Text(
              'Sem imagem',
              style: TextStyle(fontSize: 8, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  void _abrirDetalhesProduto(ProdutoCardapio produto) {
    _resetarTimerInatividade(); // ✅ Reset timer
    final corSecao = _getGradientColors(_currentSectionIndex)[0];

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder:
                (context) =>
                    ProdutoDetalhesScreen(produto: produto, corSecao: corSecao),
          ),
        )
        .then((_) {
          // Atualiza a tela quando volta dos detalhes para mostrar badge do carrinho
          setState(() {});
          _resetarTimerInatividade(); // ✅ Reset timer ao voltar
        });
  }

  Widget _buildBottomBar() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _resetarTimerInatividade(); // ✅ Reset timer
                    _sairDoApp();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.close, size: 20),
                  label: const Text(
                    'Sair',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _resetarTimerInatividade(); // ✅ Reset timer
                    _abrirCarrinho();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: roxo,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.shopping_cart, size: 20),
                      Positioned(
                        right: -8,
                        top: -8,
                        child: BadgeCarrinhoAnimado(
                          quantidade: CarrinhoService.quantidadeTotalStatic,
                          cor: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  label: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        CarrinhoService.isEmptyStatic
                            ? 'Carrinho'
                            : 'Ver Carrinho',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (CarrinhoService.isNotEmptyStatic)
                        Text(
                          'R\$ ${CarrinhoService.totalStatic.toStringAsFixed(2).replaceAll('.', ',')}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _abrirCarrinho() {
    if (CarrinhoService.isEmptyStatic) {
      _mostrarSnackBar(
        'Adicione produtos ao carrinho primeiro',
        isError: false,
      );
    } else {
      // ✅ MODIFICADO: passar dados do cliente
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder:
                  (context) => CarrinhoScreen(
                    dadosCliente: widget.dadosCliente, // ✅ NOVO
                  ),
            ),
          )
          .then((_) {
            setState(() {});
          });
    }
  }

  // ✅ MÉTODO SIMPLIFICADO: Sair direto para tela inicial
  void _sairDoApp() {
    // Limpar o carrinho se houver itens
    if (CarrinhoService.isNotEmptyStatic) {
      CarrinhoService.limpar();
      if (kDebugMode) {
        debugPrint('🗑️ Carrinho limpo ao sair');
      }
    }

    // Navegar para a SplashScreen e limpar toda a pilha
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (route) => false, // Remove todas as rotas anteriores
    );
  }

  List<Color> _getGradientColors(int index) {
    final colorSets = [
      [Colors.purple.shade400, Colors.purple.shade600], // Promoções
      [Colors.orange.shade400, Colors.orange.shade600], // Açaí
      [Colors.blue.shade400, Colors.blue.shade600], // Crie seu açaí
      [Colors.pink.shade400, Colors.pink.shade600], // Turma da Mônica
      [Colors.green.shade400, Colors.green.shade600], // Potes
      [Colors.red.shade400, Colors.red.shade600], // Cascão
      [Colors.teal.shade400, Colors.teal.shade600], // Smoothies
    ];

    return colorSets[index % colorSets.length];
  }

  IconData _getIconFromSecaoNome(String nome) {
    final nomeNormalizado = nome.toLowerCase();

    if (nomeNormalizado.contains('promo')) {
      return Icons.local_offer;
    } else if (nomeNormalizado.contains('açaí') ||
        nomeNormalizado.contains('acai')) {
      return Icons.icecream;
    } else if (nomeNormalizado.contains('crie') ||
        nomeNormalizado.contains('monte')) {
      return Icons.build;
    } else if (nomeNormalizado.contains('mônica') ||
        nomeNormalizado.contains('monica')) {
      return Icons.face;
    } else if (nomeNormalizado.contains('pote')) {
      return Icons.coffee;
    } else if (nomeNormalizado.contains('cascão') ||
        nomeNormalizado.contains('cascao')) {
      return Icons.cookie;
    } else if (nomeNormalizado.contains('smoothie')) {
      return Icons.local_drink;
    } else {
      return Icons.fastfood;
    }
  }
}

// Custom painter para criar padrões de fundo
class PatternPainter extends CustomPainter {
  final Color color;

  PatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color.withValues(alpha: 0.1)
          ..style = PaintingStyle.fill;

    // Desenha círculos decorativos
    for (int i = 0; i < 6; i++) {
      final x = (i % 2) * (size.width / 1.5);
      final y = (i ~/ 2) * (size.height / 2.5);
      canvas.drawCircle(Offset(x, y), 8 + (i * 1.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

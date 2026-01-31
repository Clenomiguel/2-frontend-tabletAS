import 'dart:async'; // Para usar Timer
import 'package:flutter/material.dart'; // Widgets do Flutter
import 'package:video_player/video_player.dart'; // Para reproduzir vídeos

/// Widget do Carrossel de Imagens/Vídeos.
/// Gerencia a exibição rotativa de conteúdo (Imagens, Vídeos ou Promos).
class CarouselWidget extends StatefulWidget {
  const CarouselWidget({super.key}); // Adicionei key para boas práticas

  @override
  State<CarouselWidget> createState() => CarouselWidgetState();
}

class CarouselWidgetState extends State<CarouselWidget> {
  // --- Controladores e Estado ---
  final PageController _pageController = PageController();
  int _currentPage = 0; // Índice do slide atual
  Timer? _autoPlayTimer; // Timer para rotação automática
  List<CarouselSlide> _slides = []; // Lista de slides a serem exibidos
  bool _isLoading = true; // Estado de carregamento inicial
  bool _isVideoPlaying = false; // Flag para pausar o autoplay durante vídeos
  VideoPlayerController? _videoController; // Controlador de vídeo atual

  // ============================================================
  // CONFIGURAÇÃO DO CARROSSEL (User Settings)
  // ============================================================

  // ✅ CONFIGURAÇÃO: Pasta local (assets)
  // Certifique-se de declarar essa pasta no pubspec.yaml
  static const String _assetsFolder = 'assets/carousel';

  // Lista de arquivos do carrossel (Nomeie e adicione seus arquivos aqui)
  static const List<String> _carouselFiles = [
    '1.jpg',
    '2.jpg',
    '3.mp4',
    // Exemplos: '4.png', 'promo.mp4', etc.
  ];

  // Configurações de API e URLs remotas (Desativadas por padrão na lógica abaixo)
  static const List<String> _remoteUrls = [];
  static const bool _loadFromApi = false;
  static const String _apiEndpoint = '/api/v1/banners';

  // Tempo de exibição de cada slide (em segundos)
  static const int _autoPlaySeconds = 5;

  // ============================================================
  // CICLO DE VIDA (Lifecycle)
  // ============================================================

  @override
  void initState() {
    super.initState();
    // Inicia o carregamento dos slides ao montar o widget
    _loadSlides();
  }

  @override
  void dispose() {
    // É crucial limpar timers e controllers para evitar vazamento de memória
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  // ============================================================
  // LÓGICA DE CARREGAMENTO DE DADOS
  // ============================================================

  /// Decide a fonte dos dados (API -> Remoto -> Local -> Padrão)
  Future<void> _loadSlides() async {
    List<CarouselSlide> slides = [];

    try {
      // Prioridade 1: Carregar da API (Se ativado)
      if (_loadFromApi) {
        slides = await _loadFromApiEndpoint();
      }

      // Prioridade 2: URLs remotas configuradas manualmente
      if (slides.isEmpty && _remoteUrls.isNotEmpty) {
        slides = _remoteUrls.map((url) => CarouselSlide.fromUrl(url)).toList();
      }

      // Prioridade 3: Assets locais (pasta assets/carousel)
      if (slides.isEmpty && _carouselFiles.isNotEmpty) {
        slides = _loadFromLocalAssets();
      }

      // Fallback: Se não encontrar nada, carrega slides de exemplo (Promo)
      if (slides.isEmpty) {
        slides = _getDefaultSlides();
      }
    } catch (e) {
      debugPrint('Erro ao carregar slides: $e');
      slides = _getDefaultSlides(); // Em caso de erro, usa o padrão
    }

    if (mounted) {
      setState(() {
        _slides = slides;
        _isLoading = false;
      });
      // Inicia a rotação automática após carregar
      _startAutoPlay();
    }
  }

  /// Converte a lista de nomes de arquivos em objetos CarouselSlide
  List<CarouselSlide> _loadFromLocalAssets() {
    return _carouselFiles.map((filename) {
      final path = '$_assetsFolder/$filename';
      final lower = filename.toLowerCase();
      // Detecta se é vídeo pela extensão
      final isVideo = lower.endsWith('.mp4') || lower.endsWith('.webm');

      return CarouselSlide(
        type: isVideo ? SlideType.video : SlideType.image,
        assetPath: path,
      );
    }).toList();
  }

  /// Placeholder para implementação futura de API
  Future<List<CarouselSlide>> _loadFromApiEndpoint() async {
    return [];
  }

  /// Slides de exemplo (hardcoded) para quando não houver arquivos
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

  // ============================================================
  // LÓGICA DE CONTROLE E AUTOPLAY
  // ============================================================

  /// Inicia o timer que muda o slide a cada X segundos
  void _startAutoPlay() {
    _autoPlayTimer?.cancel(); // Cancela anterior se existir
    _autoPlayTimer =
        Timer.periodic(Duration(seconds: _autoPlaySeconds), (timer) {
      // REGRA: Não avança automaticamente se um vídeo estiver rodando
      if (_isVideoPlaying) return;

      if (_pageController.hasClients && _slides.isNotEmpty) {
        // Calcula o próximo índice (loop infinito usando módulo %)
        final nextPage = (_currentPage + 1) % _slides.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  /// Chamado sempre que o PageView muda de página
  void _onPageChanged(int index) {
    // 1. Limpa o vídeo do slide anterior para economizar recurso
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;

    setState(() {
      _currentPage = index;
      // Define se o novo slide é vídeo para bloquear o autoplay
      _isVideoPlaying = _slides[index].type == SlideType.video;
    });

    // 2. Se o novo slide for vídeo, inicializa o player
    if (_slides[index].type == SlideType.video) {
      _initVideoForSlide(_slides[index]);
    }
  }

  /// Inicializa e toca o vídeo do slide atual
  Future<void> _initVideoForSlide(CarouselSlide slide) async {
    try {
      VideoPlayerController controller;

      // Define a fonte do vídeo (Asset ou Rede)
      if (slide.assetPath != null) {
        controller = VideoPlayerController.asset(slide.assetPath!);
      } else if (slide.networkUrl != null) {
        controller =
            VideoPlayerController.networkUrl(Uri.parse(slide.networkUrl!));
      } else {
        return;
      }

      await controller.initialize();

      // Listener para detectar quando o vídeo termina
      controller.addListener(() {
        // Se a posição atual >= duração total, o vídeo acabou
        if (controller.value.position >= controller.value.duration &&
            controller.value.duration > Duration.zero) {
          _onVideoFinished();
        }
      });

      if (mounted) {
        setState(() {
          _videoController = controller;
        });
        controller.play(); // Inicia reprodução
      }
    } catch (e) {
      debugPrint('Erro ao inicializar vídeo: $e');
      setState(() => _isVideoPlaying = false); // Libera autoplay se falhar
    }
  }

  /// Chamado quando o vídeo termina de tocar
  void _onVideoFinished() {
    if (!mounted) return;

    setState(() => _isVideoPlaying = false); // Libera o autoplay

    // Avança para o próximo slide imediatamente
    if (_pageController.hasClients && _slides.isNotEmpty) {
      final nextPage = (_currentPage + 1) % _slides.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  // ============================================================
  // CONSTRUÇÃO DA UI (BUILD)
  // ============================================================

  @override
  Widget build(BuildContext context) {
    // Tela preta de carregamento
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
        // 1. O Carrossel em si
        PageView.builder(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          // Permite arrastar manualmente mesmo durante vídeo
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: _slides.length,
          itemBuilder: (context, index) {
            // Verifica se este é o slide ativo para tocar o vídeo
            return _buildSlide(_slides[index], index == _currentPage);
          },
        ),

        // 2. Indicadores de página (Bolinhas na parte inferior)
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
                  width: _currentPage == index ? 24 : 10, // Bolinha ativa maior
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

        // 3. Botão Principal "TOQUE PARA PEDIR"
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

        // 4. Badge indicador de tipo (Canto superior direito)
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

  // ============================================================
  // BUILDERS DE SLIDES ESPECÍFICOS
  // ============================================================

  /// Redireciona para o builder correto baseado no tipo do slide
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

  /// Constrói slide de IMAGEM (Rede ou Local)
  Widget _buildImageSlide(CarouselSlide slide) {
    Widget imageWidget;

    if (slide.networkUrl != null) {
      // Imagem da internet com loading progressivo
      imageWidget = Image.network(
        slide.networkUrl!,
        fit: BoxFit.cover,
        headers: const {'User-Agent': 'Mozilla/5.0'},
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
      // Imagem local
      imageWidget = Image.asset(
        slide.assetPath!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildErrorPlaceholder(slide.assetPath),
      );
    } else {
      imageWidget = _buildErrorPlaceholder(null);
    }

    // Retorna a imagem com sobreposição de texto (se houver título)
    return Stack(
      fit: StackFit.expand,
      children: [
        imageWidget,
        // Gradiente escuro para legibilidade do texto
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
        // Texto sobreposto
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

  /// Constrói slide de VÍDEO
  Widget _buildVideoSlide(CarouselSlide slide, bool isActive) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          color: Colors.black,
          // Só exibe o player se estiver inicializado E for o slide ativo
          child: _videoController != null &&
                  _videoController!.value.isInitialized &&
                  isActive
              ? FittedBox(
                  fit: BoxFit.cover, // Preenche a tela mantendo proporção
                  child: SizedBox(
                    width: _videoController!.value.size.width,
                    height: _videoController!.value.size.height,
                    child: VideoPlayer(_videoController!),
                  ),
                )
              : Center(
                  // Loading enquanto o vídeo prepara
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

        // Barra de progresso do vídeo (opcional)
        if (_videoController != null &&
            _videoController!.value.isInitialized &&
            isActive)
          Positioned(
            bottom: 160,
            left: 40,
            right: 40,
            child: Column(
              children: [
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
                // Contador regressivo
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

        // Título discreto do vídeo no topo
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

  /// Constrói slide PROMOCIONAL (Gerado por código, sem arquivo)
  Widget _buildPromoSlide(CarouselSlide slide) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          // Usa gradiente customizado ou padrão vermelho
          colors: slide.gradient ??
              [const Color(0xFFE53935), const Color(0xFFFF7043)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Padrão de fundo (bolinhas desenhadas)
          Positioned.fill(
            child: CustomPaint(
              painter: _PatternPainter(),
            ),
          ),

          // Conteúdo centralizado
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ícone circular grande
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

                // Título gigante
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

  /// Widget placeholder para erro de imagem
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

// ============================================================
// MODELOS DE DADOS AUXILIARES
// ============================================================

/// Tipos de slides suportados
enum SlideType { image, video, promo }

/// Modelo de dados para um slide do carrossel
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

  /// Factory: Cria slide a partir de URL (detecta tipo automaticamente)
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

  /// Factory: Cria slide a partir de JSON (para uso futuro com API)
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

/// Painter customizado para desenhar o fundo decorativo dos slides Promo
class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    // Desenha círculos decorativos sutis no fundo
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

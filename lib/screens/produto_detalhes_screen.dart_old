// lib/screens/produto_detalhes_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/cardapio_models.dart';
import '../services/cardapio_service.dart';
import '../models/carrinho_models.dart';
import '../services/carrinho_service.dart';
import '../widgets/animacao_carrinho_widget.dart';

class ProdutoDetalhesScreen extends StatefulWidget {
  final ProdutoCardapio produto;
  final Color corSecao;

  const ProdutoDetalhesScreen({
    super.key,
    required this.produto,
    required this.corSecao,
  });

  @override
  State<ProdutoDetalhesScreen> createState() => _ProdutoDetalhesScreenState();
}

class _ProdutoDetalhesScreenState extends State<ProdutoDetalhesScreen>
    with TickerProviderStateMixin {
  // Estado da tela
  ProdutoCompleto? _produtoCompleto;
  bool _isLoading = true;
  String? _errorMessage;

  // Controladores de animação
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Estado do produto personalizado
  final Map<int, int> _composicaoQuantidade =
      {}; // Rastreia quantidade de cada sabor
  final Map<int, int> _complementosQuantidade = {};
  final Set<int> _preparosSelecionados = {};
  int _quantidade = 1;
  double _precoTotal = 0.0;
  String? _observacoes;

  // Variável para controlar se é personalizável
  bool _isPersonalizavel = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _carregarDetalhes();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
  }

  Future<void> _carregarDetalhes() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print('🔍 Carregando detalhes do produto ID: ${widget.produto.id}');

      final produtoCompleto = await CardapioService.obterProdutoCompleto(
        widget.produto.id,
      );

      setState(() {
        _produtoCompleto = produtoCompleto;
        _isPersonalizavel = produtoCompleto.isPersonalizavel;
        _isLoading = false;
      });

      // Inicializar seleções padrão
      _inicializarSelecoesPadrao();
      _calcularPrecoTotal();

      // Iniciar animações
      _fadeController.forward();
      _slideController.forward();

      print('✅ Produto carregado - Personalizável: $_isPersonalizavel');
      print(
        '📊 Quantidade máxima de composição: ${widget.produto.qtdMaximaComposicao}',
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });

      if (kDebugMode) {
        debugPrint('❌ Erro ao carregar detalhes do produto: $e');
      }
    }
  }

  void _inicializarSelecoesPadrao() {
    if (_produtoCompleto == null) return;

    // Selecionar composições obrigatórias por padrão (mas não exibir no carrinho)
    for (final composicao in _produtoCompleto!.composicao) {
      final composicaoId = composicao.composicaoId ?? 0;
      if (composicao.opcional != true) {
        _composicaoQuantidade[composicaoId] = 1;
      }
    }

    // Selecionar preparo padrão
    for (final preparo in _produtoCompleto!.preparos) {
      if (preparo.padrao == true) {
        _preparosSelecionados.add(preparo.preparoId ?? 0);
      }
    }
  }

  void _calcularPrecoTotal() {
    double precoUnitario = widget.produto.precoUnit ?? 0.0;

    // Somar complementos selecionados
    if (_produtoCompleto != null) {
      for (final complemento in _produtoCompleto!.complementos) {
        final complementoId = complemento.complementoId ?? 0;
        final quantidade = _complementosQuantidade[complementoId] ?? 0;
        if (quantidade > 0) {
          precoUnitario += complemento.precoAdicional * quantidade;
        }
      }
    }

    setState(() {
      _precoTotal = precoUnitario * _quantidade;
    });
  }

  // ✅ NOVO: Calcular total de sabores opcionais selecionados
  int _calcularTotalSaboresOpcionais() {
    if (_produtoCompleto == null) return 0;

    int total = 0;
    for (final entry in _composicaoQuantidade.entries) {
      // Buscar a composição correspondente para verificar se é opcional
      final composicao = _produtoCompleto!.composicao.firstWhere(
        (comp) => comp.composicaoId == entry.key,
        orElse: () => ProdutoComposicaoCompleto(),
      );

      // Contar apenas se for opcional
      if (composicao.opcional == true) {
        total += entry.value;
      }
    }

    return total;
  }

  // ✅ NOVO: Verificar se pode adicionar mais sabores
  bool _podeAdicionarSabor() {
    final qtdMaxima = widget.produto.qtdMaximaComposicao;

    // Se não tem limite definido, pode adicionar
    if (qtdMaxima == null || qtdMaxima <= 0) return true;

    final totalAtual = _calcularTotalSaboresOpcionais();
    return totalAtual < qtdMaxima;
  }

  // ✅ NOVO: Obter quantidade máxima permitida
  int? _obterQuantidadeMaxima() {
    return widget.produto.qtdMaximaComposicao;
  }

  // ✅ NOVO: Verificar se atingiu EXATAMENTE a quantidade máxima obrigatória
  bool _atingiuQuantidadeObrigatoria() {
    final qtdMaxima = widget.produto.qtdMaximaComposicao;

    // Se não tem limite definido ou é 0, não é obrigatório
    if (qtdMaxima == null || qtdMaxima <= 0) return true;

    final totalAtual = _calcularTotalSaboresOpcionais();
    return totalAtual == qtdMaxima;
  }

  // ✅ NOVO: Mostrar mensagem quando atingir o limite
  void _mostrarMensagemLimite() {
    final qtdMaxima = widget.produto.qtdMaximaComposicao;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Limite de $qtdMaxima ${qtdMaxima == 1 ? 'sabor' : 'sabores'} atingido!',
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ✅ NOVO: Mostrar mensagem quando tentar adicionar sem completar
  void _mostrarMensagemIncompleto() {
    final qtdMaxima = widget.produto.qtdMaximaComposicao;
    final totalAtual = _calcularTotalSaboresOpcionais();
    final faltam = qtdMaxima! - totalAtual;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          faltam == 1
              ? 'Selecione mais 1 sabor para continuar!'
              : 'Selecione mais $faltam sabores para continuar!',
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ============================================================
  // TRECHO DO ARQUIVO: lib/screens/produto_detalhes_screen.dart
  // MÉTODO: _adicionarAoCarrinho()
  //
  // SUBSTITUA APENAS ESTE MÉTODO NO SEU ARQUIVO ORIGINAL
  // ============================================================

  // ============================================================
  // MÉTODO COMPLETO E CORRIGIDO: _adicionarAoCarrinho()
  // SUBSTITUA ESTE MÉTODO NO SEU ARQUIVO produto_detalhes_screen.dart
  // ============================================================

  void _adicionarAoCarrinho() {
    if (_produtoCompleto == null) return;

    // ✅ VERIFICAR SE COMPLETOU A QUANTIDADE OBRIGATÓRIA DE SABORES
    if (!_atingiuQuantidadeObrigatoria()) {
      _mostrarMensagemIncompleto();
      return;
    }

    // Para produtos personalizáveis, quantidade sempre = 1
    final quantidadeFinal = _isPersonalizavel ? 1 : _quantidade;

    // ✅ DECLARAÇÃO DE TODAS AS VARIÁVEIS
    final composicaoNomes = <int, String>{};
    final composicaoSelecionadaComQuantidade =
        <int, int>{}; // ✅ ALTERADO: bool → int
    final composicaoProdutoIds = <int, int>{}; // ✅ produto_id real
    final composicaoCodigoProduto = <int, String>{}; // ✅ codigo do produto

    final complementosNomes = <int, String>{};
    final complementosPrecos = <int, double>{};
    final complementoProdutoIds = <int, int>{}; // ✅ produto_id real
    final complementosCodigoBarra = <int, String>{}; // ✅ codigo_barra

    final preparosNomes = <int, String>{};

    print('🔍 === RESOLVENDO DADOS PARA CARRINHO ===');
    print('📊 Produto: ${widget.produto.nome}');

    // ✅ RESOLVER COMPOSIÇÃO (SABORES) - APENAS OPCIONAIS
    for (final entry in _composicaoQuantidade.entries) {
      if (entry.value > 0) {
        ProdutoComposicaoCompleto? composicaoEncontrada;
        for (final comp in _produtoCompleto!.composicao) {
          if (comp.composicaoId == entry.key) {
            composicaoEncontrada = comp;
            break;
          }
        }

        // Filtro: só processar se for opcional
        if (composicaoEncontrada != null &&
            composicaoEncontrada.opcional == true &&
            composicaoEncontrada.produto != null) {
          final produtoComp = composicaoEncontrada.produto!;
          final nomeBase = produtoComp.nome ?? 'Sabor';
          final nomeComQuantidade =
              entry.value > 1 ? '${entry.value}x $nomeBase' : nomeBase;

          // Salvar todos os dados da composição
          composicaoNomes[entry.key] = nomeComQuantidade;
          composicaoSelecionadaComQuantidade[entry.key] = entry.value;
          composicaoProdutoIds[entry.key] = produtoComp.id;
          composicaoCodigoProduto[entry.key] = produtoComp.codigo ?? '';

          print(
            '   ✅ Composição: composicaoId=${entry.key}, produto_id=${produtoComp.id}, codigo="${produtoComp.codigo}", nome=$nomeBase',
          );
        }
      }
    }

    // ✅ RESOLVER COMPLEMENTOS (ADICIONAIS)
    for (final entry in _complementosQuantidade.entries) {
      if (entry.value > 0) {
        ProdutoComplementoCompleto? complementoEncontrado;
        for (final comp in _produtoCompleto!.complementos) {
          if (comp.complementoId == entry.key) {
            complementoEncontrado = comp;
            break;
          }
        }

        if (complementoEncontrado != null &&
            complementoEncontrado.produto != null) {
          final produtoComp = complementoEncontrado.produto!;

          // Salvar todos os dados do complemento
          complementosNomes[entry.key] = produtoComp.nome ?? 'Complemento';
          complementosPrecos[entry.key] = produtoComp.precoUnit ?? 0.0;
          complementoProdutoIds[entry.key] = produtoComp.id;
          complementosCodigoBarra[entry.key] = produtoComp.codigoBarra ?? '';

          print(
            '   ✅ Complemento: complementoId=${entry.key}, produto_id=${produtoComp.id}, codigo_barra="${produtoComp.codigoBarra}", nome=${produtoComp.nome}',
          );
        }
      }
    }

    // ✅ RESOLVER PREPAROS
    for (final preparoId in _preparosSelecionados) {
      ProdutoPreparoCompleto? preparoEncontrado;
      for (final prep in _produtoCompleto!.preparos) {
        if (prep.preparoId == preparoId) {
          preparoEncontrado = prep;
          break;
        }
      }

      if (preparoEncontrado != null &&
          preparoEncontrado.preparoDescricao != null) {
        preparosNomes[preparoId] = preparoEncontrado.preparoDescricao!;
      }
    }

    print('🛒 === CRIANDO ITEM DO CARRINHO ===');
    print('📦 Composição produto IDs: $composicaoProdutoIds');
    print('📦 Composição códigos: $composicaoCodigoProduto');
    print(
      '📦 Composição quantidades: $composicaoSelecionadaComQuantidade',
    ); // ✅ NOVO LOG
    print('📦 Complemento produto IDs: $complementoProdutoIds');
    print('📦 Complemento códigos barra: $complementosCodigoBarra');

    // ✅ CRIAR ITEM DO CARRINHO COM TODOS OS DADOS
    final itemCarrinho = ItemCarrinho(
      produto: widget.produto,
      quantidade: quantidadeFinal,
      precoUnitario: _precoTotal / quantidadeFinal,
      precoTotal: _precoTotal,
      composicaoSelecionada: composicaoSelecionadaComQuantidade,
      complementosSelecionados: Map.from(_complementosQuantidade),
      preparosSelecionados: Set.from(_preparosSelecionados),
      observacoes: _observacoes?.trim(),
      // Nomes
      composicaoNomes: composicaoNomes,
      complementosNomes: complementosNomes,
      preparosNomes: preparosNomes,
      // Dados dos complementos
      complementosPrecos: complementosPrecos,
      complementoProdutoIds: complementoProdutoIds,
      complementosCodigoBarra: complementosCodigoBarra,
      // Dados da composição
      composicaoProdutoIds: composicaoProdutoIds,
      composicaoCodigoProduto: composicaoCodigoProduto,
    );

    CarrinhoService.adicionarItem(itemCarrinho);

    // Mostrar feedback animado
    FeedbackCarrinhoWidget.mostrarAdicionado(
      context,
      nomeProduto: widget.produto.nome ?? 'Produto',
      quantidade: quantidadeFinal,
    );

    if (_isPersonalizavel) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    } else {
      setState(() {
        _quantidade = 1;
        _calcularPrecoTotal();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body:
          _isLoading
              ? _buildLoadingScreen()
              : _errorMessage != null
              ? _buildErrorScreen()
              : _buildMainContent(),
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [widget.corSecao, widget.corSecao.withValues(alpha: 0.8)],
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
              'Carregando detalhes...',
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
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar detalhes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Erro desconhecido',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Voltar'),
                ),
                ElevatedButton.icon(
                  onPressed: _carregarDetalhes,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.corSecao,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProdutoInfo(),
                    const SizedBox(height: 24),
                    if (_produtoCompleto?.composicao.isNotEmpty == true)
                      _buildComposicaoSection(),
                    if (_produtoCompleto?.complementos.isNotEmpty == true) ...[
                      const SizedBox(height: 24),
                      _buildComplementosSection(),
                    ],
                    if (_produtoCompleto?.preparos.isNotEmpty == true) ...[
                      const SizedBox(height: 24),
                      _buildPreparosSection(),
                    ],
                    const SizedBox(height: 24),
                    _buildObservacoesSection(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [widget.corSecao, widget.corSecao.withValues(alpha: 0.8)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.produto.nome ?? 'Produto',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_isPersonalizavel)
                      Text(
                        'Produto personalizável',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.produto.precoFormatado,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProdutoInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.corSecao.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Icon(
                    Icons.fastfood,
                    size: 40,
                    color: widget.corSecao.withValues(alpha: 0.7),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.produto.nome ?? 'Produto',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (widget.produto.nomeResumido != null)
                      Text(
                        widget.produto.nomeResumido!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.code, size: 16, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          'Código: ${widget.produto.codigo ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isPersonalizavel) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.build, color: Colors.orange.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Este produto pode ser personalizado. Será adicionado um por vez ao carrinho.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComposicaoSection() {
    final composicoes = _produtoCompleto!.composicao;
    final composicoesOpcionais =
        composicoes.where((comp) => comp.opcional == true).toList();

    if (composicoesOpcionais.isEmpty) {
      return const SizedBox.shrink();
    }

    // ✅ Calcular quantos sabores foram selecionados
    final totalSelecionado = _calcularTotalSaboresOpcionais();
    final qtdMaxima = _obterQuantidadeMaxima();
    final temLimite = qtdMaxima != null && qtdMaxima > 0;
    final completou = _atingiuQuantidadeObrigatoria();
    final faltam = temLimite ? qtdMaxima - totalSelecionado : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant_menu, color: widget.corSecao),
              const SizedBox(width: 8),
              const Text(
                'Escolha os Sabores',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // ✅ NOVO: Indicador de quantidade com status
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (temLimite) ...[
                      Text(
                        completou
                            ? '✅ Quantidade completa!'
                            : faltam == 1
                            ? '⚠️ Selecione mais 1 sabor'
                            : '⚠️ Selecione mais $faltam sabores',
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              completou
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Obrigatório escolher $qtdMaxima ${qtdMaxima == 1 ? 'sabor' : 'sabores'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ] else
                      Text(
                        'Selecione os sabores desejados',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              if (temLimite)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        completou
                            ? Colors.green.shade50
                            : totalSelecionado >= qtdMaxima
                            ? Colors.red.shade50
                            : widget.corSecao.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          completou
                              ? Colors.green.shade300
                              : totalSelecionado >= qtdMaxima
                              ? Colors.red.shade300
                              : widget.corSecao.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        completou
                            ? Icons.check_circle
                            : totalSelecionado >= qtdMaxima
                            ? Icons.check_circle
                            : Icons.info_outline,
                        size: 16,
                        color:
                            completou
                                ? Colors.green.shade600
                                : totalSelecionado >= qtdMaxima
                                ? Colors.red.shade600
                                : widget.corSecao,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$totalSelecionado / $qtdMaxima',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color:
                              completou
                                  ? Colors.green.shade700
                                  : totalSelecionado >= qtdMaxima
                                  ? Colors.red.shade700
                                  : widget.corSecao,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          Column(
            children:
                composicoesOpcionais.map((composicao) {
                  final composicaoId = composicao.composicaoId ?? 0;
                  final quantidade = _composicaoQuantidade[composicaoId] ?? 0;
                  final produto = composicao.produto;

                  // ✅ Verificar se pode adicionar mais (desabilita TODOS quando atingir limite)
                  final podeAdicionar = _podeAdicionarSabor();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color:
                            quantidade > 0
                                ? widget.corSecao.withValues(alpha: 0.3)
                                : Colors.grey.shade200,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color:
                          quantidade > 0
                              ? widget.corSecao.withValues(alpha: 0.05)
                              : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                produto?.nome ?? 'Sabor',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              if (composicao.quantidade != null)
                                Text(
                                  'Porção: ${composicao.quantidade}g',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // ✅ Controles de quantidade com trava
                        Row(
                          children: [
                            IconButton(
                              onPressed:
                                  quantidade > 0
                                      ? () {
                                        setState(() {
                                          _composicaoQuantidade[composicaoId] =
                                              quantidade - 1;
                                          if (_composicaoQuantidade[composicaoId]! <=
                                              0) {
                                            _composicaoQuantidade.remove(
                                              composicaoId,
                                            );
                                          }
                                        });
                                        _calcularPrecoTotal();
                                      }
                                      : null,
                              icon: Icon(
                                Icons.remove_circle,
                                color:
                                    quantidade > 0
                                        ? Colors.red
                                        : Colors.grey.shade300,
                              ),
                            ),

                            SizedBox(
                              width: 40,
                              child: Text(
                                quantidade.toString(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            IconButton(
                              onPressed:
                                  podeAdicionar
                                      ? () {
                                        setState(() {
                                          _composicaoQuantidade[composicaoId] =
                                              quantidade + 1;
                                        });
                                        _calcularPrecoTotal();
                                      }
                                      : () {
                                        // ✅ Mostrar mensagem quando tentar adicionar no limite
                                        _mostrarMensagemLimite();
                                      },
                              icon: Icon(
                                Icons.add_circle,
                                color:
                                    podeAdicionar
                                        ? widget.corSecao
                                        : Colors.grey.shade300,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildComplementosSection() {
    final complementos = _produtoCompleto!.complementos;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.add_circle_outline, color: widget.corSecao),
              const SizedBox(width: 8),
              const Text(
                'Adicionais',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione complementos extras ao seu produto',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),

          Column(
            children:
                complementos.map((complemento) {
                  final complementoId = complemento.complementoId ?? 0;
                  final quantidade =
                      _complementosQuantidade[complementoId] ?? 0;
                  final produto = complemento.produto;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color:
                            quantidade > 0
                                ? widget.corSecao.withValues(alpha: 0.3)
                                : Colors.grey.shade200,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color:
                          quantidade > 0
                              ? widget.corSecao.withValues(alpha: 0.05)
                              : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                produto?.nome ?? 'Complemento',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                '+ ${produto?.precoFormatado ?? 'R\$ 0,00'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: widget.corSecao,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Row(
                          children: [
                            IconButton(
                              onPressed:
                                  quantidade > 0
                                      ? () {
                                        setState(() {
                                          _complementosQuantidade[complementoId] =
                                              quantidade - 1;
                                          if (_complementosQuantidade[complementoId]! <=
                                              0) {
                                            _complementosQuantidade.remove(
                                              complementoId,
                                            );
                                          }
                                        });
                                        _calcularPrecoTotal();
                                      }
                                      : null,
                              icon: Icon(
                                Icons.remove_circle,
                                color:
                                    quantidade > 0
                                        ? Colors.red
                                        : Colors.grey.shade300,
                              ),
                            ),

                            SizedBox(
                              width: 40,
                              child: Text(
                                quantidade.toString(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _complementosQuantidade[complementoId] =
                                      quantidade + 1;
                                });
                                _calcularPrecoTotal();
                              },
                              icon: Icon(
                                Icons.add_circle,
                                color: widget.corSecao,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPreparosSection() {
    final preparos = _produtoCompleto!.preparos;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant, color: widget.corSecao),
              const SizedBox(width: 8),
              const Text(
                'Modo de Preparo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Escolha como deseja seu produto',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                preparos.map((preparo) {
                  final preparoId = preparo.preparoId ?? 0;
                  final isSelected = _preparosSelecionados.contains(preparoId);

                  return FilterChip(
                    label: Text(preparo.preparoDescricao ?? 'Preparo'),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _preparosSelecionados.add(preparoId);
                        } else {
                          _preparosSelecionados.remove(preparoId);
                        }
                      });
                    },
                    selectedColor: widget.corSecao.withValues(alpha: 0.2),
                    checkmarkColor: widget.corSecao,
                    labelStyle: TextStyle(
                      color: isSelected ? widget.corSecao : Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildObservacoesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.note_add, color: widget.corSecao),
              const SizedBox(width: 8),
              const Text(
                'Observações',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione observações especiais para seu pedido',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),

          TextField(
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Ex: Sem açúcar, gelado, caprichado...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: widget.corSecao, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            onChanged: (value) {
              _observacoes = value;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    // ✅ Verificar se pode adicionar ao carrinho
    final podeAdicionar = _atingiuQuantidadeObrigatoria();
    final qtdMaxima = _obterQuantidadeMaxima();
    final totalSelecionado = _calcularTotalSaboresOpcionais();
    final temLimite = qtdMaxima != null && qtdMaxima > 0;
    final faltam = temLimite ? qtdMaxima - totalSelecionado : 0;

    return Container(
      padding: const EdgeInsets.all(20),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ Mensagem de aviso quando não completou sabores
            if (temLimite && !podeAdicionar) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        faltam == 1
                            ? 'Selecione mais 1 sabor para continuar'
                            : 'Selecione mais $faltam sabores para continuar',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            Row(
              children: [
                if (!_isPersonalizavel) ...[
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed:
                              _quantidade > 1
                                  ? () {
                                    setState(() => _quantidade--);
                                    _calcularPrecoTotal();
                                  }
                                  : null,
                          icon: Icon(
                            Icons.remove,
                            color:
                                _quantidade > 1
                                    ? Colors.black87
                                    : Colors.grey.shade400,
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          child: Text(
                            _quantidade.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() => _quantidade++);
                            _calcularPrecoTotal();
                          },
                          icon: Icon(Icons.add, color: widget.corSecao),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                ],

                // Botão adicionar ao carrinho
                Expanded(
                  child: ElevatedButton.icon(
                    // ✅ Desabilitar se não completou sabores
                    onPressed: podeAdicionar ? _adicionarAoCarrinho : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          podeAdicionar
                              ? widget.corSecao
                              : Colors.grey.shade300,
                      foregroundColor:
                          podeAdicionar ? Colors.white : Colors.grey.shade500,
                      elevation: podeAdicionar ? 2 : 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Icon(
                      podeAdicionar
                          ? Icons.shopping_cart_outlined
                          : Icons.lock_outline,
                    ),
                    label: Text(
                      _isPersonalizavel
                          ? podeAdicionar
                              ? 'Adicionar • R\$ ${_precoTotal.toStringAsFixed(2).replaceAll('.', ',')}'
                              : 'Complete os sabores'
                          : podeAdicionar
                          ? 'Adicionar ${_quantidade}x • R\$ ${_precoTotal.toStringAsFixed(2).replaceAll('.', ',')}'
                          : 'Complete os sabores',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
}

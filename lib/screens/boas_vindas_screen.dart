import 'package:flutter/material.dart';
import 'cardapio_screen.dart'; // Importa a nova tela com API

class BoasVindasScreen extends StatefulWidget {
  final String nomeCliente;
  final bool isNovoCliente;
  final Map<String, dynamic>? dadosCliente; // ✅ NOVO

  const BoasVindasScreen({
    super.key,
    required this.nomeCliente,
    this.isNovoCliente = false,
    this.dadosCliente, // ✅ NOVO
  });

  @override
  State<BoasVindasScreen> createState() => _BoasVindasScreenState();
}

class _BoasVindasScreenState extends State<BoasVindasScreen>
    with TickerProviderStateMixin {
  static const roxo = Color(0xFF4B0082);
  static const dourado = Color(0xFFFFD700);

  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late AnimationController _sparkleController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _sparkleAnimation;

  @override
  void initState() {
    super.initState();

    // Configurar animações
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Criar animações
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _sparkleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.easeInOut),
    );

    // Iniciar animações em sequência
    _iniciarAnimacoes();
  }

  void _iniciarAnimacoes() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _fadeController.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    _scaleController.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    _slideController.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    _sparkleController.repeat(reverse: true);

    // Navegar para cardápio após animações
    await Future.delayed(const Duration(milliseconds: 3500));
    _navegarParaCardapio();
  }

  void _navegarParaCardapio() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder:
            (context) => CardapioScreen(
              nomeCliente: widget.nomeCliente,
              dadosCliente: widget.dadosCliente, // ✅ NOVO: passar dados
            ),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tamanhoTela = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [roxo, roxo.withValues(alpha: 0.8), Colors.purple.shade800],
          ),
        ),
        child: Stack(
          children: [
            // Partículas de fundo
            ...List.generate(
              20,
              (index) => _buildParticula(index, tamanhoTela),
            ),

            // Conteúdo principal
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Ícone animado
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: dourado.withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: AnimatedBuilder(
                            animation: _sparkleAnimation,
                            builder: (context, child) {
                              return Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: dourado.withValues(
                                      alpha: _sparkleAnimation.value,
                                    ),
                                    width: 3,
                                  ),
                                ),
                                child: Icon(
                                  widget.isNovoCliente
                                      ? Icons.person_add
                                      : Icons.person,
                                  size: 60,
                                  color: roxo,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Texto de boas-vindas
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            Text(
                              widget.isNovoCliente
                                  ? 'Cadastro Realizado!'
                                  : 'Bem-vindo de volta!',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 20),

                            // Nome do cliente
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: dourado.withValues(alpha: 0.5),
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                widget.nomeCliente,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                            const SizedBox(height: 30),

                            // Mensagem
                            Text(
                              widget.isNovoCliente
                                  ? 'Seu cadastro foi realizado com sucesso!\nVamos conhecer nosso cardápio?'
                                  : 'Que bom ter você aqui novamente!\nVamos ver as novidades do cardápio?',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 16,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 40),

                            // Indicador de carregamento
                            ScaleTransition(
                              scale: _scaleAnimation,
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        dourado,
                                      ),
                                      strokeWidth: 3,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Carregando cardápio...',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
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

            // Botão de pular (opcional)
            Positioned(
              top: 50,
              right: 20,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: TextButton(
                  onPressed: _navegarParaCardapio,
                  child: Text(
                    'Pular',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticula(int index, Size tamanhoTela) {
    final random = (index * 1234) % 1000 / 1000;
    final size = 2.0 + (random * 4);
    final left = random * tamanhoTela.width;
    final top = (index * 123) % tamanhoTela.height.toInt().toDouble();

    return Positioned(
      left: left,
      top: top,
      child: AnimatedBuilder(
        animation: _sparkleAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: (_sparkleAnimation.value * 0.5) + 0.1,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: dourado,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: dourado.withValues(alpha: 0.3),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

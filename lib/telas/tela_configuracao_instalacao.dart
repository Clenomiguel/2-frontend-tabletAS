// lib/telas/tela_configuracao_instalacao.dart
// Tela de configuração inicial (Wizard) - Versão Corrigida

import 'package:flutter/material.dart';
import '../../modelos/config_models.dart';
import '../../servicos/config_storage_service.dart';
import '../../servicos/config_api_service.dart';
import './passos/passos_servidor.dart';
import './passos/passos_empresa.dart';
import './passos/passos_cardapio.dart';
import './passos/passos_licenca.dart';
import './passos/passos_conclusao.dart';

// NOTA: Verifique se os imports dos "passos" acima estão corretos para a sua estrutura de pastas.
// Se a pasta 'passos' estiver no mesmo nível deste arquivo, use: import './passos/passos_servidor.dart';

class TelaConfiguracaoInstalacao extends StatefulWidget {
  final VoidCallback onConfigCompleta;
  final bool isReconfiguracao;

  const TelaConfiguracaoInstalacao({
    super.key,
    required this.onConfigCompleta,
    this.isReconfiguracao = false,
  });

  @override
  State<TelaConfiguracaoInstalacao> createState() =>
      _TelaConfiguracaoInstalacaoState();
}

class _TelaConfiguracaoInstalacaoState
    extends State<TelaConfiguracaoInstalacao> {
  final PageController _pageController = PageController();
  final ConfigApiService _apiService = ConfigApiService();

  int _currentStep = 0;
  bool _isLoading = false;

  // Dados coletados durante o wizard
  String _serverIp = '';
  int _serverPort = 8000;
  EmpresaConfig? _empresaSelecionada;
  CardapioConfig? _cardapioSelecionado;
  LicencaInfo? _licencaInfo;

  final List<String> _stepTitles = [
    'Servidor',
    'Empresa',
    'Cardápio',
    'Licença',
    'Conclusão',
  ];

  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // CORREÇÃO 1: Carregamento usando métodos estáticos (sem getInstance)
  Future<void> _carregarDadosIniciais() async {
    // Se for reconfiguração, buscamos os dados atuais para preencher os campos
    if (widget.isReconfiguracao) {
      final config = await ConfigStorageService.getConfig();

      if (config.isConfigured) {
        setState(() {
          _serverIp = config.serverIp;
          _serverPort = config.serverPort;

          // Tenta reconstruir o objeto parcial para a UI não começar zerada
          if (config.empresaId != 0) {
            _empresaSelecionada = EmpresaConfig(
              grid: config.empresaId,
              nome: config.empresaNome,
              cnpj: config.cnpj,
            );
          }

          // Recupera a licença salva
          _licencaInfo = config.licenca;
        });
      }
    }
  }

  void _nextStep() {
    if (_currentStep < _stepTitles.length - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (widget.isReconfiguracao) {
      // Se estiver reconfigurando e voltar do inicio, cancela e sai
      Navigator.pop(context);
    }
  }

  // --- Handlers de Atualização de Estado dos Passos ---

  void _onServidorConfigurado(String ip, int port) {
    setState(() {
      _serverIp = ip;
      _serverPort = port;
    });
    _nextStep();
  }

  void _onEmpresaSelecionada(EmpresaConfig empresa) {
    setState(() => _empresaSelecionada = empresa);
    _nextStep();
  }

  void _onCardapioSelecionado(CardapioConfig cardapio) {
    setState(() => _cardapioSelecionado = cardapio);
    _nextStep();
  }

  void _onLicencaVerificada(LicencaInfo licenca) {
    setState(() => _licencaInfo = licenca);
    _nextStep();
  }

  // CORREÇÃO 2: Salvamento com estrutura atualizada
  // Em lib/telas/configuracao/config_wizard_screen.dart

  // Em lib/telas/configuracao/config_wizard_screen.dart

  Future<void> _finalizarConfiguracao() async {
    // Guarda de segurança inicial
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // Monta o objeto de configuração
      final config = AppConfig(
        serverIp: _serverIp,
        serverPort: _serverPort,
        empresaId: _empresaSelecionada?.grid ?? 0,
        empresaNome: _empresaSelecionada?.displayName ?? '',
        cnpj: _empresaSelecionada?.cnpj,
        cardapioId: _cardapioSelecionado?.grid ?? 0,
        cardapioNome: _cardapioSelecionado?.nome ?? '',
        licenca: _licencaInfo,
        configurado: true,
      );

      // Salva no disco (operação assíncrona)
      final sucesso = await ConfigStorageService.saveConfig(config);

      // VERIFICAÇÃO CRÍTICA: Checa se o widget ainda está montado APÓS o await
      if (!mounted) {
        return; // Se não estiver, apenas pare. Não faça mais nada.
      }

      // Se o salvamento falhou, mostra o erro e para.
      if (!sucesso) {
        throw Exception('Falha ao gravar a configuração no disco.');
      }

      // Se tudo deu certo e o widget ainda existe, CHAMA O CALLBACK DE CONCLUSÃO.
      widget.onConfigCompleta();
    } catch (e) {
      // Mostra o erro apenas se o widget ainda existir
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Garante que o loading seja desativado apenas se o widget ainda existir
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Barra de Progresso
            _buildProgressIndicator(),

            // Conteúdo (PageView)
            Expanded(
              child: PageView(
                controller: _pageController,
                physics:
                    const NeverScrollableScrollPhysics(), // Bloqueia swipe manual
                children: [
                  StepServidor(
                    initialIp: _serverIp,
                    initialPort: _serverPort,
                    apiService: _apiService,
                    onServidorConfigurado: _onServidorConfigurado,
                  ),
                  StepEmpresa(
                    serverIp: _serverIp,
                    serverPort: _serverPort,
                    apiService: _apiService,
                    onEmpresaSelecionada: _onEmpresaSelecionada,
                    onVoltar: _previousStep,
                  ),
                  StepCardapio(
                    serverIp: _serverIp,
                    serverPort: _serverPort,
                    empresaId: _empresaSelecionada?.grid ?? 0,
                    apiService: _apiService,
                    onCardapioSelecionado: _onCardapioSelecionado,
                    onVoltar: _previousStep,
                  ),
                  StepLicenca(
                    empresa: _empresaSelecionada,
                    apiService: _apiService,
                    onLicencaVerificada: _onLicencaVerificada,
                    onVoltar: _previousStep,
                  ),
                  StepConclusao(
                    serverIp: _serverIp,
                    serverPort: _serverPort,
                    empresa: _empresaSelecionada,
                    cardapio: _cardapioSelecionado,
                    licenca: _licencaInfo,
                    isLoading: _isLoading,
                    onFinalizar: _finalizarConfiguracao,
                    onVoltar: _previousStep,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Logo
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue
                      .withValues(alpha: 0.3), // CORREÇÃO: withValues
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.restaurant_menu,
              size: 36,
              color: Color(0xFF1a1a2e),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.isReconfiguracao
                ? 'Reconfigurar Sistema'
                : 'Configuração Inicial',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _stepTitles[_currentStep],
            style: TextStyle(
              fontSize: 16,
              color:
                  Colors.white.withValues(alpha: 0.7), // CORREÇÃO: withValues
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Row(
        children: List.generate(_stepTitles.length, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;

          return Expanded(
            child: Row(
              children: [
                // Círculo
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? Colors.green
                        : isCurrent
                            ? Colors.blue
                            : Colors.grey.shade700,
                    border: isCurrent
                        ? Border.all(color: Colors.blue.shade300, width: 3)
                        : null,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isCurrent ? Colors.white : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                // Linha conectora
                if (index < _stepTitles.length - 1)
                  Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color: isCompleted ? Colors.green : Colors.grey.shade700,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

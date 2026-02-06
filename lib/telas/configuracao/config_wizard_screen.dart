// lib/telas/configuracao/config_wizard_screen.dart
// Wizard de configuração inicial do aplicativo (VERSÃO FINAL CORRIGIDA)

import 'package:flutter/material.dart';
import '../../modelos/config_models.dart';
import '../../servicos/config_storage_service.dart';
import '../../servicos/config_api_service.dart';
import '../passos/passos_servidor.dart';
import '../passos/passos_empresa.dart';
import '../passos/passos_cardapio.dart';
import '../passos/passos_licenca.dart';
import '../passos/passos_conclusao.dart';
import '../../servicos/api_service.dart'; // <-- IMPORTANTE: Adicionar este import

class ConfigWizardScreen extends StatefulWidget {
  final void Function(BuildContext) onConfigCompleta;
  final bool isReconfiguracao;

  const ConfigWizardScreen({
    super.key,
    required this.onConfigCompleta,
    this.isReconfiguracao = false,
  });

  @override
  State<ConfigWizardScreen> createState() => _ConfigWizardScreenState();
}

class _ConfigWizardScreenState extends State<ConfigWizardScreen> {
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

  Future<void> _carregarDadosIniciais() async {
    if (widget.isReconfiguracao) {
      final config = await ConfigStorageService.getConfig();
      if (mounted && config.isConfigured) {
        setState(() {
          _serverIp = config.serverIp;
          _serverPort = config.serverPort;
          if (config.empresaId != 0) {
            _empresaSelecionada = EmpresaConfig(
              grid: config.empresaId,
              nome: config.empresaNome,
              cnpj: config.cnpj,
            );
          }
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

  // =======================================================================
  // CORREÇÃO FINAL: Inicializar a API antes de navegar
  // =======================================================================
  Future<void> _finalizarConfiguracao() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
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

      final sucesso = await ConfigStorageService.saveConfig(config);

      if (!mounted) return;

      if (!sucesso) {
        throw Exception('Falha ao gravar a configuração no disco.');
      }

      // Inicializa a API com os novos dados ANTES de navegar
      Api.init(ApiConfig(
        baseUrl: 'http://${config.serverIp}:${config.serverPort}',
        empresaId: config.empresaId!,
        cardapioId: config.cardapioId,
      ));
      debugPrint('🚀 ApiService inicializado com sucesso após configuração.');

      // Agora, chama o callback para navegar para a tela de Menu
      widget.onConfigCompleta(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao finalizar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
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
            _buildHeader(),
            _buildProgressIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
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
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
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
              color: Colors.white.withOpacity(0.7),
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

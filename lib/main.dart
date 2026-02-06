// lib/main.dart
// Ponto de entrada da aplicação Totem (VERSÃO FINAL CORRIGIDA)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// Serviços
import 'servicos/api_service.dart';
import 'servicos/cart_provider.dart';
import 'servicos/config_storage_service.dart';

// Telas
import 'telas/tela_menu.dart';
import 'telas/configuracao/config_wizard_screen.dart';
import 'telas/configuracao/admin_login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Força orientação landscape para totem
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // UI imersiva (esconde barras do Android)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const TotemApp());
}

class TotemApp extends StatelessWidget {
  const TotemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Totem Self-Service',
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Roboto',
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6B21A8),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF1a1a2e),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}

/// Splash responsável por validar estado da aplicação e direcionar
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _loading = true;
  String? _error;
  bool _precisaReconfigurar = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  /// Fluxo de inicialização
  Future<void> _bootstrap() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
      _precisaReconfigurar = false;
    });

    try {
      final config = await ConfigStorageService.getConfig();

      if (!config.isConfigured) {
        debugPrint('⚙️ Nenhuma configuração encontrada. Iniciando Wizard.');
        _irParaConfiguracao();
        return;
      }

      debugPrint(
          '🚀 Configuração encontrada: ${config.serverIp}:${config.serverPort}');

      Api.init(ApiConfig(
        baseUrl: 'http://${config.serverIp}:${config.serverPort}',
        empresaId: config.empresaId!,
        cardapioId: config.cardapioId,
      ));

      debugPrint('📡 Testando conexão com servidor...');
      final online = await Api.instance.healthCheck();

      if (!online) {
        throw Exception(
            'Servidor configurado (${config.serverIp}) não responde.');
      }

      if (!mounted) return;
      _irParaMenu();
    } catch (e) {
      debugPrint('❌ Erro no bootstrap: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        _precisaReconfigurar = true;
      });
    }
  }

  // --- MÉTODOS DE NAVEGAÇÃO ---

  void _irParaConfiguracao() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ConfigWizardScreen(
          onConfigCompleta: _navegarParaMenuAposConfig,
        ),
      ),
    );
  }

  void _irParaMenu() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const MenuScreen(),
      ),
    );
  }

  // =======================================================================
  // CORREÇÃO: A função agora aceita o BuildContext vindo do Wizard
  // =======================================================================
  void _navegarParaMenuAposConfig(BuildContext wizardContext) {
    // O atraso ainda é uma boa prática para dar tempo da UI se resolver.
    Future.delayed(const Duration(milliseconds: 50), () {
      // A verificação 'if (mounted)' não é mais necessária aqui,
      // pois estamos usando o 'wizardContext' que sabemos que está ativo.
      Navigator.pushAndRemoveUntil(
        wizardContext, // <-- Usamos o contexto do Wizard, que está na tela!
        MaterialPageRoute(builder: (_) => const MenuScreen()),
        (route) => false, // Limpa todas as telas anteriores
      );
    });
  }

  void _abrirAdminParaReconfigurar() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminLoginScreen(
          onLoginSuccess: () {
            Navigator.pop(context); // Fecha a tela de login
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ConfigWizardScreen(
                  isReconfiguracao: true,
                  // Usa a mesma função de navegação corrigida
                  onConfigCompleta: _navegarParaMenuAposConfig,
                ),
              ),
            );
          },
          onCancel: () => Navigator.pop(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: _loading
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.blue),
                    SizedBox(height: 24),
                    Text(
                      'Iniciando sistema...',
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off,
                        color: Colors.redAccent, size: 80),
                    const SizedBox(height: 24),
                    Text(
                      'Falha na Inicialização',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                              color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error ?? 'Erro desconhecido',
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 48),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _bootstrap,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar Novamente'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 16),
                          ),
                        ),
                        if (_precisaReconfigurar) ...[
                          const SizedBox(width: 24),
                          OutlinedButton.icon(
                            onPressed: _abrirAdminParaReconfigurar,
                            icon: const Icon(Icons.settings),
                            label: const Text('Reconfigurar'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 16),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

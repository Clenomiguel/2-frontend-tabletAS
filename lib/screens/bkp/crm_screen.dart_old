import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:http/http.dart' as http;
import 'boas_vindas_screen.dart';
import 'splash_screen.dart';

// =============================================================================
// MODELO - ClienteResponse (Atualizado para novo backend)
// =============================================================================
class ClienteResponse {
  final int grid; // ✅ Mudou de 'id' para 'grid' (PK do novo backend)
  final int? codigo;
  final String? nome;
  final String? nomeReduzido;
  final String? tipo;
  final String? cpf;
  final String? fone; // ✅ Mudou de 'telefone' para 'fone'
  final String? celular;
  final String? email;

  ClienteResponse({
    required this.grid,
    this.codigo,
    this.nome,
    this.nomeReduzido,
    this.tipo,
    this.cpf,
    this.fone,
    this.celular,
    this.email,
  });

  factory ClienteResponse.fromJson(Map<String, dynamic> json) {
    return ClienteResponse(
      grid: json['grid'] ?? 0, // ✅ Usando 'grid' como PK
      codigo:
          json['codigo'] is int
              ? json['codigo']
              : int.tryParse(json['codigo']?.toString() ?? ''),
      nome: json['nome'],
      nomeReduzido: json['nome_reduzido'],
      tipo: json['tipo']?.toString(),
      cpf: json['cpf'],
      fone: json['fone'], // ✅ Campo correto do backend
      celular: json['celular'],
      email: json['email'],
    );
  }

  /// Retorna o telefone disponível (celular tem prioridade)
  String? get telefoneDisponivel =>
      celular?.isNotEmpty == true ? celular : fone;
}

// =============================================================================
// API SERVICE (Atualizado para novo backend FastAPI)
// =============================================================================
class ApiService {
  // ✅ CONFIGURAÇÃO DO NOVO BACKEND
  // Ajuste conforme seu ambiente
  static const String baseUrl =
      'http://192.168.3.150:8000'; // URL base do backend
  static const String apiPath =
      '/api/v1/clientes'; // Prefixo do router de clientes

  // URLs completas
  static String get clientesUrl => '$baseUrl$apiPath';
  static String get healthUrl => '$baseUrl/health';

  // =========================================================================
  // BUSCAR CLIENTE POR CPF
  // Endpoint: GET /clientes/cpf/{cpf}
  // =========================================================================
  static Future<ClienteResponse?> buscarClientePorCpf(String cpf) async {
    try {
      // Remove caracteres especiais do CPF para a URL
      final cpfLimpo = cpf.replaceAll(RegExp(r'\D'), '');
      print('🔍 Buscando CPF: $cpfLimpo');

      final response = await http
          .get(
            Uri.parse('$clientesUrl/cpf/$cpfLimpo'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      print('📡 Status: ${response.statusCode}');
      print('📄 Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ClienteResponse.fromJson(data);
      } else if (response.statusCode == 404) {
        print('ℹ️ CPF não encontrado no banco');
        return null;
      } else {
        throw Exception('Erro na consulta: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Sem conexão com o servidor');
    } on TimeoutException {
      throw Exception('Tempo de conexão esgotado');
    } catch (e) {
      print('❌ Erro ao buscar CPF: $e');
      throw Exception('Erro de conexão: $e');
    }
  }

  // =========================================================================
  // VALIDAR SE CPF JÁ EXISTE
  // Endpoint: GET /clientes/validar/cpf/{cpf}
  // =========================================================================
  static Future<bool> validarCpfExiste(String cpf) async {
    try {
      final cpfLimpo = cpf.replaceAll(RegExp(r'\D'), '');
      print('🔍 Validando CPF: $cpfLimpo');

      final response = await http
          .get(
            Uri.parse('$clientesUrl/validar/cpf/$cpfLimpo'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['exists'] ?? false;
      }
      return false;
    } catch (e) {
      print('❌ Erro ao validar CPF: $e');
      throw Exception('Erro ao validar CPF: $e');
    }
  }

  // =========================================================================
  // VALIDAR SE EMAIL JÁ EXISTE
  // Endpoint: GET /clientes/validar/email/{email}
  // =========================================================================
  static Future<bool> validarEmailExiste(String email) async {
    try {
      print('🔍 Validando Email: $email');

      final response = await http
          .get(
            Uri.parse(
              '$clientesUrl/validar/email/${Uri.encodeComponent(email)}',
            ),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['exists'] ?? false;
      }
      return false;
    } catch (e) {
      print('❌ Erro ao validar email: $e');
      return false; // Em caso de erro, permite continuar
    }
  }

  // =========================================================================
  // CADASTRAR NOVO CLIENTE
  // Endpoint: POST /clientes
  // Body: ClienteCreate { cpf, nome, email, fone?, celular? }
  // =========================================================================
  static Future<ClienteResponse?> cadastrarCliente({
    required String cpf,
    required String nome,
    required String telefone,
    required String email,
  }) async {
    try {
      // ✅ Prepara dados conforme schema ClienteCreate do backend
      final body = {
        'cpf': cpf.replaceAll(RegExp(r'\D'), ''), // Envia só números
        'nome': nome.trim().toUpperCase(), // Backend espera uppercase
        'email': email.trim().toLowerCase(), // Backend espera lowercase
        'celular': telefone.replaceAll(RegExp(r'\D'), ''), // Envia só números
      };

      print('📝 Enviando cadastro: ${json.encode(body)}');

      final response = await http
          .post(
            Uri.parse(clientesUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 15));

      print('📡 Status cadastro: ${response.statusCode}');
      print('📄 Response: ${response.body}');

      if (response.statusCode == 201) {
        // ✅ Sucesso - retorna o cliente criado
        final data = json.decode(response.body);
        print('✅ Cliente cadastrado com sucesso! Grid: ${data['grid']}');
        return ClienteResponse.fromJson(data);
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        final detail = data['detail'] ?? 'Erro no cadastro';

        if (detail.toString().toLowerCase().contains('cpf')) {
          throw Exception('CPF já está cadastrado no sistema');
        } else if (detail.toString().toLowerCase().contains('email')) {
          throw Exception('Email já está cadastrado no sistema');
        }
        throw Exception(detail);
      } else {
        final data = json.decode(response.body);
        throw Exception(data['detail'] ?? 'Erro desconhecido no cadastro');
      }
    } on SocketException {
      throw Exception('Sem conexão com o servidor');
    } on TimeoutException {
      throw Exception('Tempo de conexão esgotado');
    } catch (e) {
      print('❌ Erro no cadastro: $e');
      rethrow;
    }
  }

  // =========================================================================
  // TESTAR CONEXÃO COM O SERVIDOR
  // =========================================================================
  static Future<bool> testarConexao() async {
    try {
      print('🔍 Testando conexão: $healthUrl');

      final response = await http
          .get(Uri.parse(healthUrl))
          .timeout(const Duration(seconds: 5));

      print('📡 Status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Erro na conexão: $e');
      return false;
    }
  }

  // =========================================================================
  // DEBUG DE CONEXÃO
  // =========================================================================
  static Future<void> debugConexao() async {
    print('🐛 === DEBUG DE CONEXÃO ===');
    print('🌐 Base URL: $baseUrl');
    print('👤 Clientes URL: $clientesUrl');
    print('🏥 Health URL: $healthUrl');

    try {
      // Teste 1: Health check
      print('\n🧪 Teste 1: Health Check');
      final healthResponse = await http
          .get(Uri.parse(healthUrl))
          .timeout(const Duration(seconds: 5));
      print('   Status: ${healthResponse.statusCode}');

      // Teste 2: Listar clientes (limite 1)
      print('\n🧪 Teste 2: Listar clientes');
      final clientesResponse = await http
          .get(Uri.parse('$clientesUrl?limit=1'))
          .timeout(const Duration(seconds: 5));
      print('   Status: ${clientesResponse.statusCode}');

      // Teste 3: Estatísticas
      print('\n🧪 Teste 3: Estatísticas de clientes');
      final statsResponse = await http
          .get(Uri.parse('$clientesUrl/stats'))
          .timeout(const Duration(seconds: 5));
      print('   Status: ${statsResponse.statusCode}');
      if (statsResponse.statusCode == 200) {
        print('   Stats: ${statsResponse.body}');
      }
    } catch (e) {
      print('❌ Erro no debug: $e');
    }
    print('\n🐛 === FIM DEBUG ===');
  }

  // =========================================================================
  // TESTAR INTERNET BÁSICO
  // =========================================================================
  static Future<bool> testarInternetBasico() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('✅ Internet conectada');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Sem internet: $e');
      return false;
    }
  }
}

// =============================================================================
// CRM SCREEN (Tela de Identificação do Cliente)
// =============================================================================
class CrmScreen extends StatefulWidget {
  const CrmScreen({super.key});

  @override
  State<CrmScreen> createState() => _CrmScreenState();
}

class _CrmScreenState extends State<CrmScreen> {
  // Cores do tema
  static const roxo = Color(0xFF4B0082);
  static const cinzaFundo = Color(0xFFF6F6F8);

  // Controllers
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Máscaras
  final MaskTextInputFormatter _cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final MaskTextInputFormatter _telefoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  // Estados
  bool _cpfEncontrado = false;
  bool _mostrarCamposAdicionais = false;
  bool _isLoading = false;
  bool _conexaoOk = false;
  ClienteResponse? _clienteEncontrado;

  // Timer de inatividade (90 segundos)
  Timer? _inactivityTimer;
  int _inactivitySeconds = 90;
  static const int _maxInactivitySeconds = 90;

  @override
  void initState() {
    super.initState();
    _verificarConexao();
    _iniciarTimerInatividade();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    _cpfController.dispose();
    _nomeController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // TIMER DE INATIVIDADE
  // ===========================================================================
  void _iniciarTimerInatividade() {
    _inactivityTimer?.cancel();
    setState(() => _inactivitySeconds = _maxInactivitySeconds);

    _inactivityTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _inactivitySeconds--;
        if (_inactivitySeconds <= 0) {
          _voltarParaTelaInicial();
        }
      });
    });
  }

  void _resetarTimerInatividade() {
    _iniciarTimerInatividade();
  }

  void _voltarParaTelaInicial() {
    _inactivityTimer?.cancel();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sessão encerrada por inatividade'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SplashScreen()),
          (route) => false,
        );
      }
    });
  }

  // ===========================================================================
  // CONEXÃO
  // ===========================================================================
  Future<void> _verificarConexao() async {
    print('🔄 Verificando conexão...');

    final temInternet = await ApiService.testarInternetBasico();
    if (!temInternet) {
      setState(() => _conexaoOk = false);
      _mostrarSnackBar('Sem conexão com internet', isError: true);
      return;
    }

    await ApiService.debugConexao();

    final conexao = await ApiService.testarConexao();
    setState(() => _conexaoOk = conexao);

    if (!conexao) {
      _mostrarSnackBar('Sem conexão com servidor.', isError: true);
    } else {
      print('✅ Conexão estabelecida com sucesso');
    }
  }

  // ===========================================================================
  // VALIDAÇÕES
  // ===========================================================================
  bool _isValidCpf(String cpf) {
    cpf = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (cpf.length != 11 || RegExp(r'^(\d)\1*$').hasMatch(cpf)) return false;

    List<int> n = cpf.split('').map(int.parse).toList();

    int calc(List<int> nums, int max) {
      int sum = 0;
      for (int i = 0; i < max; i++) {
        sum += nums[i] * (max + 1 - i);
      }
      int r = (sum * 10) % 11;
      return r == 10 ? 0 : r;
    }

    int d1 = calc(n, 9);
    int d2 = calc(n, 10);
    return d1 == n[9] && d2 == n[10];
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // ===========================================================================
  // PESQUISAR CPF
  // ===========================================================================
  Future<void> _pesquisarCpf() async {
    String cpf = _cpfController.text.replaceAll(RegExp(r'\D'), '');

    if (!_isValidCpf(cpf)) {
      _mostrarSnackBar('CPF inválido.', isError: true);
      return;
    }

    if (!_conexaoOk) {
      _mostrarSnackBar('Sem conexão com servidor.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('🔍 Iniciando busca de CPF: $cpf');
      final cliente = await ApiService.buscarClientePorCpf(cpf);

      setState(() {
        _isLoading = false;
        _clienteEncontrado = cliente;
        _cpfEncontrado = cliente != null;

        if (!_cpfEncontrado) {
          _mostrarCamposAdicionais = true;
        }
      });

      if (_cpfEncontrado && cliente != null) {
        print('✅ Cliente encontrado: ${cliente.nome}');
        await Future.delayed(const Duration(seconds: 2));
        _navegarParaProximaTela();
      } else {
        _mostrarSnackBar(
          'CPF não encontrado. Preencha os dados para cadastro.',
          isError: false,
        );
      }
    } catch (e) {
      print('❌ Erro na consulta: $e');
      setState(() => _isLoading = false);
      _mostrarSnackBar(
        'Erro na consulta: ${e.toString().replaceAll('Exception: ', '')}',
        isError: true,
      );
    }
  }

  // ===========================================================================
  // CADASTRAR CLIENTE
  // ===========================================================================
  Future<void> _confirmarCadastro() async {
    if (!_validarCamposObrigatorios()) return;

    if (!_conexaoOk) {
      _mostrarSnackBar('Sem conexão com servidor.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ✅ Agora retorna o cliente cadastrado
      final clienteCadastrado = await ApiService.cadastrarCliente(
        cpf: _cpfController.text,
        nome: _nomeController.text.trim(),
        telefone: _telefoneController.text,
        email: _emailController.text.trim(),
      );

      setState(() {
        _isLoading = false;
        _clienteEncontrado = clienteCadastrado; // ✅ Guarda o cliente cadastrado
      });

      _mostrarSnackBar('Cliente cadastrado com sucesso!', isError: false);
      await Future.delayed(const Duration(seconds: 2));
      _navegarParaProximaTela();
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarSnackBar(
        e.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
    }
  }

  bool _validarCamposObrigatorios() {
    if (_nomeController.text.trim().isEmpty) {
      _mostrarSnackBar('Nome é obrigatório.', isError: true);
      return false;
    }

    if (_nomeController.text.trim().length < 3) {
      _mostrarSnackBar('Nome deve ter pelo menos 3 caracteres.', isError: true);
      return false;
    }

    String telefone = _telefoneController.text.replaceAll(RegExp(r'\D'), '');
    if (telefone.length != 11) {
      _mostrarSnackBar('Telefone deve ter 11 dígitos.', isError: true);
      return false;
    }

    if (!_isValidEmail(_emailController.text.trim())) {
      _mostrarSnackBar('Email inválido.', isError: true);
      return false;
    }

    return true;
  }

  // ===========================================================================
  // NAVEGAÇÃO
  // ===========================================================================
  void _navegarParaProximaTela() {
    String nomeCliente;
    bool isNovoCliente;
    Map<String, dynamic> dadosCliente;

    if (_cpfEncontrado && _clienteEncontrado != null) {
      // Cliente existente encontrado
      nomeCliente = _clienteEncontrado!.nome ?? 'Cliente';
      isNovoCliente = false;

      dadosCliente = {
        'pessoa_id': _clienteEncontrado!.grid, // ✅ Usando 'grid' como ID
        'pessoa_nome': _clienteEncontrado!.nome ?? '',
        'pessoa_cpf': _clienteEncontrado!.cpf ?? _cpfController.text,
        'pessoa_email': _clienteEncontrado!.email ?? '',
        'pessoa_telefone': _clienteEncontrado!.telefoneDisponivel ?? '',
      };
    } else if (_clienteEncontrado != null) {
      // Novo cliente cadastrado (retornado pela API)
      nomeCliente = _clienteEncontrado!.nome ?? _nomeController.text.trim();
      isNovoCliente = true;

      dadosCliente = {
        'pessoa_id': _clienteEncontrado!.grid, // ✅ ID retornado pela API
        'pessoa_nome': _clienteEncontrado!.nome ?? _nomeController.text.trim(),
        'pessoa_cpf': _clienteEncontrado!.cpf ?? _cpfController.text,
        'pessoa_email':
            _clienteEncontrado!.email ?? _emailController.text.trim(),
        'pessoa_telefone':
            _clienteEncontrado!.telefoneDisponivel ?? _telefoneController.text,
      };
    } else {
      // Fallback (não deveria acontecer)
      nomeCliente = _nomeController.text.trim();
      isNovoCliente = true;

      dadosCliente = {
        'pessoa_id': 0,
        'pessoa_nome': _nomeController.text.trim(),
        'pessoa_cpf': _cpfController.text,
        'pessoa_email': _emailController.text.trim(),
        'pessoa_telefone': _telefoneController.text,
      };
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder:
            (context) => BoasVindasScreen(
              nomeCliente: nomeCliente,
              isNovoCliente: isNovoCliente,
              dadosCliente: dadosCliente,
            ),
      ),
    );
  }

  // ===========================================================================
  // HELPERS UI
  // ===========================================================================
  void _mostrarSnackBar(String mensagem, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _limparFormulario() {
    setState(() {
      _cpfController.clear();
      _nomeController.clear();
      _telefoneController.clear();
      _emailController.clear();
      _cpfEncontrado = false;
      _mostrarCamposAdicionais = false;
      _clienteEncontrado = null;
    });
  }

  // ===========================================================================
  // UI WIDGETS
  // ===========================================================================
  Widget _topHeader() {
    final minutes = _inactivitySeconds ~/ 60;
    final seconds = _inactivitySeconds % 60;
    final timeDisplay =
        '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';

    Color timerColor;
    if (_inactivitySeconds > 60) {
      timerColor = Colors.white;
    } else if (_inactivitySeconds > 30) {
      timerColor = Colors.orange;
    } else {
      timerColor = Colors.red;
    }

    return Container(
      color: roxo,
      padding: const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 12),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Logo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.business, color: roxo, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'TOTEM',
                    style: TextStyle(
                      color: roxo,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Timer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: timerColor.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_outlined, color: timerColor, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    timeDisplay,
                    style: TextStyle(
                      color: timerColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Indicador de conexão
            Icon(
              _conexaoOk ? Icons.wifi : Icons.wifi_off,
              color: _conexaoOk ? Colors.white : Colors.red,
              size: 20,
            ),
            const SizedBox(width: 8),
            // Botão refresh
            IconButton(
              onPressed: () {
                _limparFormulario();
                _resetarTimerInatividade();
              },
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Limpar formulário',
            ),
          ],
        ),
      ),
    );
  }

  Widget _banner() {
    return Container(
      height: 240,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Image.asset('assets/images/banner.jpg', fit: BoxFit.cover),
    );
  }

  Widget _cpfFormCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Título
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: roxo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.store, color: roxo, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'CRM • POLPANORTE',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: roxo,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _mostrarCamposAdicionais
                ? 'Complete seus dados para continuar'
                : 'Digite seu CPF para continuar',
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black54,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),

          // Cliente encontrado
          if (_cpfEncontrado && _clienteEncontrado != null) ...[
            const SizedBox(height: 20),
            _buildClienteEncontradoCard(),
          ],

          const SizedBox(height: 20),

          // Campo CPF
          _buildTextField(
            controller: _cpfController,
            label: 'CPF',
            hint: '000.000.000-00',
            icon: Icons.credit_card,
            keyboardType: TextInputType.number,
            inputFormatters: [_cpfMask],
            enabled: !_mostrarCamposAdicionais && !_cpfEncontrado,
          ),

          // Campos adicionais
          if (_mostrarCamposAdicionais) ...[
            const SizedBox(height: 16),
            _buildTextField(
              controller: _nomeController,
              label: 'Nome Completo *',
              hint: 'Digite seu nome completo',
              icon: Icons.person,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _telefoneController,
              label: 'Telefone *',
              hint: '(00) 00000-0000',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [_telefoneMask],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _emailController,
              label: 'Email *',
              hint: 'seu.email@exemplo.com',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
            ),
          ],

          const SizedBox(height: 28),

          // Botões
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _isLoading
                          ? null
                          : () {
                            _resetarTimerInatividade();
                            Navigator.of(context).maybePop();
                          },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: roxo.withOpacity(0.5), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Voltar',
                    style: TextStyle(
                      color: roxo,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      _isLoading
                          ? null
                          : () {
                            _resetarTimerInatividade();
                            if (_cpfEncontrado) {
                              _navegarParaProximaTela();
                            } else if (_mostrarCamposAdicionais) {
                              _confirmarCadastro();
                            } else {
                              _pesquisarCpf();
                            }
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: roxo,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : Text(
                            _cpfEncontrado
                                ? 'Continuar'
                                : (_mostrarCamposAdicionais
                                    ? 'Finalizar Cadastro'
                                    : 'Pesquisar CPF'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClienteEncontradoCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.green.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Cliente Encontrado!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                    fontSize: 16,
                  ),
                ),
              ),
              Icon(Icons.check_circle, color: Colors.green.shade600, size: 24),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.green.shade300, height: 1),
          const SizedBox(height: 12),
          _buildInfoRow('Nome', _clienteEncontrado!.nome ?? 'N/A'),
          if (_clienteEncontrado!.email?.isNotEmpty == true)
            _buildInfoRow('Email', _clienteEncontrado!.email!),
          if (_clienteEncontrado!.telefoneDisponivel?.isNotEmpty == true)
            _buildInfoRow('Telefone', _clienteEncontrado!.telefoneDisponivel!),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool enabled = true,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      enabled: enabled,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      onChanged: (_) => _resetarTimerInatividade(),
      onTap: _resetarTimerInatividade,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: enabled ? roxo : Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: roxo, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        filled: true,
        fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
        labelStyle: TextStyle(
          color: enabled ? roxo : Colors.grey,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _resetarTimerInatividade,
      onPanDown: (_) => _resetarTimerInatividade(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: cinzaFundo,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _topHeader(),
            _banner(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: _cpfFormCard(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

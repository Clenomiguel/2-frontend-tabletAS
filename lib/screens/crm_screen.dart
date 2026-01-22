import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:http/http.dart' as http;
import 'boas_vindas_screen.dart';
import 'splash_screen.dart';

// Modelos para API
class ClienteResponse {
  final int id;
  final String? codigo;
  final String? nome;
  final String? nomeReduzido;
  final String? tipo;
  final String? cpf;
  final String? telefone;
  final String? celular;
  final String? email;

  ClienteResponse({
    required this.id,
    this.codigo,
    this.nome,
    this.nomeReduzido,
    this.tipo,
    this.cpf,
    this.telefone,
    this.celular,
    this.email,
  });

  factory ClienteResponse.fromJson(Map<String, dynamic> json) {
    return ClienteResponse(
      id: json['id'],
      codigo: json['codigo']?.toString(),
      nome: json['nome'],
      nomeReduzido: json['nome_reduzido'],
      tipo: json['tipo']?.toString(),
      cpf: json['cpf'],
      telefone: json['telefone'],
      celular: json['celular'],
      email: json['email'],
    );
  }
}

class ApiService {
  // Configurar a URL base da API - AJUSTE CONFORME SEU AMBIENTE
  static const String baseUrl =
      'http://192.168.3.150:8000/api/v1'; // Para emulador Android
  static const String healthUrl =
      'http://192.168.3.150:8000'; // URL base para health check

  // CONFIGURAÇÕES ALTERNATIVAS:
  // Para dispositivo físico: 'http://192.168.1.100:8000/api/v1' (substitua pelo IP da sua máquina)
  // Para iOS Simulator: 'http://127.0.0.1:8000/api/v1'
  // Para teste local: 'http://localhost:8000/api/v1'

  static Future<ClienteResponse?> buscarClientePorCpf(String cpf) async {
    try {
      // Envia CPF formatado (com pontuação) como está no banco
      final cpfFormatado = _formatarCpf(cpf);
      print('🔍 Buscando CPF: $cpfFormatado');

      final response = await http
          .get(
            Uri.parse('$baseUrl/pessoa/cpf/$cpfFormatado'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ClienteResponse.fromJson(data);
      } else if (response.statusCode == 404) {
        return null; // Cliente não encontrado
      } else {
        throw Exception('Erro na consulta: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  static Future<bool> validarCpf(String cpf) async {
    try {
      // Envia CPF formatado (com pontuação) como está no banco
      final cpfFormatado = _formatarCpf(cpf);
      print('🔍 Validando CPF: $cpfFormatado');

      final response = await http
          .get(
            Uri.parse('$baseUrl/pessoa/validar/cpf/$cpfFormatado'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['existe'] ?? false;
      }
      return false;
    } catch (e) {
      throw Exception('Erro ao validar CPF: $e');
    }
  }

  static Future<bool> cadastrarCliente({
    required String cpf,
    required String nome,
    required String telefone,
    required String email,
  }) async {
    try {
      // Prepara dados para envio
      final body = {
        'cpf': cpf, // Envia CPF como digitado (será formatado no backend)
        'nome': nome,
        'telefone': telefone,
        'email': email,
      };

      print('📝 Enviando dados para cadastro: ${json.encode(body)}');

      // Chama o endpoint POST real da API
      final response = await http
          .post(
            Uri.parse('$baseUrl/pessoa'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 15));

      print('📡 Status do cadastro: ${response.statusCode}');
      print('📄 Resposta do cadastro: ${response.body}');

      if (response.statusCode == 201) {
        // Sucesso no cadastro
        final data = json.decode(response.body);
        print('✅ Cliente cadastrado com sucesso: ${data['message']}');
        return true;
      } else if (response.statusCode == 409) {
        // CPF ou email já existe
        final data = json.decode(response.body);
        throw Exception('${data['detail']}');
      } else if (response.statusCode == 502) {
        // Erro na API do Linx
        throw Exception('Erro no sistema Linx. Tente novamente.');
      } else if (response.statusCode == 504) {
        // Timeout na API do Linx
        throw Exception('Sistema Linx indisponível. Tente novamente.');
      } else {
        // Outros erros
        final data = json.decode(response.body);
        throw Exception(
          'Erro no cadastro: ${data['detail'] ?? 'Erro desconhecido'}',
        );
      }
    } catch (e) {
      print('❌ Erro no cadastro: $e');
      throw Exception('Erro ao cadastrar cliente: $e');
    }
  }

  static Future<bool> testarConexao() async {
    try {
      print('🔍 Testando conexão: $healthUrl/health');

      final response = await http
          .get(
            Uri.parse('$healthUrl/health'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      print('📡 Status da resposta: ${response.statusCode}');
      print('📄 Corpo da resposta: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Erro na conexão: $e');
      return false;
    }
  }

  static Future<void> debugConexao() async {
    print('🐛 === DEBUG DE CONEXÃO ===');
    print('🌐 URL Base: $baseUrl');
    print('🏥 URL Health: $healthUrl/health');

    try {
      // Teste 1: Health check
      print('🧪 Teste 1: Health Check');
      final healthResponse = await http
          .get(Uri.parse('$healthUrl/health'))
          .timeout(const Duration(seconds: 5));
      print('   Status: ${healthResponse.statusCode}');
      print('   Body: ${healthResponse.body}');

      // Teste 2: Info endpoint
      print('🧪 Teste 2: Info endpoint');
      final infoResponse = await http
          .get(Uri.parse('$healthUrl/info'))
          .timeout(const Duration(seconds: 5));
      print('   Status: ${infoResponse.statusCode}');
      print('   Body: ${infoResponse.body}');

      // Teste 3: Clientes endpoint
      print('🧪 Teste 3: Clientes endpoint');
      final clientesResponse = await http
          .get(Uri.parse('$baseUrl/clientes?limit=1'))
          .timeout(const Duration(seconds: 5));
      print('   Status: ${clientesResponse.statusCode}');
      print(
        '   Body: ${clientesResponse.body.length > 200 ? clientesResponse.body.substring(0, 200) + "..." : clientesResponse.body}',
      );
    } catch (e) {
      print('❌ Erro no debug: $e');
    }
    print('🐛 === FIM DEBUG ===');
  }

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

  // Método para formatar CPF no padrão do banco (XXX.XXX.XXX-XX)
  static String _formatarCpf(String cpf) {
    // Remove tudo que não é número
    final cpfLimpo = cpf.replaceAll(RegExp(r'\D'), '');

    // Verifica se tem 11 dígitos
    if (cpfLimpo.length != 11) {
      return cpf; // Retorna original se não tiver 11 dígitos
    }

    // Formata: XXX.XXX.XXX-XX
    return '${cpfLimpo.substring(0, 3)}.${cpfLimpo.substring(3, 6)}.${cpfLimpo.substring(6, 9)}-${cpfLimpo.substring(9, 11)}';
  }
}

class CrmScreen extends StatefulWidget {
  const CrmScreen({super.key});

  @override
  State<CrmScreen> createState() => _CrmScreenState();
}

class _CrmScreenState extends State<CrmScreen> {
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

  // ✅ Timer de inatividade (90 segundos = 1min 30s)
  Timer? _inactivityTimer;
  int _inactivitySeconds = 90;
  static const int _maxInactivitySeconds = 90;

  @override
  void initState() {
    super.initState();
    _verificarConexao();

    // ✅ Iniciar timer de inatividade
    _iniciarTimerInatividade();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel(); // ✅ Cancelar timer de inatividade
    _cpfController.dispose();
    _nomeController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // ✅ NOVO: Iniciar/Reiniciar timer de inatividade
  void _iniciarTimerInatividade() {
    _inactivityTimer?.cancel();
    setState(() => _inactivitySeconds = _maxInactivitySeconds);

    _inactivityTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _inactivitySeconds--;

        // Quando chegar a zero, volta para tela inicial
        if (_inactivitySeconds <= 0) {
          _voltarParaTelaInicial();
        }
      });
    });
  }

  // ✅ NOVO: Resetar timer quando houver interação
  void _resetarTimerInatividade() {
    _iniciarTimerInatividade();
  }

  // ✅ NOVO: Voltar para tela inicial por inatividade
  void _voltarParaTelaInicial() {
    _inactivityTimer?.cancel();

    // Mostrar mensagem
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

  Future<void> _verificarConexao() async {
    print('🔄 Verificando conexão...');

    // Primeiro testa conectividade básica com internet
    final temInternet = await ApiService.testarInternetBasico();
    if (!temInternet) {
      setState(() => _conexaoOk = false);
      _mostrarSnackBar('Sem conexão com internet', isError: true);
      return;
    }

    // Executa debug completo da conexão
    await ApiService.debugConexao();

    final conexao = await ApiService.testarConexao();
    setState(() => _conexaoOk = conexao);

    if (!conexao) {
      _mostrarSnackBar('Sem conexão com servidor.', isError: true);
      print('❌ Falha na conexão com o servidor');
    } else {
      print('✅ Conexão estabelecida com sucesso');
    }
  }

  // Validação de CPF
  bool isValidCpf(String cpf) {
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

  // Validação de email
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Pesquisar CPF na API
  Future<void> _pesquisarCpf() async {
    String cpf = _cpfController.text.replaceAll(RegExp(r'\D'), '');

    if (!isValidCpf(cpf)) {
      _mostrarSnackBar('CPF inválido.', isError: true);
      return;
    }

    if (!_conexaoOk) {
      _mostrarSnackBar('Sem conexão com servidor.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    // Mostra mensagem de que está consultando
    // _mostrarSnackBar('Consultando CPF...', isError: false);

    try {
      print('🔍 Iniciando busca de CPF: ${_cpfController.text}');
      final cliente = await ApiService.buscarClientePorCpf(_cpfController.text);

      setState(() {
        _isLoading = false;
        _clienteEncontrado = cliente;
        _cpfEncontrado = cliente != null;

        if (!_cpfEncontrado) {
          _mostrarCamposAdicionais = true;
        }
      });

      if (_cpfEncontrado && cliente != null) {
        // print('✅ Cliente encontrado: ${cliente.nome}');
        // _mostrarSnackBar('Cliente encontrado: ${cliente.nome}', isError: false);
        await Future.delayed(const Duration(seconds: 2));
        _navegarParaProximaTela();
      } else {
        print('ℹ️ CPF não encontrado no banco');
        _mostrarSnackBar(
          'CPF não encontrado. Preencha os dados para cadastro.',
          isError: false,
        );
      }
    } catch (e) {
      print('❌ Erro na consulta: $e');
      setState(() => _isLoading = false);
      _mostrarSnackBar('Erro na consulta: ${e.toString()}', isError: true);
    }
  }

  // Confirmar cadastro
  Future<void> _confirmarCadastro() async {
    if (!_validarCamposObrigatorios()) return;

    if (!_conexaoOk) {
      _mostrarSnackBar('Sem conexão com servidor.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final sucesso = await ApiService.cadastrarCliente(
        cpf: _cpfController.text, // Enviará com máscara: XXX.XXX.XXX-XX
        nome: _nomeController.text.trim(),
        telefone:
            _telefoneController.text, // Enviará com máscara: (XX) XXXXX-XXXX
        email: _emailController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (sucesso) {
        _mostrarSnackBar('Cliente cadastrado com sucesso!', isError: false);
        await Future.delayed(const Duration(seconds: 2));
        _navegarParaProximaTela();
      } else {
        _mostrarSnackBar('Erro ao cadastrar cliente.', isError: true);
      }
    } catch (e) {
      setState(() => _isLoading = false);

      // Tratamento de erros específicos
      String mensagemErro = e.toString();
      if (mensagemErro.contains('CPF') &&
          mensagemErro.contains('já está cadastrado')) {
        _mostrarSnackBar('CPF já está cadastrado no sistema.', isError: true);
      } else if (mensagemErro.contains('Email') &&
          mensagemErro.contains('já está cadastrado')) {
        _mostrarSnackBar('Email já está cadastrado no sistema.', isError: true);
      } else if (mensagemErro.contains('sistema Linx indisponível')) {
        _mostrarSnackBar(
          'Sistema temporariamente indisponível. Tente novamente.',
          isError: true,
        );
      } else {
        _mostrarSnackBar('Erro no cadastro: ${e.toString()}', isError: true);
      }
    }
  }

  bool _validarCamposObrigatorios() {
    if (_nomeController.text.trim().isEmpty) {
      _mostrarSnackBar('Nome é obrigatório.', isError: true);
      return false;
    }

    String telefone = _telefoneController.text.replaceAll(RegExp(r'\D'), '');
    if (telefone.length != 11) {
      _mostrarSnackBar('Telefone deve ter 11 dígitos.', isError: true);
      return false;
    }

    if (!isValidEmail(_emailController.text.trim())) {
      _mostrarSnackBar('Email inválido.', isError: true);
      return false;
    }

    return true;
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

  void _navegarParaProximaTela() {
    // Determinar nome do cliente
    String nomeCliente;
    bool isNovoCliente = false;
    Map<String, dynamic> dadosCliente; // ✅ NOVO

    if (_cpfEncontrado && _clienteEncontrado != null) {
      // Cliente existente encontrado
      nomeCliente = _clienteEncontrado!.nome ?? 'Cliente';
      isNovoCliente = false;

      // ✅ NOVO: Montar dados do cliente
      dadosCliente = {
        'pessoa_id': _clienteEncontrado!.id,
        'pessoa_nome': _clienteEncontrado!.nome ?? '',
        'pessoa_cpf': _cpfController.text,
        'pessoa_email': _clienteEncontrado!.email ?? '',
        'pessoa_telefone':
            _clienteEncontrado!.celular ?? _clienteEncontrado!.telefone ?? '',
      };
    } else {
      // Novo cliente cadastrado
      nomeCliente = _nomeController.text.trim();
      isNovoCliente = true;

      // ✅ NOVO: Montar dados do cliente novo
      dadosCliente = {
        'pessoa_id': 0, // Será atualizado após cadastro bem-sucedido
        'pessoa_nome': _nomeController.text.trim(),
        'pessoa_cpf': _cpfController.text,
        'pessoa_email': _emailController.text.trim(),
        'pessoa_telefone': _telefoneController.text,
      };
    }

    // Navegar para tela de boas-vindas animada
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder:
            (context) => BoasVindasScreen(
              nomeCliente: nomeCliente,
              isNovoCliente: isNovoCliente,
              dadosCliente: dadosCliente, // ✅ NOVO
            ),
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

  // ----------------- UI -----------------
  Widget _topHeader() {
    // Calcular minutos e segundos para display
    final minutes = _inactivitySeconds ~/ 60;
    final seconds = _inactivitySeconds % 60;
    final timeDisplay =
        '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';

    // Definir cor do timer baseado no tempo restante
    Color timerColor;
    if (_inactivitySeconds > 60) {
      timerColor = Colors.white; // Verde: mais de 1 minuto
    } else if (_inactivitySeconds > 30) {
      timerColor = Colors.orange; // Laranja: entre 30s e 1min
    } else {
      timerColor = Colors.red; // Vermelho: menos de 30s
    }

    return Container(
      color: roxo,
      padding: const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 12),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // ✅ LOGO LINX (Placeholder - substitua por Image.asset quando tiver a imagem)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.business, color: roxo, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'LINX',
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
                // ✅ Quando tiver a imagem do logo, substitua o Container acima por:
                // Image.asset(
                //   'assets/images/logo_linx.png',
                //   height: 30,
                //   fit: BoxFit.contain,
                // ),
              ],
            ),
            const Spacer(),
            // ✅ TIMER DE INATIVIDADE
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
                _resetarTimerInatividade(); // ✅ Reset timer ao interagir
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
    final double h = 240; // ajuste fino: 180–240

    return Container(
      height: h,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Imagem do banner
          Image.asset('assets/images/banner.jpg', fit: BoxFit.cover),
        ],
      ),
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
          // Logo e título
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

          // Exibir dados do cliente encontrado
          if (_cpfEncontrado && _clienteEncontrado != null) ...[
            const SizedBox(height: 20),
            AnimatedContainer(
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
                      Icon(
                        Icons.check_circle,
                        color: Colors.green.shade600,
                        size: 24,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(color: Colors.green.shade300, height: 1),
                  const SizedBox(height: 12),
                  _buildInfoRow('Nome', _clienteEncontrado!.nome ?? 'N/A'),
                  if (_clienteEncontrado!.email != null &&
                      _clienteEncontrado!.email!.isNotEmpty)
                    _buildInfoRow('Email', _clienteEncontrado!.email!),
                  if (_clienteEncontrado!.celular != null &&
                      _clienteEncontrado!.celular!.isNotEmpty)
                    _buildInfoRow('Celular', _clienteEncontrado!.celular!),
                ],
              ),
            ),
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

          // Campos adicionais (aparecem apenas se CPF não for encontrado)
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
                            _resetarTimerInatividade(); // ✅ Reset timer
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
                            _resetarTimerInatividade(); // ✅ Reset timer
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
      // ✅ NOVO: Reset timer ao digitar
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
            width: 60,
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

  // ----------------- Build -----------------
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // ✅ Reset timer ao tocar na tela
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

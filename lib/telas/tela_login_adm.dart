// lib/telas/configuracao/admin_login_screen.dart
// Tela de login para acessar configurações do sistema (Corrigido)

import 'package:flutter/material.dart';
import '../../servicos/config_api_service.dart'; // Ajuste o caminho se necessário (../ ou ../../)
import '../../servicos/config_storage_service.dart';

class AdminLoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  final VoidCallback onCancel;

  const AdminLoginScreen({
    super.key,
    required this.onLoginSuccess,
    required this.onCancel,
  });

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioController = TextEditingController();
  final _senhaController = TextEditingController();

  final ConfigApiService _apiService = ConfigApiService();

  bool _isLoading = false;
  bool _obscureSenha = true;
  String? _erro;

  @override
  void dispose() {
    _usuarioController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _fazerLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _erro = null;
    });

    try {
      // CORREÇÃO 1: Uso do método estático getConfig() ao invés de getInstance()
      final config = await ConfigStorageService.getConfig();

      // O modelo AppConfig novo garante que empresaId é um int (padrão 0 se vazio)
      final empresaId = config.empresaId;

      final result = await _apiService.validarCredenciaisAdmin(
        usuario: _usuarioController.text.trim(),
        senha: _senhaController.text,
        empresaId: empresaId,
      );

      if (mounted) {
        if (result.success) {
          widget.onLoginSuccess();
        } else {
          setState(() {
            _isLoading = false;
            _erro = result.message;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _erro = 'Erro ao fazer login: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo/Ícone
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      // CORREÇÃO 2: withValues no lugar de withOpacity
                      color: Colors.blue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      size: 56,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Título
                  const Text(
                    'Acesso Restrito',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Entre com suas credenciais de administrador para acessar as configurações',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      // CORREÇÃO 2
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Campo Usuário
                  TextFormField(
                    controller: _usuarioController,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: _inputDecoration(
                      label: 'Usuário',
                      hint: 'Digite seu usuário',
                      prefixIcon: Icons.person,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Informe o usuário';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Campo Senha
                  TextFormField(
                    controller: _senhaController,
                    obscureText: _obscureSenha,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: _inputDecoration(
                      label: 'Senha',
                      hint: 'Digite sua senha',
                      prefixIcon: Icons.lock,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureSenha
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() => _obscureSenha = !_obscureSenha);
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Informe a senha';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _fazerLogin(),
                  ),
                  const SizedBox(height: 24),

                  // Erro
                  if (_erro != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        // CORREÇÃO 2
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.red.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _erro!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Botão Entrar
                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _fazerLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.login),
                      label: Text(
                        _isLoading ? 'Entrando...' : 'Entrar',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Botão Cancelar
                  TextButton(
                    onPressed: widget.onCancel,
                    child: Text(
                      'Cancelar',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: Colors.grey.shade400),
      hintStyle: TextStyle(color: Colors.grey.shade600),
      prefixIcon: Icon(prefixIcon, color: Colors.grey),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFF2d2d44),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }
}

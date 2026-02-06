// lib/telas/configuracao/admin_login_screen.dart
// Tela de login para acessar configurações do sistema (Corrigido)

import 'package:flutter/material.dart';
import '../../servicos/config_api_service.dart';
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
      // CORREÇÃO 1: Método estático direto (sem getInstance)
      final config = await ConfigStorageService.getConfig();

      // Precisamos do ID da empresa para validar o admin no banco correto
      // Se não tiver empresa configurada (empresaId == 0), o backend deve tratar
      final empresaId = config.empresaId ?? 0;

      final result = await _apiService.validarCredenciaisAdmin(
        usuario: _usuarioController.text.trim(),
        senha: _senhaController.text.trim(),
        empresaId: empresaId,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (result.success) {
          if (result.isOffline) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Modo Admin Offline ativado'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          widget.onLoginSuccess();
        } else {
          setState(() {
            _erro = result.message;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _erro = 'Erro de conexão: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e), // Fundo escuro
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF16213e),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.blue
                    .withValues(alpha: 0.2), // CORREÇÃO 2: withValues
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3), // CORREÇÃO 2
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Ícone Cadeado
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1), // CORREÇÃO 2
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      size: 40,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Título
                  const Text(
                    'Acesso Administrativo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Digite suas credenciais para configurar o terminal',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Mensagem de Erro
                  if (_erro != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1), // CORREÇÃO 2
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              Colors.red.withValues(alpha: 0.3), // CORREÇÃO 2
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _erro!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Campo Usuário
                  _buildInput(
                    controller: _usuarioController,
                    label: 'Usuário',
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 16),

                  // Campo Senha
                  _buildInput(
                    controller: _senhaController,
                    label: 'Senha',
                    icon: Icons.lock,
                    isPassword: true,
                  ),
                  const SizedBox(height: 32),

                  // Botão Entrar
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    ElevatedButton(
                      onPressed: _fazerLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Entrar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && _obscureSenha,
      style: const TextStyle(color: Colors.white),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Campo obrigatório';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: Colors.grey),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscureSenha ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() => _obscureSenha = !_obscureSenha);
                },
              )
            : null,
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
      ),
    );
  }
}

// lib/telas/configuracao/steps/step_servidor.dart
// Step 1: Configuração do IP e Porta do servidor

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../servicos/config_api_service.dart';

class StepServidor extends StatefulWidget {
  final String initialIp;
  final int initialPort;
  final ConfigApiService apiService;
  final Function(String ip, int port) onServidorConfigurado;

  const StepServidor({
    super.key,
    required this.initialIp,
    required this.initialPort,
    required this.apiService,
    required this.onServidorConfigurado,
  });

  @override
  State<StepServidor> createState() => _StepServidorState();
}

class _StepServidorState extends State<StepServidor> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _ipController;
  late TextEditingController _portController;

  bool _isTestando = false;
  ConnectionResult? _connectionResult;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(
      text: widget.initialIp.isNotEmpty ? widget.initialIp : '192.168.1.',
    );
    _portController = TextEditingController(
      text: widget.initialPort.toString(),
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _testarConexao() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isTestando = true;
      _connectionResult = null;
    });

    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 8000;

    final result = await widget.apiService.testarConexao(ip, port);

    setState(() {
      _isTestando = false;
      _connectionResult = result;
    });

    if (result.success) {
      // Aguarda um momento para mostrar o sucesso
      await Future.delayed(const Duration(milliseconds: 500));
      widget.onServidorConfigurado(ip, port);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ícone
            const Icon(
              Icons.dns,
              size: 64,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),

            // Descrição
            Text(
              'Configure a conexão com o servidor do AutoSystem',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 32),

            // Campo IP
            _buildLabel('Endereço IP do Servidor'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _ipController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: _inputDecoration(
                hintText: '192.168.1.100',
                prefixIcon: Icons.computer,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Informe o IP do servidor';
                }
                // Validação básica de IP
                final parts = value.split('.');
                if (parts.length != 4) {
                  return 'IP inválido (ex: 192.168.1.100)';
                }
                for (var part in parts) {
                  final num = int.tryParse(part);
                  if (num == null || num < 0 || num > 255) {
                    return 'IP inválido';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Campo Porta
            _buildLabel('Porta'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _portController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: _inputDecoration(
                hintText: '8000',
                prefixIcon: Icons.settings_ethernet,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(5),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Informe a porta';
                }
                final port = int.tryParse(value);
                if (port == null || port < 1 || port > 65535) {
                  return 'Porta inválida (1-65535)';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Resultado do teste
            if (_connectionResult != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _connectionResult!.success
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        _connectionResult!.success ? Colors.green : Colors.red,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _connectionResult!.success
                          ? Icons.check_circle
                          : Icons.error,
                      color: _connectionResult!.success
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _connectionResult!.message,
                        style: TextStyle(
                          color: _connectionResult!.success
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Botão Testar Conexão
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isTestando ? null : _testarConexao,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isTestando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.wifi_find),
                label: Text(
                  _isTestando ? 'Testando...' : 'Testar Conexão e Continuar',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Dica
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.blue.shade300,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'O IP é o endereço do computador onde está rodando o servidor da API. A porta padrão é 8000.',
                      style: TextStyle(
                        color: Colors.blue.shade300,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade500),
      prefixIcon: Icon(prefixIcon, color: Colors.grey),
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

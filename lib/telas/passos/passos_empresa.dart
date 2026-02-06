// lib/telas/configuracao/steps/step_empresa.dart
// Step 2: Seleção da Empresa

import 'package:flutter/material.dart';
import '../../../modelos/config_models.dart';
import '../../../servicos/config_api_service.dart';

class StepEmpresa extends StatefulWidget {
  final String serverIp;
  final int serverPort;
  final ConfigApiService apiService;
  final Function(EmpresaConfig empresa) onEmpresaSelecionada;
  final VoidCallback onVoltar;

  const StepEmpresa({
    super.key,
    required this.serverIp,
    required this.serverPort,
    required this.apiService,
    required this.onEmpresaSelecionada,
    required this.onVoltar,
  });

  @override
  State<StepEmpresa> createState() => _StepEmpresaState();
}

class _StepEmpresaState extends State<StepEmpresa> {
  List<EmpresaConfig> _empresas = [];
  EmpresaConfig? _empresaSelecionada;
  bool _isLoading = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarEmpresas();
  }

  Future<void> _carregarEmpresas() async {
    setState(() {
      _isLoading = true;
      _erro = null;
    });

    try {
      final empresas = await widget.apiService.buscarEmpresas(
        widget.serverIp,
        widget.serverPort,
      );

      setState(() {
        _empresas = empresas;
        _isLoading = false;
        // Se só tiver uma empresa, seleciona automaticamente
        if (empresas.length == 1) {
          _empresaSelecionada = empresas.first;
        }
      });
    } catch (e) {
      setState(() {
        _erro = 'Erro ao carregar empresas: $e';
        _isLoading = false;
      });
    }
  }

  void _continuar() {
    if (_empresaSelecionada != null) {
      widget.onEmpresaSelecionada(_empresaSelecionada!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Ícone
                const Icon(
                  Icons.business,
                  size: 64,
                  color: Colors.blue,
                ),
                const SizedBox(height: 24),

                // Descrição
                Text(
                  'Selecione a empresa que será utilizada neste terminal',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 32),

                // Loading
                if (_isLoading)
                  const Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Carregando empresas...',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),

                // Erro
                if (_erro != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          _erro!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _carregarEmpresas,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar Novamente'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Lista de empresas
                if (!_isLoading && _erro == null) ...[
                  if (_empresas.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.warning, color: Colors.orange, size: 48),
                          SizedBox(height: 12),
                          Text(
                            'Nenhuma empresa encontrada no banco de dados.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.orange),
                          ),
                        ],
                      ),
                    )
                  else
                    ...List.generate(_empresas.length, (index) {
                      final empresa = _empresas[index];
                      final isSelected =
                          _empresaSelecionada?.grid == empresa.grid;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            setState(() => _empresaSelecionada = empresa);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.blue.withOpacity(0.2)
                                  : const Color(0xFF2d2d44),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.blue
                                    : Colors.grey.shade700,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Radio visual
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.blue
                                          : Colors.grey,
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? Center(
                                          child: Container(
                                            width: 12,
                                            height: 12,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                // Ícone da empresa
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.store,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Informações
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        empresa.displayName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (empresa.cnpj != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'CNPJ: ${empresa.cnpj}',
                                          style: TextStyle(
                                            color: Colors.grey.shade400,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                      Text(
                                        'ID: ${empresa.grid}',
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Check
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.blue,
                                    size: 28,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ],
            ),
          ),
        ),

        // Botões de navegação
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1a1a2e),
            border: Border(
              top: BorderSide(color: Colors.grey.shade800),
            ),
          ),
          child: Row(
            children: [
              // Botão Voltar
              OutlinedButton.icon(
                onPressed: widget.onVoltar,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.grey.shade600),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Voltar'),
              ),
              const SizedBox(width: 16),
              // Botão Continuar
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _empresaSelecionada != null ? _continuar : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text(
                    'Continuar',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

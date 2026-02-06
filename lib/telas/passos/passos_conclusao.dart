// lib/telas/configuracao/steps/step_conclusao.dart
// Step 5: Conclusão da configuração

import 'package:flutter/material.dart';
import '../../../modelos/config_models.dart';

class StepConclusao extends StatelessWidget {
  final String serverIp;
  final int serverPort;
  final EmpresaConfig? empresa;
  final CardapioConfig? cardapio;
  final LicencaInfo? licenca;
  final bool isLoading;
  final VoidCallback onFinalizar;
  final VoidCallback onVoltar;

  const StepConclusao({
    super.key,
    required this.serverIp,
    required this.serverPort,
    required this.empresa,
    required this.cardapio,
    required this.licenca,
    required this.isLoading,
    required this.onFinalizar,
    required this.onVoltar,
  });

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
                // Ícone de sucesso
                const Icon(
                  Icons.celebration,
                  size: 64,
                  color: Colors.amber,
                ),
                const SizedBox(height: 24),

                // Título
                const Text(
                  'Tudo Pronto!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Confira as configurações antes de finalizar',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 32),

                // Resumo das configurações
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2d2d44),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade700),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resumo da Configuração',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Servidor
                      _buildConfigItem(
                        icon: Icons.dns,
                        iconColor: Colors.blue,
                        label: 'Servidor',
                        value: '$serverIp:$serverPort',
                      ),
                      const Divider(color: Colors.grey, height: 24),

                      // Empresa
                      _buildConfigItem(
                        icon: Icons.business,
                        iconColor: Colors.green,
                        label: 'Empresa',
                        value: empresa?.displayName ?? 'Não selecionada',
                        subValue:
                            empresa != null ? 'ID: ${empresa!.grid}' : null,
                      ),
                      const Divider(color: Colors.grey, height: 24),

                      // Cardápio
                      _buildConfigItem(
                        icon: Icons.restaurant_menu,
                        iconColor: Colors.orange,
                        label: 'Cardápio',
                        value: cardapio?.nome ?? 'Não selecionado',
                        subValue:
                            cardapio != null ? 'ID: ${cardapio!.grid}' : null,
                      ),
                      const Divider(color: Colors.grey, height: 24),

                      // Licença
                      _buildConfigItem(
                        icon: licenca?.valida == true
                            ? Icons.verified
                            : Icons.warning,
                        iconColor: licenca?.valida == true
                            ? Colors.green
                            : Colors.orange,
                        label: 'Licença',
                        value: licenca?.valida == true
                            ? 'Válida'
                            : 'Modo Demonstração',
                        subValue: licenca?.expiracao != null
                            ? 'Expira em: ${_formatDate(licenca!.expiracao!)}'
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Aviso sobre reconfiguração
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue.shade300),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Para alterar essas configurações posteriormente, será necessário fazer login com usuário e senha de administrador.',
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
                onPressed: isLoading ? null : onVoltar,
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
              // Botão Finalizar
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () {
                          print(
                              'DEBUG: Botão Finalizar pressionado no StepConclusao.');
                          onFinalizar(); // Chama o callback passado pelo pai
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(
                    isLoading ? 'Salvando...' : 'Finalizar Configuração',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfigItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    String? subValue,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subValue != null) ...[
                const SizedBox(height: 2),
                Text(
                  subValue,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        Icon(
          Icons.check_circle,
          color: Colors.green.shade400,
          size: 20,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

// lib/telas/configuracao/steps/step_licenca.dart
// Step 4: Verificação de Licença (VERSÃO FINAL CORRIGIDA)

import 'package:flutter/material.dart';
import '../../../modelos/config_models.dart';
import '../../../servicos/config_api_service.dart';
// =======================================================================
// 1. IMPORTAR O NOVO SERVIÇO DE ID DO DISPOSITIVO
// =======================================================================
import '../../../servicos/device_id_service.dart';

class StepLicenca extends StatefulWidget {
  final EmpresaConfig? empresa;
  final ConfigApiService apiService;
  final Function(LicencaInfo licenca) onLicencaVerificada;
  final VoidCallback onVoltar;

  const StepLicenca({
    super.key,
    required this.empresa,
    required this.apiService,
    required this.onLicencaVerificada,
    required this.onVoltar,
  });

  @override
  State<StepLicenca> createState() => _StepLicencaState();
}

class _StepLicencaState extends State<StepLicenca> {
  final _chaveController = TextEditingController();

  bool _isVerificando = false;
  bool _isAtivando = false;
  LicencaInfo? _licencaInfo;
  bool _mostrarCampoChave = false;

  @override
  void initState() {
    super.initState();
    // Verifica automaticamente ao entrar na tela
    _verificarLicenca();
  }

  @override
  void dispose() {
    _chaveController.dispose();
    super.dispose();
  }

  // O método _getDeviceId() foi removido, pois agora usaremos o DeviceIdService.

  Future<void> _verificarLicenca() async {
    if (widget.empresa == null) return;

    setState(() => _isVerificando = true);

    try {
      // =======================================================================
      // 2. USAR O DeviceIdService PARA OBTER O ID
      // =======================================================================
      final deviceId = await DeviceIdService.getDeviceId();

      final licenca = await widget.apiService.verificarLicenca(
        empresaId: widget.empresa!.grid,
        cnpj: widget.empresa!.cnpj ?? '',
        deviceId: deviceId,
      );

      if (mounted) {
        setState(() {
          _licencaInfo = licenca;
          _isVerificando = false;
          if (!licenca.valida && licenca.chave == null) {
            _mostrarCampoChave = true;
          }
        });

        if (licenca.valida) {
          widget.onLicencaVerificada(licenca);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerificando = false;
          _mostrarCampoChave = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao verificar: $e')),
        );
      }
    }
  }

  Future<void> _ativarLicenca() async {
    final chave = _chaveController.text.trim();
    if (chave.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite a chave de ativação')),
      );
      return;
    }

    setState(() => _isAtivando = true);

    try {
      // =======================================================================
      // 3. USAR O DeviceIdService AQUI TAMBÉM
      // =======================================================================
      final deviceId = await DeviceIdService.getDeviceId();

      final licenca = await widget.apiService.ativarLicenca(
        chaveAtivacao: chave,
        empresaId: widget.empresa!.grid,
        cnpj: widget.empresa!.cnpj ?? '',
        razaoSocial: widget.empresa!.nome,
        deviceId: deviceId,
      );

      if (mounted) {
        setState(() {
          _licencaInfo = licenca;
          _isAtivando = false;
        });

        if (licenca.valida) {
          widget.onLicencaVerificada(licenca);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Licença ativada com sucesso!'),
                backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(licenca.mensagem ?? 'Falha na ativação'),
                backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAtivando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isVerificando) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Verificando licença...',
                style: TextStyle(color: Colors.white)),
          ],
        ),
      );
    }

    if (_licencaInfo != null) {
      if (_licencaInfo!.valida) {
        return _buildLicencaValida();
      } else if (!_mostrarCampoChave) {
        return _buildLicencaInvalida();
      }
    }

    return _buildFormAtivacao();
  }

  Widget _buildLicencaValida() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: const Color(0xFF2d2d44),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 64, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              'Licença Ativa',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildInfoRow('Plano', _licencaInfo?.plano?.toUpperCase() ?? 'N/A',
                Icons.star),
            _buildInfoRow('Expira em', _formatDate(_licencaInfo?.expiracao),
                Icons.calendar_today),
            _buildInfoRow('Terminais',
                'Max: ${_licencaInfo?.maxTerminais ?? 1}', Icons.devices),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Notifica o pai para avançar, mesmo que já tenha avançado automaticamente
                  widget.onLicencaVerificada(_licencaInfo!);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Avançar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLicencaInvalida() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: const Color(0xFF2d2d44),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Licença Inválida ou Bloqueada',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _licencaInfo?.mensagem ?? 'Entre em contato com o suporte.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade300),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() => _mostrarCampoChave = true);
              },
              child: const Text('Tentar outra Chave de Ativação'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: widget.onVoltar,
              child: const Text('Voltar', style: TextStyle(color: Colors.grey)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFormAtivacao() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ativação do Terminal',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Este terminal não possui uma licença ativa vinculada.',
            style: TextStyle(color: Colors.grey.shade400),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _chaveController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Chave de Ativação',
              hintText: 'XXXX-XXXX-XXXX-XXXX',
              prefixIcon: const Icon(Icons.vpn_key, color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF2d2d44),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade700),
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_isAtivando)
            const Center(child: CircularProgressIndicator())
          else
            ElevatedButton.icon(
              onPressed: _ativarLicenca,
              icon: const Icon(Icons.check),
              label: const Text('Ativar Licença'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info, color: Colors.blue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Entre em contato com o suporte para adquirir uma licença ou use a chave de ativação fornecida.',
                    style: TextStyle(
                      color: Colors.blue.shade300,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: widget.onVoltar,
            child: const Text("Voltar", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.green.shade300, size: 20),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey.shade400),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

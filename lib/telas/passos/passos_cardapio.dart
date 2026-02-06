// lib/telas/configuracao/steps/step_cardapio.dart
// Step 3: Seleção do Cardápio

import 'package:flutter/material.dart';
import '../../../modelos/config_models.dart';
import '../../../servicos/config_api_service.dart';

class StepCardapio extends StatefulWidget {
  final String serverIp;
  final int serverPort;
  final int empresaId;
  final ConfigApiService apiService;
  final Function(CardapioConfig cardapio) onCardapioSelecionado;
  final VoidCallback onVoltar;

  const StepCardapio({
    super.key,
    required this.serverIp,
    required this.serverPort,
    required this.empresaId,
    required this.apiService,
    required this.onCardapioSelecionado,
    required this.onVoltar,
  });

  @override
  State<StepCardapio> createState() => _StepCardapioState();
}

class _StepCardapioState extends State<StepCardapio> {
  List<CardapioConfig> _cardapios = [];
  CardapioConfig? _cardapioSelecionado;
  bool _isLoading = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarCardapios();
  }

  Future<void> _carregarCardapios() async {
    setState(() {
      _isLoading = true;
      _erro = null;
    });

    try {
      final cardapios = await widget.apiService.buscarCardapios(
        widget.serverIp,
        widget.serverPort,
        widget.empresaId,
      );

      setState(() {
        _cardapios = cardapios;
        _isLoading = false;
        // Se só tiver um cardápio, seleciona automaticamente
        if (cardapios.length == 1) {
          _cardapioSelecionado = cardapios.first;
        }
      });
    } catch (e) {
      setState(() {
        _erro = 'Erro ao carregar cardápios: $e';
        _isLoading = false;
      });
    }
  }

  void _continuar() {
    if (_cardapioSelecionado != null) {
      widget.onCardapioSelecionado(_cardapioSelecionado!);
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
                  Icons.restaurant_menu,
                  size: 64,
                  color: Colors.blue,
                ),
                const SizedBox(height: 24),

                // Descrição
                Text(
                  'Selecione o cardápio que será exibido no terminal',
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
                          'Carregando cardápios...',
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
                          onPressed: _carregarCardapios,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar Novamente'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Lista de cardápios
                if (!_isLoading && _erro == null) ...[
                  if (_cardapios.isEmpty)
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
                            'Nenhum cardápio encontrado para esta empresa.\n\nCadastre um cardápio no sistema antes de continuar.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.orange),
                          ),
                        ],
                      ),
                    )
                  else
                    ...List.generate(_cardapios.length, (index) {
                      final cardapio = _cardapios[index];
                      final isSelected =
                          _cardapioSelecionado?.grid == cardapio.grid;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            setState(() => _cardapioSelecionado = cardapio);
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
                                // Ícone do cardápio
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.menu_book,
                                    color: Colors.green,
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
                                        cardapio.nome,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (cardapio.descricao != null &&
                                          cardapio.descricao!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          cardapio.descricao!,
                                          style: TextStyle(
                                            color: Colors.grey.shade400,
                                            fontSize: 13,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            'ID: ${cardapio.grid}',
                                            style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: cardapio.ativo
                                                  ? Colors.green
                                                      .withOpacity(0.2)
                                                  : Colors.red.withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              cardapio.ativo
                                                  ? 'Ativo'
                                                  : 'Inativo',
                                              style: TextStyle(
                                                color: cardapio.ativo
                                                    ? Colors.green
                                                    : Colors.red,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ],
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
                  onPressed: _cardapioSelecionado != null ? _continuar : null,
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

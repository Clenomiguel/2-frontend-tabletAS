import 'package:flutter/material.dart';

// Imports do projeto
import '../../utilitarios/cores_app.dart'; // Paleta de cores centralizada

/// Widget reutilizável para exibir feedback de carregamento.
/// Centraliza um spinner (CircularProgressIndicator) e uma mensagem.
class EstadoCarregamento extends StatelessWidget {
  // Mensagem a ser exibida abaixo do spinner (ex: "Carregando produtos...", "Enviando pedido...")
  final String mensagem;

  const EstadoCarregamento({
    super.key,
    this.mensagem = 'Carregando...', // Valor padrão genérico
  });

  @override
  Widget build(BuildContext context) {
    // Center garante que o conteúdo fique no meio da área disponível (tela inteira ou container)
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center, // Centraliza verticalmente na coluna
        children: [
          // 1. O Spinner (Indicador de progresso circular)
          const CircularProgressIndicator(
            color: AppColors.accentRed, // Usa a cor de destaque do app
            strokeWidth:
                4, // Espessura da linha (opcional, ajustado para melhor visibilidade)
          ),

          const SizedBox(height: 16), // Espaçamento entre ícone e texto

          // 2. A Mensagem de texto
          Text(
            mensagem,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textWhite,
              fontSize: 16, // Tamanho legível para totens
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

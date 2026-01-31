import 'package:flutter/material.dart';

// Imports do projeto
import '../../utilitarios/cores_app.dart'; // Paleta de cores centralizada

/// Widget reutilizável para exibir telas de erro amigáveis.
/// Contém: Ícone de alerta, mensagem explicativa e botão "Tentar Novamente".
class EstadoErro extends StatelessWidget {
  // A mensagem técnica ou amigável do erro (ex: "Falha na conexão")
  final String mensagem;

  // Ação a ser executada no botão (ex: recarregar a API)
  final VoidCallback onTentarNovamente;

  const EstadoErro({
    super.key,
    required this.mensagem,
    required this.onTentarNovamente,
  });

  @override
  Widget build(BuildContext context) {
    // Center centraliza o conteúdo na tela inteira
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center, // Alinha verticalmente ao centro
        children: [
          // 1. Ícone de Alerta Grande
          const Icon(
            Icons.error_outline,
            size: 64, // Tamanho grande para chamar atenção
            color: AppColors.accentRed, // Vermelho de erro/destaque
          ),

          const SizedBox(height: 16), // Espaçamento

          // 2. Título Genérico
          const Text(
            'Ops! Ocorreu um erro.',
            style: TextStyle(
              color: AppColors.textWhite,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          // 3. Mensagem Específica do Erro
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 32), // Margem lateral para não colar na borda
            child: Text(
              mensagem,
              textAlign:
                  TextAlign.center, // Centraliza texto de múltiplas linhas
              style: const TextStyle(
                color: AppColors.textGrey, // Cor mais suave para o detalhe
                fontSize: 14,
              ),
            ),
          ),

          const SizedBox(height: 24), // Espaço maior antes do botão

          // 4. Botão de Ação (Retry)
          ElevatedButton.icon(
            onPressed: onTentarNovamente,
            icon: const Icon(Icons.refresh), // Ícone de recarregar
            label: const Text('Tentar novamente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRed, // Fundo vermelho
              foregroundColor: AppColors.textWhite, // Texto/Ícone branco
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12), // Área de toque maior
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(8), // Bordas levemente arredondadas
              ),
            ),
          ),
        ],
      ),
    );
  }
}

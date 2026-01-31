import 'package:flutter/material.dart';

/// Classe utilitária para centralizar a paleta de cores do aplicativo.
///
/// Manter as cores aqui facilita:
/// 1. Alterar o tema do app inteiro mudando apenas este arquivo.
/// 2. Manter a consistência visual entre diferentes telas.
class AppColors {
  // Construtor privado para impedir instanciar a classe (ex: AppColors() -> Erro)
  AppColors._();

  // ===========================================================================
  // 1. FUNDOS (BACKGROUNDS)
  // ===========================================================================

  /// Cor de fundo principal da aplicação (Dark Mode).
  /// Usada no `Scaffold`, telas principais e fundo geral.
  static const bgDark = Color(0xFF1A1A1A);

  /// Cor de fundo secundária.
  /// Usada na Barra Lateral (Sidebar), Barra Superior (TopBar) e inputs.
  /// É levemente mais clara que o bgDark para criar profundidade.
  static const bgSidebar = Color(0xFF2D2D2D);

  // ===========================================================================
  // 2. DESTAQUES E BRANDING (ACCENTS)
  // ===========================================================================

  /// Cor primária de destaque (Vermelho).
  /// Usada em:
  /// - Botões de ação (CTA)
  /// - Itens selecionados na sidebar
  /// - Badges de notificação/preço
  /// - Ícones ativos
  static const accentRed = Color(0xFFE53935);

  // ===========================================================================
  // 3. TIPOGRAFIA (TEXTOS)
  // ===========================================================================

  /// Cor principal do texto.
  /// Usada para títulos, preços e informações importantes.
  /// Garante alto contraste sobre os fundos escuros.
  static const textWhite = Colors.white;

  /// Cor secundária do texto.
  /// Usada para:
  /// - Subtítulos e descrições
  /// - Textos de placeholder (dicas em inputs)
  /// - Ícones inativos
  static const textGrey = Color(0xFF9E9E9E);

  // ===========================================================================
  // 4. ELEMENTOS DE UI E COMPONENTES
  // ===========================================================================

  /// Cor para linhas divisórias e bordas sutis.
  /// Usada no `Divider` da sidebar ou separadores de lista.
  static const divider = Color(0xFF404040);

  /// Cor de fundo específica para os Cards de Produto.
  /// Nota: É um tom marrom-avermelhado escuro (RGB: 80, 67, 67 / Hex: #504343).
  /// Usada para destacar o produto do fundo preto da tela.
  static const cardBg = Color.fromARGB(255, 80, 67, 67);

  /// Cor de fundo para estados de carregamento (Shimmer/Loading) ou erro.
  /// Usada quando a imagem do produto ainda não carregou ou falhou.
  static const placeholderBg = Color(0xFF3D3D3D);
}

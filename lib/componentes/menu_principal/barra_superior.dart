// lib/componentes/menu_principal/barra_superior.dart

import 'package:flutter/material.dart';

/// Barra superior do menu (TopBar).
/// Contém o botão de menu, indicador de mesa, barra de pesquisa e botões de ação rápida.
class MenuTopBar extends StatelessWidget {
  // --- Dados ---
  final int? mesa; // Número da mesa (pode ser nulo)
  final TextEditingController searchController; // Controlador do campo de texto
  final String searchQuery; // Texto atual da busca (para controlar o ícone 'X')

  // --- Callbacks (Ações) ---
  final VoidCallback onOpenCarousel; // Abrir descanso de tela
  final ValueChanged<String> onSearch; // Ao digitar na busca
  final VoidCallback onClearSearch; // Ao clicar no 'X'
  final VoidCallback onChamarGarcom; // Botão Chamar Garçom
  final VoidCallback onOpenMinhaConta; // Botão Minha Conta
  final VoidCallback onOpenCart; // Botão Carrinho

  const MenuTopBar({
    super.key,
    required this.mesa,
    required this.searchController,
    required this.searchQuery,
    required this.onOpenCarousel,
    required this.onSearch,
    required this.onClearSearch,
    required this.onChamarGarcom,
    required this.onOpenMinhaConta,
    required this.onOpenCart,
  });

  // --- Cores Locais (Hardcoded conforme solicitado) ---
  static const _bgDark = Color(0xFF1A1A1A);
  static const _bgSidebar = Color(0xFF2D2D2D);
  static const _accentRed = Color(0xFFE53935);
  static const _textWhite = Colors.white;
  static const _textGrey = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70, // Altura fixa da barra
      color: _bgDark,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 1. Botão Menu/Carrossel (Quadrado Vermelho)
          GestureDetector(
            onTap: onOpenCarousel,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _accentRed,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.restaurant_menu,
                color: _textWhite,
                size: 28,
              ),
            ),
          ),

          const SizedBox(width: 20),

          // 2. Indicador de Mesa (Exibido apenas se mesa != null)
          if (mesa != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _bgSidebar,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.table_bar, color: _textGrey, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'MESA $mesa',
                    style: const TextStyle(
                      color: _textWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(width: 20),

          // 3. Barra de Pesquisa (Expanded para ocupar o espaço central)
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _bgSidebar,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  // Ícone de Lupa
                  const Icon(Icons.search, color: _textGrey, size: 20),
                  const SizedBox(width: 12),

                  // Campo de Texto
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      onChanged: onSearch,
                      style: const TextStyle(color: _textWhite, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Buscar produtos...',
                        hintStyle: TextStyle(color: _textGrey, fontSize: 14),
                        border:
                            InputBorder.none, // Remove linha inferior padrão
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),

                  // Botão de Limpar (X) - Só aparece se houver texto
                  if (searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: onClearSearch,
                      child:
                          const Icon(Icons.close, color: _textGrey, size: 20),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 20),

          // 4. Botões de Ação Rápida (Direita)
          _buildActionButton(
            Icons.room_service_outlined,
            'CHAMAR\nGARÇOM',
            onChamarGarcom,
          ),
          const SizedBox(width: 12),
          _buildActionButton(
            Icons.receipt_long_outlined,
            'MINHA\nCONTA',
            onOpenMinhaConta,
          ),
          const SizedBox(width: 12),
          _buildActionButton(
            Icons.shopping_cart_outlined,
            'CARRINHO',
            onOpenCart,
          ),
        ],
      ),
    );
  }

  /// Helper para criar os botões de ação vermelhos (Garçom, Conta, Carrinho)
  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _accentRed,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: _textWhite, size: 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: _textWhite,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                height: 1.2, // Ajusta altura da linha para texto com \n
              ),
            ),
          ],
        ),
      ),
    );
  }
}

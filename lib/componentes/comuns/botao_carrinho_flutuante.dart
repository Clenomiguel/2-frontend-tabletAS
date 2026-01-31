import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Imports do projeto
import '../../services/cart_provider.dart'; // Gerenciador de estado do carrinho
import '../../utilitarios/cores_app.dart'; // Paleta de cores

/// Botão flutuante que exibe o resumo do carrinho (Total + Preço).
/// Aparece no canto inferior direito da tela quando há itens no pedido.
class FloatingCartButton extends StatelessWidget {
  // Ação ao clicar no botão (geralmente abre a tela de Carrinho)
  final VoidCallback onTap;

  const FloatingCartButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Consumer escuta mudanças no CartProvider e reconstrói este widget
    // sempre que o carrinho é atualizado (adicionar/remover item).
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        // Regra de Negócio: Se o carrinho estiver vazio, o botão fica invisível.
        if (cart.quantidadeTotal == 0) return const SizedBox.shrink();

        // Posiciona o botão no canto da tela (dentro do Stack pai)
        return Positioned(
          bottom: 20,
          right: 20,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              // Decoração do botão (Pílula vermelha com sombra)
              decoration: BoxDecoration(
                color: AppColors.accentRed,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- ÍCONE DO CARRINHO COM BADGE ---
                  Stack(
                    clipBehavior: Clip.none, // Permite que o badge saia da área
                    children: [
                      const Icon(
                        Icons.shopping_cart,
                        color: AppColors.textWhite,
                        size: 28,
                      ),
                      // Bolinha branca com número de itens
                      Positioned(
                        top: -8,
                        right: -8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${cart.quantidadeTotal}',
                            style: const TextStyle(
                              color: AppColors.accentRed,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 12),

                  // --- INFORMAÇÕES DE TEXTO E PREÇO ---
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'VER CARRINHO',
                        style: TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        // Formatação de moeda: R$ 00,00
                        'R\$ ${cart.total.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: const TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 12),

                  // --- SETA INDICATIVA ---
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.textWhite,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

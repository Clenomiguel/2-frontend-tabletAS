import 'package:flutter/material.dart';

// Imports do projeto
import '../../modelos/cardapio_models.dart'; // Modelo de dados do produto
import '../../utilitarios/cores_app.dart'; // Paleta de cores
import './produtos_imagens.dart'; // Componente de imagem (ProdutoImage)

/// Widget que representa o Card de um Produto individual na grade.
/// Exibe a imagem, preço (badge), nome e breve descrição.
class ProdutoCard extends StatelessWidget {
  // Objeto contendo os dados do produto (Nome, Preço, ID, etc)
  final CardapioProduto produto;

  // Função executada ao clicar no card (geralmente abre detalhes)
  final VoidCallback onTap;

  const ProdutoCard({
    super.key,
    required this.produto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // GestureDetector captura o toque em toda a área do card
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // Decoração do Card (Fundo, Bordas arredondadas e Sombra)
        decoration: BoxDecoration(
          color: AppColors.cardBg, // Cor de fundo do card
          borderRadius: BorderRadius.circular(16), // Arredondamento geral
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3), // Sombra suave
              blurRadius: 8,
              offset: const Offset(0, 4), // Deslocamento vertical da sombra
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- PARTE SUPERIOR: IMAGEM E PREÇO ---
            // Expanded com flex 1 garante que a imagem ocupe metade da altura do card
            Expanded(
              flex: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. A Imagem do Produto
                  ClipRRect(
                    // Arredonda apenas as pontas de cima para casar com o container
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    // Componente modular que carrega a imagem (Base64 ou API)
                    child: ProdutoImage(
                      produtoId: produto.produtoId,
                      imagemBase64: produto.produto.imagemBase64,
                    ),
                  ),

                  // 2. O Badge de Preço (Sobreposto no canto superior direito)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentRed, // Destaque em vermelho
                        borderRadius:
                            BorderRadius.circular(20), // Formato pílula
                      ),
                      child: Text(
                        // Formatação do preço: R$ 00,00
                        'R\$ ${produto.preco.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: const TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- PARTE INFERIOR: INFORMAÇÕES DE TEXTO ---
            // Ocupa a outra metade inferior do card
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start, // Alinha à esquerda
                  mainAxisAlignment: MainAxisAlignment.start, // Alinha ao topo
                  children: [
                    // Nome do Produto
                    Text(
                      produto.produto.nome,
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2, // Limita a 2 linhas
                      overflow:
                          TextOverflow.ellipsis, // Adiciona "..." se passar
                    ),

                    // Descrição do Produto (Renderiza apenas se existir)
                    if (produto.produto.descricao != null &&
                        produto.produto.descricao!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        produto.produto.descricao!,
                        style: const TextStyle(
                          color: AppColors.textGrey, // Cor mais apagada
                          fontSize: 11,
                        ),
                        maxLines:
                            1, // Apenas 1 linha para manter o layout limpo
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

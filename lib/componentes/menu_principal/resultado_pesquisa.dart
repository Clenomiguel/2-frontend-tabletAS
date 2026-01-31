import 'package:flutter/material.dart';

// Imports do projeto
import '../../models/cardapio_models.dart';
import '../../utilitarios/cores_app.dart'; // Uso das cores centralizadas

/// Widget responsável por exibir a interface de resultados da busca.
/// Mostra um cabeçalho com contador e um grid de produtos filtrados.
class SearchResultsWidget extends StatelessWidget {
  // Termo pesquisado (para exibir no título)
  final String searchQuery;

  // Lista de produtos filtrados
  final List<CardapioProduto> results;

  // Ação para limpar a busca (fechar resultados)
  final VoidCallback onClear;

  // Ação ao clicar em um produto (necessário se o productBuilder não tratar)
  final void Function(CardapioProduto) onProductTap;

  // Construtor do card do produto (Injeção de dependência de UI)
  // Isso permite reutilizar o mesmo design do card da tela principal
  final Widget Function(CardapioProduto) productBuilder;

  const SearchResultsWidget({
    super.key,
    required this.searchQuery,
    required this.results,
    required this.onClear,
    required this.onProductTap,
    required this.productBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho com título, contador e botão limpar
        _buildHeader(),

        // Área de conteúdo (Lista ou Mensagem de Vazio)
        Expanded(child: _buildContent()),
      ],
    );
  }

  /// Constrói a barra de topo dos resultados
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Ícone de Lupa
          const Icon(Icons.search, color: AppColors.accentRed, size: 28),
          const SizedBox(width: 12),

          // Texto "Resultados para..."
          Text(
            'Resultados para "$searchQuery"',
            style: const TextStyle(
              color: AppColors.textWhite,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),

          // Badge com a quantidade de itens encontrados
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accentRed,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${results.length} ${results.length == 1 ? 'item' : 'itens'}',
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const Spacer(), // Empurra o botão de limpar para a direita

          // Botão "Limpar busca"
          GestureDetector(
            onTap: onClear,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.bgSidebar,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.close, color: AppColors.textGrey, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Limpar busca',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói o conteúdo principal (Grid ou Mensagem de vazio)
  Widget _buildContent() {
    // CASO 1: Nenhum resultado encontrado
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, color: AppColors.textGrey, size: 64),
            const SizedBox(height: 16),
            Text(
              'Nenhum produto encontrado para "$searchQuery"',
              style: const TextStyle(
                color: AppColors.textGrey,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tente buscar por outro termo',
              style: TextStyle(
                color: AppColors.textGrey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // CASO 2: Grid de resultados
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // 4 Colunas
        childAspectRatio: 1.00, // Proporção Quadrada (igual tela principal)
        crossAxisSpacing: 16, // Espaço horizontal
        mainAxisSpacing: 16, // Espaço vertical
      ),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final produto = results[index];

        // Chama o construtor passado pelo pai (ProdutoCard)
        // Nota: Não precisamos de GestureDetector aqui pois o ProdutoCard
        // já implementa o onTap internamente.
        return productBuilder(produto);
      },
    );
  }
}

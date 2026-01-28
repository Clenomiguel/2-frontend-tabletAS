// lib/widgets/secao_header.dart
// Header da seção do cardápio

import 'package:flutter/material.dart';

import '../models/cardapio_models.dart';
import '../services/api_service.dart';

class SecaoHeader extends StatelessWidget {
  final CardapioSecaoCompleta secao;

  const SecaoHeader({
    super.key,
    required this.secao,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE0E0E0)),
        ),
      ),
      child: Row(
        children: [
          // Imagem da seção (se houver)
          if (secao.imagens.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                Api.instance.getSecaoImageUrl(secao.secao.grid, size: 'thumb'),
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B21A8).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.category,
                    color: Color(0xFF6B21A8),
                    size: 28,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],

          // Título e contagem
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  secao.secao.nomeExibicao,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B21A8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${secao.produtos.length} ${secao.produtos.length == 1 ? 'produto' : 'produtos'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

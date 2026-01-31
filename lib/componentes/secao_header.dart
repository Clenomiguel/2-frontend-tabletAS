// lib/widgets/secao_header.dart
// Header da seção do cardápio

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../modelos/cardapio_models.dart';

/// Decodifica base64 de forma segura, limpando caracteres inválidos
Uint8List? _safeBase64Decode(String base64String) {
  try {
    // Remove espaços, quebras de linha e caracteres inválidos
    String clean = base64String.replaceAll(RegExp(r'\s'), '');

    // Adiciona padding se necessário
    final padding = clean.length % 4;
    if (padding > 0) {
      clean += '=' * (4 - padding);
    }

    return base64Decode(clean);
  } catch (e) {
    return null;
  }
}

class SecaoHeader extends StatelessWidget {
  final CardapioSecaoCompleta secao;

  const SecaoHeader({
    super.key,
    required this.secao,
  });

  @override
  Widget build(BuildContext context) {
    final imageBytes = secao.imagens.isNotEmpty
        ? _safeBase64Decode(secao.imagens.first)
        : null;

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
          if (imageBytes != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                imageBytes,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholder(60),
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

  Widget _buildPlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF6B21A8).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.category,
        color: Color(0xFF6B21A8),
        size: 28,
      ),
    );
  }
}

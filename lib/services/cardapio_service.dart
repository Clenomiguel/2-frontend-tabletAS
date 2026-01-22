// lib/services/cardapio_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/cardapio_models.dart';

class CardapioService {
  // Ajuste o IP conforme sua rede
  static const String baseUrl = 'http://192.168.3.150:8000/api/v1';
  static const Duration timeout = Duration(seconds: 30);

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
  };

  /// Busca a árvore completa do cardápio (Seções -> Imagens -> Produtos)
  /// Usa o endpoint /completo otimizado para mobile
  static Future<CardapioCompletoResponse?> obterCardapioDigitalCompleto(
    int cardapioId,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/cardapios/$cardapioId/completo');

      if (kDebugMode) {
        debugPrint('📡 Buscando cardápio completo: $uri');
      }

      final response = await http.get(uri, headers: _headers).timeout(timeout);

      if (response.statusCode == 200) {
        // Importante: Decodificar UTF-8 manualmente para caracteres especiais
        final bodyBytes = response.bodyBytes;
        final bodyString = utf8.decode(bodyBytes);
        final data = json.decode(bodyString);

        return CardapioCompletoResponse.fromJson(data);
      } else {
        debugPrint('❌ Erro API: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Erro de conexão: $e');
      return null;
    }
  }

  // Método auxiliar para verificar se o servidor está online
  static Future<bool> checkHealth() async {
    try {
      final uri = Uri.parse('$baseUrl/health'); // Rota que criamos antes
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

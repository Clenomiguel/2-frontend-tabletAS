import 'dart:convert'; // Para base64Decode
import 'dart:typed_data'; // Para Uint8List

/// Classe utilitária para manipulação e tratamento de Strings.
class StringUtils {
  // Construtor privado para evitar instância desnecessária (ex: StringUtils())
  StringUtils._();

  // Expressão regular compilada uma única vez para performance.
  // Encontra qualquer espaço em branco (espaços, tabs, quebras de linha \n).
  static final RegExp _whitespaceRegExp = RegExp(r'\s');

  /// Decodifica uma string Base64 para bytes (Uint8List) de forma segura.
  ///
  /// Problemas que este método resolve:
  /// 1. Remove quebras de linha ou espaços que vêm sujos da API.
  /// 2. Corrige a falta de caracteres de preenchimento ('=').
  /// 3. Retorna null em vez de travar o app se a string for inválida.
  static Uint8List? safeBase64Decode(String base64String) {
    // Se a string vier vazia, retorna nulo imediatamente
    if (base64String.isEmpty) return null;

    try {
      // 1. Limpeza: Remove todos os espaços em branco e quebras de linha
      // Muitas APIs enviam o Base64 formatado com "enters" a cada 76 caracteres.
      String clean = base64String.replaceAll(_whitespaceRegExp, '');

      // 2. Correção de Padding (Preenchimento):
      // Uma string Base64 válida deve ter um comprimento múltiplo de 4.
      // Se não tiver, precisamos adicionar sinais de igual ('=') ao final.
      final remainder = clean.length % 4;

      if (remainder > 0) {
        // Exemplo: Se sobrar 1, faltam 3 (4 - 1 = 3). Adiciona '==='.
        // Exemplo: Se sobrar 3, falta 1 (4 - 3 = 1). Adiciona '='.
        clean += '=' * (4 - remainder);
      }

      // 3. Decodificação
      return base64Decode(clean);
    } catch (_) {
      // Se a string estiver corrompida ou não for um Base64 válido,
      // retornamos null para que a UI mostre o ícone de placeholder/erro
      // em vez de quebrar a tela vermelha (crash).
      return null;
    }
  }
}

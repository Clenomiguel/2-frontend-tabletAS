// lib/utils/parsing_utils.dart
// UTILITÁRIOS PARA PARSING SEGURO DE DADOS DA API

import 'package:flutter/foundation.dart';

class ParsingUtils {
  /// Converte qualquer valor para double de forma segura
  static double? parseDouble(dynamic value, {double? defaultValue}) {
    if (value == null) return defaultValue;

    try {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value.trim());
        return parsed ?? defaultValue;
      }
      if (value is num) return value.toDouble();
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '⚠️ Erro ao converter para double: $value (${value.runtimeType}) - $e',
        );
      }
    }

    return defaultValue;
  }

  /// Converte qualquer valor para int de forma segura
  static int? parseInt(dynamic value, {int? defaultValue}) {
    if (value == null) return defaultValue;

    try {
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        return parsed ?? defaultValue;
      }
      if (value is num) return value.toInt();
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '⚠️ Erro ao converter para int: $value (${value.runtimeType}) - $e',
        );
      }
    }

    return defaultValue;
  }

  /// Converte qualquer valor para bool de forma segura
  static bool? parseBool(dynamic value, {bool? defaultValue}) {
    if (value == null) return defaultValue;

    try {
      if (value is bool) return value;
      if (value is int) return value != 0;
      if (value is double) return value != 0.0;
      if (value is String) {
        final lowerValue = value.trim().toLowerCase();
        if (lowerValue == 'true' || lowerValue == '1') return true;
        if (lowerValue == 'false' || lowerValue == '0') return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '⚠️ Erro ao converter para bool: $value (${value.runtimeType}) - $e',
        );
      }
    }

    return defaultValue;
  }

  /// Converte qualquer valor para String de forma segura
  static String? parseString(dynamic value, {String? defaultValue}) {
    if (value == null) return defaultValue;

    try {
      if (value is String) return value.isEmpty ? defaultValue : value;
      return value.toString();
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '⚠️ Erro ao converter para String: $value (${value.runtimeType}) - $e',
        );
      }
    }

    return defaultValue;
  }

  /// Log de debug para valores problemáticos
  static void debugValue(String campo, dynamic value) {
    if (kDebugMode) {
      debugPrint('🔍 Debug $campo: $value (${value.runtimeType})');
    }
  }

  /// Valida se um JSON tem as chaves esperadas
  static bool validateJsonKeys(
    Map<String, dynamic> json,
    List<String> requiredKeys,
  ) {
    final missingKeys =
        requiredKeys.where((key) => !json.containsKey(key)).toList();

    if (missingKeys.isNotEmpty && kDebugMode) {
      debugPrint('⚠️ Chaves faltantes no JSON: $missingKeys');
      debugPrint('🔍 Chaves disponíveis: ${json.keys.toList()}');
    }

    return missingKeys.isEmpty;
  }

  /// Extrai valor aninhado de JSON de forma segura
  static dynamic safeGet(
    Map<String, dynamic> json,
    String path, {
    dynamic defaultValue,
  }) {
    try {
      final keys = path.split('.');
      dynamic current = json;

      for (final key in keys) {
        if (current is Map<String, dynamic> && current.containsKey(key)) {
          current = current[key];
        } else {
          return defaultValue;
        }
      }

      return current;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Erro ao extrair $path do JSON: $e');
      }
      return defaultValue;
    }
  }

  /// Converte lista de forma segura
  static List<T> parseList<T>(
    dynamic value,
    T Function(dynamic) parser, {
    List<T>? defaultValue,
  }) {
    if (value == null) return defaultValue ?? [];

    try {
      if (value is List) {
        return value
            .map((item) {
              try {
                return parser(item);
              } catch (e) {
                if (kDebugMode) {
                  debugPrint('⚠️ Erro ao converter item da lista: $item - $e');
                }
                return null;
              }
            })
            .where((item) => item != null)
            .cast<T>()
            .toList();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '⚠️ Erro ao converter lista: $value (${value.runtimeType}) - $e',
        );
      }
    }

    return defaultValue ?? [];
  }
}

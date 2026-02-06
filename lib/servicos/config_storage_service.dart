// lib/servicos/config_storage_service.dart
// Serviço para armazenar configurações localmente (Shared Preferences)

import 'dart:convert';
import 'package:flutter/foundation.dart'; // Para debugPrint
import 'package:shared_preferences/shared_preferences.dart';
import '../modelos/config_models.dart';

class ConfigStorageService {
  static const String _configKey = 'app_config';
  static const String _primeiroAcessoKey = 'primeiro_acesso';

  // ===========================================================================
  // MÉTODOS PRINCIPAIS (Leitura e Escrita)
  // ===========================================================================

  /// Recupera a configuração salva no disco.
  /// Retorna AppConfig.empty() se não houver nada salvo (evita null).
  static Future<AppConfig> getConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_configKey);

      if (jsonString == null || jsonString.isEmpty) {
        return AppConfig.empty();
      }

      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return AppConfig.fromJson(jsonMap);
    } catch (e) {
      debugPrint('❌ Erro ao ler configuração: $e');
      return AppConfig.empty();
    }
  }

  /// Salva a configuração completa no disco
  static Future<bool> saveConfig(AppConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(config.toJson());

      final result = await prefs.setString(_configKey, jsonString);
      debugPrint('💾 Configuração salva: IP=${config.serverIp}');

      // Se salvou configuração, marca que não é mais primeiro acesso
      if (result) {
        await setPrimeiroAcesso(false);
      }

      return result;
    } catch (e) {
      debugPrint('❌ Erro ao salvar configuração: $e');
      return false;
    }
  }

  /// Limpa todas as configurações (Reset de fábrica)
  static Future<bool> clearConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_configKey);
      await prefs.setBool(_primeiroAcessoKey, true); // Reseta flag de acesso
      debugPrint('🗑️ Configurações limpas com sucesso');
      return true;
    } catch (e) {
      debugPrint('❌ Erro ao limpar config: $e');
      return false;
    }
  }

  // ===========================================================================
  // CONTROLE DE PRIMEIRO ACESSO
  // ===========================================================================

  static Future<bool> isPrimeiroAcesso() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_primeiroAcessoKey) ?? true;
  }

  static Future<void> setPrimeiroAcesso(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_primeiroAcessoKey, value);
  }

  // ===========================================================================
  // MÉTODOS AUXILIARES DE ATUALIZAÇÃO PARCIAL
  // ===========================================================================

  /// Atualiza apenas os dados do servidor (IP/Porta)
  static Future<bool> atualizarServidor(String ip, int porta) async {
    final config = await getConfig();
    final novaConfig = config.copyWith(
      serverIp: ip,
      serverPort: porta,
    );
    return await saveConfig(novaConfig);
  }

  /// Atualiza apenas a empresa selecionada
  static Future<bool> atualizarEmpresa(
      int empresaId, String? empresaNome, String? cnpj) async {
    final config = await getConfig();
    final novaConfig = config.copyWith(
      empresaId: empresaId,
      empresaNome: empresaNome,
      cnpj: cnpj,
    );
    return await saveConfig(novaConfig);
  }

  /// Atualiza apenas o cardápio
  static Future<bool> atualizarCardapio(
      int? cardapioId, String? cardapioNome) async {
    final config = await getConfig();
    final novaConfig = config.copyWith(
      cardapioId: cardapioId,
      cardapioNome: cardapioNome,
    );
    return await saveConfig(novaConfig);
  }

  /// Atualiza/Salva a licença obtida
  static Future<bool> atualizarLicenca(LicencaInfo licenca) async {
    final config = await getConfig();
    final novaConfig = config.copyWith(
      licenca: licenca,
    );
    return await saveConfig(novaConfig);
  }
}

// lib/servicos/device_id_service.dart
// Serviço para obter um identificador único e persistente para a instalação do app.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceIdService {
  // Chave usada para salvar o ID no armazenamento local.
  static const _deviceIdKey = 'unique_device_id';

  /// Obtém o ID único do dispositivo.
  ///
  /// Na primeira vez que é chamado, gera um novo UUID, salva-o localmente
  /// e o retorna. Nas chamadas subsequentes, apenas lê e retorna o ID já salvo.
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);

    if (deviceId == null || deviceId.isEmpty) {
      // Se não houver ID, gere um novo (UUID v4) e salve-o.
      deviceId = const Uuid().v4();
      await prefs.setString(_deviceIdKey, deviceId);
      debugPrint('✨ Novo Device ID gerado e salvo: $deviceId');
    } else {
      debugPrint('🔑 Device ID recuperado do armazenamento: $deviceId');
    }

    return deviceId;
  }
}

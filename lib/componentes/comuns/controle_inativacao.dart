import 'dart:async';
import 'package:flutter/foundation.dart'; // Necessário para o tipo VoidCallback

/// Controlador responsável por detectar inatividade do usuário.
/// Usado principalmente em totens para resetar a aplicação para a tela
/// de descanso (Carrossel) caso o cliente abandone o pedido no meio.
class InactivityController {
  // Configurações
  final Duration timeout; // Tempo limite (ex: 90 segundos)
  final VoidCallback onTimeout; // Função executada quando o tempo acaba

  // Estado interno
  Timer? _timer;

  InactivityController({
    required this.timeout,
    required this.onTimeout,
  });

  /// Inicia ou Reinicia a contagem do timer.
  /// Deve ser chamado sempre que houver interação na tela (toque).
  void start() {
    _cancelTimer();
    _timer = Timer(timeout, onTimeout);
  }

  /// Alias para [start]. Reinicia a contagem do zero.
  void reset() {
    start();
  }

  /// Para o timer definitivamente.
  /// Deve ser chamado quando o widget for destruído ou quando
  /// o carrossel já estiver visível (para não gastar recursos).
  void stop() {
    _cancelTimer();
  }

  /// Método de limpeza padrão do Flutter (alias para stop)
  void dispose() {
    stop();
  }

  /// Cancela o timer atual se existir e limpa a referência.
  void _cancelTimer() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }
  }

  /// Verifica se o timer está rodando atualmente.
  bool get isRunning => _timer?.isActive ?? false;
}

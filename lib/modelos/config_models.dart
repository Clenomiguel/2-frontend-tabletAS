// lib/modelos/config_models.dart
// Modelos para configuração do aplicativo
// Ajustado para compatibilidade com Main e StorageService

import 'dart:convert';

/// Configuração completa do aplicativo
class AppConfig {
  final String serverIp;
  final int serverPort;
  final int empresaId;
  final String empresaNome;
  final String? cnpj; // Adicionado para manter contexto da licença
  final int cardapioId;
  final String cardapioNome;

  // Alterado: Agrupamos os dados de licença no objeto LicencaInfo
  // para facilitar a validação no main.dart
  final LicencaInfo? licenca;

  final bool configurado;

  AppConfig({
    required this.serverIp,
    required this.serverPort,
    required this.empresaId,
    required this.empresaNome,
    this.cnpj,
    required this.cardapioId,
    required this.cardapioNome,
    this.licenca,
    this.configurado = false,
  });

  String get baseUrl => 'http://$serverIp:$serverPort';

  /// Getter necessário para o main.dart saber se inicia o Wizard
  bool get isConfigured => configurado && serverIp.isNotEmpty;

  factory AppConfig.empty() {
    return AppConfig(
      serverIp: '',
      serverPort: 8000,
      empresaId: 0,
      empresaNome: '',
      cnpj: null,
      cardapioId: 0,
      cardapioNome: '',
      configurado: false,
      licenca: null,
    );
  }

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      serverIp: json['server_ip'] ?? '',
      serverPort: json['server_port'] ?? 8000,
      empresaId: json['empresa_id'] ?? 0,
      empresaNome: json['empresa_nome'] ?? '',
      cnpj: json['cnpj'],
      cardapioId: json['cardapio_id'] ?? 0,
      cardapioNome: json['cardapio_nome'] ?? '',
      // Recupera o objeto licença aninhado
      licenca: json['licenca'] != null
          ? LicencaInfo.fromJson(json['licenca'])
          : null,
      configurado: json['configurado'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'server_ip': serverIp,
      'server_port': serverPort,
      'empresa_id': empresaId,
      'empresa_nome': empresaNome,
      'cnpj': cnpj,
      'cardapio_id': cardapioId,
      'cardapio_nome': cardapioNome,
      // Salva o objeto licença completo
      'licenca': licenca?.toJson(),
      'configurado': configurado,
    };
  }

  AppConfig copyWith({
    String? serverIp,
    int? serverPort,
    int? empresaId,
    String? empresaNome,
    String? cnpj,
    int? cardapioId,
    String? cardapioNome,
    LicencaInfo? licenca,
    bool? configurado,
  }) {
    return AppConfig(
      serverIp: serverIp ?? this.serverIp,
      serverPort: serverPort ?? this.serverPort,
      empresaId: empresaId ?? this.empresaId,
      empresaNome: empresaNome ?? this.empresaNome,
      cnpj: cnpj ?? this.cnpj,
      cardapioId: cardapioId ?? this.cardapioId,
      cardapioNome: cardapioNome ?? this.cardapioNome,
      licenca: licenca ?? this.licenca,
      configurado: configurado ?? this.configurado,
    );
  }

  @override
  String toString() {
    return 'AppConfig(server: $baseUrl, empresa: $empresaNome, licenca: ${licenca?.valida}, configurado: $configurado)';
  }
}

/// Empresa disponível para seleção
class EmpresaConfig {
  final int grid;
  final String nome;
  final String? cnpj;
  final String? fantasia;
  final bool ativo;

  EmpresaConfig({
    required this.grid,
    required this.nome,
    this.cnpj,
    this.fantasia,
    this.ativo = true,
  });

  factory EmpresaConfig.fromJson(Map<String, dynamic> json) {
    return EmpresaConfig(
      grid: json['grid'] ?? json['id'] ?? 0,
      nome: json['nome'] ?? json['razao_social'] ?? '',
      cnpj: json['cnpj'],
      fantasia: json['fantasia'] ?? json['nome_fantasia'],
      ativo: json['ativo'] ?? true,
    );
  }

  String get displayName => fantasia?.isNotEmpty == true ? fantasia! : nome;

  @override
  String toString() => 'EmpresaConfig(grid: $grid, nome: $nome)';
}

/// Cardápio disponível para seleção
class CardapioConfig {
  final int
      grid; // Usaremos grid para manter padrão com Empresa, mas mapeia ID também
  final String nome;
  final String? descricao;
  final bool ativo;

  // Getter auxiliar para compatibilidade se algum código chamar .id
  int get id => grid;

  CardapioConfig({
    required this.grid,
    required this.nome,
    this.descricao,
    this.ativo = true,
  });

  factory CardapioConfig.fromJson(Map<String, dynamic> json) {
    return CardapioConfig(
      grid: json['grid'] ?? json['id'] ?? 0,
      nome: json['nome'] ??
          json['descricao'] ??
          '', // API as vezes retorna descricao como nome
      descricao: json['descricao'],
      ativo: json['ativo'] ?? true,
    );
  }

  @override
  String toString() => 'CardapioConfig(id: $grid, nome: $nome)';
}

/// Resposta de verificação de licença
class LicencaInfo {
  final bool valida;
  final String? chave;
  final DateTime? expiracao;
  final String? mensagem;
  final String? plano;
  final int? maxTerminais;

  LicencaInfo({
    required this.valida,
    this.chave,
    this.expiracao,
    this.mensagem,
    this.plano,
    this.maxTerminais,
  });

  factory LicencaInfo.fromJson(Map<String, dynamic> json) {
    return LicencaInfo(
      valida: json['valida'] ?? false,
      chave: json['chave'],
      expiracao: json['expiracao'] != null
          ? DateTime.tryParse(
              json['expiracao']) // tryParse é mais seguro que parse
          : null,
      mensagem: json['mensagem'],
      plano: json['plano'],
      maxTerminais: json['max_terminais'] ?? json['maxTerminais'],
    );
  }

  // Adicionado toJson para permitir salvar no SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'valida': valida,
      'chave': chave,
      'expiracao': expiracao?.toIso8601String(),
      'mensagem': mensagem,
      'plano': plano,
      'max_terminais': maxTerminais,
    };
  }

  factory LicencaInfo.invalida(String mensagem) {
    return LicencaInfo(
      valida: false,
      mensagem: mensagem,
    );
  }
}

/// Credenciais de admin para acessar configurações
class AdminCredentials {
  final String usuario;
  final String senha;

  AdminCredentials({
    required this.usuario,
    required this.senha,
  });

  Map<String, dynamic> toJson() {
    return {
      'usuario': usuario,
      'senha': senha,
    };
  }
}

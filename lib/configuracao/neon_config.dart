// lib/config/neon_config.dart
// ⚠️ CONFIGURAÇÃO DO BANCO NEON - PREENCHA COM SUAS CREDENCIAIS
//
// IMPORTANTE: Este arquivo contém credenciais sensíveis!
// Em produção, considere:
// 1. Usar variáveis de ambiente
// 2. Usar Flutter Secure Storage para armazenar credenciais
// 3. Ofuscar o código com flutter_obfuscate
// 4. Usar um backend intermediário (mais seguro)

class NeonConfig {
  // ============================================================================
  // PREENCHA SUAS CREDENCIAIS AQUI
  // ============================================================================

  /// Host do banco Neon (sem https://)
  /// Exemplo: ep-solitary-moon-acbvevrl-pooler.sa-east-1.aws.neon.tech
  static const String host =
      'ep-solitary-moon-acbvevrl-pooler.sa-east-1.aws.neon.tech';

  /// Porta do banco (geralmente 5432)
  static const int port = 5432;

  /// Nome do banco de dados
  static const String database = 'neondb';

  /// Usuário do banco
  static const String username = 'neondb_owner';

  /// Senha do banco
  /// ⚠️ NUNCA commite este arquivo com a senha real no Git!
  static const String password = 'npg_b3vjPV4FBKil';

  // ============================================================================
  // CONFIGURAÇÕES ADICIONAIS (não altere)
  // ============================================================================

  /// Usar SSL (obrigatório para Neon)
  static const bool useSSL = true;

  /// Timeout de conexão em segundos
  static const int connectionTimeout = 30;

  /// Timeout de query em segundos
  static const int queryTimeout = 30;

  // ============================================================================
  // STRING DE CONEXÃO COMPLETA (para referência)
  // ============================================================================

  /// Gera a string de conexão no formato PostgreSQL
  static String get connectionString {
    return 'postgresql://$username:$password@$host:$port/$database?sslmode=require';
  }
}

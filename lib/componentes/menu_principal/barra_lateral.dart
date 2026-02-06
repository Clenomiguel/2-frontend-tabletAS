import 'dart:typed_data'; // Necessário para manipular bytes da imagem (Uint8List)
import 'package:flutter/material.dart'; // Importa widgets do Flutter

// Imports do projeto
import '../../modelos/cardapio_models.dart'; // Modelo de dados das seções
import '../../utilitarios/cores_app.dart'; // Paleta de cores centralizada
import '../../utilitarios/safebase64.dart'; // Utilitário para decodificar Base64

// Imports das telas de configuração e login
import '../../telas/configuracao/admin_login_screen.dart';
import '../../telas/configuracao/config_wizard_screen.dart';

/// Widget que representa a barra lateral de navegação (Menu de Categorias).
/// Recebe a lista de seções e gerencia qual está selecionada.
class MenuSidebar extends StatelessWidget {
  // Lista completa de seções (com imagens e produtos)
  final List<CardapioSecaoCompleta> secoes;

  // Índice da seção atualmente ativa/selecionada
  final int selectedIndex;

  // Callback (função) executada quando o usuário clica em uma seção
  final ValueChanged<int> onSecaoSelected;

  const MenuSidebar({
    super.key,
    required this.secoes,
    required this.selectedIndex,
    required this.onSecaoSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Container principal da barra lateral
    return Container(
      width: 140, // Largura fixa da sidebar
      color: AppColors.bgSidebar, // Cor de fundo definida nos utilitários
      child: Column(
        children: [
          // Lista de categorias (Expansível para ocupar o espaço disponível)
          Expanded(
            child: ListView.separated(
              itemCount: secoes.length, // Total de categorias
              // Construtor do separador (linha fina entre itens)
              separatorBuilder: (_, __) => const Divider(
                color: AppColors.divider,
                height: 1,
              ),
              // Construtor de cada item da lista
              itemBuilder: (context, index) {
                final secao = secoes[index];
                // Verifica se este item é o selecionado
                final isSelected = index == selectedIndex;

                // Retorna o widget do item (componente privado abaixo)
                return _SidebarItem(
                  // Define ícone baseado no nome (lógica auxiliar)
                  icon: _getSecaoIcon(secao.nome),
                  // Nome da seção em maiúsculo
                  label: secao.nome.toUpperCase(),
                  // Estado de seleção
                  isSelected: isSelected,
                  // Tenta decodificar a imagem se existir, senão nulo
                  imageBytes: secao.imagens.isNotEmpty
                      ? StringUtils.safeBase64Decode(secao.imagens.first)
                      : null,
                  // Ao clicar, chama a função do pai passando o índice
                  onTap: () => onSecaoSelected(index),
                );
              },
            ),
          ),

          // Divisor antes dos links do rodapé
          const Divider(color: AppColors.divider, height: 1),

          // Link estático "SOBRE"
          _buildSidebarLink(
            context,
            label: 'SOBRE',
            onTap: () {
              // Ação para o Sobre
            },
          ),

          // Divisor entre Sobre e Configurações
          const Divider(color: AppColors.divider, height: 1),

          // Link estático "CONFIGURAÇÕES"
          _buildSidebarLink(
            context,
            label: 'CONFIGURAÇÕES',
            icon: Icons.settings,
            onTap: () {
              // Primeiro, abre a tela de Login Administrativo
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminLoginScreen(
                    onCancel: () => Navigator.pop(context),
                    onLoginSuccess: () {
                      // Se o login for bem-sucedido, substitui a tela de login pelo Wizard de Configuração
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ConfigWizardScreen(
                            isReconfiguracao: true,
                            onConfigCompleta: (BuildContext wizardContext) {
                              // <-- CORREÇÃO: Aceita o BuildContext
                              // Fecha o wizard usando o SEU PRÓPRIO CONTEXTO (wizardContext)
                              Navigator.pop(wizardContext);

                              // Mostra a notificação.
                              // Aqui, podemos usar o 'context' da BarraLateral, pois ele ainda existe.
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Configurações atualizadas!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),

          // Espaçamento final
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Constrói um link de texto simples ou com ícone para o rodapé da sidebar
  Widget _buildSidebarLink(BuildContext context,
      {required String label, IconData? icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppColors.textGrey, size: 14),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textGrey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Lógica para escolher o ícone baseado no nome da categoria.
  IconData _getSecaoIcon(String nome) {
    final lower = nome.toLowerCase();

    if (lower.contains('hambur') || lower.contains('lanche')) {
      return Icons.lunch_dining;
    }
    if (lower.contains('pizza')) {
      return Icons.local_pizza;
    }
    if (lower.contains('bebida') || lower.contains('drink')) {
      return Icons.local_bar;
    }
    if (lower.contains('sobremesa') || lower.contains('doce')) {
      return Icons.cake;
    }
    if (lower.contains('cafe') || lower.contains('café')) {
      return Icons.coffee;
    }
    if (lower.contains('salada')) {
      return Icons.eco;
    }
    if (lower.contains('entrada')) {
      return Icons.restaurant;
    }
    if (lower.contains('prato') || lower.contains('principal')) {
      return Icons.dinner_dining;
    }
    // Ícone padrão caso nada corresponda
    return Icons.fastfood;
  }
}

/// Componente visual privado para um item da sidebar.
class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Uint8List? imageBytes; // Imagem em bytes (opcional)
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.imageBytes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // InkWell fornece o efeito visual de clique (ripple)
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        // Decoração condicional baseada na seleção
        decoration: BoxDecoration(
          // Fundo vermelho translúcido se selecionado
          color: isSelected ? AppColors.accentRed.withValues(alpha: 0.2) : null,
          // Borda vermelha na esquerda se selecionado
          border: isSelected
              ? const Border(
                  left: BorderSide(color: AppColors.accentRed, width: 4),
                )
              : null,
        ),
        child: Column(
          children: [
            // Se tiver imagem válida, exibe ela
            if (imageBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  imageBytes!,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  // Se a imagem falhar ao renderizar, mostra o ícone
                  errorBuilder: (_, __, ___) => _buildIcon(),
                ),
              )
            // Se não tiver imagem, exibe o ícone
            else
              _buildIcon(),

            const SizedBox(height: 8),

            // Texto da categoria
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                // Muda a cor do texto se estiver selecionado
                color: isSelected ? AppColors.textWhite : AppColors.textGrey,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow
                  .ellipsis, // Trunca com "..." se passar de 2 linhas
            ),
          ],
        ),
      ),
    );
  }

  /// Helper para construir o ícone com o estilo correto
  Widget _buildIcon() {
    return Icon(
      icon,
      color: isSelected ? AppColors.textWhite : AppColors.textGrey,
      size: 28,
    );
  }
}

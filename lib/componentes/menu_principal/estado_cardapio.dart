import 'dart:async'; // Para utilizar o Timer
import 'package:flutter/material.dart'; // Para ChangeNotifier e debugPrint (se necessário)

// Imports do projeto
import '../../modelos/cardapio_models.dart';
import '../../servicos/api_service.dart';

/// ViewModel responsável por gerenciar todo o estado da tela de Menu.
/// Inclui: carregamento de dados, filtros de busca, navegação e timer de inatividade.
class MenuViewModel extends ChangeNotifier {
  // ============================================================
  // ESTADO DE DADOS (API E UI PRINCIPAL)
  // ============================================================

  CardapioCompleto? cardapio; // Objeto principal com os dados do cardápio
  bool carregando = true; // Controla o spinner de loading
  String? erro; // Armazena mensagens de erro da API
  int secaoSelecionadaIndex = 0; // Índice da categoria selecionada na sidebar

  // ============================================================
  // ESTADO DE BUSCA
  // ============================================================

  String buscaQuery = ''; // Texto digitado pelo usuário
  List<CardapioProduto> resultadosBusca = []; // Lista filtrada de produtos

  // ============================================================
  // CONFIGURAÇÃO DE INATIVIDADE (TOTEM)
  // ============================================================

  // Tempo sem toque até voltar para o carrossel (descanso de tela)
  static const int tempoInatividadeSegundos = 90;

  Timer? _timerInatividade; // Objeto do timer
  bool mostrarCarrossel = true; // Controla se o descanso de tela está visível

  // ============================================================
  // MÉTODOS: CARREGAMENTO DE DADOS
  // ============================================================

  /// Busca o cardápio completo na API.
  /// [cardapioId] é opcional; se nulo, busca o cardápio ativo padrão.
  Future<void> carregarCardapio({int? cardapioId}) async {
    // Define estado inicial de carregamento
    carregando = true;
    erro = null;
    notifyListeners(); // Notifica a UI para mostrar o spinner

    try {
      CardapioCompleto? dadosCarregados;

      // Decide qual endpoint chamar
      if (cardapioId != null) {
        dadosCarregados = await Api.instance.getCardapioCompleto(cardapioId);
      } else {
        dadosCarregados = await Api.instance.getCardapioAtivo();
      }

      // Validação simples
      if (dadosCarregados == null) {
        throw ApiException('Nenhum cardápio encontrado');
      }

      // Sucesso: Atualiza os dados e finaliza o loading
      cardapio = dadosCarregados;
      carregando = false;
      notifyListeners(); // UI atualiza para mostrar os produtos
    } catch (e) {
      // Erro: Salva a mensagem para exibir o botão "Tentar Novamente"
      erro = e.toString();
      carregando = false;
      notifyListeners();
    }
  }

  // ============================================================
  // MÉTODOS: NAVEGAÇÃO E SELEÇÃO
  // ============================================================

  /// Altera a categoria selecionada na barra lateral.
  void selecionarSecao(int index) {
    secaoSelecionadaIndex = index;
    reiniciarTimerInatividade(); // Interação conta como atividade
    notifyListeners();
  }

  // ============================================================
  // MÉTODOS: LÓGICA DE BUSCA
  // ============================================================

  /// Filtra os produtos com base no texto digitado.
  void buscar(String query) {
    // Normaliza o texto (remove espaços e põe em minúsculo)
    buscaQuery = query.trim().toLowerCase();
    resultadosBusca.clear();

    // Se a busca estiver vazia, apenas notifica para limpar a tela
    if (buscaQuery.isEmpty) {
      notifyListeners();
      return;
    }

    // Algoritmo de busca linear
    // Varre todas as seções e seus produtos
    for (final secao in cardapio?.secoes ?? []) {
      for (final produto in secao.produtos) {
        final nome = produto.produto.nome.toLowerCase();
        final descricao = (produto.produto.descricao ?? '').toLowerCase();

        // Verifica correspondência no Nome OU Descrição
        if (nome.contains(buscaQuery) || descricao.contains(buscaQuery)) {
          resultadosBusca.add(produto);
        }
      }
    }
    notifyListeners(); // Atualiza a UI com os resultados
  }

  /// Limpa o campo de busca e reseta a lista de resultados.
  void limparBusca() {
    buscaQuery = '';
    resultadosBusca.clear();
    notifyListeners();
  }

  // ============================================================
  // MÉTODOS: CONTROLE DE INATIVIDADE
  // ============================================================

  /// Inicia o monitoramento de inatividade (chamado no initState).
  void iniciarTimerInatividade() {
    reiniciarTimerInatividade();
  }

  /// Reseta o relógio. Deve ser chamado em qualquer toque na tela.
  void reiniciarTimerInatividade() {
    // Cancela o timer anterior para não acumular
    _timerInatividade?.cancel();

    // Só inicia a contagem se o carrossel NÃO estiver visível.
    // (Se o carrossel já está na tela, não precisamos contar tempo).
    if (!mostrarCarrossel) {
      _timerInatividade = Timer(
        const Duration(seconds: tempoInatividadeSegundos),
        _tempoEsgotado, // Função chamada quando o tempo acaba
      );
    }
  }

  /// Ação executada quando o usuário fica ocioso por X segundos.
  void _tempoEsgotado() {
    mostrarCarrossel = true; // Mostra o descanso de tela
    secaoSelecionadaIndex = 0; // Reseta a navegação para o início
    notifyListeners(); // UI reage exibindo o CarouselWidget
  }

  /// Alias para reiniciarTimerInatividade, usado nos Listeners da UI.
  void registrarAtividadeUsuario() {
    reiniciarTimerInatividade();
  }

  /// Esconde o carrossel e permite o uso do sistema.
  void fecharCarrossel() {
    mostrarCarrossel = false;
    reiniciarTimerInatividade(); // Começa a contar o tempo agora
    notifyListeners();
  }

  /// Força a exibição do carrossel (ex: finalizou pedido).
  void abrirCarrossel() {
    _timerInatividade?.cancel(); // Para o timer pois já estamos no carrossel
    mostrarCarrossel = true;
    notifyListeners();
  }

  // ============================================================
  // CLEANUP
  // ============================================================

  @override
  void dispose() {
    // Importante: Cancela o timer para evitar vazamento de memória
    // quando o ViewModel for descartado.
    _timerInatividade?.cancel();
    super.dispose();
  }
}

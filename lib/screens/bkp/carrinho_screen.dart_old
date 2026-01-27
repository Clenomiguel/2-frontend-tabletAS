// lib/screens/carrinho_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/carrinho_service.dart';
import '../models/carrinho_models.dart';
import './splash_screen.dart';
import '../services/prevenda_service.dart';

class CarrinhoScreen extends StatefulWidget {
  final Map<String, dynamic>? dadosCliente;

  const CarrinhoScreen({super.key, this.dadosCliente});

  @override
  State<CarrinhoScreen> createState() => _CarrinhoScreenState();
}

class _CarrinhoScreenState extends State<CarrinhoScreen> {
  static const roxo = Color(0xFF4B0082);

  @override
  void initState() {
    super.initState();
    CarrinhoService.instance.addListener(_onCarrinhoChanged);
  }

  @override
  void dispose() {
    CarrinhoService.instance.removeListener(_onCarrinhoChanged);
    super.dispose();
  }

  void _onCarrinhoChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final carrinho = CarrinhoService.instance.carrinho;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body:
          carrinho.isEmpty
              ? _buildCarrinhoVazio()
              : _buildCarrinhoComItens(carrinho),
      bottomNavigationBar:
          carrinho.isNotEmpty ? _buildBottomBar(carrinho) : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Meu Carrinho',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: roxo,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        if (CarrinhoService.instance.isNotEmpty)
          IconButton(
            onPressed: _mostrarConfirmacaoLimpeza,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Limpar carrinho',
          ),
      ],
    );
  }

  Widget _buildCarrinhoVazio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Seu carrinho está vazio',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Adicione produtos para aparecerem aqui',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: roxo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.arrow_back),
              label: const Text(
                'Voltar ao Cardápio',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarrinhoComItens(Carrinho carrinho) {
    return Column(
      children: [
        // Header com resumo
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Icon(Icons.shopping_basket, color: roxo),
              const SizedBox(width: 8),
              Text(
                '${carrinho.quantidadeTotal} ${carrinho.quantidadeTotal == 1 ? 'item' : 'itens'}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Text(
                'Total: ${carrinho.total.toStringAsFixed(2).replaceAll('.', ',')} R\$',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: roxo,
                ),
              ),
            ],
          ),
        ),

        // Lista de itens
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: carrinho.itens.length,
            itemBuilder: (context, index) {
              final item = carrinho.itens[index];
              return _buildItemCarrinho(item, index);
            },
          ),
        ),

        // Resumo de valores
        _buildResumoValores(carrinho),
      ],
    );
  }

  Widget _buildItemCarrinho(ItemCarrinho item, int index) {
    final temPersonalizacoes =
        item.composicaoSelecionada.isNotEmpty ||
        item.complementosSelecionados.isNotEmpty ||
        item.preparosSelecionados.isNotEmpty ||
        (item.observacoes?.trim().isNotEmpty == true);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagem do produto
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.fastfood,
                    color: roxo.withValues(alpha: 0.6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Informações do produto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.produto.nome ?? 'Produto',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.produto.precoFormatado} x ${item.quantidade}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (temPersonalizacoes) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Personalizado',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Controles e preço
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'R\$ ${item.precoTotal.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (temPersonalizacoes)
                      // Para produtos personalizados, apenas botão remover
                      IconButton(
                        onPressed: () => _removerItem(item.id),
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red.shade400,
                        ),
                        tooltip: 'Remover',
                      )
                    else
                      // Para produtos simples, controles de quantidade
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _decrementarItem(item.id),
                            icon: Icon(
                              item.quantidade == 1
                                  ? Icons.delete_outline
                                  : Icons.remove_circle_outline,
                              color: Colors.red.shade400,
                            ),
                            tooltip:
                                item.quantidade == 1 ? 'Remover' : 'Diminuir',
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item.quantidade.toString(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _incrementarItem(item.id),
                            icon: Icon(
                              Icons.add_circle_outline,
                              color: Colors.green.shade400,
                            ),
                            tooltip: 'Aumentar',
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),

            // Detalhes das personalizações
            if (temPersonalizacoes) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              _buildDetalhesPersonalizacao(item),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetalhesPersonalizacao(ItemCarrinho item) {
    final detalhes = <Widget>[];

    if (kDebugMode) {
      print('🛒 === EXIBINDO DETALHES NO CARRINHO ===');
      print('📦 Produto: ${item.produto.nome}');
      print('📊 Composições selecionadas: ${item.composicaoSelecionada}');
      print('📊 Complementos selecionados: ${item.complementosSelecionados}');
      print('📊 Preparos selecionados: ${item.preparosSelecionados}');
      print('📊 Nomes composição: ${item.composicaoNomes}');
      print('📊 Nomes complementos: ${item.complementosNomes}');
      print('📊 Nomes preparos: ${item.preparosNomes}');
    }

    // ✅ SABORES ESCOLHIDOS - USA QUANTIDADE DIRETA DO MAPA
    if (item.composicaoSelecionada.isNotEmpty &&
        item.composicaoNomes.isNotEmpty) {
      detalhes.add(
        _buildSecaoTitulo(Icons.restaurant_menu, 'Sabores Escolhidos:'),
      );

      for (final entry in item.composicaoSelecionada.entries) {
        final qtdSelecionada = entry.value; // ✅ AGORA É INT DIRETO!

        if (qtdSelecionada > 0) {
          // ✅ MUDADO: entry.value → qtdSelecionada > 0
          final nomeCompleto =
              item.composicaoNomes[entry.key] ?? 'Sabor (ID: ${entry.key})';

          detalhes.add(_buildItemLista(nomeCompleto, qtdSelecionada));

          if (kDebugMode) {
            print('   ✅ Sabor: $nomeCompleto - Qtd: $qtdSelecionada');
          }
        }
      }
      detalhes.add(const SizedBox(height: 8));
    }

    // ✅ COMPLEMENTOS SELECIONADOS
    if (item.complementosSelecionados.isNotEmpty) {
      detalhes.add(
        _buildSecaoTitulo(Icons.add_circle_outline, 'Complementos:'),
      );

      for (final entry in item.complementosSelecionados.entries) {
        if (entry.value > 0) {
          final quantidade = entry.value;
          final nomeComplemento =
              item.complementosNomes[entry.key] ??
              'Complemento (ID: ${entry.key})';

          // ✅ Usar preço real salvo no ItemCarrinho
          final precoUnitario = item.complementosPrecos[entry.key] ?? 0.0;
          final valorTotal = precoUnitario * quantidade;

          detalhes.add(
            _buildItemComplemento(
              nomeComplemento,
              quantidade,
              precoUnitario,
              valorTotal,
            ),
          );

          if (kDebugMode) {
            print(
              '   ✅ Complemento: $nomeComplemento - Qtd: $quantidade - Preço unit: R\$ ${precoUnitario.toStringAsFixed(2)} - Total: R\$ ${valorTotal.toStringAsFixed(2)}',
            );
          }
        }
      }
      detalhes.add(const SizedBox(height: 8));
    }

    // ✅ PREPAROS SELECIONADOS
    if (item.preparosSelecionados.isNotEmpty) {
      final preparosSelecionados = item.preparosNomes.values.toList();

      if (preparosSelecionados.isNotEmpty) {
        final textPreparos =
            preparosSelecionados.length > 1
                ? 'Preparos: ${preparosSelecionados.join(', ')}'
                : 'Preparo: ${preparosSelecionados.first}';
        detalhes.add(_buildDetalheItem(Icons.restaurant, textPreparos));

        if (kDebugMode) {
          print('📋 Preparos: $textPreparos');
        }
      }
    }

    // Observações
    if (item.observacoes?.trim().isNotEmpty == true) {
      detalhes.add(
        _buildDetalheItem(Icons.note, 'Observações: ${item.observacoes!}'),
      );

      if (kDebugMode) {
        print('📋 Observações: ${item.observacoes}');
      }
    }

    // ✅ RESUMO DE PREÇOS
    if (item.complementosSelecionados.isNotEmpty) {
      detalhes.add(const SizedBox(height: 12));
      detalhes.add(_buildResumoPrecos(item));
    }

    if (kDebugMode) {
      print('🛒 === FIM DETALHES CARRINHO ===');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: detalhes,
    );
  }

  Widget _buildSecaoTitulo(IconData icon, String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: roxo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, size: 12, color: roxo.withValues(alpha: 0.7)),
          ),
          const SizedBox(width: 8),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemLista(String nome, int quantidade) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 16),
      child: Row(
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: 13,
              color: roxo,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              '$nome - Qtd: x$quantidade', // ✅ Mostra quantidade diretamente
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemComplemento(
    String nome,
    int quantidade,
    double precoUnitario,
    double valorTotal,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '• ',
                style: TextStyle(
                  fontSize: 13,
                  color: roxo,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Text(
                  '$nome - Qtd: x$quantidade',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              'Unit: + R\$ ${precoUnitario.toStringAsFixed(2).replaceAll('.', ',')} | Total: R\$ ${valorTotal.toStringAsFixed(2).replaceAll('.', ',')}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoPrecos(ItemCarrinho item) {
    final precoBase = item.produto.precoUnit ?? 0.0;

    // Calcular total de adicionais usando preços reais salvos
    double totalAdicionais = 0.0;
    for (final entry in item.complementosSelecionados.entries) {
      if (entry.value > 0) {
        final precoUnitario = item.complementosPrecos[entry.key] ?? 0.0;
        totalAdicionais += precoUnitario * entry.value;
      }
    }

    final subtotal = precoBase + totalAdicionais;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Base: R\$ ${precoBase.toStringAsFixed(2).replaceAll('.', ',')}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              Text(
                'Adicionais: R\$ ${totalAdicionais.toStringAsFixed(2).replaceAll('.', ',')}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Divider(height: 1, color: Colors.grey.shade300),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              Text(
                'R\$ ${subtotal.toStringAsFixed(2).replaceAll('.', ',')}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: roxo,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetalheItem(IconData icon, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: roxo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, size: 12, color: roxo.withValues(alpha: 0.7)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoValores(Carrinho carrinho) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildLinhaResumo('Subtotal', carrinho.subtotal),
          if (carrinho.desconto > 0)
            _buildLinhaResumo('Desconto', -carrinho.desconto, isDesconto: true),
          if (carrinho.taxaEntrega > 0)
            _buildLinhaResumo('Taxa de Entrega', carrinho.taxaEntrega),
          const Divider(),
          _buildLinhaResumo('Total', carrinho.total, isBold: true),
        ],
      ),
    );
  }

  Widget _buildLinhaResumo(
    String label,
    double valor, {
    bool isBold = false,
    bool isDesconto = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: Colors.black87,
            ),
          ),
          Text(
            '${isDesconto ? '-' : ''}R\$ ${valor.abs().toStringAsFixed(2).replaceAll('.', ',')}',
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color:
                  isDesconto
                      ? Colors.green
                      : isBold
                      ? roxo
                      : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(Carrinho carrinho) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: roxo,
                      side: BorderSide(color: roxo, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text(
                      'Continuar Comprando',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _finalizarPedido,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: roxo,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.payment),
                    label: Text(
                      'Finalizar (R\$ ${carrinho.total.toStringAsFixed(2).replaceAll('.', ',')})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _incrementarItem(String itemId) {
    CarrinhoService.incrementarItem(itemId);
  }

  void _decrementarItem(String itemId) {
    CarrinhoService.decrementarItem(itemId);
  }

  void _removerItem(String itemId) {
    CarrinhoService.removerItem(itemId);
  }

  void _mostrarConfirmacaoLimpeza() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Limpar Carrinho'),
            content: const Text(
              'Tem certeza que deseja remover todos os itens do carrinho?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  CarrinhoService.limpar();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Limpar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  void _finalizarPedido() async {
    if (widget.dadosCliente == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: Dados do cliente não encontrados'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Finalizar Pedido'),
            content: Text(
              'Pedido no valor de R\$ ${CarrinhoService.totalStatic.toStringAsFixed(2).replaceAll('.', ',')} será finalizado e enviado ao PDV Linx.\n\n'
              'Deseja continuar?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: roxo),
                child: const Text(
                  'Confirmar Pedido',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirmar != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Enviando pedido...'),
                  ],
                ),
              ),
            ),
          ),
    );

    try {
      final resultado = await PrevendaService.registrarPrevenda(
        pessoaId: widget.dadosCliente!['pessoa_id'] ?? 0,
        pessoaNome: widget.dadosCliente!['pessoa_nome'] ?? '',
        pessoaCpf: widget.dadosCliente!['pessoa_cpf'] ?? '',
        pessoaEmail: widget.dadosCliente!['pessoa_email'] ?? '',
        pessoaEndereco: widget.dadosCliente!['pessoa_endereco'],
        pessoaBairro: widget.dadosCliente!['pessoa_bairro'],
        pessoaMunicipio: widget.dadosCliente!['pessoa_municipio'],
        pessoaMunicipioCodigo: widget.dadosCliente!['pessoa_municipio_codigo'],
        pessoaCep: widget.dadosCliente!['pessoa_cep'],
        pessoaNumero: widget.dadosCliente!['pessoa_numero'],
        pessoaComplemento: widget.dadosCliente!['pessoa_complemento'],
        pessoaTelefone: widget.dadosCliente!['pessoa_telefone'],
        carrinho: CarrinhoService.instance.carrinho,
      );

      if (mounted) Navigator.of(context).pop();

      if (resultado['sucesso'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                resultado['mensagem'] ?? 'Pedido finalizado com sucesso!',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );

          CarrinhoService.limpar();

          Future.microtask(() {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const SplashScreen()),
              (route) => false,
            );
          });
        }
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Erro ao Finalizar'),
                  content: Text(
                    resultado['mensagem'] ??
                        'Erro desconhecido ao processar o pedido.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Erro'),
                content: Text('Erro ao processar pedido: $e'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }

      if (kDebugMode) {
        debugPrint('❌ Erro ao finalizar pedido: $e');
      }
    }
  }
}

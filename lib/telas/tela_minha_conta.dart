// lib/screens/minha_conta_screen.dart
// Tela de consulta da comanda do cliente

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../modelos/comanda_models.dart';
import '../servicos/api_service.dart';

class MinhaContaScreen extends StatefulWidget {
  final String? comandaInicial;

  const MinhaContaScreen({super.key, this.comandaInicial});

  @override
  State<MinhaContaScreen> createState() => _MinhaContaScreenState();
}

class _MinhaContaScreenState extends State<MinhaContaScreen> {
  final _comandaController = TextEditingController();

  ComandaCompleta? _comanda;
  bool _isLoading = false;
  String? _error;
  bool _showScanner = false;

  // Cores do tema
  static const _bgDark = Color(0xFF1A1A1A);
  static const _bgCard = Color(0xFF2D2D2D);
  static const _accentRed = Color(0xFFE53935);
  static const _accentGreen = Color(0xFF4CAF50);
  static const _textWhite = Colors.white;
  static const _textGrey = Color(0xFF9E9E9E);

  @override
  void initState() {
    super.initState();
    if (widget.comandaInicial != null) {
      _comandaController.text = widget.comandaInicial!;
      _buscarComanda();
    }
  }

  @override
  void dispose() {
    _comandaController.dispose();
    super.dispose();
  }

  Future<void> _buscarComanda() async {
    final comanda = _comandaController.text.trim();
    if (comanda.isEmpty) {
      setState(() => _error = 'Digite o número da comanda');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _showScanner = false;
    });

    try {
      final result = await Api.instance.getComandaCompleta(comanda);
      debugPrint('Resultado da API: $result');
      setState(() {
        _comanda = ComandaCompleta.fromJson(result);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao buscar comanda: $e');
      setState(() {
        _error = e.toString().contains('404')
            ? 'Comanda não encontrada'
            : 'Erro ao buscar comanda: ${e.toString()}';
        _comanda = null;
        _isLoading = false;
      });
    }
  }

  void _onQRCodeDetected(String code) {
    setState(() {
      _comandaController.text = code;
      _showScanner = false;
    });
    _buscarComanda();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: _bgDark,
        foregroundColor: _textWhite,
        title: const Text(
          'MINHA CONTA',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Área de busca
          _buildSearchArea(),

          // Conteúdo principal
          Expanded(
            child: _showScanner
                ? _buildScanner()
                : _isLoading
                    ? _buildLoading()
                    : _error != null
                        ? _buildError()
                        : _comanda != null
                            ? _buildComandaDetails()
                            : _buildEmptyState(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Campo de texto + botão escanear
          Row(
            children: [
              // Campo de texto
              Expanded(
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: _bgDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _comandaController,
                    style: const TextStyle(
                      color: _textWhite,
                      fontSize: 18,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      hintText: 'Número da comanda',
                      hintStyle: TextStyle(color: _textGrey),
                      prefixIcon: Icon(Icons.receipt_long, color: _textGrey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    onSubmitted: (_) => _buscarComanda(),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Botão escanear
              GestureDetector(
                onTap: () => setState(() => _showScanner = !_showScanner),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _showScanner ? _accentRed : _bgDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _showScanner ? Icons.close : Icons.qr_code_scanner,
                    color: _textWhite,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Botão buscar
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _buscarComanda,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentRed,
                foregroundColor: _textWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'BUSCAR COMANDA',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanner() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accentRed, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Rotacionar a câmera para paisagem
            RotatedBox(
              quarterTurns: 3, // Rotaciona 270 graus (ou -90)
              child: MobileScanner(
                controller: MobileScannerController(
                  facing: CameraFacing.front,
                  formats: [
                    BarcodeFormat.code128,
                    BarcodeFormat.code39,
                    BarcodeFormat.code93,
                    BarcodeFormat.codabar,
                    BarcodeFormat.ean13,
                    BarcodeFormat.ean8,
                    BarcodeFormat.itf,
                    BarcodeFormat.upcA,
                    BarcodeFormat.upcE,
                    BarcodeFormat.qrCode,
                  ],
                ),
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    if (barcode.rawValue != null) {
                      _onQRCodeDetected(barcode.rawValue!);
                      break;
                    }
                  }
                },
              ),
            ),
            // Overlay com guia para código de barras (horizontal)
            Center(
              child: Container(
                width: 300,
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: _accentRed, width: 3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_scanner, color: _accentRed, size: 40),
                    SizedBox(height: 8),
                    Text(
                      'Posicione o código de barras aqui',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Texto de instrução
            const Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Text(
                'Aponte para o código de barras da comanda',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(color: Colors.black, blurRadius: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _accentRed),
          SizedBox(height: 16),
          Text(
            'Buscando comanda...',
            style: TextStyle(color: _textWhite, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: _accentRed),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: const TextStyle(color: _textWhite, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'Verifique o número e tente novamente',
            style: TextStyle(color: _textGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 100,
            color: _textGrey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          const Text(
            'Digite ou escaneie sua comanda',
            style: TextStyle(color: _textWhite, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            'para visualizar seus pedidos',
            style: TextStyle(color: _textGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildComandaDetails() {
    return Column(
      children: [
        // Header da comanda
        _buildComandaHeader(),

        // Lista de produtos
        Expanded(
          child: _comanda!.produtos.isEmpty
              ? _buildEmptyProducts()
              : _buildProductsList(),
        ),

        // Rodapé com total
        _buildTotalFooter(),
      ],
    );
  }

  Widget _buildComandaHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Ícone
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _accentRed.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.receipt,
              color: _accentRed,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comanda #${_comanda!.comanda}',
                  style: const TextStyle(
                    color: _textWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Aberta em ${_formatDateTime(_comanda!.tsAbertura)}',
                  style: const TextStyle(color: _textGrey, fontSize: 13),
                ),
              ],
            ),
          ),

          // Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(_comanda!.status).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _comanda!.statusFormatado,
              style: TextStyle(
                color: _getStatusColor(_comanda!.status),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyProducts() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 60, color: _textGrey),
          SizedBox(height: 16),
          Text(
            'Nenhum produto na comanda',
            style: TextStyle(color: _textWhite, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    final produtosPrincipais = _comanda!.produtosPrincipais;

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: produtosPrincipais.length,
      itemBuilder: (context, index) {
        final produto = produtosPrincipais[index];
        final complementos = _comanda!.getComplementos(produto.codigo);

        return _buildProductItem(produto, complementos);
      },
    );
  }

  Widget _buildProductItem(
      ComandaProduto produto, List<ComandaProduto> complementos) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Produto principal
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Quantidade
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _accentRed.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      produto.quantidadeFormatada,
                      style: const TextStyle(
                        color: _accentRed,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Nome e detalhes
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        produto.produtoNome,
                        style: const TextStyle(
                          color: _textWhite,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (produto.observacao.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          produto.observacao,
                          style: const TextStyle(
                            color: _textGrey,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(produto.hora),
                        style: const TextStyle(color: _textGrey, fontSize: 11),
                      ),
                    ],
                  ),
                ),

                // Preço
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      produto.precoFormatado,
                      style: const TextStyle(
                        color: _textWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (produto.quantidade > 1)
                      Text(
                        '${produto.precoUnitFormatado} un.',
                        style: const TextStyle(color: _textGrey, fontSize: 11),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Complementos
          if (complementos.isNotEmpty) ...[
            Container(
              width: double.infinity,
              height: 1,
              color: _bgDark,
            ),
            ...complementos.map((comp) => _buildComplementoItem(comp)),
          ],
        ],
      ),
    );
  }

  Widget _buildComplementoItem(ComandaProduto complemento) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _bgDark.withValues(alpha: 0.5),
      ),
      child: Row(
        children: [
          const SizedBox(width: 52), // Alinha com o nome do principal
          const Icon(Icons.subdirectory_arrow_right,
              color: _textGrey, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              complemento.produtoNome,
              style: const TextStyle(color: _textGrey, fontSize: 13),
            ),
          ),
          Text(
            complemento.precoFormatado,
            style: const TextStyle(color: _textGrey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Resumo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Itens',
                  style: TextStyle(color: _textGrey, fontSize: 14),
                ),
                Text(
                  '${_comanda!.produtos.length}',
                  style: const TextStyle(color: _textWhite, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(color: _bgDark),
            const SizedBox(height: 8),

            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL',
                  style: TextStyle(
                    color: _textWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'R\$ ${_comanda!.valor.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: const TextStyle(
                    color: _accentGreen,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Botão atualizar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _buscarComanda,
                icon: const Icon(Icons.refresh),
                label: const Text('ATUALIZAR'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _textWhite,
                  side: const BorderSide(color: _textGrey),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'L':
        return _accentGreen;
      case 'F':
        return Colors.orange;
      case 'C':
        return _accentRed;
      case 'P':
        return Colors.blue;
      default:
        return _textGrey;
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} às ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

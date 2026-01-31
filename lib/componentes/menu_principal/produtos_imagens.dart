import 'dart:typed_data'; // Para manipular os bytes da imagem (Uint8List)
import 'package:flutter/material.dart';

// Imports do projeto
import '../../servicos/api_service.dart'; // Serviço para buscar imagem na API
import '../../utilitarios/safebase64.dart'; // Utilitário de decodificação (StringUtils)
import '../../utilitarios/cores_app.dart'; // Paleta de cores

/// Widget responsável por carregar e exibir a imagem do produto.
/// Lógica:
/// 1. Tenta decodificar a String Base64 se ela já existir.
/// 2. Se não, faz uma chamada à API para buscar a imagem pelo ID.
/// 3. Gerencia estados de Loading, Sucesso e Erro (Placeholder).
class ProdutoImage extends StatefulWidget {
  final int produtoId; // ID para buscar na API caso necessário
  final String? imagemBase64; // String da imagem vinda do cache/lista inicial

  const ProdutoImage({
    super.key,
    required this.produtoId,
    this.imagemBase64,
  });

  @override
  State<ProdutoImage> createState() => _ProdutoImageState();
}

class _ProdutoImageState extends State<ProdutoImage> {
  // --- Estado Local ---
  Uint8List? _imageBytes; // Os dados binários da imagem para exibição
  bool _isLoading = true; // Controla se mostra o spinner
  bool _hasError = false; // Controla se mostra o ícone de fallback

  // --- Ciclo de Vida ---

  @override
  void initState() {
    super.initState();
    // Inicia o carregamento assim que o componente é montado
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant ProdutoImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Se o ID do produto mudar (ex: reciclagem de views em listas), recarrega
    if (oldWidget.produtoId != widget.produtoId) {
      _loadImage();
    }
  }

  // --- Lógica de Carregamento ---

  Future<void> _loadImage() async {
    // Reseta o estado para "Carregando"
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    // 1. TENTATIVA VIA BASE64 (Rápido/Cache)
    // Verifica se recebemos a string base64 e se ela não está vazia
    if (widget.imagemBase64 != null && widget.imagemBase64!.isNotEmpty) {
      // Usa o utilitário para limpar e decodificar a string
      final bytes = StringUtils.safeBase64Decode(widget.imagemBase64!);

      if (bytes != null) {
        // Se decodificou com sucesso, exibe e encerra a função
        if (mounted) {
          setState(() {
            _imageBytes = bytes;
            _isLoading = false;
          });
        }
        return; // Interrompe aqui, não precisa ir na API
      }
    }

    // 2. TENTATIVA VIA API (Lento/Rede)
    try {
      // Chama o endpoint que retorna os bytes da imagem
      final bytes = await Api.instance.getProdutoImagem(widget.produtoId);

      // Verifica se o widget ainda está na tela antes de atualizar o estado
      if (mounted) {
        setState(() {
          _imageBytes = bytes;
          _isLoading = false;
          // Se bytes for null, considera como erro
          _hasError = bytes == null;
        });
      }
    } catch (e) {
      // Se der erro de conexão ou outro, mostra o placeholder
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  // --- Construção da UI ---

  @override
  Widget build(BuildContext context) {
    // CASO 1: Carregando
    if (_isLoading) {
      return Container(
        color: AppColors.placeholderBg, // Fundo cinza escuro
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: AppColors.textGrey,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    // CASO 2: Erro ou Imagem Nula (Mostra Placeholder)
    if (_hasError || _imageBytes == null) {
      return Container(
        color: AppColors.placeholderBg,
        child: const Center(
          child: Icon(
            Icons.fastfood, // Ícone genérico de comida
            color: AppColors.textGrey,
            size: 48,
          ),
        ),
      );
    }

    // CASO 3: Sucesso (Mostra a Imagem)
    return Image.memory(
      _imageBytes!,
      fit: BoxFit.cover, // Preenche o quadrado cortando excessos
      // Fallback de segurança caso os bytes estejam corrompidos
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.placeholderBg,
        child: const Center(
          child: Icon(
            Icons.fastfood,
            color: AppColors.textGrey,
            size: 48,
          ),
        ),
      ),
    );
  }
}

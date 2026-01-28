// lib/widgets/base64_image.dart
// Widget para exibir imagens base64 do backend

import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// Widget que exibe imagem de produto carregada do backend (base64)
class ProdutoImage extends StatefulWidget {
  final int produtoId;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const ProdutoImage({
    super.key,
    required this.produtoId,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  @override
  State<ProdutoImage> createState() => _ProdutoImageState();
}

class _ProdutoImageState extends State<ProdutoImage> {
  Uint8List? _imageBytes;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(ProdutoImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.produtoId != widget.produtoId) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final bytes = await Api.instance.getProdutoImagem(widget.produtoId);

      if (mounted) {
        setState(() {
          _imageBytes = bytes;
          _isLoading = false;
          _hasError = bytes == null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (_isLoading) {
      child = widget.placeholder ?? _defaultPlaceholder();
    } else if (_hasError || _imageBytes == null) {
      child = widget.errorWidget ?? _defaultErrorWidget();
    } else {
      child = Image.memory(
        _imageBytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) {
          return widget.errorWidget ?? _defaultErrorWidget();
        },
      );
    }

    if (widget.borderRadius != null) {
      return ClipRRect(
        borderRadius: widget.borderRadius!,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: child,
        ),
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: child,
    );
  }

  Widget _defaultPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _defaultErrorWidget() {
    return Container(
      color: Colors.grey[200],
      child: Icon(
        Icons.fastfood_outlined,
        size: (widget.width ?? 100) * 0.4,
        color: Colors.grey[400],
      ),
    );
  }
}

/// Widget que exibe imagem de seção do cardápio (base64)
class SecaoImage extends StatefulWidget {
  final int secaoId;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const SecaoImage({
    super.key,
    required this.secaoId,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  @override
  State<SecaoImage> createState() => _SecaoImageState();
}

class _SecaoImageState extends State<SecaoImage> {
  Uint8List? _imageBytes;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(SecaoImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.secaoId != widget.secaoId) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final bytes = await Api.instance.getSecaoImagem(widget.secaoId);

      if (mounted) {
        setState(() {
          _imageBytes = bytes;
          _isLoading = false;
          _hasError = bytes == null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (_isLoading) {
      child = widget.placeholder ?? _defaultPlaceholder();
    } else if (_hasError || _imageBytes == null) {
      child = widget.errorWidget ?? _defaultErrorWidget();
    } else {
      child = Image.memory(
        _imageBytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) {
          return widget.errorWidget ?? _defaultErrorWidget();
        },
      );
    }

    if (widget.borderRadius != null) {
      return ClipRRect(
        borderRadius: widget.borderRadius!,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: child,
        ),
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: child,
    );
  }

  Widget _defaultPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _defaultErrorWidget() {
    return Container(
      color: Colors.grey[200],
      child: Icon(
        Icons.category_outlined,
        size: (widget.width ?? 100) * 0.4,
        color: Colors.grey[400],
      ),
    );
  }
}

/// Widget genérico para exibir imagem base64 diretamente
class Base64Image extends StatelessWidget {
  final String? base64String;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const Base64Image({
    super.key,
    required this.base64String,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorWidget,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (base64String == null || base64String!.isEmpty) {
      return _buildError();
    }

    try {
      final bytes = _decodeBase64(base64String!);

      Widget image = Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildError(),
      );

      if (borderRadius != null) {
        return ClipRRect(
          borderRadius: borderRadius!,
          child: image,
        );
      }

      return image;
    } catch (e) {
      return _buildError();
    }
  }

  Uint8List _decodeBase64(String base64String) {
    String cleanBase64 = base64String;

    // Remove prefixo data:image/xxx;base64, se existir
    if (cleanBase64.contains(',')) {
      cleanBase64 = cleanBase64.split(',').last;
    }

    // Remove espaços e quebras de linha
    cleanBase64 = cleanBase64.replaceAll(RegExp(r'\s'), '');

    // Adiciona padding se necessário
    final padding = cleanBase64.length % 4;
    if (padding > 0) {
      cleanBase64 += '=' * (4 - padding);
    }

    return base64Decode(cleanBase64);
  }

  Widget _buildError() {
    return errorWidget ??
        Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: Icon(
            Icons.image_not_supported_outlined,
            size: (width ?? 100) * 0.4,
            color: Colors.grey[400],
          ),
        );
  }
}

/// Provider/Cache para imagens (opcional, para uso com Provider/Riverpod)
class ImageCacheProvider {
  final Map<String, Uint8List> _cache = {};

  Future<Uint8List?> getImage(
      String key, Future<Uint8List?> Function() loader) async {
    if (_cache.containsKey(key)) {
      return _cache[key];
    }

    final bytes = await loader();
    if (bytes != null) {
      _cache[key] = bytes;
    }
    return bytes;
  }

  void clear() {
    _cache.clear();
  }

  void remove(String key) {
    _cache.remove(key);
  }

  bool has(String key) => _cache.containsKey(key);
}

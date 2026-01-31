// lib/models/comanda_models.dart
// Modelos para comanda e seus produtos

class ComandaCompleta {
  final String comanda;
  final int empresa;
  final String? responsavel;
  final int? quantidadePessoas;
  final String? clienteNome;
  final int id;
  final DateTime tsAbertura;
  final double valor;
  final String status;
  final String? pafHash;
  final String? responsavelNome;
  final List<ComandaProduto> produtos;

  ComandaCompleta({
    required this.comanda,
    required this.empresa,
    this.responsavel,
    this.quantidadePessoas,
    this.clienteNome,
    required this.id,
    required this.tsAbertura,
    required this.valor,
    required this.status,
    this.pafHash,
    this.responsavelNome,
    required this.produtos,
  });

  factory ComandaCompleta.fromJson(Map<String, dynamic> json) {
    return ComandaCompleta(
      comanda: json['comanda']?.toString() ?? '',
      empresa: json['empresa'] ?? 0,
      responsavel: json['responsavel'],
      quantidadePessoas: json['quantidade_pessoas'],
      clienteNome: json['cliente_nome'],
      id: json['id'] ?? 0,
      tsAbertura:
          DateTime.tryParse(json['ts_abertura'] ?? '') ?? DateTime.now(),
      valor: (json['valor'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      pafHash: json['paf_hash'],
      responsavelNome: json['responsavel_nome'],
      produtos: (json['produtos'] as List<dynamic>?)
              ?.map((p) => ComandaProduto.fromJson(p))
              .toList() ??
          [],
    );
  }

  /// Retorna o status formatado
  String get statusFormatado {
    switch (status.toUpperCase()) {
      case 'L':
        return 'Aberta';
      case 'F':
        return 'Fechada';
      case 'C':
        return 'Cancelada';
      case 'P':
        return 'Paga';
      default:
        return status;
    }
  }

  /// Calcula o total dos produtos (para conferência)
  double get totalProdutos {
    return produtos.fold(0.0, (sum, p) => sum + p.valor);
  }

  /// Retorna apenas produtos principais (sem parent)
  List<ComandaProduto> get produtosPrincipais {
    return produtos.where((p) => p.parent == null).toList();
  }

  /// Retorna complementos de um produto
  List<ComandaProduto> getComplementos(int codigoProduto) {
    return produtos.where((p) => p.parent == codigoProduto).toList();
  }
}

class ComandaProduto {
  final int codigo;
  final String comanda;
  final int produto;
  final double quantidade;
  final int? terminal;
  final DateTime hora;
  final int? vendedor;
  final int? orcamento;
  final int? departamento;
  final double precoUnit;
  final double valor;
  final int? parent;
  final int? local;
  final int empresa;
  final int comandaId;
  final String? comandaOrigem;
  final String? pafHash;
  final String? codigoBarra;
  final String observacao;
  final String? clienteNome;
  final String produtoNome;

  ComandaProduto({
    required this.codigo,
    required this.comanda,
    required this.produto,
    required this.quantidade,
    this.terminal,
    required this.hora,
    this.vendedor,
    this.orcamento,
    this.departamento,
    required this.precoUnit,
    required this.valor,
    this.parent,
    this.local,
    required this.empresa,
    required this.comandaId,
    this.comandaOrigem,
    this.pafHash,
    this.codigoBarra,
    required this.observacao,
    this.clienteNome,
    required this.produtoNome,
  });

  factory ComandaProduto.fromJson(Map<String, dynamic> json) {
    return ComandaProduto(
      codigo: json['codigo'] ?? 0,
      comanda: json['comanda']?.toString() ?? '',
      produto: json['produto'] ?? 0,
      quantidade: (json['quantidade'] ?? 0).toDouble(),
      terminal: json['terminal'],
      hora: DateTime.tryParse(json['hora'] ?? '') ?? DateTime.now(),
      vendedor: json['vendedor'],
      orcamento: json['orcamento'],
      departamento: json['departamento'],
      precoUnit: (json['preco_unit'] ?? 0).toDouble(),
      valor: (json['valor'] ?? 0).toDouble(),
      parent: json['parent'],
      local: json['local'],
      empresa: json['empresa'] ?? 0,
      comandaId: json['comanda_id'] ?? 0,
      comandaOrigem: json['comanda_origem'],
      pafHash: json['paf_hash'],
      codigoBarra: json['codigo_barra'],
      observacao: json['observacao'] ?? '',
      clienteNome: json['cliente_nome'],
      produtoNome: json['produto_nome'] ?? 'Produto',
    );
  }

  /// Verifica se é um complemento
  bool get isComplemento => parent != null;

  /// Quantidade formatada
  String get quantidadeFormatada {
    if (quantidade == quantidade.toInt()) {
      return quantidade.toInt().toString();
    }
    return quantidade.toStringAsFixed(2);
  }

  /// Preço formatado
  String get precoFormatado {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  /// Preço unitário formatado
  String get precoUnitFormatado {
    return 'R\$ ${precoUnit.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}

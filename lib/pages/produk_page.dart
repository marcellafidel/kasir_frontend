import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProdukPage extends StatefulWidget {
  final String token;

  const ProdukPage({super.key, required this.token});

  @override
  State<ProdukPage> createState() => _ProdukPageState();
}

class _ProdukPageState extends State<ProdukPage> {
  static const Color maroon = Color(0xFF800020);
  static const Color background = Color(0xFFFAF8F8);
  static const String baseUrl = 'http://192.168.18.52:3000/api/v1';

  static const List<String> units = [
    'pcs',
    'kg',
    'gram',
    'liter',
    'porsi',
    'meter',
    'paket',
  ];

  List<dynamic> products = [];
  List<dynamic> categories = [];
  bool isLoading = true;
  String? errorMessage;

  Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      };

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http
          .get(Uri.parse('$baseUrl/products'), headers: headers)
          .timeout(const Duration(seconds: 15));

      final result = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(result['message'] ?? 'Gagal mengambil produk');
      }

      if (!mounted) return;

      setState(() {
        products = result['data'] is List ? result['data'] : [];
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  Future<void> fetchCategories() async {
    final response = await http
        .get(Uri.parse('$baseUrl/categories'), headers: headers)
        .timeout(const Duration(seconds: 15));

    final result = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(result['message'] ?? 'Gagal mengambil kategori');
    }

    final data = result['data'];

    if (data is List) {
      categories = List<dynamic>.from(data);
    } else if (data is Map && data['categories'] is List) {
      categories = List<dynamic>.from(data['categories']);
    } else {
      categories = [];
    }
  }

  double? parseNumber(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  String formatStock(dynamic stock) {
    final value = double.tryParse(stock.toString());

    if (value == null) return '0';

    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }

    return value.toString().replaceAll('.', ',');
  }

  String formatPrice(dynamic price) {
    final value = double.tryParse(price.toString());

    if (value == null) return price.toString();

    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }

    return value.toString().replaceAll('.', ',');
  }

  Future<String?> showCreateCategoryDialog() async {
    final controller = TextEditingController();

    try {
      return await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Buat Kategori Baru'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nama kategori',
              hintText: 'Contoh: Minuman',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();

                if (name.isNotEmpty) {
                  Navigator.pop(dialogContext, name);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> showAddProductForm() async {
    await showProductForm();
  }

  Future<void> showEditProductForm(
    Map<String, dynamic> product,
  ) async {
    await showProductForm(product: product);
  }

  Future<void> showProductForm({
    Map<String, dynamic>? product,
  }) async {
    final isEdit = product != null;
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(
      text: product?['name']?.toString() ?? '',
    );

    final priceController = TextEditingController(
      text: product?['price']?.toString() ?? '',
    );

    final stockController = TextEditingController(
      text: product == null
          ? '0'
          : formatStock(product['stock']).replaceAll(',', '.'),
    );

    String unit = units.contains(product?['unit'])
        ? product!['unit'].toString()
        : 'pcs';

    bool allowDecimal = product?['allowDecimal'] == true;

    int? categoryId = product?['categoryId'] == null
        ? null
        : int.tryParse(product!['categoryId'].toString());

    bool saving = false;
    String? formError;

    try {
      await fetchCategories();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kategori gagal dimuat: $e')),
        );
      }
    }

    if (!mounted) {
      nameController.dispose();
      priceController.dispose();
      stockController.dispose();
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: !saving,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final categoryExists = categories.any(
            (category) =>
                int.tryParse(category['id'].toString()) == categoryId,
          );

          return AlertDialog(
            title: Text(isEdit ? 'Edit Produk' : 'Tambah Produk'),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Nama produk',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama produk wajib diisi';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: priceController,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Harga (Rp)',
                          hintText: 'Contoh: 15000',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final price = parseNumber(value ?? '');

                          if (price == null ||
                              !price.isFinite ||
                              price <= 0) {
                            return 'Masukkan harga yang valid';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: stockController,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: isEdit ? 'Stok' : 'Stok awal',
                          hintText: 'Contoh: 10 atau 1,5',
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final stock = parseNumber(value ?? '');

                          if (stock == null ||
                              !stock.isFinite ||
                              stock < 0) {
                            return 'Masukkan stok yang valid';
                          }

                          if (!allowDecimal &&
                              stock != stock.truncateToDouble()) {
                            return 'Stok harus bilangan bulat';
                          }

                          if (allowDecimal &&
                              (stock * 100 -
                                          (stock * 100).round())
                                      .abs() >
                                  0.000001) {
                            return 'Maksimal 2 angka desimal';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: unit,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Satuan',
                          border: OutlineInputBorder(),
                        ),
                        items: units.map((value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => unit = value);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Stok boleh desimal'),
                        subtitle: const Text('Contoh: 1,5 kg'),
                        value: allowDecimal,
                        onChanged: (value) {
                          setDialogState(() {
                            allowDecimal = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int?>(
                        key: ValueKey(
                          'category-$categoryId-${categories.length}',
                        ),
                        initialValue: categoryExists ? categoryId : null,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Kategori (opsional)',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Tanpa kategori'),
                          ),
                          ...categories.map((category) {
                            return DropdownMenuItem<int?>(
                              value: int.tryParse(
                                category['id'].toString(),
                              ),
                              child: Text(
                                category['name']?.toString() ??
                                    'Kategori',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                          if (!isEdit)
                            const DropdownMenuItem<int?>(
                              value: -1,
                              child: Text('+ Buat kategori baru'),
                            ),
                        ],
                        onChanged: (value) async {
                          if (value == -1) {
                            try {
                              final categoryName =
                                  await showCreateCategoryDialog();

                              if (categoryName == null ||
                                  categoryName.trim().isEmpty) {
                                return;
                              }

                              final response = await http
                                  .post(
                                    Uri.parse('$baseUrl/categories'),
                                    headers: headers,
                                    body: jsonEncode({
                                      'name': categoryName.trim(),
                                    }),
                                  )
                                  .timeout(const Duration(seconds: 15));

                              final result = jsonDecode(response.body);

                              if (!dialogContext.mounted) return;

                              if (response.statusCode == 201) {
                                final newCategory = result['data'];

                                if (newCategory is! Map ||
                                    newCategory['id'] == null) {
                                  setDialogState(() {
                                    formError =
                                        'Data kategori baru tidak valid.';
                                  });
                                  return;
                                }

                                final newId = int.tryParse(
                                  newCategory['id'].toString(),
                                );

                                setDialogState(() {
                                  categories = [
                                    ...categories,
                                    newCategory,
                                  ];
                                  categoryId = newId;
                                  formError = null;
                                });
                              } else {
                                setDialogState(() {
                                  formError =
                                      result['message']?.toString() ??
                                          'Gagal membuat kategori';
                                });
                              }
                            } catch (e) {
                              if (!dialogContext.mounted) return;

                              setDialogState(() {
                                formError =
                                    'Gagal membuat kategori: $e';
                              });
                            }
                          } else {
                            setDialogState(() {
                              categoryId = value;
                              formError = null;
                            });
                          }
                        },
                      ),
                      if (formError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          formError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: const Text('Batal'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: maroon,
                ),
                onPressed: saving
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) {
                          return;
                        }

                        setDialogState(() {
                          saving = true;
                          formError = null;
                        });

                        try {
                          final body = jsonEncode({
                            'name': nameController.text.trim(),
                            'price': parseNumber(priceController.text),
                            'unit': unit,
                            'stock': parseNumber(stockController.text),
                            'allowDecimal': allowDecimal,
                            'categoryId': categoryId,
                          });

                          final http.Response response;

                          if (isEdit) {
                            response = await http
                                .put(
                                  Uri.parse(
                                    '$baseUrl/products/${product['id']}',
                                  ),
                                  headers: headers,
                                  body: body,
                                )
                                .timeout(const Duration(seconds: 15));
                          } else {
                            response = await http
                                .post(
                                  Uri.parse('$baseUrl/products'),
                                  headers: headers,
                                  body: body,
                                )
                                .timeout(const Duration(seconds: 15));
                          }

                          final result = jsonDecode(response.body);

                          final success = isEdit
                              ? response.statusCode == 200
                              : response.statusCode == 201;

                          if (success) {
                            if (!dialogContext.mounted) return;

                            Navigator.pop(dialogContext);
                            await fetchProducts();

                            if (!mounted) return;

                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEdit
                                      ? 'Produk berhasil diperbarui'
                                      : 'Produk berhasil ditambahkan',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            if (!dialogContext.mounted) return;

                            setDialogState(() {
                              saving = false;
                              formError =
                                  result['message']?.toString() ??
                                      'Gagal menyimpan produk';
                            });
                          }
                        } catch (e) {
                          if (!dialogContext.mounted) return;

                          setDialogState(() {
                            saving = false;
                            formError = 'Gagal menyimpan: $e';
                          });
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isEdit ? 'Simpan Perubahan' : 'Simpan',
                      ),
              ),
            ],
          );
        },
      ),
    );

    nameController.dispose();
    priceController.dispose();
    stockController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: maroon,
        foregroundColor: Colors.white,
        title: const Text('Produk'),
        actions: [
          IconButton(
            onPressed: fetchProducts,
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showAddProductForm,
        backgroundColor: maroon,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Produk'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: fetchProducts,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : products.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: maroon,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Belum ada produk',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: maroon,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tekan tombol Tambah Produk untuk mulai.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: fetchProducts,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          16,
                          16,
                          16,
                          90,
                        ),
                        itemCount: products.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final product = products[index];
                          final category = product['category'];

                          return Card(
                            color: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(
                                color: Colors.black12,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFF3E3E8),
                                child: Icon(
                                  Icons.inventory_2_rounded,
                                  color: maroon,
                                ),
                              ),
                              title: Text(
                                product['name']?.toString() ??
                                    'Tanpa nama',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  'Kategori: ${category?['name'] ?? '-'}\n'
                                  'Stok: ${formatStock(product['stock'])} '
                                  '${product['unit'] ?? ''}',
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Rp ${formatPrice(product['price'] ?? '0')}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: maroon,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Edit produk',
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      color: maroon,
                                    ),
                                    onPressed: () {
                                      showEditProductForm(
                                        Map<String, dynamic>.from(product),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
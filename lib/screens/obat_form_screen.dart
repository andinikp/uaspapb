// File: lib/screens/obat_form_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/obat_repository.dart';
import '../models/obat_model.dart';

class ObatFormScreen extends StatefulWidget {
  final ObatModel? obat; // Null jika Tambah, Ada jika Edit

  const ObatFormScreen({super.key, this.obat});

  @override
  State<ObatFormScreen> createState() => _ObatFormScreenState();
}

class _ObatFormScreenState extends State<ObatFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _namaController;
  late TextEditingController _satuanController;
  late TextEditingController _stokController;
  late TextEditingController _hargaController;

  bool get isEditing => widget.obat != null;

  late int _stok;
  Timer? _holdTimer;

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller dengan data obat jika sedang EDIT
    _namaController = TextEditingController(text: widget.obat?.namaObat);
    _satuanController = TextEditingController(text: widget.obat?.satuan);
    _stokController = TextEditingController(
      text: widget.obat?.stokSaatIni.toString(),
    );
    _hargaController = TextEditingController(
      text: _formatHarga(widget.obat?.hargaJual),
    );

    _stok = widget.obat?.stokSaatIni ?? int.tryParse(_stokController.text) ?? 0;
    _stokController.text = _stok.toString();

    // sinkronisasi ketika user mengetik manual
    _stokController.addListener(() {
      final v = int.tryParse(_stokController.text);
      if (v != null && v != _stok) {
        setState(() => _stok = v);
      }
    });
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _namaController.dispose();
    _satuanController.dispose();
    _stokController.dispose();
    _hargaController.dispose();
    super.dispose();
  }

  bool _isSubmitting = false;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final repo = Provider.of<ObatRepository>(context, listen: false);

    final nama = _namaController.text;
    final satuan = _satuanController.text;
    final stok = int.tryParse(_stokController.text) ?? 0;
    final harga = double.tryParse(_hargaController.text) ?? 0.0;

    try {
      if (isEditing) {
        // Logika UPDATE
        final updatedObat = ObatModel(
          obatId: widget.obat!.obatId,
          namaObat: nama,
          satuan: satuan,
          stokSaatIni: stok,
          hargaJual: harga,
        );
        await repo.updateObat(updatedObat);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data obat berhasil diubah!')),
        );
      } else {
        // Logika CREATE
        await repo.addObat(
          namaObat: nama,
          satuan: satuan,
          stokSaatIni: stok,
          hargaJual: harga,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Obat baru berhasil ditambahkan!')),
        );
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan data: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // -- Stock stepper helpers (Shopee-like) --
  void _changeStokBy(int delta) {
    setState(() {
      final newVal = _stok + delta;
      _stok = newVal < 0 ? 0 : newVal;
      _stokController.text = _stok.toString();
    });
  }

  void _startHold(int delta) {
    _holdTimer?.cancel();
    // immediate feedback
    _changeStokBy(delta);
    // after short delay start faster periodic changes
    _holdTimer = Timer(const Duration(milliseconds: 320), () {
      _holdTimer?.cancel();
      _holdTimer = Timer.periodic(
        const Duration(milliseconds: 120),
        (_) => _changeStokBy(delta),
      );
    });
  }

  void _stopHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
  }

  String _formatHarga(double? harga) {
    if (harga == null) return '';
    // Tampilkan tanpa ".0" kalau bilangan bulat
    if (harga == harga.truncateToDouble()) return harga.toInt().toString();
    return harga.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing
              ? 'Edit Obat: ${widget.obat!.namaObat}'
              : 'Tambah Obat Baru',
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              // Modern card container
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.teal.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.medication,
                              color: Colors.teal,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isEditing ? 'Edit Obat' : 'Tambah Obat Baru',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Nama Obat
                      TextFormField(
                        controller: _namaController,
                        decoration: InputDecoration(
                          labelText: 'Nama Obat',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Nama obat wajib diisi' : null,
                      ),

                      const SizedBox(height: 12),

                      // Satuan
                      TextFormField(
                        controller: _satuanController,
                        decoration: InputDecoration(
                          labelText: 'Satuan (Cth: Tablet)',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Stok Saat Ini — Shopee-like stepper
                      Text(
                        'Stok Saat Ini',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Minus
                            GestureDetector(
                              onTap: () => _changeStokBy(-1),
                              onLongPressStart: (d) => _startHold(-1),
                              onLongPressEnd: (d) => _stopHold(),
                              child: Container(
                                width: 44,
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.remove,
                                  size: 20,
                                  color: Colors.black54,
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Input angka tengah (bisa diedit manual)
                            SizedBox(
                              width: 92,
                              child: TextFormField(
                                controller: _stokController,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) =>
                                    int.tryParse(value ?? '') == null
                                    ? 'Wajib angka'
                                    : null,
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Plus
                            GestureDetector(
                              onTap: () => _changeStokBy(1),
                              onLongPressStart: (d) => _startHold(1),
                              onLongPressEnd: (d) => _stopHold(),
                              child: Container(
                                width: 44,
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.teal.shade400,
                                      Colors.teal.shade600,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.teal.withOpacity(0.12),
                                      offset: const Offset(0, 4),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.add,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Harga
                      TextFormField(
                        controller: _hargaController,
                        decoration: InputDecoration(
                          labelText: 'Harga Jual per Satuan (Rp)',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => double.tryParse(value!) == null
                            ? 'Wajib angka'
                            : null,
                      ),

                      const SizedBox(height: 18),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  isEditing
                                      ? 'Simpan Perubahan'
                                      : 'Tambah Obat',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

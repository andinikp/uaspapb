// File: lib/screens/pasien_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../repositories/pasien_repository.dart';
import '../models/pasien_model.dart';

class PasienFormScreen extends StatefulWidget {
  final PasienModel? pasien; // Null jika Tambah, Ada jika Edit

  const PasienFormScreen({super.key, this.pasien});

  @override
  State<PasienFormScreen> createState() => _PasienFormScreenState();
}

class _PasienFormScreenState extends State<PasienFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaController;
  late TextEditingController _nikController;
  late TextEditingController _alamatController;
  late TextEditingController _telpController;
  late DateTime _tglLahir;

  // Pilihan Jenis Kelamin (UI saja — belum disimpan ke model)
  String? _selectedGender;

  bool get isEditing => widget.pasien != null;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.pasien?.namaPasien);
    _nikController = TextEditingController(text: widget.pasien?.nik);
    _alamatController = TextEditingController(text: widget.pasien?.alamat);
    _telpController = TextEditingController(text: widget.pasien?.noTelp);
    _tglLahir = widget.pasien?.tglLahir ?? DateTime.now();
    _selectedGender = widget.pasien?.jenisKelamin; // inisialisasi jika edit
  }

  @override
  void dispose() {
    _namaController.dispose();
    _nikController.dispose();
    _alamatController.dispose();
    _telpController.dispose();
    super.dispose();
  }

  // --- FUNGSI SUBMIT (CREATE / UPDATE) ---
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final repo = Provider.of<PasienRepository>(context, listen: false);

      if (isEditing) {
        // Update the existing Hive-backed object rather than creating a new one
        final pasien = widget.pasien!;
        pasien.namaPasien = _namaController.text;
        pasien.nik = _nikController.text;
        pasien.tglLahir = _tglLahir;
        pasien.alamat = _alamatController.text;
        pasien.noTelp = _telpController.text;
        pasien.jenisKelamin = _selectedGender;
        await repo.updatePasien(pasien);
      } else {
        await repo.addPasien(
          namaPasien: _namaController.text,
          nik: _nikController.text,
          tglLahir: _tglLahir,
          alamat: _alamatController.text,
          noTelp: _telpController.text,
          jenisKelamin: _selectedGender,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _tglLahir,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _tglLahir) {
      setState(() {
        _tglLahir = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing
              ? 'Edit Pasien: ${widget.pasien!.namaPasien}'
              : 'Tambah Pasien Baru',
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
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
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isEditing ? 'Edit Pasien' : 'Tambah Pasien Baru',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Nama
                      TextFormField(
                        controller: _namaController,
                        decoration: InputDecoration(
                          labelText: 'Nama Lengkap',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Nama tidak boleh kosong' : null,
                      ),

                      const SizedBox(height: 12),

                      // NIK dan Telp berdampingan
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _nikController,
                              decoration: InputDecoration(
                                labelText: 'NIK',
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty)
                                  return 'NIK harus diisi';
                                if (!RegExp(r'^\d+$').hasMatch(value))
                                  return 'NIK harus berupa angka';
                                if (value.length < 10)
                                  return 'NIK minimal 10 digit';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _telpController,
                              decoration: InputDecoration(
                                labelText: 'Nomor Telepon',
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty)
                                  return 'Nomor telepon harus diisi';
                                if (!RegExp(r'^\d+$').hasMatch(value))
                                  return 'Nomor telepon harus berupa angka';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      // Dropdown Jenis Kelamin (opsi Laki-laki / Perempuan)
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: InputDecoration(
                          labelText: 'Jenis Kelamin',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Laki-laki',
                            child: Text('Laki-laki'),
                          ),
                          DropdownMenuItem(
                            value: 'Perempuan',
                            child: Text('Perempuan'),
                          ),
                        ],
                        onChanged: (val) =>
                            setState(() => _selectedGender = val),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Pilih jenis kelamin'
                            : null,
                      ),

                      const SizedBox(height: 12),

                      // Alamat
                      TextFormField(
                        controller: _alamatController,
                        decoration: InputDecoration(
                          labelText: 'Alamat',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        maxLines: 3,
                      ),

                      const SizedBox(height: 12),

                      // Tanggal Lahir (tile yang rapi)
                      InkWell(
                        onTap: () => _selectDate(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.calendar_today,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Tanggal Lahir: ${_tglLahir.day}/${_tglLahir.month}/${_tglLahir.year}',
                                ),
                              ),
                              const Icon(Icons.edit, color: Colors.black38),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            isEditing ? 'Simpan Perubahan' : 'Tambah Pasien',
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

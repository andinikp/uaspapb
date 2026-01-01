import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/rekam_medis_repository.dart';
import '../repositories/antrian_repository.dart';
import '../repositories/resep_repository.dart';
import '../repositories/obat_repository.dart';
import '../models/obat_model.dart';
import '../models/resep_model.dart';
import '../models/antrian_model.dart';

class InputRMScreen extends StatefulWidget {
  final AntrianModel antrian;
  const InputRMScreen({super.key, required this.antrian});

  @override
  State<InputRMScreen> createState() => _InputRMScreenState();
}

class _InputRMScreenState extends State<InputRMScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _keluhanController = TextEditingController();
  final TextEditingController _diagnosaController = TextEditingController();
  final TextEditingController _tindakanController = TextEditingController();

  ObatModel? _selectedObat;
  final TextEditingController _jumlahResepController = TextEditingController();
  final TextEditingController _aturanPakaiController = TextEditingController();

  bool _membutuhkanResep = false;
  bool _loading = false;

  @override
  void dispose() {
    _keluhanController.dispose();
    _diagnosaController.dispose();
    _tindakanController.dispose();
    _jumlahResepController.dispose();
    _aturanPakaiController.dispose();
    super.dispose();
  }

  Future<void> _submitRM() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final rmRepo = Provider.of<RekamMedisRepository>(context, listen: false);
    final antrianRepo = Provider.of<AntrianRepository>(context, listen: false);
    final resepRepo = Provider.of<ResepRepository>(context, listen: false);

    final rmId = await rmRepo.addRekamMedis(
      antrianId: widget.antrian.antrianId,
      pasienId: widget.antrian.pasienId,
      dokterId: widget.antrian.dokterId,
      keluhan: _keluhanController.text.trim(),
      diagnosa: _diagnosaController.text.trim(),
      tindakan: _tindakanController.text.trim(),
      membutuhkanResep: _membutuhkanResep,
    );

    if (_membutuhkanResep) {
      // Jika membutuhkan resep, buat resep (walau bisa kosong jika dokter tidak mengisi detail obat)
      final obatRepo = Provider.of<ObatRepository>(context, listen: false);
      ResepDetailModel? detail;

      if (_selectedObat != null && _jumlahResepController.text.isNotEmpty) {
        ObatModel? matched;

        // cari kecocokan nama persis (case-insensitive)
        final exact = obatRepo.obatList.where(
          (o) =>
              o.namaObat.toLowerCase() == _selectedObat!.namaObat.toLowerCase(),
        );
        if (exact.isNotEmpty) matched = exact.first;

        // jika tidak ditemukan, coba pencocokan partial
        if (matched == null) {
          final partial = obatRepo.obatList.where(
            (o) => o.namaObat.toLowerCase().contains(
              _selectedObat!.namaObat.toLowerCase(),
            ),
          );
          if (partial.isNotEmpty) matched = partial.first;
        }

        // Jika matched ditemukan, gunakan data nyata; jika tidak, gunakan input dokter (harga 0)
        detail = ResepDetailModel(
          obatId: matched?.obatId ?? _selectedObat!.obatId,
          namaObat: matched?.namaObat ?? _selectedObat!.namaObat,
          jumlah: int.tryParse(_jumlahResepController.text) ?? 1,
          hargaSatuan: matched?.hargaJual ?? _selectedObat!.hargaJual,
          aturanPakai: _aturanPakaiController.text.trim(),
        );

        if (matched == null) {
          // beri tahu bahwa obat tidak ditemukan sehingga harga/stok tidak otomatis terhubung
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Perhatian: obat yang dimasukkan tidak ditemukan di inventaris, harganya akan tersimpan sebagai Rp 0 dan stok tidak akan berkurang saat diproses.',
                ),
                duration: Duration(seconds: 4),
              ),
            );
          }
        }
      }

      await resepRepo.addResep(
        rmId: rmId,
        pasienId: widget.antrian.pasienId,
        detailObat: detail == null ? [] : [detail],
      );

      // Karena ada resep, antrian menunggu apoteker dulu
      await antrianRepo.updateAntrianStatus(
        widget.antrian.antrianId,
        AntrianStatus.menungguObat,
      );
    } else {
      // Tidak ada resep: buat resep kosong sebagai notifikasi ke apotek, lalu langsung ke kasir
      await resepRepo.addResep(
        rmId: rmId,
        pasienId: widget.antrian.pasienId,
        detailObat: [],
      );

      await antrianRepo.updateAntrianStatus(
        widget.antrian.antrianId,
        AntrianStatus.selesai,
      );
    }

    setState(() => _loading = false);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Rekam medis tersimpan')));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Input RM - Antrian #${widget.antrian.nomorAntrian}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _keluhanController,
                decoration: const InputDecoration(
                  labelText: 'Keluhan',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Masukkan keluhan' : null,
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _diagnosaController,
                decoration: const InputDecoration(
                  labelText: 'Diagnosa',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Masukkan diagnosa' : null,
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tindakanController,
                decoration: const InputDecoration(
                  labelText: 'Tindakan',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Masukkan tindakan' : null,
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Membutuhkan Resep'),
                value: _membutuhkanResep,
                onChanged: (v) => setState(() => _membutuhkanResep = v),
              ),
              if (_membutuhkanResep) ...[
                const SizedBox(height: 8),
                // Sederhana: input nama obat dan jumlah (idealnya pakai dropdown dari ObatRepository)
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Nama Obat',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(
                    () => _selectedObat = ObatModel(
                      obatId: v,
                      namaObat: v,
                      hargaJual: 0,
                      stokSaatIni: 0,
                      satuan: 'pcs',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _jumlahResepController,
                  decoration: const InputDecoration(
                    labelText: 'Jumlah',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _aturanPakaiController,
                  decoration: const InputDecoration(
                    labelText: 'Aturan Pakai',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loading ? null : _submitRM,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Simpan RM'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

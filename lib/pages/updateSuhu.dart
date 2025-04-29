import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UpdateSuhuPage extends StatelessWidget {
  const UpdateSuhuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF2F5FC),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: UpdateSuhuContent()),
          ],
        ),
      ),
    );
  }
}

class UpdateSuhuContent extends StatefulWidget {
  const UpdateSuhuContent({super.key});

  @override
  State<UpdateSuhuContent> createState() => _UpdateSuhuContentState();
}

class _UpdateSuhuContentState extends State<UpdateSuhuContent> {
  final _minController = TextEditingController();
  final _maxController = TextEditingController();
  bool _isLoading = false;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    try {
      setState(() => _isLoading = true);

      final response = await _supabase
          .from('temperature_settings')
          .select()
          .order('updated_at', ascending: false)
          .limit(1)
          .single();

      if (mounted) {
        setState(() {
          _minController.text = response['min_temperature'].toString();
          _maxController.text = response['max_temperature'].toString();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memuat pengaturan suhu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveSettings() async {
    final min = double.tryParse(_minController.text);
    final max = double.tryParse(_maxController.text);

    if (min == null || max == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon masukkan angka yang valid'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (min >= max) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Suhu minimum harus lebih kecil dari suhu maksimum'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      await _supabase.from('temperature_settings').insert({
        'min_temperature': min,
        'max_temperature': max,
        'user_id': _supabase.auth.currentUser?.id,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sukses'),
            content: const Text('Pengaturan suhu berhasil disimpan'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan pengaturan suhu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Atur Batas Suhu',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text("Batas Suhu Minimum"),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _minController,
                        decoration: InputDecoration(
                          hintText: "Contoh: 24",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 20),
                      const Text("Batas Suhu Maksimum"),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _maxController,
                        decoration: InputDecoration(
                          hintText: "Contoh: 32",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveSettings,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.blue,
                          ),
                          child: const Text(
                            "Simpan",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }
}

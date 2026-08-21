import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _saldoKey = 'total_saldo';
  static const String _riwayatKey = 'riwayat';

  // ============================================================
  // SIMPAN DATA
  // ============================================================

  static Future<void> simpanDataLokal(
    int totalSaldo,
    List<Map<String, dynamic>> riwayat,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Simpan saldo
      await prefs.setInt(
        _saldoKey,
        totalSaldo,
      );

      // Ubah List<Map> menjadi List<String> JSON
      final List<String> dataStringList =
          riwayat.map((item) => jsonEncode(item)).toList();

      // Simpan riwayat
      await prefs.setStringList(
        _riwayatKey,
        dataStringList,
      );
    } catch (e) {
      // Mencegah aplikasi langsung crash jika terjadi masalah storage
      print('Gagal menyimpan data: $e');
    }
  }

  // ============================================================
  // MUAT DATA
  // ============================================================

  static Future<Map<String, dynamic>> muatDataLokal() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Ambil saldo
      final int saldo =
          prefs.getInt(_saldoKey) ?? 0;

      // Ambil riwayat
      final List<String>? dataStringList =
          prefs.getStringList(_riwayatKey);

      List<Map<String, dynamic>> riwayat = [];

      if (dataStringList != null) {
        riwayat = dataStringList.map((item) {
          try {
            final decoded = jsonDecode(item);

            return Map<String, dynamic>.from(decoded);
          } catch (e) {
            // Jika ada satu data JSON rusak,
            // data tersebut dilewati agar aplikasi tidak crash
            return <String, dynamic>{};
          }
        }).where((item) => item.isNotEmpty).toList();
      }

      return {
        'saldo': saldo,
        'riwayat': riwayat,
      };
    } catch (e) {
      print('Gagal memuat data: $e');

      // Jika terjadi error, kembalikan data default
      return {
        'saldo': 0,
        'riwayat': <Map<String, dynamic>>[],
      };
    }
  }
}
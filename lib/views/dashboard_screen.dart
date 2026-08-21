import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _totalSaldo = 0;

  List<Map<String, dynamic>> _riwayatPengeluaran = [];

  @override
  void initState() {
    super.initState();
    _muatDataLokal();
  }

  // ============================================================
  // SHAREDPREFERENCES
  // ============================================================

  Future<void> _muatDataLokal() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _totalSaldo = prefs.getInt('total_saldo') ?? 0;

      final List<String>? dataStringList =
          prefs.getStringList('riwayat');

      if (dataStringList != null) {
        _riwayatPengeluaran = dataStringList
            .map(
              (item) => jsonDecode(item) as Map<String, dynamic>,
            )
            .toList();
      }
    });
  }

  Future<void> _simpanDataLokal() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('total_saldo', _totalSaldo);

    final List<String> dataStringList = _riwayatPengeluaran
        .map(
          (item) => jsonEncode(item),
        )
        .toList();

    await prefs.setStringList(
      'riwayat',
      dataStringList,
    );
  }

  // ============================================================
  // TAMBAH PENGELUARAN
  // ============================================================

  void _tambahPengeluaran(
    String judul,
    int nominal,
  ) {
    if (nominal <= 0 || judul.trim().isEmpty) {
      return;
    }

    setState(() {
      _totalSaldo -= nominal;

      _riwayatPengeluaran.insert(
        0,
        {
          'judul': judul.trim(),
          'nominal': nominal,
          'tanggal': DateTime.now()
              .toString()
              .substring(0, 10),
        },
      );
    });

    _simpanDataLokal();
  }

  // ============================================================
  // MODAL BOTTOM SHEET
  // ============================================================

  void _tampilkanModalInput() {
    final judulController = TextEditingController();
    final nominalController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom:
                MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(28),
                bottom: Radius.circular(28),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // HANDLE
                  Center(
                    child: Container(
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // TITLE
                  const Text(
                    'Tambah Pengeluaran',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Catat pengeluaranmu agar uang saku tetap terkontrol.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // KETERANGAN
                  const Text(
                    'Keterangan',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextField(
                    controller: judulController,
                    textInputAction:
                        TextInputAction.next,
                    decoration: InputDecoration(
                      hintText:
                          'Contoh: Beli Pop Ice',
                      prefixIcon: const Icon(
                        Icons.receipt_long_outlined,
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // NOMINAL
                  const Text(
                    'Nominal Pengeluaran',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  TextField(
                    controller: nominalController,
                    keyboardType:
                        TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Contoh: 5000',
                      prefixIcon: const Icon(
                        Icons.payments_outlined,
                      ),
                      prefixText: 'Rp ',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // BUTTON SIMPAN
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final String judul =
                            judulController.text;

                        final int nominal =
                            int.tryParse(
                                  nominalController
                                      .text,
                                ) ??
                                0;

                        if (judul.trim().isEmpty ||
                            nominal <= 0) {
                          ScaffoldMessenger.of(ctx)
                              .showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Masukkan keterangan dan nominal yang valid.',
                              ),
                            ),
                          );

                          return;
                        }

                        _tambahPengeluaran(
                          judul,
                          nominal,
                        );

                        Navigator.pop(ctx);
                      },
                      icon: const Icon(
                        Icons.save_outlined,
                      ),
                      label: const Text(
                        'Simpan Pengeluaran',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // FORMAT RUPIAH
  // ============================================================

  String _formatRupiah(int angka) {
    final String angkaString =
        angka.abs().toString();

    String hasil = '';

    for (int i = 0;
        i < angkaString.length;
        i++) {
      if (i > 0 &&
          (angkaString.length - i) % 3 == 0) {
        hasil += '.';
      }

      hasil += angkaString[i];
    }

    return 'Rp $hasil';
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SakuSiswa',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // ==================================================
            // SALDO CARD
            // ==================================================

            Card(
              elevation: 0,
              color: Colors.teal,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(24),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,
                      children: [
                        const Text(
                          'Sisa Uang Saku',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                          ),
                        ),
                        Container(
                          padding:
                              const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white
                                .withOpacity(0.15),
                            borderRadius:
                                BorderRadius.circular(
                              12,
                            ),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_outlined,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Text(
                      _formatRupiah(
                        _totalSaldo,
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _totalSaldo += 50000;
                          });

                          _simpanDataLokal();
                        },
                        icon: const Icon(
                          Icons.add,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Isi Uang Saku +Rp50.000',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                        style:
                            OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Colors.white54,
                          ),
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            vertical: 12,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ==================================================
            // JUDUL RIWAYAT
            // ==================================================

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Riwayat Pengeluaran',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_riwayatPengeluaran.length} transaksi',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ==================================================
            // LISTVIEW
            // ==================================================

            Expanded(
              child: _riwayatPengeluaran.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons
                                .receipt_long_outlined,
                            size: 70,
                            color:
                                Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada pengeluaran',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.w600,
                              color:
                                  Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Yuk mulai catat pengeluaranmu.',
                            style: TextStyle(
                              color:
                                  Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount:
                          _riwayatPengeluaran.length,
                      itemBuilder:
                          (context, index) {
                        final item =
                            _riwayatPengeluaran[
                                index];

                        return Card(
                          elevation: 0,
                          margin:
                              const EdgeInsets.only(
                            bottom: 10,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              16,
                            ),
                            side: BorderSide(
                              color: Colors
                                  .grey.shade200,
                            ),
                          ),
                          child: ListTile(
                            contentPadding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            leading: CircleAvatar(
                              backgroundColor:
                                  Colors.red
                                      .withOpacity(
                                0.1,
                              ),
                              child: const Icon(
                                Icons
                                    .shopping_bag_outlined,
                                color: Colors.red,
                              ),
                            ),
                            title: Text(
                              item['judul']
                                  .toString(),
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                            subtitle: Padding(
                              padding:
                                  const EdgeInsets
                                      .only(
                                top: 4,
                              ),
                              child: Text(
                                item['tanggal']
                                    .toString(),
                              ),
                            ),
                            trailing: Text(
                              '- ${_formatRupiah(
                                item['nominal']
                                    as int,
                              )}',
                              style:
                                  const TextStyle(
                                color: Colors.red,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

      // ========================================================
      // FLOATING ACTION BUTTON
      // ========================================================

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: _tampilkanModalInput,
        icon: const Icon(
          Icons.add,
        ),
        label: const Text(
          'Catat Pengeluaran',
        ),
      ),
    );
  }
}
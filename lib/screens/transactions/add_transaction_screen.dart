import 'package:amplopku/core/constants/colors.dart';
import 'package:amplopku/core/utils/currency.dart';
import 'package:amplopku/models/envelope_model.dart';
import 'package:amplopku/services/auth_service.dart';
import 'package:amplopku/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/icon_helper.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({
    super.key,
    this.onTransactionSaved,
  });

  /// Dipanggil setelah transaksi berhasil disimpan.
  /// Pada navigasi utama, callback ini mengembalikan pengguna ke Beranda.
  final VoidCallback? onTransactionSaved;

  @override
  State<AddTransactionScreen> createState() {
    return _AddTransactionScreenState();
  }
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  bool _isIncome = false;
  bool _isLoading = false;

  String _selectedEnvelopeId = '';
  String _detectedIcon = 'wallet';

  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    _titleController.addListener(_updateDetectedIcon);
  }

  @override
  void dispose() {
    _titleController.removeListener(_updateDetectedIcon);

    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();

    super.dispose();
  }

  void _updateDetectedIcon() {
    final String detectedIcon = IconHelper.detectIconName(
      _titleController.text,
      isIncome: _isIncome,
    );

    if (detectedIcon != _detectedIcon && mounted) {
      setState(() {
        _detectedIcon = detectedIcon;
      });
    }
  }

  void _changeTransactionType(bool isIncome) {
    setState(() {
      _isIncome = isIncome;

      if (_isIncome) {
        _selectedEnvelopeId = '';
      }

      _detectedIcon = IconHelper.detectIconName(
        _titleController.text,
        isIncome: _isIncome,
      );
    });
  }

  double get _amount {
    final String cleanValue = _amountController.text
        .replaceAll('.', '')
        .replaceAll(',', '')
        .trim();

    return double.tryParse(cleanValue) ?? 0.0;
  }

  Future<void> _selectDate() async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDate = selectedDate;
    });
  }

  void _resetForm() {
    _titleController.clear();
    _amountController.clear();
    _noteController.clear();
    _formKey.currentState?.reset();

    if (!mounted) {
      return;
    }

    setState(() {
      _isIncome = false;
      _selectedEnvelopeId = '';
      _selectedDate = DateTime.now();
      _detectedIcon = 'wallet';
    });
  }

  Future<void> _saveTransaction() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = _authService.currentUser;

    if (user == null) {
      if (!mounted) {
        return;
      }

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );

      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _firestoreService.addTransaction(
        uid: user.uid,
        title: _titleController.text.trim(),
        description: _noteController.text.trim(),
        amount: _amount,
        type: _isIncome ? 'income' : 'expense',
        envelopeId: _isIncome ? '' : _selectedEnvelopeId,
        icon: _detectedIcon,
        date: _selectedDate,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isIncome
                ? 'Pemasukan berhasil disimpan'
                : 'Pengeluaran berhasil disimpan',
          ),
        ),
      );

      _resetForm();

      // Halaman Tambah berada di dalam IndexedStack, bukan route terpisah.
      // Karena itu jangan Navigator.pop(), sebab pada Flutter Web tindakan
      // tersebut dapat menghapus route /home dan menghasilkan layar putih.
      if (widget.onTransactionSaved != null) {
        widget.onTransactionSaved!();
      } else if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Transaksi'),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _firestoreService.getEnvelopes(user.uid),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Gagal memuat amplop.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final List<EnvelopeModel> envelopes =
                snapshot.data?.docs.map((document) {
                      return EnvelopeModel.fromMap(
                        document.id,
                        document.data(),
                      );
                    }).toList() ??
                    <EnvelopeModel>[];

            final bool selectedEnvelopeExists =
                _selectedEnvelopeId.isEmpty ||
                envelopes.any(
                  (envelope) => envelope.id == _selectedEnvelopeId,
                );

            if (!selectedEnvelopeExists) {
              _selectedEnvelopeId = '';
            }

            EnvelopeModel? selectedEnvelope;

            for (final EnvelopeModel envelope in envelopes) {
              if (envelope.id == _selectedEnvelopeId) {
                selectedEnvelope = envelope;
                break;
              }
            }

            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildTransactionTypeSelector(),

                  const SizedBox(height: 24),

                  _buildIconPreview(),

                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _titleController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Nama transaksi',
                      hintText: _isIncome
                          ? 'Contoh: Gaji bulanan'
                          : 'Contoh: Servis laptop',
                      prefixIcon: Icon(
                        IconHelper.getIcon(_detectedIcon),
                        color: AppColors.primary,
                      ),
                    ),
                    validator: (value) {
                      final String title = value?.trim() ?? '';

                      if (title.isEmpty) {
                        return 'Nama transaksi wajib diisi';
                      }

                      if (title.length < 2) {
                        return 'Nama transaksi terlalu pendek';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  if (!_isIncome) ...[
                    DropdownButtonFormField<String>(
                      key: ValueKey<String>(
                        'envelope-$_selectedEnvelopeId-${envelopes.length}',
                      ),
                      initialValue: _selectedEnvelopeId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Pilih amplop',
                        helperText:
                            'Opsional. Pilih Tanpa amplop untuk transaksi lainnya.',
                        prefixIcon: Icon(
                          Icons.account_balance_wallet_outlined,
                        ),
                      ),
                      items: <DropdownMenuItem<String>>[
                        const DropdownMenuItem<String>(
                          value: '',
                          child: Row(
                            children: [
                              Icon(
                                Icons.category_outlined,
                                color: AppColors.textGrey,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Tanpa amplop / Lainnya',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                        ...envelopes.map(
                          (EnvelopeModel envelope) {
                            final bool budgetTersedia =
                                envelope.balance > 0;

                            return DropdownMenuItem<String>(
                              value: envelope.id,
                              enabled: budgetTersedia,
                              child: Row(
                                children: [
                                  Icon(
                                    IconHelper.getIcon(envelope.icon),
                                    color: envelope.envelopeColor,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      envelope.nama,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    budgetTersedia
                                        ? rupiah(envelope.balance)
                                        : 'Budget habis',
                                    style: TextStyle(
                                      color: budgetTersedia
                                          ? AppColors.textGrey
                                          : Colors.red,
                                      fontSize: 12,
                                      fontWeight: budgetTersedia
                                          ? FontWeight.normal
                                          : FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                      onChanged: (String? value) {
                        setState(() {
                          _selectedEnvelopeId = value ?? '';
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              envelopes.isEmpty
                                  ? 'Kamu belum mempunyai amplop. Transaksi tetap bisa disimpan sebagai Tanpa amplop.'
                                  : selectedEnvelope == null
                                      ? 'Pilih amplop yang masih memiliki sisa budget. Amplop yang budgetnya habis tidak dapat digunakan.'
                                      : selectedEnvelope.balance <= 0
                                          ? 'Budget ${selectedEnvelope.nama} sudah habis. Pilih amplop lain atau pilih Tanpa amplop.'
                                          : 'Sisa budget ${selectedEnvelope.nama}: ${rupiah(selectedEnvelope.balance)}.',
                              style: const TextStyle(
                                color: AppColors.textGrey,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],

                  // ==========================
                  // NOMINAL (SUDAH DIPERBAIKI)
                  // ==========================
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Nominal',
                      hintText: '25000',
                      prefixText: 'Rp ',
                      prefixIcon: Icon(
                        Icons.payments_outlined,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nominal wajib diisi';
                      }

                      if (_amount <= 0) {
                        return 'Masukkan nominal yang valid';
                      }

                      if (!_isIncome && _selectedEnvelopeId.isNotEmpty) {
                        if (selectedEnvelope == null) {
                          return 'Amplop tidak ditemukan. Pilih ulang amplop';
                        }

                        if (selectedEnvelope.balance <= 0) {
                          return 'Budget amplop ${selectedEnvelope.nama} sudah habis';
                        }

                        if (_amount > selectedEnvelope.balance) {
                          return 'Nominal melebihi sisa budget ${rupiah(selectedEnvelope.balance)}';
                        }
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _noteController,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Catatan',
                      hintText: 'Catatan tambahan, opsional',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(
                        Icons.notes_rounded,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  InkWell(
                    onTap: _selectDate,
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.border,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_month_rounded,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tanggal transaksi',
                                  style: TextStyle(
                                    color: AppColors.textGrey,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  formatDate(_selectedDate),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveTransaction,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              IconHelper.getIcon(_detectedIcon),
                            ),
                      label: Text(
                        _isLoading
                            ? 'Menyimpan...'
                            : 'Simpan Transaksi',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTransactionTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildTypeButton(
            label: 'Pengeluaran',
            icon: Icons.arrow_upward_rounded,
            selected: !_isIncome,
            onTap: () {
              _changeTransactionType(false);
            },
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _buildTypeButton(
            label: 'Pemasukan',
            icon: Icons.arrow_downward_rounded,
            selected: _isIncome,
            onTap: () {
              _changeTransactionType(true);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTypeButton({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : AppColors.textGrey,
              size: 20,
            ),

            const SizedBox(width: 8),

            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconPreview() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (
              Widget child,
              Animation<double> animation,
            ) {
              return ScaleTransition(
                scale: animation,
                child: child,
              );
            },

            child: Container(
              key: ValueKey<String>(_detectedIcon),
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(18),
              ),

              child: Icon(
                IconHelper.getIcon(_detectedIcon),
                color: Colors.white,
                size: 28,
              ),
            ),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ikon otomatis',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  'Ikon berubah mengikuti nama transaksi yang kamu ketik.',
                  style: TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
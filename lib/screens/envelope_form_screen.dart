import 'package:amplopku/core/constants/colors.dart';
import 'package:amplopku/core/utils/currency.dart';
import 'package:amplopku/core/utils/icon_helper.dart';
import 'package:amplopku/models/envelope_model.dart';
import 'package:amplopku/services/auth_service.dart';
import 'package:amplopku/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EnvelopeFormScreen extends StatefulWidget {
  final EnvelopeModel? envelope;
  final double monthlyIncome;

  const EnvelopeFormScreen({
    super.key,
    this.envelope,
    required this.monthlyIncome,
  });

  bool get isEditing {
    return envelope != null;
  }

  @override
  State<EnvelopeFormScreen> createState() {
    return _EnvelopeFormScreenState();
  }
}

class _EnvelopeFormScreenState
    extends State<EnvelopeFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _budgetController;

  bool _isSaving = false;

  late int _selectedColor;
  late String _selectedIcon;

  static const List<int> _colors = [
    0xFF16A34A,
    0xFF3B82F6,
    0xFFF97316,
    0xFFEF4444,
    0xFF8B5CF6,
    0xFFEC4899,
    0xFF06B6D4,
    0xFF64748B,
  ];

  @override
  void initState() {
    super.initState();

    final envelope = widget.envelope;

    _nameController = TextEditingController(
      text: envelope?.nama ?? '',
    );

    _budgetController = TextEditingController(
      text: envelope == null
          ? ''
          : envelope.budget.toStringAsFixed(0),
    );

    _selectedColor = envelope?.color ?? _colors.first;

    _selectedIcon = envelope?.icon.isNotEmpty == true
        ? envelope!.icon
        : IconHelper.detectIconName(
            envelope?.nama ?? '',
          );

    _nameController.addListener(_updateAutomaticIcon);
  }

  @override
  void dispose() {
    _nameController.removeListener(_updateAutomaticIcon);
    _nameController.dispose();
    _budgetController.dispose();

    super.dispose();
  }

  void _updateAutomaticIcon() {
    final detectedIcon = IconHelper.detectIconName(
      _nameController.text,
    );

    if (detectedIcon != _selectedIcon && mounted) {
      setState(() {
        _selectedIcon = detectedIcon;
      });
    }
  }

  double get _budget {
    final cleanValue = _budgetController.text
        .replaceAll('.', '')
        .replaceAll(',', '')
        .trim();

    return double.tryParse(cleanValue) ?? 0;
  }

  double get _percentage {
    if (widget.monthlyIncome <= 0) {
      return 0;
    }

    return (_budget / widget.monthlyIncome) * 100;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = AuthService().currentUser;

    if (user == null) {
      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (_) => false,
      );

      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (widget.isEditing) {
        await FirestoreService().updateEnvelope(
          uid: user.uid,
          envelopeId: widget.envelope!.id,
          nama: _nameController.text.trim(),
          percentage: _percentage,
          budget: _budget,
          color: _selectedColor,
          icon: _selectedIcon,
        );
      } else {
        await FirestoreService().saveEnvelope(
          uid: user.uid,
          nama: _nameController.text.trim(),
          percentage: _percentage,
          budget: _budget,
          color: _selectedColor,
          icon: _selectedIcon,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Amplop berhasil diperbarui'
                : 'Amplop berhasil ditambahkan',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error
                .toString()
                .replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final envelopeColor = Color(_selectedColor);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing
              ? 'Edit Amplop'
              : 'Tambah Amplop',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                widget.isEditing
                    ? 'Perbarui data amplop'
                    : 'Buat amplop baru',
                style:
                    Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Ikon akan dipilih secara otomatis berdasarkan nama amplop.',
                style: TextStyle(
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: envelopeColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: envelopeColor.withOpacity(0.24),
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedSwitcher(
                      duration:
                          const Duration(milliseconds: 200),
                      transitionBuilder: (
                        child,
                        animation,
                      ) {
                        return ScaleTransition(
                          scale: animation,
                          child: child,
                        );
                      },
                      child: Container(
                        key: ValueKey(_selectedIcon),
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: envelopeColor,
                          borderRadius:
                              BorderRadius.circular(18),
                        ),
                        child: Icon(
                          IconHelper.getIcon(
                            _selectedIcon,
                          ),
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nameController.text
                                    .trim()
                                    .isEmpty
                                ? 'Nama amplop'
                                : _nameController.text
                                    .trim(),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            rupiah(_budget),
                            style: TextStyle(
                              color: envelopeColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameController,
                textCapitalization:
                    TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Nama amplop',
                  hintText:
                      'Contoh: Makan, Kos, Transportasi',
                  prefixIcon: Icon(
                    IconHelper.getIcon(_selectedIcon),
                    color: envelopeColor,
                  ),
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Nama amplop wajib diisi';
                  }

                  if (value.trim().length < 2) {
                    return 'Nama amplop terlalu pendek';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (_) {
                  setState(() {});
                },
                decoration: const InputDecoration(
                  labelText: 'Budget amplop',
                  hintText: '1000000',
                  prefixText: 'Rp ',
                  prefixIcon: Icon(
                    Icons.payments_outlined,
                  ),
                ),
                validator: (_) {
                  if (_budget <= 0) {
                    return 'Masukkan budget yang valid';
                  }

                  if (widget.isEditing &&
                      _budget <
                          (widget.envelope?.spent ?? 0)) {
                    return 'Budget tidak boleh lebih kecil dari dana yang sudah terpakai';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:
                      AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.pie_chart_outline_rounded,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.monthlyIncome > 0
                            ? '${rupiah(_budget)} = '
                                '${_percentage.toStringAsFixed(1)}% '
                                'dari pendapatan bulanan'
                            : rupiah(_budget),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),

              Text(
                'Pilih warna',
                style:
                    Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _colors.map((value) {
                  final selected =
                      _selectedColor == value;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedColor = value;
                      });
                    },
                    borderRadius:
                        BorderRadius.circular(99),
                    child: AnimatedContainer(
                      duration:
                          const Duration(milliseconds: 180),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Color(value),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? Colors.black87
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: selected
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 21,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed:
                      _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          IconHelper.getIcon(
                            _selectedIcon,
                          ),
                        ),
                  label: Text(
                    _isSaving
                        ? 'Menyimpan...'
                        : widget.isEditing
                            ? 'Simpan Perubahan'
                            : 'Tambah Amplop',
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
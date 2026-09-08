import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EnvelopeSliderCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final double percentage;
  final double income;
  final ValueChanged<double> onChanged;

  const EnvelopeSliderCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.percentage,
    required this.income,
    required this.onChanged,
  });

  String formatCurrency(double value) {
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return format.format(value);
  }

  @override
  Widget build(BuildContext context) {
    final nominal = income * percentage / 100;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(.15),
                  child: Icon(
                    icon,
                    color: color,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    "${percentage.toInt()}%",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              ],
            ),

            const SizedBox(height: 20),

            Slider(
              value: percentage,
              min: 0,
              max: 100,
              divisions: 100,
              activeColor: color,
              label: percentage.toInt().toString(),
              onChanged: onChanged,
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Nominal",
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
                Text(
                  formatCurrency(nominal),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RiwayatPage extends StatelessWidget {
  const RiwayatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FC),
      body: const SafeArea(
        child: Column(
          children: [
            Expanded(child: RiwayatContent()),
          ],
        ),
      ),
    );
  }
}

class RiwayatContent extends StatelessWidget {
  const RiwayatContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Riwayat Pemanas',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Pilih Tanggal:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _DateDropdown(date: '22/04/2025')),
              const SizedBox(width: 12),
              const Icon(Icons.remove, color: Colors.grey),
              const SizedBox(width: 12),
              Expanded(child: _DateDropdown(date: '22/04/2025')),
            ],
          ),
          const SizedBox(height: 20),
          const Expanded(child: _TemperatureHistoryList()),
        ],
      ),
    );
  }
}

class _DateDropdown extends StatelessWidget {
  final String date;
  const _DateDropdown({required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: date,
          items: [DropdownMenuItem(value: date, child: Text(date))],
          onChanged: (value) {},
          icon: const Icon(Icons.arrow_drop_down),
        ),
      ),
    );
  }
}

class _TemperatureHistoryList extends StatelessWidget {
  const _TemperatureHistoryList();

  @override
  Widget build(BuildContext context) {
    final historyData = List.generate(4, (_) => {
          "day": "Selasa",
          "date": "22/04/2025",
          "time": "04:50:23",
        });

    return ListView.builder(
      itemCount: historyData.length,
      itemBuilder: (context, index) {
        final item = historyData[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.storage, size: 32),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['day']!,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    item['date']!,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                item['time']!,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }
}

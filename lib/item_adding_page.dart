
import 'package:flutter/material.dart';

class ItemAddingPage extends StatefulWidget {
  const ItemAddingPage({super.key});

  @override
  _ItemAddingPageState createState() => _ItemAddingPageState();
}

class _ItemAddingPageState extends State<ItemAddingPage> {
  String? selectedStore; // Selected store from the dropdown
  DateTimeRange? dateRange; // Date range for availability

  // List of store options
  final List<String> stores = ["City Gross", "Willys", "Lidl", "Rusta", "Xtra"];

  // Method to pick date range
  Future<void> pickDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: dateRange,
    );
    if (picked != null) {
      setState(() {
        dateRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload New Ad'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Dropdown for selecting store
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Select Store',
                border: OutlineInputBorder(),
              ),
              value: selectedStore,
              items: stores
                  .map((store) => DropdownMenuItem<String>(
                        value: store,
                        child: Text(store),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedStore = value;
                });
              },
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Ad Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Price',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  items: ['KG', 'ST']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) {},
                  hint: const Text('Unit'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Member Price (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => pickDateRange(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  dateRange == null
                      ? 'Select Date Range'
                      : '${dateRange!.start.toLocal()} to ${dateRange!.end.toLocal()}',
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (selectedStore == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a store!')),
                  );
                  return;
                }

                // Action to upload ad
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Ad uploaded for store: $selectedStore successfully!')),
                );
              },
              child: const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }
}


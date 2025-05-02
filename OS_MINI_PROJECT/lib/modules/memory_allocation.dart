import 'package:flutter/material.dart';

class MemoryAllocationScreen extends StatefulWidget {
  @override
  _MemoryAllocationScreenState createState() => _MemoryAllocationScreenState();
}

class _MemoryAllocationScreenState extends State<MemoryAllocationScreen> {
  final _blockController = TextEditingController();
  final _processController = TextEditingController();

  List<int> memoryBlocks = [];
  List<int> processes = [];
  List<String> allocations = [];
  List<int> originalBlocks = [];
  List<int> currentBlocks = [];

  String _getAlgorithmStatus() {
    if (_blockController.text.isEmpty || _processController.text.isEmpty) {
      return "Enter blocks and processes to start";
    }
    if (allocations.isEmpty) {
      return "Click an algorithm to allocate";
    }
    return allocations.any((a) => a.contains("Not Allocated"))
        ? "Partial Allocation (Some processes couldn't be allocated)"
        : "Success (All processes allocated)";
  }

  void firstFit() {
    setState(() {
      allocations.clear();
      currentBlocks = List.from(originalBlocks);

      for (int i = 0; i < processes.length; i++) {
        bool allocated = false;
        for (int j = 0; j < currentBlocks.length; j++) {
          if (currentBlocks[j] >= processes[i]) {
            final originalSize = originalBlocks[j];
            final remainingSize = currentBlocks[j] - processes[i];
            allocations.add(
              'P${i + 1} (${processes[i]}KB) → Block ${j + 1} (Original: ${originalSize}KB, Remaining: ${remainingSize}KB)',
            );
            currentBlocks[j] = remainingSize;
            allocated = true;
            break;
          }
        }
        if (!allocated) {
          allocations.add(
            'P${i + 1} (${processes[i]}KB) → Not Allocated (No suitable block)',
          );
        }
      }
    });
  }

  void bestFit() {
    setState(() {
      allocations.clear();
      currentBlocks = List.from(originalBlocks);

      for (int i = 0; i < processes.length; i++) {
        int bestIdx = -1;
        int minDiff = 999999; // Large number instead of double.maxFinite

        for (int j = 0; j < currentBlocks.length; j++) {
          int diff = currentBlocks[j] - processes[i];
          if (diff >= 0 && diff < minDiff) {
            minDiff = diff;
            bestIdx = j;
          }
        }

        if (bestIdx != -1) {
          final originalSize = originalBlocks[bestIdx];
          final remainingSize = currentBlocks[bestIdx] - processes[i];
          allocations.add(
            'P${i + 1} (${processes[i]}KB) → Block ${bestIdx + 1} (Original: ${originalSize}KB, Remaining: ${remainingSize}KB)',
          );
          currentBlocks[bestIdx] = remainingSize;
        } else {
          allocations.add(
            'P${i + 1} (${processes[i]}KB) → Not Allocated (No suitable block)',
          );
        }
      }
    });
  }

  void updateInputs() {
    setState(() {
      memoryBlocks = _blockController.text
          .split(',')
          .where((s) => s.trim().isNotEmpty)
          .map((s) => int.tryParse(s.trim()) ?? 0)
          .where((num) => num > 0)
          .toList();

      processes = _processController.text
          .split(',')
          .where((s) => s.trim().isNotEmpty)
          .map((s) => int.tryParse(s.trim()) ?? 0)
          .where((num) => num > 0)
          .toList();

      originalBlocks = List.from(memoryBlocks);
      currentBlocks = List.from(memoryBlocks);
      allocations.clear();
    });
  }

  void clearAll() {
    setState(() {
      _blockController.clear();
      _processController.clear();
      memoryBlocks.clear();
      processes.clear();
      originalBlocks.clear();
      currentBlocks.clear();
      allocations.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Memory Allocation Simulator",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, size: 28),
            onPressed: clearAll,
            tooltip: "Clear All",
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue.withOpacity(0.1), Colors.white],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.all(constraints.maxWidth > 600 ? 24 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade50, Colors.white],
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.memory,
                                    color: Colors.blue, size: 28),
                                SizedBox(width: 12),
                                Text(
                                  "Memory Blocks",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            TextField(
                              controller: _blockController,
                              decoration: InputDecoration(
                                labelText:
                                    "Enter block sizes (comma separated)",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                hintText: "e.g. 100, 500, 200, 300, 600",
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: Icon(Icons.dashboard_customize),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: LinearGradient(
                            colors: [Colors.purple.shade50, Colors.white],
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.settings_applications,
                                    color: Colors.purple, size: 28),
                                SizedBox(width: 12),
                                Text(
                                  "Processes",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple.shade900,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            TextField(
                              controller: _processController,
                              decoration: InputDecoration(
                                labelText:
                                    "Enter process sizes (comma separated)",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                hintText: "e.g. 212, 417, 112, 426",
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: Icon(Icons.app_settings_alt),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 32),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          icon: Icon(Icons.search,
                              size: 24, color: Colors.blue.shade900),
                          label: Text(
                            "First-Fit",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: constraints.maxWidth > 600 ? 32 : 16,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.blue.shade100,
                            elevation: 8,
                            shadowColor: Colors.blue.withOpacity(0.5),
                          ),
                          onPressed: () {
                            updateInputs();
                            if (memoryBlocks.isNotEmpty &&
                                processes.isNotEmpty) {
                              firstFit();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      "Please enter valid block and process sizes"),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                        ElevatedButton.icon(
                          icon: Icon(Icons.zoom_out_map,
                              size: 24, color: Colors.purple.shade900),
                          label: Text(
                            "Best-Fit",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade900,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: constraints.maxWidth > 600 ? 32 : 16,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.purple.shade100,
                            elevation: 8,
                            shadowColor: Colors.purple.withOpacity(0.5),
                          ),
                          onPressed: () {
                            updateInputs();
                            if (memoryBlocks.isNotEmpty &&
                                processes.isNotEmpty) {
                              bestFit();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      "Please enter valid block and process sizes"),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 32),
                    Text(
                      "Allocation Results",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    SizedBox(height: 16),
                    if (allocations.isEmpty)
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "No allocations yet. Enter block and process sizes above.",
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: constraints.maxWidth,
                          ),
                          child: Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                gradient: LinearGradient(
                                  colors: [Colors.grey.shade50, Colors.white],
                                ),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        vertical: 8, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: allocations.any((a) =>
                                              a.contains("Not Allocated"))
                                          ? Colors.orange.shade100
                                          : Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _getAlgorithmStatus(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: allocations.any((a) =>
                                                a.contains("Not Allocated"))
                                            ? Colors.orange.shade900
                                            : Colors.green.shade900,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  ...allocations
                                      .map((allocation) => Container(
                                            margin: EdgeInsets.only(bottom: 12),
                                            padding: EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color: allocation
                                                      .contains("Not Allocated")
                                                  ? Colors.orange.shade50
                                                  : Colors.green.shade50,
                                              border: Border.all(
                                                color: allocation.contains(
                                                        "Not Allocated")
                                                    ? Colors.orange.shade200
                                                    : Colors.green.shade200,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  allocation.contains(
                                                          "Not Allocated")
                                                      ? Icons.warning
                                                      : Icons.check_circle,
                                                  color: allocation.contains(
                                                          "Not Allocated")
                                                      ? Colors.orange
                                                      : Colors.green,
                                                  size: 24,
                                                ),
                                                SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    allocation,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: allocation.contains(
                                                              "Not Allocated")
                                                          ? Colors
                                                              .orange.shade900
                                                          : Colors
                                                              .green.shade900,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ))
                                      .toList(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

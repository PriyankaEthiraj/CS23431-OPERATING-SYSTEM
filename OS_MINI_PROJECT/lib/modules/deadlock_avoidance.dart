import 'package:flutter/material.dart';

class BankersAlgorithmScreen extends StatefulWidget {
  @override
  _BankersAlgorithmScreenState createState() => _BankersAlgorithmScreenState();
}

class _BankersAlgorithmScreenState extends State<BankersAlgorithmScreen> {
  final _formKey = GlobalKey<FormState>();
  int numProcesses = 3;
  int numResources = 3;
  List<List<int>> allocation = [];
  List<List<int>> max = [];
  List<int> available = [];
  List<int> totalResources = [];
  List<List<int>> need = [];
  List<int> safeSequence = [];
  String resultMessage = '';
  bool isSafe = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    setState(() {
      allocation =
          List.generate(numProcesses, (i) => List.filled(numResources, 0));
      max = List.generate(numProcesses, (i) => List.filled(numResources, 0));
      available = List.filled(numResources, 0);
      totalResources = List.filled(numResources, 0);
      need = List.generate(numProcesses, (i) => List.filled(numResources, 0));
    });
  }

  void _calculateNeed() {
    setState(() {
      need = List.generate(
        numProcesses,
        (i) => List.generate(numResources, (j) => max[i][j] - allocation[i][j]),
      );
    });
  }

  void _checkSafety() {
    setState(() {
      safeSequence.clear();
      resultMessage = '';
      isSafe = false;
    });

    List<int> work = List.from(available);
    List<bool> finish = List.filled(numProcesses, false);
    int count = 0;

    while (count < numProcesses) {
      bool found = false;

      for (int i = 0; i < numProcesses; i++) {
        if (!finish[i]) {
          bool canAllocate = true;
          for (int j = 0; j < numResources; j++) {
            if (need[i][j] > work[j]) {
              canAllocate = false;
              break;
            }
          }

          if (canAllocate) {
            for (int j = 0; j < numResources; j++) {
              work[j] += allocation[i][j];
            }
            safeSequence.add(i);
            finish[i] = true;
            found = true;
            count++;
          }
        }
      }

      if (!found) {
        break;
      }
    }

    setState(() {
      isSafe = count == numProcesses;
      resultMessage = isSafe
          ? 'System is in a safe state. Safe sequence: ${safeSequence.map((p) => 'P$p').join(' → ')}'
          : 'System is not in a safe state (deadlock possible)';
    });
  }

  void _resetData() {
    setState(() {
      _initializeData();
      safeSequence.clear();
      resultMessage = '';
      isSafe = false;
    });
  }

  Widget _buildMatrixInput(String title, List<List<int>> matrix,
      Function(int, int, String) onChanged) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12), // Reduced padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16, // Reduced font size
                color: Colors.purple.shade400, // Lighter color
              ),
            ),
            Divider(height: 16), // Reduced height
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(width: 50), // Reduced width
                      ...List.generate(
                        numResources,
                        (j) => Container(
                          width: 60, // Reduced width
                          padding: EdgeInsets.symmetric(
                              vertical: 4), // Reduced padding
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            'R$j',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  ...List.generate(
                    numProcesses,
                    (i) => Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'P$i',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade700,
                              ),
                            ),
                          ),
                          ...List.generate(
                            numResources,
                            (j) => Container(
                              width: 70,
                              margin: EdgeInsets.symmetric(horizontal: 4),
                              child: TextFormField(
                                initialValue: matrix[i][j].toString(),
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.purple.shade900,
                                ),
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 8,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.purple.shade200,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.purple.shade400,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                onChanged: (value) => onChanged(i, j, value),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalResourcesInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total Resources (Optional)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(
              numResources,
              (j) => Container(
                width: 60,
                child: Column(
                  children: [
                    Text('R$j', textAlign: TextAlign.center),
                    SizedBox(height: 4),
                    TextFormField(
                      initialValue: totalResources[j].toString(),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          totalResources[j] = int.tryParse(value) ?? 0;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Resources',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 8),
        Row(
          children: List.generate(numResources, (j) {
            return Container(
              width: 60,
              margin: EdgeInsets.only(right: 8),
              child: Column(
                children: [
                  Text('R$j', textAlign: TextAlign.center),
                  SizedBox(height: 4),
                  TextFormField(
                    initialValue: available[j].toString(),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        available[j] = int.tryParse(value) ?? 0;
                      });
                    },
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildNeedMatrix() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Need Matrix (Max - Allocation)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(width: 60),
                  ...List.generate(
                    numResources,
                    (j) => Container(
                      width: 60,
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('R$j', textAlign: TextAlign.center),
                    ),
                  ),
                ],
              ),
              ...List.generate(
                numProcesses,
                (i) => Row(
                  children: [
                    Container(
                      width: 60,
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('P$i', textAlign: TextAlign.center),
                    ),
                    ...List.generate(
                      numResources,
                      (j) => Container(
                        width: 60,
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          need[i][j].toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Banker's Algorithm",
          style: TextStyle(
            color: Colors.purple.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.purple.shade700),
            onPressed: _resetData,
            tooltip: 'Reset Data',
          ),
        ],
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(8), // Reduced padding
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'Processes',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade700,
                                ),
                              ),
                              SizedBox(height: 8),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.purple.shade200),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButton<int>(
                                  value: numProcesses,
                                  isExpanded: true,
                                  underline: SizedBox(),
                                  items: [1, 2, 3, 4, 5].map((int value) {
                                    return DropdownMenuItem<int>(
                                      value: value,
                                      child: Text('$value'),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      numProcesses = value!;
                                      _initializeData();
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'Resources',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade700,
                                ),
                              ),
                              SizedBox(height: 8),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.purple.shade200),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButton<int>(
                                  value: numResources,
                                  isExpanded: true,
                                  underline: SizedBox(),
                                  items: [1, 2, 3, 4, 5].map((int value) {
                                    return DropdownMenuItem<int>(
                                      value: value,
                                      child: Text('$value'),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      numResources = value!;
                                      _initializeData();
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                _buildMatrixInput(
                  'Allocation Matrix',
                  allocation,
                  (i, j, value) {
                    setState(() {
                      allocation[i][j] = int.tryParse(value) ?? 0;
                    });
                  },
                ),
                SizedBox(height: 16),
                _buildMatrixInput(
                  'Maximum Claim Matrix',
                  max,
                  (i, j, value) {
                    setState(() {
                      max[i][j] = int.tryParse(value) ?? 0;
                    });
                  },
                ),
                SizedBox(height: 16),
                _buildTotalResourcesInput(),
                SizedBox(height: 16),
                _buildAvailableInput(),
                SizedBox(height: 16),
                // Replace Wrap with Column for vertical button layout
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _calculateNeed,
                        icon: Icon(Icons.calculate,
                            color: Colors.purple.shade700),
                        label: Text('Calculate Need Matrix'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade100,
                          foregroundColor: Colors.purple.shade700,
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _checkSafety,
                        icon:
                            Icon(Icons.security, color: Colors.purple.shade700),
                        label: Text('Check Safety'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade200,
                          foregroundColor: Colors.purple.shade700,
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                if (need.any((row) => row.any((cell) => cell != 0))) ...[
                  _buildNeedMatrix(),
                  SizedBox(height: 16),
                ],
                if (resultMessage.isNotEmpty) ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width - 32,
                        minWidth: 300,
                      ),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSafe ? Colors.green[50] : Colors.red[50],
                        border: Border.all(
                          color: isSafe ? Colors.green : Colors.red,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        resultMessage,
                        style: TextStyle(
                          color: isSafe ? Colors.green[800] : Colors.red[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:math';

import 'package:flutter/material.dart';

class CPUSchedulingScreen extends StatefulWidget {
  @override
  _CPUSchedulingScreenState createState() => _CPUSchedulingScreenState();
}

class _CPUSchedulingScreenState extends State<CPUSchedulingScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  List<String> _processIds = [];
  List<int> _burstTimes = [];
  List<int> _arrivalTimes = [];
  List<int> _priorities = [];
  List<int> _waitingTimes = [];
  List<int> _turnaroundTimes = [];
  List<int> _remainingTimes = [];
  int _timeQuantum = 2;

  String processId = '';
  int burstTime = 0;
  int arrivalTime = 0;
  int priority = 0;
  String _selectedAlgorithm = 'FCFS';

  List<Map<String, dynamic>> _ganttData = [];
  double avgWaitingTime = 0;
  double avgTurnaroundTime = 0;

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addProcess() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _processIds.add(processId);
        _burstTimes.add(burstTime);
        _arrivalTimes.add(arrivalTime);
        _priorities.add(priority);
        _remainingTimes.add(burstTime);

        // Reset the form fields
        processId = '';
        burstTime = 0;
        arrivalTime = 0;
        priority = 0;

        // Reset the form to clear the text fields
        _formKey.currentState?.reset();
      });
    }
  }

  void _resetSimulation() {
    setState(() {
      _processIds.clear();
      _burstTimes.clear();
      _arrivalTimes.clear();
      _priorities.clear();
      _waitingTimes.clear();
      _turnaroundTimes.clear();
      _remainingTimes.clear();
      _ganttData.clear();
      avgWaitingTime = 0;
      avgTurnaroundTime = 0;
    });
  }

  void _simulateScheduling() {
    switch (_selectedAlgorithm) {
      case 'FCFS':
        _simulateFCFS();
        break;
      case 'SJF (Non-Preemptive)':
        _simulateSJF();
        break;
      case 'SJF (Preemptive)':
        _simulateSJFPreemptive();
        break;
      case 'Priority (Non-Preemptive)':
        _simulatePriority(false);
        break;
      case 'Priority (Preemptive)':
        _simulatePriority(true);
        break;
      case 'RR':
        _simulateRR();
        break;
    }
  }

  void _simulateFCFS() {
    if (_processIds.isEmpty) return;

    List<Map<String, dynamic>> result = [];
    List<int> waitingTimes = List.filled(_processIds.length, 0);
    List<int> turnaroundTimes = List.filled(_processIds.length, 0);
    int currentTime = 0;

    List<int> indices = List.generate(_processIds.length, (i) => i);
    indices.sort((a, b) => _arrivalTimes[a].compareTo(_arrivalTimes[b]));

    for (int i = 0; i < indices.length; i++) {
      int idx = indices[i];
      int at = _arrivalTimes[idx];
      int bt = _burstTimes[idx];

      if (currentTime < at) currentTime = at;

      int startTime = currentTime;
      int endTime = currentTime + bt;
      waitingTimes[idx] = startTime - at;
      turnaroundTimes[idx] = endTime - at;

      result.add({
        'pid': _processIds[idx],
        'start': startTime,
        'end': endTime,
        'duration': bt,
      });

      currentTime = endTime;
    }

    _updateResults(result, waitingTimes, turnaroundTimes);
  }

  void _simulateSJF() {
    if (_processIds.isEmpty) return;

    List<Map<String, dynamic>> result = [];
    List<int> waitingTimes = List.filled(_processIds.length, 0);
    List<int> turnaroundTimes = List.filled(_processIds.length, 0);
    int currentTime = 0;

    List<int> indices = List.generate(_processIds.length, (i) => i);
    indices.sort((a, b) => _arrivalTimes[a].compareTo(_arrivalTimes[b]));

    List<int> readyQueue = [];
    int processIndex = 0;

    while (processIndex < indices.length || readyQueue.isNotEmpty) {
      while (processIndex < indices.length &&
          _arrivalTimes[indices[processIndex]] <= currentTime) {
        readyQueue.add(indices[processIndex++]);
      }

      if (readyQueue.isEmpty) {
        currentTime = _arrivalTimes[indices[processIndex]];
        continue;
      }

      readyQueue.sort((a, b) => _burstTimes[a].compareTo(_burstTimes[b]));
      int idx = readyQueue.removeAt(0);
      int bt = _burstTimes[idx];
      int at = _arrivalTimes[idx];

      int startTime = currentTime;
      int endTime = currentTime + bt;
      waitingTimes[idx] = startTime - at;
      turnaroundTimes[idx] = endTime - at;

      result.add({
        'pid': _processIds[idx],
        'start': startTime,
        'end': endTime,
        'duration': bt,
      });

      currentTime = endTime;
    }

    _updateResults(result, waitingTimes, turnaroundTimes);
  }

  void _simulateSJFPreemptive() {
    if (_processIds.isEmpty) return;

    List<Map<String, dynamic>> result = [];
    List<int> waitingTimes = List.filled(_processIds.length, 0);
    List<int> turnaroundTimes = List.filled(_processIds.length, 0);
    List<int> remainingTimes = List.from(_burstTimes);
    int currentTime = 0;

    List<int> indices = List.generate(_processIds.length, (i) => i);
    indices.sort((a, b) => _arrivalTimes[a].compareTo(_arrivalTimes[b]));

    int completed = 0;
    int prev = -1;
    int processIndex = 0;

    while (completed < _processIds.length) {
      // Find all processes that have arrived
      List<int> readyQueue = [];
      for (int i = 0; i < _processIds.length; i++) {
        if (_arrivalTimes[i] <= currentTime && remainingTimes[i] > 0) {
          readyQueue.add(i);
        }
      }

      if (readyQueue.isEmpty) {
        currentTime++;
        continue;
      }

      // Sort by remaining time (SRTF)
      readyQueue.sort((a, b) => remainingTimes[a].compareTo(remainingTimes[b]));
      int idx = readyQueue.first;

      if (prev != idx && prev != -1) {
        // Add the previous process segment to the Gantt chart
        int lastEnd = result.isNotEmpty ? result.last['end'] : 0;
        if (lastEnd < currentTime) {
          result.add({
            'pid': _processIds[prev],
            'start': lastEnd,
            'end': currentTime,
            'duration': currentTime - lastEnd,
          });
        }
      }

      remainingTimes[idx]--;
      currentTime++;
      prev = idx;

      if (remainingTimes[idx] == 0) {
        completed++;
        turnaroundTimes[idx] = currentTime - _arrivalTimes[idx];
        waitingTimes[idx] = turnaroundTimes[idx] - _burstTimes[idx];
      }
    }

    // Add the last process segment
    if (prev != -1) {
      int lastEnd = result.isNotEmpty ? result.last['end'] : 0;
      if (lastEnd < currentTime) {
        result.add({
          'pid': _processIds[prev],
          'start': lastEnd,
          'end': currentTime,
          'duration': currentTime - lastEnd,
        });
      }
    }

    _updateResults(result, waitingTimes, turnaroundTimes);
  }

  void _simulatePriority(bool isPreemptive) {
    if (_processIds.isEmpty) return;

    List<Map<String, dynamic>> result = [];
    List<int> waitingTimes = List.filled(_processIds.length, 0);
    List<int> turnaroundTimes = List.filled(_processIds.length, 0);
    List<int> remainingTimes = List.from(_burstTimes);
    int currentTime = 0;

    List<int> indices = List.generate(_processIds.length, (i) => i);
    indices.sort((a, b) => _arrivalTimes[a].compareTo(_arrivalTimes[b]));

    int completed = 0;
    int prev = -1;
    int processIndex = 0;

    while (completed < _processIds.length) {
      // Find all processes that have arrived
      List<int> readyQueue = [];
      for (int i = 0; i < _processIds.length; i++) {
        if (_arrivalTimes[i] <= currentTime && remainingTimes[i] > 0) {
          readyQueue.add(i);
        }
      }

      if (readyQueue.isEmpty) {
        currentTime++;
        continue;
      }

      // Sort by priority (lower number = higher priority)
      readyQueue.sort((a, b) => _priorities[a].compareTo(_priorities[b]));
      int idx = readyQueue.first;

      if (!isPreemptive) {
        // Non-preemptive - run to completion
        int bt = remainingTimes[idx];
        int at = _arrivalTimes[idx];

        int startTime = currentTime;
        int endTime = currentTime + bt;
        waitingTimes[idx] = startTime - at;
        turnaroundTimes[idx] = endTime - at;
        remainingTimes[idx] = 0;

        result.add({
          'pid': _processIds[idx],
          'start': startTime,
          'end': endTime,
          'duration': bt,
        });

        currentTime = endTime;
        completed++;
      } else {
        // Preemptive - run for 1 time unit
        if (prev != idx && prev != -1) {
          // Add the previous process segment to the Gantt chart
          int lastEnd = result.isNotEmpty ? result.last['end'] : 0;
          if (lastEnd < currentTime) {
            result.add({
              'pid': _processIds[prev],
              'start': lastEnd,
              'end': currentTime,
              'duration': currentTime - lastEnd,
            });
          }
        }

        remainingTimes[idx]--;
        currentTime++;
        prev = idx;

        if (remainingTimes[idx] == 0) {
          completed++;
          turnaroundTimes[idx] = currentTime - _arrivalTimes[idx];
          waitingTimes[idx] = turnaroundTimes[idx] - _burstTimes[idx];
        }
      }
    }

    // For preemptive, add the last process segment
    if (isPreemptive && prev != -1) {
      int lastEnd = result.isNotEmpty ? result.last['end'] : 0;
      if (lastEnd < currentTime) {
        result.add({
          'pid': _processIds[prev],
          'start': lastEnd,
          'end': currentTime,
          'duration': currentTime - lastEnd,
        });
      }
    }

    _updateResults(result, waitingTimes, turnaroundTimes);
  }

  void _simulateRR() {
    if (_processIds.isEmpty) return;

    List<Map<String, dynamic>> result = [];
    List<int> waitingTimes = List.filled(_processIds.length, 0);
    List<int> turnaroundTimes = List.filled(_processIds.length, 0);
    List<int> remainingTimes = List.from(_burstTimes);
    int currentTime = 0;

    List<int> queue = [];
    List<bool> isInQueue = List.filled(_processIds.length, false);
    int processIndex = 0;

    List<int> indices = List.generate(_processIds.length, (i) => i);
    indices.sort((a, b) => _arrivalTimes[a].compareTo(_arrivalTimes[b]));

    while (processIndex < indices.length &&
        _arrivalTimes[indices[processIndex]] <= currentTime) {
      queue.add(indices[processIndex]);
      isInQueue[indices[processIndex]] = true;
      processIndex++;
    }

    while (queue.isNotEmpty) {
      int idx = queue.removeAt(0);
      isInQueue[idx] = false;
      int executionTime = min(_timeQuantum, remainingTimes[idx]);
      remainingTimes[idx] -= executionTime;

      int startTime = currentTime;
      int endTime = currentTime + executionTime;

      result.add({
        'pid': _processIds[idx],
        'start': startTime,
        'end': endTime,
        'duration': executionTime,
      });

      while (processIndex < indices.length &&
          _arrivalTimes[indices[processIndex]] <= endTime) {
        if (!isInQueue[indices[processIndex]] &&
            remainingTimes[indices[processIndex]] > 0) {
          queue.add(indices[processIndex]);
          isInQueue[indices[processIndex]] = true;
        }
        processIndex++;
      }

      if (remainingTimes[idx] > 0) {
        queue.add(idx);
        isInQueue[idx] = true;
      } else {
        turnaroundTimes[idx] = endTime - _arrivalTimes[idx];
        waitingTimes[idx] = turnaroundTimes[idx] - _burstTimes[idx];
      }

      currentTime = endTime;

      if (queue.isEmpty && processIndex < indices.length) {
        currentTime = _arrivalTimes[indices[processIndex]];
        while (processIndex < indices.length &&
            _arrivalTimes[indices[processIndex]] <= currentTime) {
          if (!isInQueue[indices[processIndex]] &&
              remainingTimes[indices[processIndex]] > 0) {
            queue.add(indices[processIndex]);
            isInQueue[indices[processIndex]] = true;
          }
          processIndex++;
        }
      }
    }

    _updateResults(result, waitingTimes, turnaroundTimes);
  }

  void _updateResults(List<Map<String, dynamic>> result, List<int> waitingTimes,
      List<int> turnaroundTimes) {
    setState(() {
      _ganttData = result;
      _waitingTimes = waitingTimes;
      _turnaroundTimes = turnaroundTimes;
      avgWaitingTime =
          waitingTimes.reduce((a, b) => a + b) / waitingTimes.length;
      avgTurnaroundTime =
          turnaroundTimes.reduce((a, b) => a + b) / turnaroundTimes.length;
    });
  }

  Widget _buildEnhancedGanttChart() {
    if (_ganttData.isEmpty) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: Text(
          "No data available. Add processes and simulate to see the Gantt Chart.",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final colors = [
      Color(0xFF8BA4FF), // Soft blue
      Color(0xFF95D5B2), // Soft green
      Color(0xFFFFB7B7), // Soft red
      Color(0xFFFFC3A0), // Soft orange
      Color(0xFFBDB2FF), // Soft purple
      Color(0xFFA0E7E5), // Soft teal
    ];

    Map<String, Color> processColors = {};
    for (int i = 0; i < _processIds.length; i++) {
      processColors[_processIds[i]] = colors[i % colors.length];
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        children: [
          Container(
            height: 40,
            child: Row(
              children: _ganttData.map((process) {
                return Container(
                  width: process['duration'] * 30.0,
                  margin: EdgeInsets.only(right: 2),
                  decoration: BoxDecoration(
                    color: processColors[process['pid']],
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: processColors[process['pid']]!.withOpacity(0.5),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    process['pid'],
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 10),
          Row(
            children: _ganttData.map((process) {
              return SizedBox(
                width: process['duration'] * 30.0,
                child: Column(
                  children: [
                    Text('${process['start']}'),
                    Text('${process['end']}'),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedProcessTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Process Details",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 48,
              dataRowHeight: 56,
              columnSpacing: 32,
              columns: [
                DataColumn(
                  label: Text(
                    "Process",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Arrival",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Burst",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (_selectedAlgorithm.contains('Priority'))
                  DataColumn(
                    label: Text(
                      "Priority",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                DataColumn(
                  label: Text(
                    "Waiting",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "Turnaround",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              rows: List.generate(
                _processIds.length,
                (index) => DataRow(
                  cells: [
                    DataCell(
                      Text(
                        _processIds[index],
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    DataCell(Text(_arrivalTimes[index].toString())),
                    DataCell(Text(_burstTimes[index].toString())),
                    if (_selectedAlgorithm.contains('Priority'))
                      DataCell(Text(_priorities[index].toString())),
                    DataCell(
                      Text(
                        index < _waitingTimes.length
                            ? _waitingTimes[index].toString()
                            : '-',
                      ),
                    ),
                    DataCell(
                      Text(
                        index < _turnaroundTimes.length
                            ? _turnaroundTimes[index].toString()
                            : '-',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FF), // Light blue-tinted background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          "CPU Scheduling Simulator",
          style: TextStyle(
            color: Color(0xFF6384FF), // Soft blue
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.all(12),
            child: IconButton(
              icon: Icon(Icons.refresh, color: Color(0xFF8BA4FF), size: 28),
              onPressed: _resetSimulation,
              tooltip: "Reset Simulation",
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildAlgorithmSelector(),
                SizedBox(height: 32),
                _buildProcessInputForm(),
                SizedBox(height: 32),
                if (_ganttData.isNotEmpty) ...[
                  _buildResults(),
                  SizedBox(height: 32),
                  _buildEnhancedProcessTable(),
                  SizedBox(height: 32),
                  _buildGanttChartCard(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGanttChartCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            "Gantt Chart",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 24),
          _buildEnhancedGanttChart(),
        ],
      ),
    );
  }

  Widget _buildAlgorithmSelector() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE6EEFF), Color(0xFFF3F6FF)], // Soft gradient
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF8BA4FF).withOpacity(0.15),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Select Algorithm",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedAlgorithm,
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down, color: Colors.blue),
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                items: [
                  'FCFS',
                  'SJF (Non-Preemptive)',
                  'SJF (Preemptive)',
                  'Priority (Non-Preemptive)',
                  'Priority (Preemptive)',
                  'RR',
                ].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedAlgorithm = value!);
                },
              ),
            ),
          ),
          if (_selectedAlgorithm == 'RR') ...[
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: "Time Quantum",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() => _timeQuantum = int.tryParse(value) ?? 2);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProcessInputForm() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Process Details",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 20),
            _buildTextField(
              label: "Process ID",
              onSaved: (value) => processId = value!,
              validator: (value) => value!.isEmpty ? 'Required' : null,
            ),
            SizedBox(height: 16),
            _buildTextField(
              label: "Burst Time",
              keyboardType: TextInputType.number,
              onSaved: (value) => burstTime = int.parse(value!),
              validator: (value) => value!.isEmpty ? 'Required' : null,
            ),
            SizedBox(height: 16),
            _buildTextField(
              label: "Arrival Time",
              keyboardType: TextInputType.number,
              onSaved: (value) => arrivalTime = int.parse(value!),
              validator: (value) => value!.isEmpty ? 'Required' : null,
            ),
            if (_selectedAlgorithm.contains('Priority')) ...[
              SizedBox(height: 16),
              _buildTextField(
                label: "Priority",
                keyboardType: TextInputType.number,
                onSaved: (value) => priority = int.parse(value!),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
            ],
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    text: "Add Process",
                    icon: Icons.add_circle_outline,
                    color: Colors.blue,
                    onPressed: _addProcess,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildActionButton(
                    text: "Simulate",
                    icon: Icons.play_circle_outline,
                    color: Colors.green,
                    onPressed: _simulateScheduling,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    TextInputType? keyboardType,
    FormFieldSetter<String>? onSaved,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Color(0xFF6384FF)),
        filled: true,
        fillColor: Color(0xFFF3F6FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Color(0xFFE6EEFF), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Color(0xFF8BA4FF), width: 2),
        ),
      ),
      keyboardType: keyboardType,
      onSaved: onSaved,
      validator: validator,
    );
  }

  Widget _buildActionButton({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: ElevatedButton.icon(
          icon: Icon(icon),
          label: Text(text),
          style: ElevatedButton.styleFrom(
            backgroundColor: color.withOpacity(0.9),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16),
            elevation: 4,
            shadowColor: color.withOpacity(0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }

  Widget _buildResults() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE6EEFF), Color(0xFFF3F6FF)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF8BA4FF).withOpacity(0.15),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            "Results",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6384FF),
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  "Average Waiting Time",
                  avgWaitingTime.toStringAsFixed(2),
                  Color(0xFFE6EEFF),
                  Color(0xFF6384FF),
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                child: _buildMetricCard(
                  "Average Turnaround Time",
                  avgTurnaroundTime.toStringAsFixed(2),
                  Color(0xFFE8F5E9),
                  Color(0xFF66BB6A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String value, Color bgColor, Color textColor) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

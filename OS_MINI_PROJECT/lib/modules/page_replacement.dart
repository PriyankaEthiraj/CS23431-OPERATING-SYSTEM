import 'package:flutter/material.dart';

class PageReplacementScreen extends StatefulWidget {
  const PageReplacementScreen({Key? key}) : super(key: key);

  @override
  State<PageReplacementScreen> createState() => _PageReplacementScreenState();
}

class _PageReplacementScreenState extends State<PageReplacementScreen> {
  final TextEditingController _pagesController =
      TextEditingController(text: '7, 0, 1, 2, 0, 3, 0, 4, 2, 3');
  final TextEditingController _framesController =
      TextEditingController(text: '3');
  String _selectedAlgorithm = 'FIFO';
  String _result = '';
  bool _isCalculating = false;
  List<List<int>> _frameStates = [];
  List<int> _pageSequence = [];
  List<bool> _hitMissList = [];
  int _currentStep = 0;
  int _faultCount = 0;
  int _hitCount = 0;

  final Color _primaryColor = Colors.purple.shade300;
  final Color _secondaryColor = Colors.pink.shade200;
  final Color _accentColor = Colors.deepPurple.shade200;
  final Color _faultColor = Colors.red.shade300;
  final Color _hitColor = Colors.green.shade400;
  final Color _frameBorderColor = Colors.grey.shade400;

  @override
  void dispose() {
    _pagesController.dispose();
    _framesController.dispose();
    super.dispose();
  }

  void _calculate() {
    setState(() {
      _isCalculating = true;
      _result = '';
      _frameStates = [];
      _hitMissList = [];
      _currentStep = 0;
      _faultCount = 0;
      _hitCount = 0;
    });

    try {
      _pageSequence = _pagesController.text
          .split(',')
          .map((e) => int.tryParse(e.trim()))
          .where((e) => e != null)
          .cast<int>()
          .toList();

      final frameCount = int.tryParse(_framesController.text.trim()) ?? 0;

      if (_pageSequence.isEmpty || frameCount <= 0) {
        setState(() {
          _result = 'Please enter valid input:\n'
              '- Page numbers should be comma-separated\n'
              '- Number of frames should be positive';
          _isCalculating = false;
        });
        return;
      }

      switch (_selectedAlgorithm) {
        case 'LRU':
          _lruAlgorithm(_pageSequence, frameCount);
          break;
        case 'Optimal':
          _optimalAlgorithm(_pageSequence, frameCount);
          break;
        case 'FIFO':
        default:
          _fifoAlgorithm(_pageSequence, frameCount);
      }

      setState(() {
        _result = 'Total Page Faults: $_faultCount\n'
            'Total Hits: $_hitCount\n'
            'Hit Ratio: ${(_hitCount / _pageSequence.length * 100).toStringAsFixed(1)}%';
        _isCalculating = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Error occurred: ${e.toString()}';
        _isCalculating = false;
      });
    }
  }

  void _fifoAlgorithm(List<int> pages, int frameCount) {
    List<int> frames = [];
    _frameStates = [];
    _hitMissList = [];
    _faultCount = 0;
    _hitCount = 0;

    for (var page in pages) {
      bool isHit = frames.contains(page);
      _hitMissList.add(isHit);

      if (!isHit) {
        if (frames.length < frameCount) {
          frames.add(page); // Changed from insert(0) to add for FIFO
        } else {
          frames.removeAt(0); // Remove oldest
          frames.add(page); // Add new at end
        }
        _faultCount++;
      } else {
        _hitCount++;
      }
      _frameStates.add(List.from(frames));
    }
  }

  void _lruAlgorithm(List<int> pages, int frameCount) {
    List<int> frames = [];
    Map<int, int> recentlyUsed = {};
    _frameStates = [];
    _hitMissList = [];
    _faultCount = 0;
    _hitCount = 0;

    for (int i = 0; i < pages.length; i++) {
      int page = pages[i];
      bool isHit = frames.contains(page);
      _hitMissList.add(isHit);

      if (!isHit) {
        if (frames.length < frameCount) {
          frames.add(page);
        } else {
          int lruPage = frames.reduce((a, b) =>
              (recentlyUsed[a] ?? 0) < (recentlyUsed[b] ?? 0) ? a : b);
          frames.remove(lruPage);
          frames.add(page);
        }
        _faultCount++;
      } else {
        _hitCount++;
        frames.remove(page);
        frames.add(page); // Move to most recently used position
      }
      recentlyUsed[page] = i;
      _frameStates.add(List.from(frames));
    }
  }

  void _optimalAlgorithm(List<int> pages, int frameCount) {
    List<int> frames = [];
    _frameStates = [];
    _hitMissList = [];
    _faultCount = 0;
    _hitCount = 0;

    for (int i = 0; i < pages.length; i++) {
      int page = pages[i];
      bool isHit = frames.contains(page);
      _hitMissList.add(isHit);

      if (!isHit) {
        if (frames.length < frameCount) {
          frames.add(page);
        } else {
          Map<int, int> nextUse = {};
          for (int f in frames) {
            int index = pages.sublist(i + 1).indexOf(f);
            nextUse[f] = index == -1 ? pages.length : index;
          }
          int pageToReplace =
              frames.reduce((a, b) => nextUse[a]! > nextUse[b]! ? a : b);
          frames.remove(pageToReplace);
          frames.add(page);
        }
        _faultCount++;
      } else {
        _hitCount++;
      }
      _frameStates.add(List.from(frames));
    }
  }

  void _nextStep() {
    if (_currentStep < _pageSequence.length - 1) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page Replacement Visualizer'),
        backgroundColor: Colors.white,
        foregroundColor: _primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: constraints.maxWidth > 600 ? 24 : 12,
              vertical: 8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: _frameBorderColor.withOpacity(0.3),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        const Text(
                          'Configuration',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 15),
                              child: Text(
                                'Pages:',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _pagesController,
                                decoration: InputDecoration(
                                  hintText: '7,0,1,2,0,3,0,4,2,3',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Replace Row with Column for Frames and Algorithm
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Frames input
                            Row(
                              children: [
                                const Text(
                                  'Frames:',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 80,
                                  child: TextField(
                                    controller: _framesController,
                                    decoration: InputDecoration(
                                      hintText: '3',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 12),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Algorithm dropdown
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Algorithm:',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: _selectedAlgorithm,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'FIFO',
                                      child: Text('FIFO'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'LRU',
                                      child: Text('LRU'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Optimal',
                                      child: Text('Optimal'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedAlgorithm = value!;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isCalculating ? null : _calculate,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              backgroundColor: _primaryColor,
                            ),
                            child: _isCalculating
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Run Simulation',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_frameStates.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side:
                          BorderSide(color: _frameBorderColor.withOpacity(0.3)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  'Step ${_currentStep + 1} of ${_pageSequence.length}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _primaryColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _hitMissList[_currentStep]
                                      ? _hitColor.withOpacity(0.2)
                                      : _faultColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Current: ${_pageSequence[_currentStep]}',
                                  style: TextStyle(
                                    color: _hitMissList[_currentStep]
                                        ? _hitColor
                                        : _faultColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildFrameVisualization(constraints),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _hitMissList[_currentStep]
                                  ? _hitColor.withOpacity(0.1)
                                  : _faultColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _hitMissList[_currentStep]
                                      ? Icons.check_circle
                                      : Icons.error,
                                  color: _hitMissList[_currentStep]
                                      ? _hitColor
                                      : _faultColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _hitMissList[_currentStep]
                                      ? 'HIT'
                                      : 'MISS (Fault)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _hitMissList[_currentStep]
                                        ? _hitColor
                                        : _faultColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: _prevStep,
                                icon: const Icon(Icons.chevron_left),
                                style: IconButton.styleFrom(
                                  backgroundColor:
                                      _accentColor.withOpacity(0.2),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                onPressed: _nextStep,
                                icon: const Icon(Icons.chevron_right),
                                style: IconButton.styleFrom(
                                  backgroundColor:
                                      _accentColor.withOpacity(0.2),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFrameVisualization(BoxConstraints constraints) {
    final frameCount = int.tryParse(_framesController.text.trim()) ?? 3;
    final isHit =
        _currentStep < _hitMissList.length && _hitMissList[_currentStep];

    return Column(
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: constraints.maxWidth * 0.6,
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: _frameBorderColor.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Current State',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: _frameBorderColor.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      for (int i = frameCount - 1;
                          i >= _frameStates[_currentStep].length;
                          i--)
                        Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            border: i > 0
                                ? Border(
                                    bottom: BorderSide(
                                        color:
                                            _frameBorderColor.withOpacity(0.3)))
                                : null,
                          ),
                          child: const Center(child: Text(' ')),
                        ),
                      for (int i = _frameStates[_currentStep].length - 1;
                          i >= 0;
                          i--)
                        Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            color: _secondaryColor.withOpacity(0.2),
                            border: i > 0
                                ? Border(
                                    bottom: BorderSide(
                                        color:
                                            _frameBorderColor.withOpacity(0.3)))
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              _frameStates[_currentStep][i].toString(),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: !isHit && i == 0
                                    ? _faultColor
                                    : _primaryColor,
                              ),
                            ),
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
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _frameBorderColor.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Frame History',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              SizedBox(height: 8),
              ...List.generate(
                _currentStep + 1,
                (i) => Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 30,
                        child: Text(
                          '${i + 1}.',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 30,
                        child: Text(
                          '${_pageSequence[i]}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: !_hitMissList[i]
                                ? _faultColor
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                      Text(' → '),
                      Expanded(
                        child: Text(
                          _frameStates[i].join(' '),
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: i == _currentStep
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _hitMissList[i]
                              ? _hitColor.withOpacity(0.1)
                              : _faultColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _hitMissList[i] ? 'Hit' : 'Miss',
                          style: TextStyle(
                            fontSize: 12,
                            color: _hitMissList[i] ? _hitColor : _faultColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSummaryItem('Hits', _hitCount, _hitColor),
                  _buildSummaryItem('Misses', _faultCount, _faultColor),
                  _buildSummaryItem('Faults', _faultCount, _faultColor),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

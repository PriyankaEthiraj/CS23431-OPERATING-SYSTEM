import 'package:flutter/material.dart';
import 'modules/cpu_scheduling.dart';
import 'modules/memory_allocation.dart';
import 'modules/deadlock_avoidance.dart';
import 'modules/page_replacement.dart';
import 'dart:ui';

void main() {
  runApp(OpSysToolkit());
}

class OpSysToolkit extends StatelessWidget {
  OpSysToolkit({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpSys Toolkit',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF4285F4),
          brightness: Brightness.light,
          primary: Color(0xFF4285F4),
          secondary: Color(0xFF34A853),
          background: Colors.white,
          onBackground: Colors.black87,
          surface: Colors.white,
          onSurface: Colors.black87,
        ),
        useMaterial3: true,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: Colors.white,
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF4285F4)),
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        textTheme: TextTheme(
          headlineLarge: TextStyle(
            color: Colors.black87,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(
            color: Colors.black87,
            fontSize: 16,
          ),
          bodyMedium: TextStyle(
            color: Colors.black87,
            fontSize: 14,
          ),
        ),
      ),
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AnimatedBackgroundPainter extends CustomPainter {
  final Animation<double> animation;

  AnimatedBackgroundPainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFF6C63FF).withOpacity(0.08)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < 30; i++) {
      final offset = 30.0 * animation.value + (i * 40);
      canvas.drawCircle(
        Offset(size.width * (i % 4) / 3.5, offset % size.height),
        18 * (1 - animation.value),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class AnimatedBackground extends StatefulWidget {
  @override
  _AnimatedBackgroundState createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 15),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: AnimatedBackgroundPainter(_controller),
      child: Container(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  HomeScreen({Key? key}) : super(key: key);

  final List<Map<String, dynamic>> modules = [
    {
      'title': 'CPU Scheduling',
      'description': 'Various CPU scheduling algorithms',
      'icon': Icons.schedule,
      'screen': CPUSchedulingScreen(),
      'color': Colors.blueAccent,
    },
    {
      'title': 'Memory Allocation',
      'description': 'Memory allocation algorithms',
      'icon': Icons.memory,
      'screen': MemoryAllocationScreen(),
      'color': Colors.greenAccent,
    },
    {
      'title': 'Deadlock Avoidance',
      'description': 'Banker\'s Algorithm for deadlock prevention',
      'icon': Icons.warning,
      'screen': BankersAlgorithmScreen(),
      'color': Colors.orangeAccent,
    },
    {
      'title': 'Page Replacement',
      'description': 'FIFO, LRU, and Optimal page replacement',
      'icon': Icons.layers,
      'screen': PageReplacementScreen(),
      'color': Colors.purpleAccent,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "OpSys Toolkit",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey.shade200,
            height: 1.0,
          ),
        ),
      ),
      body: Stack(
        children: [
          AnimatedBackground(),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF8F9FE), Color(0xFFEEF1F9)],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    SizedBox(height: 32),
                    Expanded(child: _buildModulesList(context)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OpSys Toolkit',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
                height: 1.2,
              ),
        ),
        SizedBox(height: 12),
        Text(
          'Advanced System Architecture & Process Management Suite',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.black54,
                fontSize: 18,
                letterSpacing: 0.5,
              ),
        ),
      ],
    );
  }

  Widget _buildModulesList(BuildContext context) {
    return ListView.builder(
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final module = modules[index];
        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                module['color'].withOpacity(0.1),
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: module['color'].withOpacity(0.2),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            leading: Icon(module['icon'], color: module['color'], size: 32),
            title: Text(
              module['title'],
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            subtitle: Text(module['description'],
                style: TextStyle(fontSize: 14, color: Colors.black54)),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => module['screen'])),
          ),
        );
      },
    );
  }
}

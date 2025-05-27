import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/jebam_screen.dart';
import '../screens/tharpanam_screen.dart';
import '../screens/homam_screen.dart';
import '../screens/dhaanam_screen.dart';

class PracticeScreensController extends StatefulWidget {
  final int initialPage;
  
  const PracticeScreensController({
    super.key,
    this.initialPage = 0,
  });
  
  @override
  State<PracticeScreensController> createState() => _PracticeScreensControllerState();
}

class _PracticeScreensControllerState extends State<PracticeScreensController> {
  late PageController _pageController;
  int _currentPage = 0;
  
  // The list of practice screens with their titles
  final List<Map<String, dynamic>> _practiceScreens = [
    {
      'title': 'JEBAM',
      'screen': const JebamScreen(),
      'icon': Icons.format_list_numbered_rounded,
    },
    {
      'title': 'THARPANAM',
      'screen': const TharpanamScreen(),
      'icon': Icons.water_drop_rounded,
    },
    {
      'title': 'HOMAM',
      'screen': const HomamScreen(),
      'icon': Icons.local_fire_department_rounded,
    },
    {
      'title': 'DHAANAM',
      'screen': const DhaanamScreen(),
      'icon': Icons.spa_rounded,
    },
  ];
  
  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(
      initialPage: widget.initialPage,
      viewportFraction: 1.0,
    );
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    HapticFeedback.lightImpact();
    setState(() {
      _currentPage = page;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Page view with iOS physics
          PageView.builder(
            controller: _pageController,
            itemCount: _practiceScreens.length,
            onPageChanged: _onPageChanged,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              return _practiceScreens[index]['screen'];
            },
          ),
          
          // Page indicator dots
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _practiceScreens.length,
                  (index) => _buildPageIndicator(index),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Custom animated page indicator
  Widget _buildPageIndicator(int index) {
    bool isActive = _currentPage == index;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 5.0),
      height: isActive ? 10.0 : 8.0,
      width: isActive ? 24.0 : 8.0,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(5.0),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 51),
                  blurRadius: 3.0,
                  spreadRadius: 0.0,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
    );
  }
}
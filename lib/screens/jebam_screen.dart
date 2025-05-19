import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../providers/sadhana_provider.dart';

class JebamScreen extends StatefulWidget {
  const JebamScreen({super.key});

  @override
  State<JebamScreen> createState() => _JebamScreenState();
}

class _JebamScreenState extends State<JebamScreen>
    with SingleTickerProviderStateMixin {
  final _jebamController = TextEditingController();
  final _extraCountController = TextEditingController();
  final _extraMultiplierController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation; // Changed to correct type

  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  
  // Theme colors - Forest Green Palette
  final Color _primaryGradientStart = const Color(0xFF3A5F2E);  // Muted forest green
  final Color _primaryGradientEnd = const Color(0xFF5C8D4A);    // Lighter forest green
  final Color _accentColor = const Color(0xFF855A32);           // Earthy brown accent
  final Color _accentColorLight = const Color(0xFFB58863);      // Lighter brown
  final Color _textColor = Colors.white;
  final Color _cardColor = const Color(0x1DFFFFFF);             // Slightly more opaque card background
  
  // Gold accent for special elements
  final Color _goldAccent = const Color(0xFFD4B483);            // Soft gold accent

  // Heatmap colors with alpha values - Green/Teal palette
  final Color _heatLow = const Color(0x8082C26E);     // Light green with alpha 0x80 (50%)
  final Color _heatMedium = const Color(0xB350A745);  // Medium green with alpha 0xB3 (70%)  
  final Color _heatHigh = const Color(0xFF2E7D32);    // Deep green (100% opacity)

  @override
  void initState() {
    super.initState();

    // Set up controllers with initial values
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeControllers();
    });

    // Setup animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  void _initializeControllers() {
    final provider = Provider.of<SadhanaProvider>(context, listen: false);
    _jebamController.text = provider.jebamCount.toString();
    _extraCountController.text = "108"; // Default value (changed from 112)
    _extraMultiplierController.text = "3"; // Default value
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SadhanaProvider>(context);
    final currentMonthJebam = provider.jebamCount;
    final heatmap = provider.jebamHeatmap;
    
    // Filter heatmap data for current month/year
    final filteredHeatmap = _getFilteredHeatmapData(heatmap);

    // Calculate days in the current month for display
    final daysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_primaryGradientStart, _primaryGradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          image: const DecorationImage(
            image: AssetImage('assets/images/subtle_pattern.png'),
            repeat: ImageRepeat.repeat,
            opacity: 0.05, // Very subtle pattern overlay
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Month selector
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                      child: _buildMonthSelector(),
                    ),
                  ),

                  // Heatmap section
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                      child: _buildHeatmapSection(daysInMonth, filteredHeatmap),
                    ),
                  ),

                  // Monthly stats section
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: _buildMonthlyStatsSection(currentMonthJebam, daysInMonth),
                    ),
                  ),

                  // Bottom padding
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: FadeTransition(
        opacity: _fadeAnimation,
        child: const Text(
          'JEBAM',
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            letterSpacing: 1.5,
            fontSize: 24,
            color: Colors.white,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3.0,
                color: Color(0x99000000),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0x33FFFFFF), // Replacing withOpacity(0.2)
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0x33FFFFFF),
              width: 1,
            ),
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        onPressed: () => Navigator.pop(context),
        tooltip: 'Back',
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x33FFFFFF), width: 1.5), // Replacing withOpacity
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000), // Replacing withOpacity(0.1)
            blurRadius: 8,
            spreadRadius: 0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous month button
          _buildMonthNavigationButton(
            icon: Icons.chevron_left,
            onPressed: _goToPreviousMonth,
          ),

          // Current month display
          Column(
            children: [
              Text(
                DateFormat('MMMM').format(DateTime(selectedYear, selectedMonth)),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                ),
              ),
              Text(
                selectedYear.toString(),
                style: TextStyle(
                  fontSize: 14,
                  color: Color.fromRGBO(
                    _textColor.red, 
                    _textColor.green, 
                    _textColor.blue, 
                    0.8
                  ), // Replacing withOpacity
                ),
              ),
            ],
          ),

          // Next month button
          _buildMonthNavigationButton(
            icon: Icons.chevron_right,
            onPressed: _goToNextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthNavigationButton({required IconData icon, required VoidCallback onPressed}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Color(0x33FFFFFF), // Replacing withOpacity(0.2)
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: _textColor,
            size: 24,
          ),
        ),
      ),
    );
  }

  void _goToPreviousMonth() {
    setState(() {
      if (selectedMonth > 1) {
        selectedMonth--;
      } else {
        selectedMonth = 12;
        selectedYear--;
      }
    });
  }

  void _goToNextMonth() {
    setState(() {
      if (selectedMonth < 12) {
        selectedMonth++;
      } else {
        selectedMonth = 1;
        selectedYear++;
      }
    });
  }

  Map<String, int> _getFilteredHeatmapData(Map<String, int> allData) {
    Map<String, int> filtered = {};
    
    for (var entry in allData.entries) {
      DateTime date = DateTime.parse(entry.key);
      if (date.month == selectedMonth && date.year == selectedYear) {
        filtered[entry.key] = entry.value;
      }
    }
    
    return filtered;
  }

  Widget _buildHeatmapSection(int daysInMonth, Map<String, int> heatmap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Daily Progress',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: _textColor,
              ),
            ),
            // Info icon with tooltip
            Tooltip(
              message: 'Tap on any day to update count',
              preferBelow: false,
              decoration: BoxDecoration(
                color: Color.fromRGBO(
                  _accentColor.red, 
                  _accentColor.green, 
                  _accentColor.blue, 
                  0.9
                ), // Replacing withOpacity
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.info_outline,
                color: Color.fromRGBO(
                  _textColor.red, 
                  _textColor.green, 
                  _textColor.blue, 
                  0.8
                ), // Replacing withOpacity
                size: 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Glassmorphism Card for Heatmap
        _buildGlassmorphicCard(
          child: Column(
            children: [
              // Week day headers
              _buildWeekdayHeaders(),
              
              const SizedBox(height: 8),
              
              // Grid of days
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  childAspectRatio: 1,
                ),
                itemCount: daysInMonth,
                itemBuilder: (context, index) {
                  return _buildDayCell(index, heatmap);
                },
              ),

              const SizedBox(height: 20),

              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(_heatLow, '< 100'),
                  const SizedBox(width: 16),
                  _buildLegendItem(_heatMedium, '100-200'),
                  const SizedBox(width: 16),
                  _buildLegendItem(_heatHigh, '> 200'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayHeaders() {
    final weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: weekdayNames.map((day) => Text(
          day,
          style: TextStyle(
            fontSize: 12,
            color: Color.fromRGBO(
              _textColor.red, 
              _textColor.green, 
              _textColor.blue, 
              0.7
            ), // Replacing withOpacity
            fontWeight: FontWeight.w500,
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildDayCell(int index, Map<String, int> heatmap) {
    final day = index + 1;
    final date = DateTime(selectedYear, selectedMonth, day);
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    // Determine cell color based on data
    Color cellColor;
    bool hasData = heatmap.containsKey(dateStr);
    int? count = hasData ? heatmap[dateStr] : null;

    if (hasData && count != null) {
      if (count > 200) {
        cellColor = _heatHigh;
      } else if (count > 100) {
        cellColor = _heatMedium;
      } else {
        cellColor = _heatLow;
      }
    } else {
      cellColor = const Color(0x1AFFFFFF); // Replacing Colors.white.withOpacity(0.1)
    }

    // Highlight current day
    bool isToday = date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        splashColor: _accentColorLight.withOpacity(0.3),
        onTap: () {
          _showDayEditDialog(context, date, count ?? 0);
        },
        child: Container(
          decoration: BoxDecoration(
            color: cellColor,
            borderRadius: BorderRadius.circular(8),
            border: isToday
                ? Border.all(
                    color: Colors.white,
                    width: 2,
                  )
                : null,
            boxShadow: hasData ? [
              BoxShadow(
                color: cellColor.withOpacity(0.5),
                blurRadius: 4,
                spreadRadius: 0,
                offset: const Offset(0, 1),
              ),
            ] : null,
          ),
          child: Center(
            child: Text(
              day.toString(),
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyStatsSection(int currentMonthJebam, int daysInMonth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This Month',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: _textColor,
          ),
        ),
        const SizedBox(height: 16),

        // Glassmorphism Card for Monthly Stats
        _buildGlassmorphicCard(
          child: Column(
            children: [
              // Total count display with animation
              _buildTotalCountDisplay(currentMonthJebam),

              const SizedBox(height: 24),

              // Base calculation row
              _buildBaseCalculationRow(daysInMonth),

              const SizedBox(height: 24),

              // Extras section
              _buildExtrasSection(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalCountDisplay(int currentMonthJebam) {
    return GestureDetector(
      onTap: () {
        _showEditDialog(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0x26FFFFFF), // Replacing withOpacity(0.15)
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0x26FFFFFF),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000), // Replacing withOpacity(0.08)
              blurRadius: 10,
              spreadRadius: 0,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'Total Count',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color.fromRGBO(
                  _textColor.red, 
                  _textColor.green, 
                  _textColor.blue, 
                  0.8
                ), // Replacing withOpacity
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<int>(
                  duration: const Duration(milliseconds: 800),
                  tween: IntTween(begin: 0, end: currentMonthJebam),
                  builder: (context, value, child) {
                    return Text(
                      value.toString(),
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: _goldAccent, // Using gold accent color for emphasis
                        shadows: const [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 2.0,
                            color: Color(0x40000000),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.edit_rounded,
                  color: Color.fromRGBO(
                    _textColor.red, 
                    _textColor.green, 
                    _textColor.blue, 
                    0.6
                  ), // Replacing withOpacity
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBaseCalculationRow(int daysInMonth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Base count
        _buildEditableNumberField(
          value: _extraCountController.text,
          onTap: () => _showBaseCountEditDialog(context),
        ),

        Text(
          'X',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: _textColor,
          ),
        ),

        // Days
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: const Color(0x26FFFFFF), // Replacing withOpacity(0.15)
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            daysInMonth.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _textColor,
            ),
          ),
        ),

        // Calculate button
        _buildActionButton(
          label: 'Calculate',
          onPressed: () => _calculateBaseTotal(daysInMonth),
        ),
      ],
    );
  }

  Widget _buildExtrasSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.add_circle_outline,
              color: _textColor.withOpacity(0.8),
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              'Add Extras',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _textColor,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Extra count
            _buildEditableNumberField(
              value: _extraCountController.text,
              onTap: () => _showBaseCountEditDialog(context),
            ),

            const SizedBox(width: 16),

            Text(
              'X',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: _textColor,
              ),
            ),

            const SizedBox(width: 16),

            // Extra multiplier
            _buildEditableNumberField(
              value: _extraMultiplierController.text,
              onTap: () => _showExtraMultiplierEditDialog(context),
            ),

            const SizedBox(width: 16),

            // Apply button
            _buildActionButton(
              label: 'Apply',
              onPressed: _addExtras,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEditableNumberField({
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: const Color(0x26FFFFFF), // Replacing withOpacity(0.15)
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0x26FFFFFF),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000), // Replacing withOpacity(0.05)
              blurRadius: 4,
              spreadRadius: 0,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _goldAccent, // Using gold for numbers
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.edit_rounded,
              color: Color.fromRGBO(
                _textColor.red, 
                _textColor.green, 
                _textColor.blue, 
                0.6
              ), // Replacing withOpacity
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: _accentColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        elevation: 3,
        shadowColor: const Color(0x66000000),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _calculateBaseTotal(int daysInMonth) {
    final baseCount = int.tryParse(_extraCountController.text) ?? 108;
    final total = baseCount * daysInMonth;
    
    _jebamController.text = total.toString();
    final provider = Provider.of<SadhanaProvider>(context, listen: false);
    provider.updateJebamCount(total);

    _showSuccessSnackBar('Updated total count to $total');
  }

  void _addExtras() {
    final baseCount = int.tryParse(_extraCountController.text) ?? 108;
    final multiplier = int.tryParse(_extraMultiplierController.text) ?? 3;
    final extras = baseCount * multiplier;
    final currentTotal = int.tryParse(_jebamController.text) ?? 0;
    final newTotal = currentTotal + extras;

    _jebamController.text = newTotal.toString();
    final provider = Provider.of<SadhanaProvider>(context, listen: false);
    provider.updateJebamCount(newTotal);

    _showSuccessSnackBar('Added $extras extras. New total: $newTotal');
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2E7D32), // Deep green
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Widget _buildGlassmorphicCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0x26FFFFFF), // Slightly more visible than before
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0x40FFFFFF), // Brighter border
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000), // Deeper shadow
                blurRadius: 20,
                spreadRadius: 0,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12, 
            color: Color.fromRGBO(
              _textColor.red, 
              _textColor.green, 
              _textColor.blue, 
              0.8
            ), // Replacing withOpacity
          ),
        ),
      ],
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _buildDialog(
        title: 'Update Jebam Count',
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: _jebamController,
            keyboardType: TextInputType.number,
            decoration: _getInputDecoration('Count'),
            validator: _validateNumber,
            autofocus: true,
          ),
        ),
        onSave: () {
          if (_formKey.currentState!.validate()) {
            final count = int.parse(_jebamController.text);
            Provider.of<SadhanaProvider>(context, listen: false)
                .updateJebamCount(count);
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  void _showBaseCountEditDialog(BuildContext context) {
    // Create a new controller for this dialog to avoid conflicts
    final controller = TextEditingController(text: _extraCountController.text);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => _buildDialog(
        title: 'Update Base Count',
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: _getInputDecoration('Base Count'),
            validator: _validateNumber,
            autofocus: true,
          ),
        ),
        onSave: () {
          if (formKey.currentState!.validate()) {
            setState(() {
              _extraCountController.text = controller.text;
            });
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  void _showExtraMultiplierEditDialog(BuildContext context) {
    final controller = TextEditingController(text: _extraMultiplierController.text);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => _buildDialog(
        title: 'Update Multiplier',
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: _getInputDecoration('Multiplier'),
            validator: _validateNumber,
            autofocus: true,
          ),
        ),
        onSave: () {
          if (formKey.currentState!.validate()) {
            setState(() {
              _extraMultiplierController.text = controller.text;
            });
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  void _showDayEditDialog(BuildContext context, DateTime date, int currentCount) {
    final controller = TextEditingController(text: currentCount.toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => _buildDialog(
        title: 'Update Count for ${DateFormat('MMMM d, yyyy').format(date)}',
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: _getInputDecoration('Count'),
            validator: _validateNumber,
            autofocus: true,
          ),
        ),
        onSave: () {
          if (formKey.currentState!.validate()) {
            final count = int.parse(controller.text);

            // Update the heatmap with this day's count
            final dateStr = DateFormat('yyyy-MM-dd').format(date);
            final provider = Provider.of<SadhanaProvider>(context, listen: false);
            provider.updateJebamHeatmap(dateStr, count);

            // Calculate new total
            int currentTotal = int.tryParse(_jebamController.text) ?? 0;
            int difference = count - currentCount; // May be positive or negative
            int newTotal = currentTotal + difference;
            _jebamController.text = newTotal.toString();
            provider.updateJebamCount(newTotal);

            Navigator.pop(context);
            
            // Show feedback to user
            final message = difference >= 0 
                ? 'Added $difference to $dateStr' 
                : 'Removed ${-difference} from $dateStr';
            _showSuccessSnackBar(message);
          }
        },
      ),
    );
  }

  Widget _buildDialog({
    required String title,
    required Widget content,
    required VoidCallback onSave,
  }) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 16,
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xE6FFFFFF), // Replacing withOpacity(0.9)
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000), // Replacing withOpacity(0.2)
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _accentColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                content,
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF757575),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Update',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _getInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: _accentColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: const Color(0x1A808080), // Light gray with alpha
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _accentColor, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x40808080), width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  String? _validateNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a value';
    }
    if (int.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    if (int.parse(value) < 0) {
      return 'Please enter a positive number';
    }
    return null;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _jebamController.dispose();
    _extraCountController.dispose();
    _extraMultiplierController.dispose();
    super.dispose();
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animations/animations.dart';
import 'dart:ui';
import '../providers/sadhana_provider.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isEmailFocused = false;
  bool _isPasswordFocused = false;
  late AnimationController _animationController;
  late Animation<double> _logoAnimation;
  late Animation<double> _formAnimation;
  
  // Login Screen Theme Colors
  final Color _primaryDark = const Color(0xFF0D2B3E);    // Deep teal/midnight blue
  final Color _primaryMedium = const Color(0xFF1A4A6E);  // Medium teal blue
  final Color _accentColor = const Color(0xFFD8B468);    // Gentle gold/amber
  final Color _errorColor = const Color(0xFFCF6679);     // Soft rose for errors
  final Color _textColor = Colors.white;
  final Color _inputBgColor = const Color(0x26FFFFFF);   // White with 15% opacity
  
  // Form focus colors
  final Color _focusedBorderColor = const Color(0xFFD8B468); // Gold for focus
  final Color _unfocusedBorderColor = const Color(0x33FFFFFF); // White with 20% opacity

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _logoAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _formAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final sadhanaProvider = Provider.of<SadhanaProvider>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;

    // Check if already logged in
    if (sadhanaProvider.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      });
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _primaryDark,
              _primaryMedium,
              const Color(0xFF2A5E80), // Slightly lighter blue
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.08, // 8% of screen width
                      vertical: isVerySmallScreen ? 12.0 : 20.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top section with logo and title
                        Column(
                          children: [
                            SizedBox(height: screenHeight * 0.01), // 1% of screen height
                            
                            // App title with animation - more compact
                            AnimatedBuilder(
                              animation: _logoAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _logoAnimation.value,
                                  child: child,
                                );
                              },
                              child: ShaderMask(
                                shaderCallback: (Rect bounds) {
                                  return LinearGradient(
                                    colors: [_textColor, Color.fromRGBO(_textColor.red, _textColor.green, _textColor.blue, 0.7)],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ).createShader(bounds);
                                },
                                child: Text(
                                  "Rhythmbhara Tara Sadhana",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isVerySmallScreen ? 20 : (isSmallScreen ? 24 : 28),
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                    shadows: const [
                                      Shadow(
                                        color: Color(0x40000000),
                                        blurRadius: 5,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: screenHeight * 0.02), // 2% of screen height

                            // Deity silhouette with responsive size
                            AnimatedBuilder(
                              animation: _logoAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _logoAnimation.value,
                                  child: Opacity(
                                    opacity: _logoAnimation.value,
                                    child: child,
                                  ),
                                );
                              },
                              child: _buildCompactLogo(isVerySmallScreen, isSmallScreen),
                            ),
                          ],
                        ),

                        // Middle section with form
                        Column(
                          children: [
                            SizedBox(height: screenHeight * 0.02), // 2% of screen height

                            // Login Form with animation and enhanced glassmorphism
                            AnimatedBuilder(
                              animation: _formAnimation,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0, 30 * (1 - _formAnimation.value)),
                                  child: Opacity(
                                    opacity: _formAnimation.value,
                                    child: child,
                                  ),
                                );
                              },
                              child: _buildCompactGlassmorphicCard(
                                isSmallScreen: isSmallScreen,
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      // Welcome text with enhanced typography
                                      RichText(
                                        text: TextSpan(
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: isSmallScreen ? 20 : 24,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                          children: [
                                            const TextSpan(text: "Welcome "),
                                            TextSpan(
                                              text: "Back",
                                              style: TextStyle(
                                                color: _accentColor,
                                                fontSize: isSmallScreen ? 20 : 24,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                                shadows: const [
                                                  Shadow(
                                                    color: Color(0x4D000000),
                                                    offset: Offset(1, 1),
                                                    blurRadius: 3,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      SizedBox(height: isSmallScreen ? 4 : 8),

                                      // Subtitle with softer color
                                      Text(
                                        "Sign in to continue your spiritual journey",
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 12 : 14,
                                          color: const Color(0xB3FFFFFF), // White with 70% opacity
                                        ),
                                      ),

                                      SizedBox(height: isSmallScreen ? 20 : 28),

                                      // Enhanced Email field with focus effect
                                      Focus(
                                        onFocusChange: (hasFocus) {
                                          setState(() {
                                            _isEmailFocused = hasFocus;
                                          });
                                        },
                                        child: _buildCompactTextFormField(
                                          controller: _emailController,
                                          isPasswordField: false,
                                          isFocused: _isEmailFocused,
                                          isSmallScreen: isSmallScreen,
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please enter your email';
                                            }
                                            if (!RegExp(
                                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                            ).hasMatch(value)) {
                                              return 'Please enter a valid email';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),

                                      SizedBox(height: isSmallScreen ? 12 : 16),

                                      // Enhanced Password field with focus effect
                                      Focus(
                                        onFocusChange: (hasFocus) {
                                          setState(() {
                                            _isPasswordFocused = hasFocus;
                                          });
                                        },
                                        child: _buildCompactTextFormField(
                                          controller: _passwordController,
                                          isPasswordField: true,
                                          isFocused: _isPasswordFocused,
                                          isSmallScreen: isSmallScreen,
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please enter your password';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),

                                      SizedBox(height: isSmallScreen ? 8 : 12),

                                      // Forgot password with improved tap area
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              PageRouteBuilder(
                                                pageBuilder: (context, animation, secondaryAnimation) => 
                                                    const ForgotPasswordScreen(),
                                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                                  return FadeTransition(
                                                    opacity: animation,
                                                    child: child,
                                                  );
                                                },
                                              ),
                                            );
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              'Forgot Password?',
                                              style: TextStyle(
                                                color: _accentColor,
                                                fontWeight: FontWeight.w500,
                                                fontSize: isSmallScreen ? 12 : 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      SizedBox(height: isSmallScreen ? 20 : 28),

                                      // Enhanced login button with gradient and animation
                                      _buildCompactPrimaryButton(
                                        isLoading: sadhanaProvider.isLoading,
                                        onPressed: sadhanaProvider.isLoading
                                            ? null
                                            : () => _performLogin(context),
                                        label: 'Login',
                                        icon: Icons.arrow_forward,
                                        isSmallScreen: isSmallScreen,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Bottom section with social login and signup
                        Column(
                          children: [
                            SizedBox(height: screenHeight * 0.015), // 1.5% of screen height

                            // Animated divider with improved style
                            FadeTransition(
                              opacity: _formAnimation,
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8.0 : 12.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 1.5,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.white.withAlpha(0),
                                              Colors.white.withAlpha(204), // White with 80% opacity
                                            ],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                      child: Text(
                                        "OR",
                                        style: TextStyle(
                                          color: Color.fromRGBO(_textColor.red, _textColor.green, _textColor.blue, 0.9),
                                          fontWeight: FontWeight.bold,
                                          fontSize: isSmallScreen ? 12 : 14,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: 1.5,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.white.withAlpha(204), // White with 80% opacity
                                              Colors.white.withAlpha(0),
                                            ],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Enhanced Google Sign-In Button
                            FadeTransition(
                              opacity: _formAnimation,
                              child: _buildCompactSocialLoginButton(
                                isLoading: sadhanaProvider.isLoading,
                                onPressed: sadhanaProvider.isLoading
                                    ? null
                                    : () => _signInWithGoogle(context),
                                label: "Sign in with Google",
                                logoAsset: 'assets/images/google_logo.png',
                                isSmallScreen: isSmallScreen,
                              ),
                            ),

                            SizedBox(height: screenHeight * 0.015), // 1.5% of screen height

                            // Enhanced Sign Up Link with animation
                            FadeTransition(
                              opacity: _formAnimation,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Don't have an account? ",
                                    style: TextStyle(
                                      color: Color.fromRGBO(_textColor.red, _textColor.green, _textColor.blue, 0.9),
                                      fontSize: isSmallScreen ? 14 : 16,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder: (context, animation, secondaryAnimation) =>
                                              const SignupScreen(),
                                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                            return SharedAxisTransition(
                                              animation: animation,
                                              secondaryAnimation: secondaryAnimation,
                                              transitionType: SharedAxisTransitionType.horizontal,
                                              child: child,
                                            );
                                          },
                                        ),
                                      );
                                    },
                                    child: Text(
                                      "Sign Up",
                                      style: TextStyle(
                                        color: _accentColor,
                                        fontSize: isSmallScreen ? 14 : 16,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                        decorationColor: _accentColor,
                                        shadows: const [
                                          Shadow(
                                            color: Color(0x4D000000),
                                            offset: Offset(1, 1),
                                            blurRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: screenHeight * 0.01), // 1% of screen height
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Compact logo builder
  Widget _buildCompactLogo(bool isVerySmallScreen, bool isSmallScreen) {
    final logoSize = isVerySmallScreen ? 100.0 : (isSmallScreen ? 130.0 : 160.0);
    final glowSize = logoSize + 40;
    final iconSize = logoSize * 0.6;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow
        Container(
          height: glowSize,
          width: glowSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _accentColor.withAlpha(60),
                _accentColor.withAlpha(20),
                Colors.transparent,
              ],
              stops: const [0.4, 0.7, 1.0],
            ),
          ),
        ),
        
        // Main circle container
        Container(
          height: logoSize,
          width: logoSize,
          decoration: BoxDecoration(
            color: const Color(0xFF0A1922),
            shape: BoxShape.circle,
            boxShadow: [
              // Inner subtle glow
              BoxShadow(
                color: _accentColor.withAlpha(60),
                blurRadius: 15,
                spreadRadius: -2,
              ),
              // Outer shadow
              const BoxShadow(
                color: Color(0x66000000),
                blurRadius: 25,
                spreadRadius: 2,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  _accentColor,
                  const Color(0xFFE8CFA3), // Lighter gold
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Icon(
                Icons.self_improvement,
                size: iconSize,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  // Compact glassmorphic card builder
  Widget _buildCompactGlassmorphicCard({required Widget child, required bool isSmallScreen}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
          decoration: BoxDecoration(
            color: const Color(0x26FFFFFF), // White with 15% opacity
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0x33FFFFFF), // White with 20% opacity
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000), // Black with 10% opacity
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

  // Compact text form field builder
  Widget _buildCompactTextFormField({
    required TextEditingController controller,
    required bool isPasswordField,
    required bool isFocused,
    required bool isSmallScreen,
    required String? Function(String?)? validator,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _inputBgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFocused ? _focusedBorderColor : _unfocusedBorderColor,
          width: isFocused ? 2.0 : 1.0,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: _accentColor.withAlpha(40),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: isPasswordField ? TextInputType.visiblePassword : TextInputType.emailAddress,
        decoration: InputDecoration(
          labelText: isPasswordField ? 'Password' : 'Email',
          hintText: isPasswordField ? 'Enter your password' : 'Enter your email',
          floatingLabelBehavior: FloatingLabelBehavior.never,
          labelStyle: const TextStyle(
            color: Colors.white,
          ),
          hintStyle: const TextStyle(
            color: Color(0xB3FFFFFF), // White with 70% opacity
          ),
          prefixIcon: Icon(
            isPasswordField ? Icons.lock_outline : Icons.email_outlined,
            color: isFocused ? _accentColor : Colors.white,
            size: isSmallScreen ? 20 : 22,
          ),
          suffixIcon: isPasswordField
              ? IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: isFocused ? _accentColor : Colors.white,
                    size: isSmallScreen ? 20 : 22,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: _errorColor,
              width: 1.5,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: _errorColor,
              width: 1.5,
            ),
          ),
          errorStyle: TextStyle(
            color: _errorColor,
            fontSize: isSmallScreen ? 11 : 12,
          ),
          filled: false,
          contentPadding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 14 : 16,
          ),
        ),
        style: TextStyle(
          fontSize: isSmallScreen ? 14 : 16,
          color: Colors.white,
        ),
        obscureText: isPasswordField && !_isPasswordVisible,
        validator: validator,
      ),
    );
  }
  
  // Compact primary button builder
  Widget _buildCompactPrimaryButton({
    required bool isLoading,
    required VoidCallback? onPressed,
    required String label,
    required IconData icon,
    required bool isSmallScreen,
  }) {
    return Container(
      width: double.infinity,
      height: isSmallScreen ? 48 : 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFDAB35C), // Slightly brighter gold
            _accentColor,
            const Color(0xFFBE975B), // Darker gold
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withAlpha(76), // 30% opacity
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          splashColor: Colors.white.withAlpha(40),
          highlightColor: Colors.white.withAlpha(20),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 14, horizontal: 20),
            child: isLoading
                ? Center(
                    child: SizedBox(
                      height: isSmallScreen ? 20 : 24,
                      width: isSmallScreen ? 20 : 24,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        icon,
                        size: isSmallScreen ? 16 : 18,
                        color: Colors.white,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
  
  // Compact social login button builder
  Widget _buildCompactSocialLoginButton({
    required bool isLoading,
    required VoidCallback? onPressed,
    required String label,
    required String logoAsset,
    required bool isSmallScreen,
  }) {
    return Container(
      width: double.infinity,
      height: isSmallScreen ? 48 : 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000), // Black with 8% opacity
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          splashColor: Colors.grey.withAlpha(40),
          highlightColor: Colors.grey.withAlpha(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 0,
              horizontal: 24,
            ),
            child: isLoading
                ? Center(
                    child: SizedBox(
                      height: isSmallScreen ? 20 : 24,
                      width: isSmallScreen ? 20 : 24,
                      child: const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF757575)),
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        logoAsset,
                        height: isSmallScreen ? 20 : 24,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        label,
                        style: TextStyle(
                          color: const Color(0xFF2C2C2C),
                          fontWeight: FontWeight.w600,
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  void _performLogin(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      try {
        await Provider.of<SadhanaProvider>(
          context,
          listen: false,
        ).login(_emailController.text.trim(), _passwordController.text);

        // Navigation will happen automatically via the isLoggedIn check in build()
      } catch (e) {
        // Enhanced error notification
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      e.toString().replaceAll("Exception: ", ""),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              backgroundColor: _errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  void _signInWithGoogle(BuildContext context) async {
    try {
      await Provider.of<SadhanaProvider>(
        context,
        listen: false,
      ).signInWithGoogle();

      // Navigation will happen automatically via the isLoggedIn check in build()
    } catch (e) {
      // Enhanced error notification
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Google Sign-In failed: ${e.toString()}",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            backgroundColor: _errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
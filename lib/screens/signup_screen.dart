import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'dart:async';
import 'dart:math';
import '../providers/sadhana_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _verificationCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _emailFormKey = GlobalKey<FormState>();
  
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isEmailVerified = false;
  bool _isVerifyingEmail = false;
  bool _isResendingCode = false;
  
  // Current step: 0 = Email verification, 1 = Complete signup
  int _currentStep = 0;
  
  // Email verification
  String _verificationCode = '';
  Timer? _resendTimer;
  int _resendCountdown = 0;
  
  late AnimationController _animationController;
  late Animation<double> _logoAnimation;
  late Animation<double> _formAnimation;

  // Login Screen Theme Colors (matching login_screen.dart)
  final Color _primaryDark = const Color(0xFF0D2B3E);    // Deep teal/midnight blue
  final Color _primaryMedium = const Color(0xFF1A4A6E);  // Medium teal blue
  final Color _accentColor = const Color(0xFFD8B468);    // Gentle gold/amber
  final Color _errorColor = const Color(0xFFCF6679);     // Soft rose for errors
  final Color _successColor = const Color(0xFF66BB6A);   // Success green
  final Color _textColor = Colors.white;
  final Color _inputBgColor = const Color(0x26FFFFFF);   // White with 15% opacity
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
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _verificationCodeController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  // Generate a random 6-digit verification code
  String _generateVerificationCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Simulate sending verification email
  Future<void> _sendVerificationEmail() async {
    setState(() {
      _isVerifyingEmail = true;
    });

    try {
      // Generate verification code
      _verificationCode = _generateVerificationCode();
      
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 2));
      
      // In a real app, you would send the verification code via email
      // For demo purposes, we'll show it in a dialog
      _showVerificationCodeDialog();
      
      // Start resend countdown
      _startResendCountdown();
      
    } catch (e) {
      _showErrorMessage('Failed to send verification email. Please try again.');
    } finally {
      setState(() {
        _isVerifyingEmail = false;
      });
    }
  }

  // Show verification code dialog (for demo purposes)
  void _showVerificationCodeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: _primaryMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Verification Code',
          style: TextStyle(color: _textColor, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'For demo purposes, your verification code is:',
              style: TextStyle(color: _textColor.withOpacity(0.8)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _accentColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _accentColor, width: 2),
              ),
              child: Text(
                _verificationCode,
                style: TextStyle(
                  color: _accentColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Enter this code in the verification field below.',
              style: TextStyle(color: _textColor.withOpacity(0.8)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it!', style: TextStyle(color: _accentColor)),
          ),
        ],
      ),
    );
  }

  // Start resend countdown
  void _startResendCountdown() {
    setState(() {
      _resendCountdown = 60;
    });
    
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  // Verify the entered code
  Future<void> _verifyEmailCode() async {
    if (_verificationCodeController.text.trim() == _verificationCode) {
      setState(() {
        _isEmailVerified = true;
        _currentStep = 1;
      });
      _showSuccessMessage('Email verified successfully!');
    } else {
      _showErrorMessage('Invalid verification code. Please try again.');
    }
  }

  // Resend verification code
  Future<void> _resendVerificationCode() async {
    if (_resendCountdown > 0) return;
    
    setState(() {
      _isResendingCode = true;
    });
    
    try {
      _verificationCode = _generateVerificationCode();
      await Future.delayed(const Duration(seconds: 1));
      _showVerificationCodeDialog();
      _startResendCountdown();
      _showSuccessMessage('Verification code resent!');
    } catch (e) {
      _showErrorMessage('Failed to resend verification code.');
    } finally {
      setState(() {
        _isResendingCode = false;
      });
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 16))),
          ],
        ),
        backgroundColor: _successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 16))),
          ],
        ),
        backgroundColor: _errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sadhanaProvider = Provider.of<SadhanaProvider>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;

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
          image: const DecorationImage(
            image: AssetImage('assets/images/subtle_pattern.png'),
            repeat: ImageRepeat.repeat,
            opacity: 0.05,
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
                      horizontal: screenWidth * 0.08,
                      vertical: isVerySmallScreen ? 12.0 : 20.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top section
                        Column(
                          children: [
                            // Back button
                            Align(
                              alignment: Alignment.topLeft,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    _currentStep == 0 ? Icons.arrow_back : Icons.arrow_back,
                                    color: _textColor,
                                  ),
                                  onPressed: () {
                                    if (_currentStep == 1) {
                                      setState(() {
                                        _currentStep = 0;
                                      });
                                    } else {
                                      Navigator.pop(context);
                                    }
                                  },
                                ),
                              ),
                            ),

                            SizedBox(height: screenHeight * 0.02),

                            // App title with animation
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
                                  _currentStep == 0 ? "Verify Email" : "Complete Signup",
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

                            SizedBox(height: screenHeight * 0.02),

                            // Logo with responsive size
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
                            SizedBox(height: screenHeight * 0.02),

                            // Progress indicator
                            _buildProgressIndicator(),

                            SizedBox(height: screenHeight * 0.02),

                            // Main form with animation
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
                              child: _currentStep == 0
                                  ? _buildEmailVerificationStep(isSmallScreen)
                                  : _buildCompleteSignupStep(isSmallScreen),
                            ),
                          ],
                        ),

                        // Bottom section with social login and signin
                        if (_currentStep == 1) _buildBottomSection(sadhanaProvider, isSmallScreen),
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

  Widget _buildCompactLogo(bool isVerySmallScreen, bool isSmallScreen) {
    final logoSize = isVerySmallScreen ? 80.0 : (isSmallScreen ? 100.0 : 120.0);
    final glowSize = logoSize + 30;
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
              BoxShadow(
                color: _accentColor.withAlpha(60),
                blurRadius: 15,
                spreadRadius: -2,
              ),
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
                  const Color(0xFFE8CFA3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Icon(
                _currentStep == 0 ? Icons.mark_email_read : Icons.account_circle,
                size: iconSize,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildProgressDot(0, _currentStep >= 0),
        Container(
          width: 30,
          height: 2,
          color: _currentStep >= 1 ? _accentColor : Colors.white.withOpacity(0.3),
        ),
        _buildProgressDot(1, _currentStep >= 1),
      ],
    );
  }

  Widget _buildProgressDot(int step, bool isActive) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: isActive ? _accentColor : Colors.white.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildEmailVerificationStep(bool isSmallScreen) {
    return _buildCompactGlassmorphicCard(
      isSmallScreen: isSmallScreen,
      child: Form(
        key: _emailFormKey,
        child: Column(
          children: [
            // Title
            Text(
              'Verify Your Email',
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmallScreen ? 20 : 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),

            SizedBox(height: isSmallScreen ? 4 : 8),

            Text(
              'We\'ll send a verification code to confirm your email',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                color: const Color(0xB3FFFFFF),
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: isSmallScreen ? 20 : 28),

            // Email field
            _buildCompactTextFormField(
              controller: _emailController,
              labelText: 'Email Address',
              hintText: 'Enter your email',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              isSmallScreen: isSmallScreen,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),

            SizedBox(height: isSmallScreen ? 16 : 20),

            // Verification code field (only show if email is being verified)
            if (_isVerifyingEmail || _verificationCode.isNotEmpty) ...[
              _buildCompactTextFormField(
                controller: _verificationCodeController,
                labelText: 'Verification Code',
                hintText: 'Enter 6-digit code',
                prefixIcon: Icons.security,
                keyboardType: TextInputType.number,
                isSmallScreen: isSmallScreen,
                maxLength: 6,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter verification code';
                  }
                  if (value.length != 6) {
                    return 'Code must be 6 digits';
                  }
                  return null;
                },
              ),

              SizedBox(height: isSmallScreen ? 12 : 16),

              // Resend code option
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Didn\'t receive code?',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: isSmallScreen ? 12 : 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: _resendCountdown > 0 || _isResendingCode ? null : _resendVerificationCode,
                    child: Text(
                      _resendCountdown > 0 
                          ? 'Resend in ${_resendCountdown}s'
                          : _isResendingCode ? 'Sending...' : 'Resend Code',
                      style: TextStyle(
                        color: _resendCountdown > 0 || _isResendingCode 
                            ? Colors.white.withOpacity(0.5)
                            : _accentColor,
                        fontSize: isSmallScreen ? 12 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: isSmallScreen ? 16 : 20),
            ],

            // Action button
            _buildCompactPrimaryButton(
              isLoading: _isVerifyingEmail,
              onPressed: _isVerifyingEmail ? null : () async {
                if (_verificationCode.isEmpty) {
                  // Send verification code
                  if (_emailFormKey.currentState!.validate()) {
                    await _sendVerificationEmail();
                  }
                } else {
                  // Verify code
                  await _verifyEmailCode();
                }
              },
              label: _verificationCode.isEmpty ? 'Send Verification Code' : 'Verify Email',
              icon: _verificationCode.isEmpty ? Icons.send : Icons.verified,
              isSmallScreen: isSmallScreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleteSignupStep(bool isSmallScreen) {
    final sadhanaProvider = Provider.of<SadhanaProvider>(context);
    
    return _buildCompactGlassmorphicCard(
      isSmallScreen: isSmallScreen,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Success message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _successColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _successColor, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: _successColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Email verified: ${_emailController.text}',
                      style: TextStyle(
                        color: _successColor,
                        fontSize: isSmallScreen ? 12 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: isSmallScreen ? 16 : 20),

            // Title
            Text(
              'Complete Your Profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmallScreen ? 20 : 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),

            SizedBox(height: isSmallScreen ? 4 : 8),

            Text(
              'Just a few more details to get started',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                color: const Color(0xB3FFFFFF),
              ),
            ),

            SizedBox(height: isSmallScreen ? 20 : 28),

            // Name field
            _buildCompactTextFormField(
              controller: _nameController,
              labelText: 'Full Name',
              hintText: 'Enter your full name',
              prefixIcon: Icons.person_outline,
              isSmallScreen: isSmallScreen,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),

            SizedBox(height: isSmallScreen ? 12 : 16),

            // Password field
            _buildCompactTextFormField(
              controller: _passwordController,
              labelText: 'Password',
              hintText: 'Enter your password',
              prefixIcon: Icons.lock_outline,
              obscureText: !_isPasswordVisible,
              isSmallScreen: isSmallScreen,
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  color: _textColor.withOpacity(0.7),
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),

            SizedBox(height: isSmallScreen ? 12 : 16),

            // Confirm password field
            _buildCompactTextFormField(
              controller: _confirmPasswordController,
              labelText: 'Confirm Password',
              hintText: 'Confirm your password',
              prefixIcon: Icons.lock_outline,
              obscureText: !_isConfirmPasswordVisible,
              isSmallScreen: isSmallScreen,
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  color: _textColor.withOpacity(0.7),
                ),
                onPressed: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),

            SizedBox(height: isSmallScreen ? 20 : 28),

            // Sign up button
            _buildCompactPrimaryButton(
              isLoading: sadhanaProvider.isLoading,
              onPressed: sadhanaProvider.isLoading ? null : () => _performSignup(context),
              label: 'Create Account',
              icon: Icons.arrow_forward,
              isSmallScreen: isSmallScreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection(SadhanaProvider sadhanaProvider, bool isSmallScreen) {
    return Column(
      children: [
        // Divider
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
                          Colors.white.withAlpha(204),
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
                          Colors.white.withAlpha(204),
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

        // Google Sign-In Button
        FadeTransition(
          opacity: _formAnimation,
          child: _buildCompactSocialLoginButton(
            isLoading: sadhanaProvider.isLoading,
            onPressed: sadhanaProvider.isLoading ? null : () => _signInWithGoogle(context),
            label: "Sign up with Google",
            logoAsset: 'assets/images/google_logo.png',
            isSmallScreen: isSmallScreen,
          ),
        ),

        const SizedBox(height: 15),

        // Sign In Link
        FadeTransition(
          opacity: _formAnimation,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: TextStyle(
                  color: Color.fromRGBO(_textColor.red, _textColor.green, _textColor.blue, 0.9),
                  fontSize: isSmallScreen ? 14 : 16,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text(
                  'Sign In',
                  style: TextStyle(
                    color: _accentColor,
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                    decorationColor: _accentColor,
                  ),
                ),
              ),
            ],
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
            color: const Color(0x26FFFFFF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0x33FFFFFF),
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
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
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    int? maxLength,
    required bool isSmallScreen,
    required String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _inputBgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _unfocusedBorderColor,
          width: 1.0,
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLength: maxLength,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          floatingLabelBehavior: FloatingLabelBehavior.never,
          labelStyle: const TextStyle(color: Colors.white),
          hintStyle: const TextStyle(color: Color(0xB3FFFFFF)),
          prefixIcon: Icon(prefixIcon, color: _accentColor, size: isSmallScreen ? 20 : 22),
          suffixIcon: suffixIcon,
          counterText: '',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _focusedBorderColor, width: 2.0),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _errorColor, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _errorColor, width: 1.5),
          ),
          errorStyle: TextStyle(color: _errorColor, fontSize: isSmallScreen ? 11 : 12),
          filled: false,
          contentPadding: EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 16),
        ),
        style: TextStyle(fontSize: isSmallScreen ? 14 : 16, color: Colors.white),
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
            const Color(0xFFDAB35C),
            _accentColor,
            const Color(0xFFBE975B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withAlpha(76),
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
                      Icon(icon, size: isSmallScreen ? 16 : 18, color: Colors.white),
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
            color: Color(0x14000000),
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
            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 24),
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
                      Image.asset(logoAsset, height: isSmallScreen ? 20 : 24),
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

  void _performSignup(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      try {
        await Provider.of<SadhanaProvider>(context, listen: false).register(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      } catch (e) {
        _showErrorMessage(e.toString().replaceAll("Exception: ", ""));
      }
    }
  }

  void _signInWithGoogle(BuildContext context) async {
    try {
      await Provider.of<SadhanaProvider>(context, listen: false).signInWithGoogle();

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      _showErrorMessage("Google Sign-In failed: ${e.toString()}");
    }
  }
}
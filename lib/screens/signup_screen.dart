import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _emailFormKey = GlobalKey<FormState>();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isEmailVerified = false;
  bool _isVerifyingEmail = false;
  bool _isResendingCode = false;
  bool _isCheckingVerification = false;
  bool _isLoading = false;
  bool _isAccountLocked = false;

  // Current step: 0 = Email verification, 1 = Complete signup
  int _currentStep = 0;

  // Email verification tracking
  Timer? _resendTimer;
  Timer? _timeoutTimer;
  int _resendCountdown = 0;
  int _verificationAttempts = 0;
  int _timeRemaining = 300; // 5 minutes in seconds
  User? _tempUser;
  
  // CRITICAL: Store the temp password to reuse it
  String? _tempPassword;

  late AnimationController _animationController;
  late Animation<double> _logoAnimation;
  late Animation<double> _formAnimation;

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Theme Colors
  final Color _primaryDark = const Color(0xFF0D2B3E);
  final Color _primaryMedium = const Color(0xFF1A4A6E);
  final Color _accentColor = const Color(0xFFD8B468);
  final Color _errorColor = const Color(0xFFCF6679);
  final Color _successColor = const Color(0xFF66BB6A);
  final Color _textColor = Colors.white;
  final Color _inputBgColor = const Color(0x26FFFFFF);
  final Color _focusedBorderColor = const Color(0xFFD8B468);
  final Color _unfocusedBorderColor = const Color(0x33FFFFFF);

  @override
  void initState() {
    super.initState();
    
    // CRITICAL: Activate signup protection immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<SadhanaProvider>(context, listen: false);
      provider.setSignupProcessActive(true);
    });
    
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

  // IMPROVED: Better cleanup method with proper error handling
  Future<void> _cleanupIncompleteVerification() async {
    if (_tempUser != null && !_isEmailVerified) {
      try {
        debugPrint('Cleaning up incomplete verification for: ${_emailController.text}');
        
        if (_tempPassword != null) {
          try {
            // Sign in with temp credentials to delete the user
            await _auth.signInWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _tempPassword!,
            );
            
            final currentUser = _auth.currentUser;
            if (currentUser != null) {
              await currentUser.delete();
              debugPrint('Successfully deleted incomplete user account');
            }
          } catch (e) {
            debugPrint('Error deleting user during cleanup: $e');
            // If deletion fails, try to sign out anyway
            try {
              await _auth.signOut();
            } catch (_) {}
          }
        }
      } catch (e) {
        debugPrint('Error in cleanup process: $e');
      } finally {
        // Always reset state
        _tempUser = null;
        _tempPassword = null;
        if (mounted) {
          setState(() {
            _isEmailVerified = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    // CRITICAL: Deactivate signup protection when leaving
    final provider = Provider.of<SadhanaProvider>(context, listen: false);
    provider.setSignupProcessActive(false);
    
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _resendTimer?.cancel();
    _timeoutTimer?.cancel();

    // IMPROVED: Always cleanup if we have incomplete verification
    if (_tempUser != null && !_isEmailVerified) {
      Future.microtask(() => _cleanupIncompleteVerification());
    }

    super.dispose();
  }

  // Send verification email
  Future<void> _sendVerificationEmail() async {
    if (_isAccountLocked) {
      _showErrorMessage('Account verification is locked. Please contact admin for assistance.');
      return;
    }

    if (_verificationAttempts >= 70) {
      setState(() {
        _isAccountLocked = true;
      });
      _showErrorMessage('Too many verification attempts. Account locked. Please contact admin.');
      return;
    }

    setState(() {
      _isVerifyingEmail = true;
    });

    try {
      final email = _emailController.text.trim();
      
      // Generate temp password only once and store it
      _tempPassword = 'TempPass_${DateTime.now().millisecondsSinceEpoch}!';

      UserCredential? userCredential;
      
      try {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: _tempPassword!,
        );
        
        _tempUser = userCredential.user;
        
        // CRITICAL: Sign out immediately to prevent auto-login
        await _auth.signOut();
        
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          _showErrorMessage('An account with this email already exists. If you haven\'t verified it, please wait for it to be cleaned up or contact support.');
          return;
        }
        throw Exception('Firebase error: ${e.message}');
      }

      if (_tempUser != null && _tempPassword != null) {
        try {
          // Re-authenticate with temp user to send verification
          await _auth.signInWithEmailAndPassword(
            email: email,
            password: _tempPassword!,
          );
          
          final currentUser = _auth.currentUser;
          if (currentUser != null) {
            await currentUser.sendEmailVerification();
            
            // CRITICAL: Sign out again after sending email
            await _auth.signOut();
          }
          
          _verificationAttempts++;
          
          _showSuccessMessage('Verification email sent to $email (Attempt $_verificationAttempts/70)');
          _startResendCountdown();
          _startTimeCountdown();
          
          // Show dialog AFTER successful email sending
          if (mounted) {
            _showEmailSentDialog();
          }
          
        } catch (emailError) {
          // Clean up if email sending fails
          await _cleanupIncompleteVerification();
          throw Exception('Failed to send verification email: ${emailError.toString()}');
        }
      } else {
        throw Exception('Failed to create temporary user account');
      }
      
    } catch (e) {
      String errorMessage = 'Failed to send verification email';
      
      if (e.toString().contains('email-already-in-use')) {
        errorMessage = 'An account with this email already exists';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = 'Please enter a valid email address';
      } else if (e.toString().contains('network-request-failed')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('too-many-requests')) {
        errorMessage = 'Too many attempts. Please try again later.';
      } else {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }
      
      _showErrorMessage(errorMessage);
      
      // Ensure user is signed out
      try {
        await _auth.signOut();
      } catch (_) {}
      
      _tempUser = null;
      _tempPassword = null;
    } finally {
      if (mounted) {
        setState(() {
          _isVerifyingEmail = false;
        });
      }
    }
  }

  // Start 5-minute countdown timer
  void _startTimeCountdown() {
    setState(() {
      _timeRemaining = 300; // 5 minutes
    });
    
    _timeoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        if (mounted) {
          setState(() {
            _timeRemaining--;
          });
        }
      } else {
        timer.cancel();
        if (!_isEmailVerified && _tempUser != null) {
          _markAsUnverifiedAndAllowRetry();
        }
      }
    });
  }

  // Mark as unverified after timeout and allow retry
  void _markAsUnverifiedAndAllowRetry() {
    if (mounted) {
      setState(() {
        _isEmailVerified = false;
      });
      
      _cleanupIncompleteVerification();
      
      _showErrorMessage('Verification timeout (5 minutes). Please try again. (${70 - _verificationAttempts} attempts remaining)');
    }
  }

  // Manual check verification button
  Future<void> _checkVerificationStatus() async {
    if (_tempUser == null || _tempPassword == null) {
      _showErrorMessage('No verification session found. Please send verification email again.');
      return;
    }
    
    setState(() {
      _isCheckingVerification = true;
    });
    
    try {
      final email = _emailController.text.trim();
      
      // Use the SAME temp password that was used to create the account
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: _tempPassword!, // Using stored password
      );
      
      final currentUser = _auth.currentUser;
      
      if (currentUser != null) {
        await currentUser.reload();
        
        if (currentUser.emailVerified) {
          setState(() {
            _isEmailVerified = true;
            _tempUser = currentUser;
          });
          
          _timeoutTimer?.cancel();
          
          // CRITICAL: Sign out after checking - don't stay logged in
          await _auth.signOut();
          
          _showSuccessMessage('Email verified successfully! Click Continue to proceed.');
        } else {
          // Sign out if not verified
          await _auth.signOut();
          _showErrorMessage('Email not yet verified. Please check your email and click the verification link.');
        }
      }
    } catch (e) {
      try {
        await _auth.signOut();
      } catch (_) {}
      
      if (e.toString().contains('invalid-credential')) {
        _showErrorMessage('Verification session expired. Please send verification email again.');
        // Reset the verification process
        _tempUser = null;
        _tempPassword = null;
        setState(() {
          _isEmailVerified = false;
        });
      } else {
        _showErrorMessage('Error checking verification status: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingVerification = false;
        });
      }
    }
  }

  // Show info dialog about email being sent
  void _showEmailSentDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: _primaryMedium,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.mail_outline, color: _accentColor),
            const SizedBox(width: 8),
            Text(
              'Verification Email Sent!',
              style: TextStyle(color: _textColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mark_email_read, size: 64, color: _successColor),
            const SizedBox(height: 16),
            Text(
              'We\'ve sent a verification link to:',
              style: TextStyle(color: _textColor.withOpacity(0.8)),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _inputBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _emailController.text,
                style: TextStyle(
                  color: _accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _errorColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _errorColor, width: 1),
              ),
              child: Column(
                children: [
                  Text(
                    'IMPORTANT: You have 5 minutes to verify',
                    style: TextStyle(
                      color: _errorColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Attempts: $_verificationAttempts/70',
                    style: TextStyle(
                      color: _errorColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Steps:\n1. Go to your email\n2. Click the verification link\n3. Return to this app\n4. Click "Check Verification Status" button',
              style: TextStyle(color: _textColor.withOpacity(0.8), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: _accentColor)),
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
        if (mounted) {
          setState(() {
            _resendCountdown--;
          });
        }
      } else {
        timer.cancel();
      }
    });
  }

  // Resend verification email
  Future<void> _resendVerificationEmail() async {
    if (_resendCountdown > 0 || _tempUser == null || _tempPassword == null) return;
    
    if (_verificationAttempts >= 70) {
      setState(() {
        _isAccountLocked = true;
      });
      _showErrorMessage('Too many verification attempts. Account locked.');
      return;
    }
    
    setState(() {
      _isResendingCode = true;
    });
    
    try {
      final email = _emailController.text.trim();
      
      // Use the SAME temp password for resending
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: _tempPassword!, // Using stored password
      );
      
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await currentUser.sendEmailVerification();
        
        // Sign out after sending
        await _auth.signOut();
        
        _verificationAttempts++;
        _startResendCountdown();
        _showSuccessMessage('Verification email resent! (Attempt $_verificationAttempts/70)');
      }
    } catch (e) {
      try {
        await _auth.signOut();
      } catch (_) {}
      
      if (e.toString().contains('invalid-credential')) {
        _showErrorMessage('Verification session expired. Please send verification email again.');
        _tempUser = null;
        _tempPassword = null;
        setState(() {
          _isEmailVerified = false;
        });
      } else if (e.toString().contains('too-many-requests')) {
        _showErrorMessage('Too many attempts. Please wait before requesting another email.');
      } else {
        _showErrorMessage('Failed to resend verification email: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResendingCode = false;
        });
      }
    }
  }

  // Format time remaining
  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // IMPROVED: Complete signup with better error handling and database field consistency
  Future<void> _completeSignup() async {
    if (_tempUser == null || _tempPassword == null) {
      _showErrorMessage('No user session found. Please start over.');
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      _showErrorMessage('Please enter your full name.');
      return;
    }

    if (_passwordController.text.isEmpty) {
      _showErrorMessage('Please enter a password.');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorMessage('Passwords do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      
      // Sign in to complete the process using the SAME temp password
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: _tempPassword!, // Using stored password
      );
      
      final currentUser = _auth.currentUser;
      
      if (currentUser == null || !currentUser.emailVerified) {
        await _auth.signOut();
        _showErrorMessage('Please verify your email first.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Update password to user's chosen password
      await currentUser.updatePassword(_passwordController.text);
      await currentUser.updateDisplayName(_nameController.text.trim());
      
      // FIXED: Create user document with 'id' field (consistent naming)
      await _firestore.collection('users').doc(currentUser.uid).set({
        'id': currentUser.uid,  // Using 'id' instead of 'uid' for consistency
        'email': currentUser.email,
        'name': _nameController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'emailVerified': true,
        'lastLogin': FieldValue.serverTimestamp(),
        'verificationAttempts': _verificationAttempts,
      });

      if (!mounted) return;
      
      // CRITICAL: Deactivate signup protection before final login
      final sadhanaProvider = Provider.of<SadhanaProvider>(context, listen: false);
      sadhanaProvider.setSignupProcessActive(false);
      
      // NOW we can login through the provider
      await sadhanaProvider.login(_emailController.text.trim(), _passwordController.text);

      if (!mounted) return;
      
      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      try {
        await _auth.signOut();
      } catch (_) {}
      
      if (e.toString().contains('invalid-credential')) {
        _showErrorMessage('Verification session expired. Please start the signup process again.');
        _tempUser = null;
        _tempPassword = null;
        setState(() {
          _isEmailVerified = false;
          _currentStep = 0;
        });
      } else {
        _showErrorMessage('Failed to complete signup: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
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
    if (!mounted) return;
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
              const Color(0xFF2A5E80),
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
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
                            // IMPROVED: Back button with better cleanup logic
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
                                  icon: Icon(Icons.arrow_back, color: _textColor),
                                  onPressed: () async {
                                    if (_currentStep == 1) {
                                      // CRITICAL: Going back from step 2 to step 1 - cleanup incomplete signup
                                      if (_tempUser != null && !_isEmailVerified) {
                                        await _cleanupIncompleteVerification();
                                      }
                                      setState(() {
                                        _currentStep = 0;
                                        // Reset form fields when going back
                                        _nameController.clear();
                                        _passwordController.clear();
                                        _confirmPasswordController.clear();
                                      });
                                    } else {
                                      // CRITICAL: Deactivate protection before leaving
                                      final provider = Provider.of<SadhanaProvider>(context, listen: false);
                                      provider.setSignupProcessActive(false);
                                      
                                      if (_tempUser != null && !_isEmailVerified) {
                                        await _cleanupIncompleteVerification();
                                      }
                                      if (mounted) {
                                        Navigator.pop(context);
                                      }
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
                                    colors: [_textColor, _textColor.withOpacity(0.7)],
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

  // ... (Rest of the widget building methods remain the same as in your original code)
  // I'll include the key methods but the rest can stay as they were

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
                _accentColor.withOpacity(0.2),
                _accentColor.withOpacity(0.08),
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
                color: _accentColor.withOpacity(0.2),
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
                colors: [_accentColor, const Color(0xFFE8CFA3)],
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
              _isAccountLocked ? 'Account Locked' : 'Verify Your Email',
              style: TextStyle(
                color: _isAccountLocked ? _errorColor : Colors.white,
                fontSize: isSmallScreen ? 20 : 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),

            SizedBox(height: isSmallScreen ? 4 : 8),

            Text(
              _isAccountLocked 
                  ? 'Too many verification attempts. Contact admin.'
                  : 'We\'ll send a verification link to confirm your email',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                color: _isAccountLocked ? _errorColor : const Color(0xB3FFFFFF),
              ),
              textAlign: TextAlign.center,
            ),

            if (_isAccountLocked) ...[
              SizedBox(height: isSmallScreen ? 16 : 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _errorColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _errorColor, width: 1),
                ),
                child: Column(
                  children: [
                    Icon(Icons.lock, color: _errorColor, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      'Account Verification Locked',
                      style: TextStyle(
                        color: _errorColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You have exceeded the maximum number of verification attempts (70). Please contact admin for assistance.',
                      style: TextStyle(
                        color: _errorColor,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ] else ...[
              SizedBox(height: isSmallScreen ? 20 : 28),

              // Email field
              _buildCompactTextFormField(
                controller: _emailController,
                labelText: 'Email Address',
                hintText: 'Enter your email',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                isSmallScreen: isSmallScreen,
                enabled: _tempUser == null,
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

              // Time remaining display
              if (_tempUser != null && _timeRemaining > 0) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _timeRemaining < 60 ? _errorColor.withOpacity(0.2) : _accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _timeRemaining < 60 ? _errorColor : _accentColor, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer,
                        color: _timeRemaining < 60 ? _errorColor : _accentColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Time remaining: ${_formatTime(_timeRemaining)}',
                          style: TextStyle(
                            color: _timeRemaining < 60 ? _errorColor : _accentColor,
                            fontSize: isSmallScreen ? 12 : 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),
              ],

              // Status message if email sent
              if (_tempUser != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isEmailVerified 
                        ? _successColor.withOpacity(0.2)
                        : _accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isEmailVerified ? _successColor : _accentColor, 
                      width: 1
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isEmailVerified ? Icons.check_circle : Icons.info_outline, 
                            color: _isEmailVerified ? _successColor : _accentColor, 
                            size: 20
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _isEmailVerified 
                                  ? 'Email verified! Click Continue below.'
                                  : 'Check your email and click the verification link.',
                              style: TextStyle(
                                color: _isEmailVerified ? _successColor : _accentColor,
                                fontSize: isSmallScreen ? 12 : 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (!_isEmailVerified) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Attempts: $_verificationAttempts/70',
                          style: TextStyle(
                            color: _accentColor,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                SizedBox(height: isSmallScreen ? 12 : 16),

                // Check verification button (manual)
                if (!_isEmailVerified) ...[
                  SizedBox(
                    width: double.infinity,
                    child: _buildCompactSecondaryButton(
                      isLoading: _isCheckingVerification,
                      onPressed: _isCheckingVerification ? null : _checkVerificationStatus,
                      label: 'Check Verification Status',
                      icon: Icons.refresh,
                      isSmallScreen: isSmallScreen,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                ],

                // Resend option
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Didn\'t receive the email?',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: _resendCountdown > 0 || _isResendingCode || _verificationAttempts >= 70 ? null : _resendVerificationEmail,
                      child: Text(
                        _resendCountdown > 0 
                            ? 'Resend in ${_resendCountdown}s'
                            : _isResendingCode ? 'Sending...' 
                            : _verificationAttempts >= 70 ? 'Limit reached'
                            : 'Resend Email',
                        style: TextStyle(
                          color: _resendCountdown > 0 || _isResendingCode || _verificationAttempts >= 70
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
                onPressed: _isVerifyingEmail || _isAccountLocked ? null : () async {
                  if (_tempUser == null) {
                    // Send verification email
                    if (_emailFormKey.currentState!.validate()) {
                      await _sendVerificationEmail();
                    }
                  } else if (_isEmailVerified) {
                    // ONLY allow continue if email is actually verified
                    setState(() {
                      _currentStep = 1;
                    });
                  } else {
                    // Show message to check verification
                    _showErrorMessage('Please click the verification link in your email, then click "Check Verification Status".');
                  }
                },
                label: _tempUser == null 
                    ? 'Send Verification Email' 
                    : _isEmailVerified ? 'Continue' : 'Waiting for Verification',
                icon: _tempUser == null 
                    ? Icons.send 
                    : _isEmailVerified ? Icons.arrow_forward : Icons.hourglass_empty,
                isSmallScreen: isSmallScreen,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompleteSignupStep(bool isSmallScreen) {
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
              isLoading: _isLoading,
              onPressed: _isLoading ? null : () {
                if (_formKey.currentState!.validate()) {
                  _completeSignup();
                }
              },
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
                          Colors.white.withOpacity(0),
                          Colors.white.withOpacity(0.8),
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
                      color: _textColor.withOpacity(0.9),
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
                          Colors.white.withOpacity(0.8),
                          Colors.white.withOpacity(0),
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
                  color: _textColor.withOpacity(0.9),
                  fontSize: isSmallScreen ? 14 : 16,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // CRITICAL: Deactivate protection before going to login
                  final provider = Provider.of<SadhanaProvider>(context, listen: false);
                  provider.setSignupProcessActive(false);
                  Navigator.pop(context);
                },
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
  Widget _buildCompactGlassmorphicCard({
    required Widget child,
    required bool isSmallScreen,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
          decoration: BoxDecoration(
            color: const Color(0x26FFFFFF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x33FFFFFF), width: 1.5),
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
    bool enabled = true,
    required String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _inputBgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _unfocusedBorderColor, width: 1.0),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLength: maxLength,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          floatingLabelBehavior: FloatingLabelBehavior.never,
          labelStyle: const TextStyle(color: Colors.white),
          hintStyle: const TextStyle(color: Color(0xB3FFFFFF)),
          prefixIcon: Icon(
            prefixIcon,
            color: _accentColor,
            size: isSmallScreen ? 20 : 22,
          ),
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
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.1),
              width: 1.0,
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
            color: _accentColor.withOpacity(0.3),
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
          splashColor: Colors.white.withOpacity(0.15),
          highlightColor: Colors.white.withOpacity(0.08),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: isSmallScreen ? 12 : 14,
              horizontal: 20,
            ),
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

  // Compact secondary button builder
  Widget _buildCompactSecondaryButton({
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
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accentColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withOpacity(0.12),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          splashColor: _accentColor.withOpacity(0.15),
          highlightColor: _accentColor.withOpacity(0.08),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: isSmallScreen ? 12 : 14,
              horizontal: 20,
            ),
            child: isLoading
                ? Center(
                    child: SizedBox(
                      height: isSmallScreen ? 20 : 24,
                      width: isSmallScreen ? 20 : 24,
                      child: CircularProgressIndicator(
                        color: _accentColor,
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
                          color: _accentColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        icon,
                        size: isSmallScreen ? 16 : 18,
                        color: _accentColor,
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
          splashColor: Colors.grey.withOpacity(0.15),
          highlightColor: Colors.grey.withOpacity(0.08),
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

  void _signInWithGoogle(BuildContext context) async {
    try {
      if (!mounted) return;

      // CRITICAL: Deactivate signup protection for Google sign-in
      final provider = Provider.of<SadhanaProvider>(context, listen: false);
      provider.setSignupProcessActive(false);

      await provider.signInWithGoogle();

      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      _showErrorMessage("Google Sign-In failed: ${e.toString()}");
    }
  }
}
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/khata_provider.dart';
import '../widgets/custom_numpad.dart';
import 'dashboard_screen.dart';

import '../../utils/biometric_helper.dart';

class PinLockScreen extends StatefulWidget {
  final bool isVerifying; // true: login unlock, false: setting up new pin

  const PinLockScreen({super.key, required this.isVerifying});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  
  String _inputCode = '';
  String _setupFirstCode = ''; // For double confirmation on setup
  bool _isConfirmingSetup = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _shakeAnimation = Tween<double>(begin: 0.0, end: 24.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);

    _statusMessage = widget.isVerifying 
        ? "Enter your security PIN or use Biometrics" 
        : "Choose a 4-digit Security PIN";

    if (widget.isVerifying) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndTriggerBiometrics();
      });
    }
  }

  Future<void> _checkAndTriggerBiometrics() async {
    final provider = Provider.of<KhataProvider>(context, listen: false);
    if (provider.biometricLockEnabled) {
      final authenticated = await BiometricHelper.authenticate(
        localizedReason: 'Scan fingerprint or face to unlock your Khata app',
      );
      if (authenticated && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _triggerErrorShake(String message) {
    setState(() {
      _inputCode = '';
      _statusMessage = message;
    });
    _shakeController.forward(from: 0.0);
  }

  void _onKeyPress(String digit) {
    if (_inputCode.length >= 4) return;

    setState(() {
      _inputCode += digit;
    });

    if (_inputCode.length == 4) {
      // Small delay to allow the last dot to render visually
      Future.delayed(const Duration(milliseconds: 150), () {
        _processPin();
      });
    }
  }

  void _onDelete() {
    if (_inputCode.isEmpty) return;
    setState(() {
      _inputCode = _inputCode.substring(0, _inputCode.length - 1);
    });
  }

  void _processPin() {
    final provider = Provider.of<KhataProvider>(context, listen: false);

    if (widget.isVerifying) {
      // Verifying PIN to unlock
      if (_inputCode == provider.securityPin) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      } else {
        _triggerErrorShake("Incorrect PIN. Please try again.");
      }
    } else {
      // Setting up new PIN
      if (!_isConfirmingSetup) {
        // First entry
        _setupFirstCode = _inputCode;
        setState(() {
          _inputCode = '';
          _isConfirmingSetup = true;
          _statusMessage = "Confirm your 4-digit Security PIN";
        });
      } else {
        // Confirmation entry
        if (_inputCode == _setupFirstCode) {
          provider.enablePinLock(_inputCode);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Security PIN set successfully"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          // Reset setup confirmation
          _setupFirstCode = '';
          _isConfirmingSetup = false;
          _triggerErrorShake("PINs do not match. Restart setup.");
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: !widget.isVerifying 
          ? AppBar(
              title: const Text("Setup Security Lock"),
              backgroundColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context, false),
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Title Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (widget.isVerifying ? theme.primaryColor : const Color(0xFF10B981)).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.isVerifying ? Icons.lock_outline_rounded : Icons.security_rounded,
                size: 40,
                color: widget.isVerifying ? theme.primaryColor : const Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 24),
            
            // Text Header
            Text(
              widget.isVerifying ? "Welcome Back" : "Security Lock",
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: _shakeController.isAnimating ? Colors.red : theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                ),
              ),
            ),
            
            const SizedBox(height: 36),
            
            // Dots indicator with Shake Animation
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                // Generate a custom horizontal offset based on sine function and shake value
                final offset = _shakeAnimation.value * sin(_shakeAnimation.value * pi * 0.1);
                return Transform.translate(
                  offset: Offset(offset, 0),
                  child: child,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final filled = index < _inputCode.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: filled 
                          ? (widget.isVerifying ? theme.primaryColor : const Color(0xFF10B981))
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: filled 
                            ? (widget.isVerifying ? theme.primaryColor : const Color(0xFF10B981))
                            : (isDark ? Colors.white24 : Colors.black26),
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
            ),
            
            if (widget.isVerifying && Provider.of<KhataProvider>(context, listen: false).biometricLockEnabled) ...[
              const SizedBox(height: 24),
              IconButton(
                icon: const Icon(Icons.fingerprint, size: 48, color: Colors.blueAccent),
                tooltip: "Unlock with Biometrics",
                onPressed: _checkAndTriggerBiometrics,
              ),
            ],
            
            const Spacer(),
            
            // Numpad input
            CustomNumpad(
              onKeyPressed: _onKeyPress,
              onDeletePressed: _onDelete,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

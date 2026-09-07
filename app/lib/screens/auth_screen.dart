import 'package:flutter/material.dart';
import '../services/solana_service.dart';
import '../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  final SolanaService service;

  const AuthScreen({super.key, required this.service});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _emailCtrl = TextEditingController(text: 'alex.chen@acmecorp.com');
  final TextEditingController _otpCtrl = TextEditingController();
  bool _isOtpSent = false;
  String? _generatedOtp;
  String? _errorMsg;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _handleWorkEmailSubmit() async {
    final email = _emailCtrl.text.trim();
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _errorMsg = 'Please enter a valid work email address.');
      return;
    }

    setState(() {
      _errorMsg = null;
    });

    final otp = await widget.service.requestEmailOtp(email);
    setState(() {
      _generatedOtp = otp;
      _otpCtrl.text = otp; // Pre-fill for instantaneous demo testing
      _isOtpSent = true;
    });
  }

  void _handleVerifyOtp() async {
    final email = _emailCtrl.text.trim();
    final code = _otpCtrl.text.trim();

    if (code.isEmpty) {
      setState(() => _errorMsg = 'Please enter the 6-digit verification code.');
      return;
    }

    final success = await widget.service.verifyEmailOtp(email, code);
    if (!success) {
      setState(() => _errorMsg = 'Invalid verification code. Please try again.');
    }
  }

  void _handleGoogleSignIn() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderHover,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Choose a Google Account',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textMain),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const Text(
                'to continue to Solana Identity & Wallet',
                style: TextStyle(fontSize: 13, color: AppColors.textDim),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Account Option 1
              _GoogleAccountTile(
                name: 'Alex Chen',
                email: 'alex.chen@gmail.com',
                onTap: () {
                  Navigator.pop(context);
                  widget.service.signInWithGoogle(name: 'Alex Chen', email: 'alex.chen@gmail.com');
                },
              ),
              const SizedBox(height: 10),

              // Account Option 2
              _GoogleAccountTile(
                name: 'Elena Rostova',
                email: 'elena.rostova@techcorp.io',
                onTap: () {
                  Navigator.pop(context);
                  widget.service.signInWithGoogle(name: 'Elena Rostova', email: 'elena.rostova@techcorp.io');
                },
              ),
              const SizedBox(height: 14),

              // Use another account
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  widget.service.signInWithGoogle(name: 'Solana Dev', email: 'developer@solana.org');
                },
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 16, color: AppColors.cyan),
                label: const Text('Use another account', style: TextStyle(color: AppColors.cyan, fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.borderHover),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo & Hero Header
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.cyan],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.shield_rounded, color: Colors.white, size: 34),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Solana Identity & Wallet',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: AppColors.textMain,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Self-Sovereign Identity • Zero-Gas Transactions\nDecentralized Asset Ownership & RBAC',
                  style: TextStyle(fontSize: 13, color: AppColors.textDim, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                if (!_isOtpSent) ...[
                  // --- GOOGLE OAUTH BUTTON ---
                  ElevatedButton(
                    onPressed: widget.service.isLoading ? null : _handleGoogleSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1F2937),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Stylized Google 'G' icon
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              'G',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF4285F4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Continue with Google',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'OR WORK EMAIL',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textDim, letterSpacing: 0.5),
                        ),
                      ),
                      const Expanded(child: Divider(color: AppColors.border)),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Work Email Input Card
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Corporate Work Email',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDim),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: AppColors.textMain, fontSize: 14),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20, color: AppColors.textDim),
                            hintText: 'alex.chen@acmecorp.com',
                            hintStyle: const TextStyle(color: AppColors.textDim, fontSize: 13),
                            filled: true,
                            fillColor: AppColors.bgSecondary,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton(
                          onPressed: widget.service.isLoading ? null : _handleWorkEmailSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(46),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: widget.service.isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text(
                                  'Continue with Work Email',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // --- OTP VERIFICATION CARD ---
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.lock_clock_rounded, size: 20, color: AppColors.primaryLight),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Enter Verification Code',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textMain),
                                  ),
                                  Text(
                                    'Sent to ${_emailCtrl.text}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textDim),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Code banner
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.emerald.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.emerald.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.mark_email_read_rounded, size: 16, color: AppColors.emerald),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Demo OTP Code: $_generatedOtp (Auto-filled)',
                                  style: const TextStyle(color: AppColors.emerald, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // OTP Text field
                        TextField(
                          controller: _otpCtrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: AppTheme.mono(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textMain),
                          decoration: InputDecoration(
                            hintText: '849201',
                            hintStyle: AppTheme.mono(fontSize: 22, color: AppColors.textDim),
                            filled: true,
                            fillColor: AppColors.bgSecondary,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        ElevatedButton(
                          onPressed: widget.service.isLoading ? null : _handleVerifyOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(46),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: widget.service.isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text(
                                  'Verify & Launch Wallet',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                        ),
                        const SizedBox(height: 10),

                        TextButton(
                          onPressed: () => setState(() => _isOtpSent = false),
                          child: const Text(
                            '← Change Email',
                            style: TextStyle(fontSize: 12, color: AppColors.textDim),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (_errorMsg != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.rose.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.rose.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.rose, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMsg!,
                            style: const TextStyle(color: AppColors.rose, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 36),

                // Enterprise Security Note
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_rounded, size: 12, color: AppColors.textDim),
                      const SizedBox(width: 6),
                      Text(
                        'Secured by Solana Devnet • Non-Custodial Key Derivation',
                        style: TextStyle(fontSize: 11, color: AppColors.textDim),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleAccountTile extends StatelessWidget {
  final String name;
  final String email;
  final VoidCallback onTap;

  const _GoogleAccountTile({
    required this.name,
    required this.email,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFF4285F4),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  name[0],
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMain)),
                  Text(email, style: const TextStyle(fontSize: 11, color: AppColors.textDim)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textDim),
          ],
        ),
      ),
    );
  }
}

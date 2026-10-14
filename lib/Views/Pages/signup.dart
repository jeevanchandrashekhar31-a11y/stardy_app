import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/color_codes.dart';
import '../../services/auth_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitEmailAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an email and password')),
      );
      return;
    }

    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    );
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }

    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      if (_isLogin) {
        await AuthService.instance.signInWithEmail(email, password);
      } else {
        await AuthService.instance.signUpWithEmail(email, password);
      }
      if (!mounted) return;
      // We no longer navigate directly to /main.
      // SessionController handles routing to /syncing.
      // But we can let GoRouter intercept a go() or we can do nothing.
      // If we do nothing, GoRouter will redirect if it's already watching. Wait, does AuthPage itself get redirected?
      // Yes, if SessionState changes to Syncing, the redirect will move us to /syncing!
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String errorMsg = 'Authentication failed';
      switch (e.code) {
        case 'user-not-found':
          errorMsg = 'No user found with this email.';
          break;
        case 'wrong-password':
          errorMsg = 'Incorrect password.';
          break;
        case 'email-already-in-use':
          errorMsg = 'This email is already registered.';
          break;
        case 'invalid-credential':
          errorMsg = 'Invalid email or password.';
          break;
        default:
          errorMsg = e.message ?? errorMsg;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMsg)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("An unexpected error occurred")),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitGoogleAuth() async {
    try {
      final credential = await AuthService.instance.signInWithGoogle();
      if (credential == null || !mounted) return;
      // Navigation is handled by GoRouter's redirect based on SessionState
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Google sign-in isn't configured yet")),
      );
    }
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    bool showToggle = false,
    TextInputType keyboardType = TextInputType.text,
    IconData? icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: TextField(
        controller: controller,
        obscureText: obscure ? _obscurePassword : false,
        keyboardType: keyboardType,

        style: const TextStyle(
          fontSize: 15,
          color: AppColors.primaryDark,
          letterSpacing: -0.8,
        ),

        decoration: InputDecoration(
          hintText: hint,

          hintStyle: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            letterSpacing: -0.8,
          ),

          prefixIcon: icon != null
              ? Icon(icon, color: Colors.grey.shade600, size: 20)
              : null,

          suffixIcon: showToggle
              ? IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),

                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                )
              : null,

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),

            borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
          ),

          filled: true,
          fillColor: AppColors.background,

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFCCCCCC),

      body: Stack(
        children: [
          // BACKGROUND LOGO
          Container(
            height: size.height,

            decoration: const BoxDecoration(color: Color(0xFFCCCCCC)),

            child: Opacity(
              opacity: 0.35,

              child: Align(
                alignment: Alignment.topCenter,

                child: Padding(
                  padding: EdgeInsets.only(top: size.height * 0.05),

                  child: Image.asset(
                    'assets/images/Group_17.png',
                    width: size.width,
                    height: size.height * 0.35,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),

          // BOTTOM CARD
          Align(
            alignment: Alignment.bottomCenter,

            child: Container(
              height: _isLogin ? size.height * 0.60 : size.height * 0.68,

              width: double.infinity,

              decoration: const BoxDecoration(
                color: AppColors.background,

                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(36),
                  topRight: Radius.circular(36),
                ),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 24,
                    offset: Offset(0, -6),
                  ),
                ],
              ),

              padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),

              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    // TITLE
                    Text(
                      _isLogin ? 'Welcome Back' : 'Create Account',

                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                        letterSpacing: -0.8,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // EMAIL
                    _buildInputField(
                      controller: _emailController,
                      hint: 'Email / Phone',
                      keyboardType: TextInputType.emailAddress,
                      icon: Icons.email_outlined,
                    ),

                    const SizedBox(height: 14),

                    // PASSWORD
                    _buildInputField(
                      controller: _passwordController,
                      hint: 'Password',
                      obscure: true,
                      showToggle: true,
                      icon: Icons.lock_outline,
                    ),

                    const SizedBox(height: 14),

                    // TOGGLE LOGIN / SIGNUP
                    Align(
                      alignment: Alignment.centerRight,

                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isLogin = !_isLogin;
                          });
                        },

                        child: Row(
                          mainAxisSize: MainAxisSize.min,

                          children: [
                            Text(
                              _isLogin
                                  ? "Don't have an account "
                                  : "Already have an account ",

                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.primaryDark,
                                letterSpacing: -0.8,
                              ),
                            ),

                            const Icon(
                              Icons.arrow_forward,
                              color: AppColors.primary,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // BUTTON
                    // BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 56,

                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitEmailAuth,

                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          foregroundColor: AppColors.background,

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),

                          elevation: 0,
                        ),

                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isLogin ? 'Login' : 'Sign Up',

                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.8,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // OTHER ACCOUNT
                    Center(
                      child: Text(
                        _isLogin
                            ? 'Sign in using another account'
                            : 'Sign up using another account',

                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // GOOGLE + LINKEDIN BUTTONS
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: _submitGoogleAuth,

                            child: Container(
                              width: 58,
                              height: 58,

                              decoration: BoxDecoration(
                                color: AppColors.background,

                                borderRadius: BorderRadius.circular(16),

                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),

                                    blurRadius: 14,

                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),

                              child: const Center(
                                child: Text(
                                  'G',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "LinkedIn sign-in isn't available in this demo yet",
                                  ),
                                ),
                              );
                            },

                            child: Container(
                              width: 58,
                              height: 58,

                              decoration: BoxDecoration(
                                color: const Color(0xFF0A66C2),

                                borderRadius: BorderRadius.circular(16),

                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),

                                    blurRadius: 14,

                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),

                              child: const Center(
                                child: Text(
                                  'in',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    fontStyle: FontStyle.italic,
                                  ),
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
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _urlController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isVerifyingUrl = false;
  bool _urlVerified = false;
  String? _urlStatus;

  @override
  void initState() {
    super.initState();
    _loadUrl();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('backend_url');
    if (url != null) {
      setState(() {
        _urlController.text = url;
        _urlVerified = true;
        _urlStatus = 'Using saved backend';
      });
    }
  }

  Future<void> _login() async {
    if (!_urlVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verify backend URL before signing in.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final apiClient = Provider.of<ApiClient>(context, listen: false);
    final success = await apiClient.login(
      _urlController.text,
      _emailController.text,
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Login failed. Check credentials or URL.')),
      );
    }
  }

  Future<void> _verifyUrl() async {
    if (_urlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter backend URL to verify.')),
      );
      return;
    }

    setState(() {
      _isVerifyingUrl = true;
      _urlStatus = null;
      _urlVerified = false;
    });

    final apiClient = Provider.of<ApiClient>(context, listen: false);
    final normalized = await apiClient.verifyBackend(_urlController.text);
    if (!mounted) return;
    setState(() {
      _isVerifyingUrl = false;
      if (normalized != null) {
        _urlController.text = normalized;
        _urlVerified = true;
        _urlStatus = 'Backend verified';
      } else {
        _urlVerified = false;
        _urlStatus = 'Unable to reach backend';
      }
    });
  }

  void _handleUrlChanged(String _) {
    if (_urlVerified || _urlStatus != null) {
      setState(() {
        _urlVerified = false;
        _urlStatus = null;
      });
    }
  }

  InputDecoration _inputDecoration({
    required IconData icon,
    required String label,
    String? hint,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final fillColor =
        colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: colorScheme.primary),
      filled: true,
      fillColor: fillColor,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: colorScheme.primary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo.png',
                  height: 72,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),
                Text(
                  'Free Mail',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Self-hosted inbox access',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                Card(
                  elevation: 8,
                  color:
                      colorScheme.surfaceContainerHigh.withValues(alpha: 0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _urlController,
                            keyboardType: TextInputType.url,
                            style: TextStyle(color: colorScheme.onSurface),
                            decoration: _inputDecoration(
                              icon: Icons.link,
                              label: 'Backend URL',
                              hint: 'https://mail.yourdomain.com',
                          ).copyWith(
                            suffixIcon: IconButton(
                              onPressed: _isVerifyingUrl ? null : _verifyUrl,
                              tooltip: 'Verify backend',
                              icon: _isVerifyingUrl
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Icon(
                                      _urlVerified ? Icons.check_circle : Icons.cloud_outlined,
                                      color: _urlVerified
                                          ? colorScheme.primary
                                          : colorScheme.onSurfaceVariant,
                                    ),
                            ),
                          ),
                          onChanged: _handleUrlChanged,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter backend URL';
                              }
                              return null;
                            },
                          ),
                        if (_urlStatus != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _urlStatus!,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _urlVerified
                                  ? colorScheme.primary
                                  : colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                          enabled: _urlVerified,
                          style: TextStyle(
                            color: _urlVerified
                                ? colorScheme.onSurface
                                : colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                            decoration: _inputDecoration(
                              icon: Icons.person,
                              label: 'Email',
                              hint: 'admin@example.com',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                          enabled: _urlVerified,
                          style: TextStyle(
                            color: _urlVerified
                                ? colorScheme.onSurface
                                : colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                            decoration: _inputDecoration(
                              icon: Icons.lock,
                              label: 'Password',
                              hint: 'Your admin password',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                          onPressed: _isLoading || !_urlVerified ? null : _login,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: colorScheme.onPrimary,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Sign in'),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Use the same admin credentials configured in your backend .env file.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
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

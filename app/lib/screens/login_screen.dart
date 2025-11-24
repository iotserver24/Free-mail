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
                _urlVerified
                    ? _LoginForm(
                        formKey: _formKey,
                        emailController: _emailController,
                        passwordController: _passwordController,
                        isLoading: _isLoading,
                        onSubmit: _login,
                      )
                    : _UrlVerificationCard(
                        urlController: _urlController,
                        verifying: _isVerifyingUrl,
                        statusText: _urlStatus,
                        onVerify: _verifyUrl,
                        onChanged: _handleUrlChanged,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UrlVerificationCard extends StatelessWidget {
  const _UrlVerificationCard({
    required this.urlController,
    required this.verifying,
    required this.onVerify,
    required this.onChanged,
    this.statusText,
  });

  final TextEditingController urlController;
  final bool verifying;
  final VoidCallback onVerify;
  final ValueChanged<String> onChanged;
  final String? statusText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      elevation: 8,
      color: colors.surfaceContainerHigh.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Connect to your backend',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              keyboardType: TextInputType.url,
              style: TextStyle(color: colors.onSurface),
              decoration: InputDecoration(
                labelText: 'Backend URL',
                hintText: 'https://mail.yourdomain.com',
                prefixIcon: const Icon(Icons.link),
                suffixIcon: IconButton(
                  onPressed: verifying ? null : onVerify,
                  tooltip: 'Verify backend',
                  icon: verifying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                ),
                filled: true,
                fillColor:
                    colors.surfaceContainerHighest.withValues(alpha: 0.4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onChanged: onChanged,
            ),
            if (statusText != null) ...[
              const SizedBox(height: 12),
              Text(
                statusText!,
                style: TextStyle(
                  color: statusText!.contains('verified')
                      ? colors.primary
                      : colors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: verifying ? null : onVerify,
              child: verifying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Verify'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      elevation: 8,
      color: colors.surfaceContainerHigh.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Administrator credentials',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'admin@example.com',
                  prefixIcon: const Icon(Icons.person_outline),
                  filled: true,
                  fillColor:
                      colors.surfaceContainerHighest.withValues(alpha: 0.4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
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
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Your admin password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  filled: true,
                  fillColor:
                      colors.surfaceContainerHighest.withValues(alpha: 0.4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
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
                onPressed: isLoading
                    ? null
                    : () {
                        if (formKey.currentState?.validate() ?? false) {
                          onSubmit();
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final sp = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(sp.l10n('premium_edition'))),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.cloud_sync_rounded, size: 80, color: Color(0xFF6366F1)),
              const SizedBox(height: 24),
              Text(
                sp.languageCode == 'my' ? 'Cloud သို့ ဝင်ရောက်ရန်' : 'Cloud Sync',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5),
              ),
              const SizedBox(height: 12),
              Text(
                sp.languageCode == 'my' ? 'သင်၏ဒေတာများကို မည်သည့်နေရာမှမဆို အသုံးပြုနိုင်ရန် Google နှင့် ချိတ်ဆက်ပါ' : 'Securely sync your data with Google',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 15),
              ),
              const SizedBox(height: 48),
              
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton.icon(
                  onPressed: _loginWithGoogle,
                  icon: const Icon(Icons.g_mobiledata_rounded, size: 36),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      sp.languageCode == 'my' ? 'Google ဖြင့်ရှေ့ဆက်ရန်' : 'Continue with Google',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 8,
                    shadowColor: const Color(0xFF6366F1).withOpacity(0.4),
                  ),
                ),
              
              const SizedBox(height: 40),
              const Text(
                'By continuing, you agree to our Terms of Service.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _loginWithGoogle() async {
    setState(() => _isLoading = true);
    
    final sp = Provider.of<SettingsProvider>(context, listen: false);
    // Use the default API URL from settings
    final error = await sp.loginWithGoogle(sp.settings.apiBaseUrl);
    
    if (mounted) {
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login successful!')),
        );
        Navigator.pop(context);
      } else if (error != 'Google sign-in canceled') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
        );
      }
    }
    setState(() => _isLoading = false);
  }
}

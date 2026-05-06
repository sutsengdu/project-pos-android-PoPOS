import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/staff_provider.dart';
import '../providers/settings_provider.dart';

class StaffLoginScreen extends StatefulWidget {
  const StaffLoginScreen({super.key});

  @override
  State<StaffLoginScreen> createState() => _StaffLoginScreenState();
}

class _StaffLoginScreenState extends State<StaffLoginScreen> {
  String _pin = '';
  String? _error;

  void _handlePinInput(String val) {
    if (_pin.length < 4) {
      setState(() {
        _pin += val;
        _error = null;
      });
    }

    if (_pin.length == 4) {
      _login();
    }
  }

  void _login() async {
    final staffProvider = Provider.of<StaffProvider>(context, listen: false);
    final success = await staffProvider.login(_pin);
    if (!success) {
      setState(() {
        _pin = '';
        _error = 'Invalid PIN';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sp = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [const Color(0xFF1E1E2E), const Color(0xFF11111B)]
              : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_person_rounded, size: 80, color: Color(0xFF6366F1)),
                  const SizedBox(height: 24),
                  Text(
                    sp.languageCode == 'my' ? 'ဝန်ထမ်းဝင်ရန်' : 'Staff Login',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sp.languageCode == 'my' ? 'လျှို့ဝှက်နံပါတ် (၄) လုံး ရိုက်ထည့်ပါ' : 'Enter your 4-digit PIN',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 40),
                  
                  // PIN Display dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      bool isFilled = index < _pin.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFilled ? const Color(0xFF6366F1) : (isDark ? Colors.white10 : Colors.grey[300]),
                          border: isFilled ? null : Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
                        ),
                      );
                    }),
                  ),
                  
                  const SizedBox(height: 16),
                  if (_error != null)
                    Text(_error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 40),

                  // Number Pad
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    children: [
                      ...['1', '2', '3', '4', '5', '6', '7', '8', '9'].map(_buildNumberButton),
                      const SizedBox.shrink(),
                      _buildNumberButton('0'),
                      IconButton(
                        onPressed: () {
                          if (_pin.isNotEmpty) {
                            setState(() => _pin = _pin.substring(0, _pin.length - 1));
                          }
                        },
                        icon: const Icon(Icons.backspace_outlined, size: 28),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberButton(String val) {
    return InkWell(
      onTap: () => _handlePinInput(val),
      borderRadius: BorderRadius.circular(50),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Center(
          child: Text(val, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

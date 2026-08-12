import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;
  bool _isLoading = false;

  static const _gold = Color(0xFFF4A532);
  static const _navy = Color(0xFF060F1E);

  final List<Map<String, dynamic>> _roles = [
    {
      'id': 'buyer',
      'title': 'Buyer',
      'subtitle': 'Browse and purchase marine products',
      'icon': Icons.shopping_bag_outlined,
      'color': Color(0xFF4488FF),
      'perks': ['Browse all listings', 'Contact sellers directly', 'Track your orders'],
    },
    {
      'id': 'seller',
      'title': 'Seller',
      'subtitle': 'List and sell your marine products',
      'icon': Icons.storefront_outlined,
      'color': Color(0xFF00C896),
      'perks': ['Post unlimited listings', 'Manage orders', 'Chat with buyers'],
    },
    {
      'id': 'agent',
      'title': 'Agent',
      'subtitle': 'Facilitate marine trade deals & logistics',
      'icon': Icons.handshake_outlined,
      'color': Color(0xFFF4A532),
      'perks': ['Access all listings', 'Mediate transactions', 'Build your network'],
    },
  ];

  Future<void> _confirm() async {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a role to continue.'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Write role to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'role': _selectedRole}, SetOptions(merge: true));

      if (mounted) {
        // ── FIX: pass the selected role as a route argument so ProfileSetup
        //         can render the correct fields immediately without waiting
        //         for a Firestore round-trip
        Navigator.pushReplacementNamed(
          context,
          '/profile-setup',
          arguments: _selectedRole, // e.g. 'buyer' | 'seller' | 'agent'
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.network(
              'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: _navy),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [_navy.withOpacity(0.8), _navy.withOpacity(0.95), _navy],
              ),
            ),
          ),
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(height: 3, decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, _gold, Colors.transparent],
              ),
            )),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Step indicator
                    Row(children: List.generate(3, (i) => Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                        height: 3,
                        decoration: BoxDecoration(
                          color: i == 0 ? _gold : Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ))),
                    const SizedBox(height: 28),
                    const Text("What's your role?",
                        style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text('This helps us tailor your experience',
                        style: TextStyle(color: _gold.withOpacity(0.6), fontSize: 13)),
                  ]),
                ),
                const SizedBox(height: 28),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    itemCount: _roles.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (_, i) {
                      final role     = _roles[i];
                      final selected = _selectedRole == role['id'];
                      final color    = role['color'] as Color;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedRole = role['id']),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: selected
                                ? color.withOpacity(0.12)
                                : Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: selected ? color : Colors.white.withOpacity(0.1),
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                color: color.withOpacity(selected ? 0.2 : 0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(role['icon'] as IconData, color: color, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(role['title'] as String,
                                    style: TextStyle(
                                      color: selected ? Colors.white : Colors.white.withOpacity(0.85),
                                      fontSize: 17, fontWeight: FontWeight.w800,
                                    )),
                                const SizedBox(height: 3),
                                Text(role['subtitle'] as String,
                                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                                const SizedBox(height: 12),
                                ...(role['perks'] as List<String>).map((p) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(children: [
                                    Icon(Icons.check_circle_outline, color: color, size: 13),
                                    const SizedBox(width: 6),
                                    Text(p, style: TextStyle(
                                      color: Colors.white.withOpacity(0.55), fontSize: 12,
                                    )),
                                  ]),
                                )),
                              ],
                            )),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 22, height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selected ? color : Colors.transparent,
                                border: Border.all(
                                  color: selected ? color : Colors.white24, width: 1.5,
                                ),
                              ),
                              child: selected
                                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                                  : null,
                            ),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 16, 28, 32),
                  child: SizedBox(
                    width: double.infinity, height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _confirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gold, foregroundColor: _navy,
                        disabledBackgroundColor: _gold.withOpacity(0.3),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Continue',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                              color: Color(0xFF060F1E))),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
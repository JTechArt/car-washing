import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'moderator_auth_provider.dart';

class ModeratorLoginScreen extends ConsumerStatefulWidget {
  const ModeratorLoginScreen({super.key});

  @override
  ConsumerState<ModeratorLoginScreen> createState() =>
      _ModeratorLoginScreenState();
}

class _ModeratorLoginScreenState
    extends ConsumerState<ModeratorLoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await ref.read(moderatorAuthProvider.notifier).login(
          _phoneCtrl.text.trim(),
          _passCtrl.text,
        );
    if (mounted &&
        ref.read(moderatorAuthProvider).value?.status ==
            ModeratorAuthStatus.authenticated) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(moderatorAuthProvider);
    final isLoading = auth.isLoading;
    final error = auth.hasError ? auth.error.toString() : null;

    return Scaffold(
      backgroundColor: const Color(0xFF1B4F72),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(48),
          child: SizedBox(
            width: 420,
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B4F72),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text('Լ',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Lva Moderator',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                          Text('Staff Operations Panel',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '+374 77 123 456',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(error,
                          style: TextStyle(color: Colors.red.shade700)),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: isLoading ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1B4F72),
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Sign In',
                            style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 12),
                  const Text('For authorized staff only',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

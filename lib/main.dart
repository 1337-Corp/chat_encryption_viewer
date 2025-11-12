import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';
import 'encryption_demo_service.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(const ChatEncryptionViewerApp());
}

class ChatEncryptionViewerApp extends StatelessWidget {
  const ChatEncryptionViewerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat Encryption Viewer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session;

        if (session != null) {
          return const EncryptionViewerPage();
        }

        return const LoginPage();
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Initialize encryption
      final userId = Supabase.instance.client.auth.currentUser!.id;
      await EncryptionDemoService.initializeForPassword(
        _passwordController.text,
        userId,
      );
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 80,
                  color: Colors.deepPurpleAccent,
                ),
                const SizedBox(height: 24),
                Text(
                  'Chat Encryption Viewer',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'See how your chats are encrypted',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outlined),
                  ),
                  obscureText: true,
                  enabled: !_isLoading,
                  onSubmitted: _isLoading ? null : (_) => _signIn(),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign In'),
                  ),
                ),
                const SizedBox(height: 24),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline,
                                size: 20, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              'About This App',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          'This is a proof-of-concept app that demonstrates how chats are stored encrypted in the chuk_chat application.',
                          style: TextStyle(fontSize: 14),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• End-to-end encryption with AES-256-GCM\n'
                          '• Client-side encryption (server never sees plaintext)\n'
                          '• 600,000 PBKDF2 iterations for key derivation',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
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

class EncryptionViewerPage extends StatefulWidget {
  const EncryptionViewerPage({super.key});

  @override
  State<EncryptionViewerPage> createState() => _EncryptionViewerPageState();
}

class _EncryptionViewerPageState extends State<EncryptionViewerPage> {
  bool _showEncrypted = true;
  bool _isLoading = true;
  final List<Map<String, String>> _demoChats = [];

  @override
  void initState() {
    super.initState();
    _initializeDemo();
  }

  Future<void> _initializeDemo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final keyLoaded = await EncryptionDemoService.tryLoadKey(userId);

      if (!keyLoaded) {
        // Key not available, will need to re-login
        await Supabase.instance.client.auth.signOut();
        return;
      }

      // Create demo chats
      _demoChats.addAll([
        {
          'title': 'Chat 1: Secret Project Discussion',
          'message': 'Let\'s discuss the new secret project tomorrow at 3 PM.',
        },
        {
          'title': 'Chat 2: API Keys',
          'message': 'The API key is: sk-abc123def456. Don\'t share it!',
        },
        {
          'title': 'Chat 3: Personal Information',
          'message':
              'My address is 123 Main St, and my phone is 555-1234. Call me!',
        },
      ]);
    } catch (e) {
      debugPrint('Error initializing: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    EncryptionDemoService.clearKey();
    await Supabase.instance.client.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Encrypted Chats Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.deepPurple.withOpacity(0.1),
                  child: Row(
                    children: [
                      const Icon(Icons.account_circle, color: Colors.white70),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.email ?? 'Unknown User',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Your chats are encrypted client-side',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Toggle switch
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _showEncrypted ? Icons.lock : Icons.lock_open,
                            color: _showEncrypted
                                ? Colors.green
                                : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _showEncrypted
                                ? 'Showing: Encrypted'
                                : 'Showing: Decrypted',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      Switch(
                        value: _showEncrypted,
                        onChanged: (value) {
                          setState(() {
                            _showEncrypted = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Chat list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _demoChats.length,
                    itemBuilder: (context, index) {
                      return ChatCard(
                        title: _demoChats[index]['title']!,
                        message: _demoChats[index]['message']!,
                        showEncrypted: _showEncrypted,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class ChatCard extends StatefulWidget {
  final String title;
  final String message;
  final bool showEncrypted;

  const ChatCard({
    super.key,
    required this.title,
    required this.message,
    required this.showEncrypted,
  });

  @override
  State<ChatCard> createState() => _ChatCardState();
}

class _ChatCardState extends State<ChatCard> {
  String? _encryptedText;
  bool _isEncrypting = false;

  @override
  void initState() {
    super.initState();
    _encryptMessage();
  }

  Future<void> _encryptMessage() async {
    setState(() {
      _isEncrypting = true;
    });

    try {
      final encrypted = await EncryptionDemoService.encrypt(widget.message);
      if (mounted) {
        setState(() {
          _encryptedText = encrypted;
          _isEncrypting = false;
        });
      }
    } catch (e) {
      debugPrint('Encryption error: $e');
      if (mounted) {
        setState(() {
          _isEncrypting = false;
        });
      }
    }
  }

  String _formatEncryptedText(String encrypted) {
    try {
      final json = jsonDecode(encrypted) as Map<String, dynamic>;
      final formatted = const JsonEncoder.withIndent('  ').convert(json);
      return formatted;
    } catch (e) {
      return encrypted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.showEncrypted
                    ? Colors.red.withOpacity(0.1)
                    : Colors.green.withOpacity(0.1),
                border: Border.all(
                  color: widget.showEncrypted
                      ? Colors.red.withOpacity(0.3)
                      : Colors.green.withOpacity(0.3),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _isEncrypting
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : SelectableText(
                      widget.showEncrypted
                          ? _formatEncryptedText(_encryptedText ?? 'Encrypting...')
                          : widget.message,
                      style: TextStyle(
                        fontFamily: widget.showEncrypted ? 'monospace' : null,
                        fontSize: widget.showEncrypted ? 12 : 14,
                        color: widget.showEncrypted
                            ? Colors.red.shade300
                            : Colors.green.shade300,
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  widget.showEncrypted ? Icons.lock : Icons.lock_open,
                  size: 14,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.showEncrypted
                        ? 'Encrypted (as stored on device)'
                        : 'Decrypted (only visible with your password)',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

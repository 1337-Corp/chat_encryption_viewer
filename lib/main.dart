import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';
import 'encryption_service.dart';
import 'dart:convert';
import 'utils/color_extensions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(const ChatEncryptionViewerApp());
}

// Theme colors (matching chuk_chat)
const Color kDefaultBgColor = Color(0xFF211B15);
const Color kDefaultAccentColor = Color(0xFF3F5E5D);
const Color kDefaultIconFgColor = Color(0xFF93854C);

class ChatEncryptionViewerApp extends StatelessWidget {
  const ChatEncryptionViewerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat Encryption Viewer',
      debugShowCheckedModeBanner: false,
      theme: _buildAppTheme(),
      home: const AuthGate(),
    );
  }

  ThemeData _buildAppTheme() {
    const accent = kDefaultAccentColor;
    const iconFg = kDefaultIconFgColor;
    const bg = kDefaultBgColor;

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      cardColor: bg,
      dividerColor: iconFg.withValues(alpha: .4),
      iconTheme: const IconThemeData(color: iconFg),
      colorScheme: const ColorScheme(
        primary: accent,
        secondary: iconFg,
        surface: bg,
        error: Colors.red,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: iconFg,
        onError: Colors.white,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: IconThemeData(color: iconFg),
        titleTextStyle: TextStyle(color: iconFg, fontSize: 20),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bg.lighten(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: iconFg.withValues(alpha: 0.3), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: iconFg.withValues(alpha: 0.3), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        labelStyle: TextStyle(color: iconFg.withValues(alpha: 0.8)),
        hintStyle: TextStyle(color: iconFg.withValues(alpha: 0.6)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
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
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

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
      await EncryptionService.initializeForPassword(_passwordController.text);
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
    final theme = Theme.of(context);
    final scaffoldBg = theme.scaffoldBackgroundColor;
    final iconFg = theme.iconTheme.color ?? Colors.white;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              color: scaffoldBg.lighten(0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: iconFg.withValues(alpha: 0.2)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Chat Encryption Viewer',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: iconFg,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to view your encrypted chats',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: iconFg.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'you@example.com',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter your email address.';
                          }
                          if (!value.contains('@')) {
                            return 'Email looks invalid.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                        ),
                        obscureText: _obscurePassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter your password.';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters.';
                          }
                          return null;
                        },
                        onFieldSubmitted: _isLoading ? null : (_) => _signIn(),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signIn,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Sign in'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline,
                                    size: 16,
                                    color: theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'About This App',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'View your real chats from chuk_chat. Toggle between encrypted (as stored) and decrypted views.',
                              style: TextStyle(
                                fontSize: 12,
                                color: iconFg.withValues(alpha: 0.7),
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
  List<Map<String, dynamic>> _chats = [];
  List<Map<String, dynamic>> _filteredChats = [];
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  final Map<String, String> _chatTitles = {}; // Cache decrypted titles

  @override
  void initState() {
    super.initState();
    _loadChats();
    _searchController.addListener(_filterChats);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterChats() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredChats = _chats;
      } else {
        _filteredChats = _chats.where((chat) {
          final title = _chatTitles[chat['id']] ?? '';
          return title.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _loadChats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final keyLoaded = await EncryptionService.tryLoadKey();

      if (!keyLoaded) {
        // Key not available, will need to re-login
        await Supabase.instance.client.auth.signOut();
        return;
      }

      // Fetch ALL chats from Supabase (no limit)
      final data = await Supabase.instance.client
          .from('encrypted_chats')
          .select('id, encrypted_payload, created_at, is_starred')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        _chats = data
            .whereType<Map<String, dynamic>>()
            .map((chat) => Map<String, dynamic>.from(chat))
            .toList();
        _filteredChats = _chats;
      });

      // Decrypt titles for search
      _decryptTitles();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading chats: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _decryptTitles() async {
    for (var chat in _chats) {
      try {
        final encryptedPayload = chat['encrypted_payload'] as String;
        final decrypted = await EncryptionService.decrypt(encryptedPayload);
        final payload = jsonDecode(decrypted) as Map<String, dynamic>;
        final messages = payload['messages'] as List?;

        if (messages != null && messages.isNotEmpty) {
          final firstMessage = messages.first as Map<String, dynamic>;
          final text = firstMessage['text'] as String? ?? '';
          _chatTitles[chat['id']] = text.trim();
        }
      } catch (e) {
        // Skip if can't decrypt
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _signOut() async {
    await EncryptionService.clearKey();
    await Supabase.instance.client.auth.signOut();
  }

  Future<void> _exportChats(bool encrypted) async {
    if (_chats.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No chats to export')),
      );
      return;
    }

    try {
      final exportData = <Map<String, dynamic>>[];

      for (var chat in _chats) {
        if (encrypted) {
          // Export encrypted
          exportData.add({
            'id': chat['id'],
            'encrypted_payload': chat['encrypted_payload'],
            'created_at': chat['created_at'],
            'is_starred': chat['is_starred'],
          });
        } else {
          // Export decrypted
          final encryptedPayload = chat['encrypted_payload'] as String;
          final decrypted = await EncryptionService.decrypt(encryptedPayload);
          final payload = jsonDecode(decrypted) as Map<String, dynamic>;

          exportData.add({
            'id': chat['id'],
            'messages': payload['messages'],
            'created_at': chat['created_at'],
            'is_starred': chat['is_starred'],
          });
        }
      }

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      if (!mounted) return;

      // Show export dialog with the JSON
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(encrypted ? 'Encrypted Chats (JSON)' : 'Decrypted Chats (JSON)'),
          content: SingleChildScrollView(
            child: SelectableText(
              jsonString,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Copy to clipboard
                Clipboard.setData(ClipboardData(text: jsonString));
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
              child: const Text('Copy to Clipboard'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = Supabase.instance.client.auth.currentUser;
    final iconFg = theme.iconTheme.color ?? Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Encrypted Chats Viewer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadChats,
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.file_download),
            tooltip: 'Export Chats',
            onSelected: (value) {
              if (value == 'encrypted') {
                _exportChats(true);
              } else if (value == 'decrypted') {
                _exportChats(false);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'encrypted',
                child: Row(
                  children: [
                    Icon(Icons.lock, size: 20),
                    SizedBox(width: 12),
                    Text('Export Encrypted (JSON)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'decrypted',
                child: Row(
                  children: [
                    Icon(Icons.lock_open, size: 20),
                    SizedBox(width: 12),
                    Text('Export Decrypted (JSON)'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadChats,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Info banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      child: Row(
                        children: [
                          Icon(Icons.account_circle,
                              color: iconFg.withValues(alpha: 0.7)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.email ?? 'Unknown User',
                                  style: TextStyle(
                                    color: iconFg,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Total: ${_chats.length} chats${_filteredChats.length != _chats.length ? ' (${_filteredChats.length} shown)' : ''}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: iconFg.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Search bar
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search chats...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                    // Toggle switch
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: iconFg,
                                ),
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
                      child: _filteredChats.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.chat_bubble_outline,
                                      size: 64,
                                      color: iconFg.withValues(alpha: 0.3)),
                                  const SizedBox(height: 16),
                                  Text(
                                    _chats.isEmpty ? 'No chats found' : 'No matching chats',
                                    style: TextStyle(
                                      color: iconFg.withValues(alpha: 0.6),
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _chats.isEmpty
                                        ? 'Start chatting in chuk_chat to see them here!'
                                        : 'Try a different search term',
                                    style: TextStyle(
                                      color: iconFg.withValues(alpha: 0.4),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredChats.length,
                              itemBuilder: (context, index) {
                                return ChatCard(
                                  chat: _filteredChats[index],
                                  showEncrypted: _showEncrypted,
                                  index: index + 1,
                                  title: _chatTitles[_filteredChats[index]['id']],
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => ChatDetailPage(
                                          chat: _filteredChats[index],
                                        ),
                                      ),
                                    );
                                  },
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
  final Map<String, dynamic> chat;
  final bool showEncrypted;
  final int index;
  final String? title;
  final VoidCallback? onTap;

  const ChatCard({
    super.key,
    required this.chat,
    required this.showEncrypted,
    required this.index,
    this.title,
    this.onTap,
  });

  @override
  State<ChatCard> createState() => _ChatCardState();
}

class _ChatCardState extends State<ChatCard> {
  String? _decryptedPreview;
  bool _isDecrypting = false;
  String? _decryptionError;

  @override
  void initState() {
    super.initState();
    // Use cached title if available, otherwise decrypt
    if (widget.title != null && widget.title!.isNotEmpty) {
      _decryptedPreview = widget.title;
      _isDecrypting = false;
    } else {
      _decryptChat();
    }
  }

  @override
  void didUpdateWidget(ChatCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title && widget.title != null) {
      setState(() {
        _decryptedPreview = widget.title;
      });
    }
  }

  Future<void> _decryptChat() async {
    setState(() {
      _isDecrypting = true;
      _decryptionError = null;
    });

    try {
      final encryptedPayload = widget.chat['encrypted_payload'] as String;
      final decrypted = await EncryptionService.decrypt(encryptedPayload);
      final payload = jsonDecode(decrypted) as Map<String, dynamic>;
      final messages = payload['messages'] as List?;

      if (messages != null && messages.isNotEmpty) {
        final firstMessage = messages.first as Map<String, dynamic>;
        final text = firstMessage['text'] as String? ?? '';
        if (mounted) {
          setState(() {
            _decryptedPreview = text.trim().isEmpty
                ? 'Chat ${widget.index}'
                : text;
            _isDecrypting = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _decryptedPreview = 'Chat ${widget.index}';
            _isDecrypting = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _decryptionError = e.toString();
          _isDecrypting = false;
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
    final theme = Theme.of(context);
    final iconFg = theme.iconTheme.color ?? Colors.white;
    final encryptedPayload = widget.chat['encrypted_payload'] as String;
    final createdAt = DateTime.parse(widget.chat['created_at'] as String);
    final isStarred = widget.chat['is_starred'] as bool? ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: theme.scaffoldBackgroundColor.lighten(0.03),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: iconFg.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
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
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isDecrypting
                        ? 'Chat ${widget.index} (decrypting...)'
                        : _decryptedPreview ?? 'Chat ${widget.index}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: iconFg,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isStarred)
                  Icon(Icons.star, size: 20, color: theme.colorScheme.primary),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Created: ${createdAt.toLocal().toString().split('.')[0]}',
              style: TextStyle(
                fontSize: 12,
                color: iconFg.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.showEncrypted
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.green.withValues(alpha: 0.1),
                border: Border.all(
                  color: widget.showEncrypted
                      ? Colors.red.withValues(alpha: 0.3)
                      : Colors.green.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _isDecrypting && !widget.showEncrypted
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _decryptionError != null && !widget.showEncrypted
                      ? SelectableText(
                          'Decryption error: $_decryptionError',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        )
                      : SelectableText(
                          widget.showEncrypted
                              ? _formatEncryptedText(encryptedPayload)
                              : _decryptedPreview ?? 'Chat ${widget.index}',
                          style: TextStyle(
                            fontFamily:
                                widget.showEncrypted ? 'monospace' : null,
                            fontSize: widget.showEncrypted ? 11 : 14,
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
                  color: iconFg.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.showEncrypted
                        ? 'Encrypted (as stored in database)'
                        : 'Decrypted (only visible with your password)',
                    style: TextStyle(
                      fontSize: 12,
                      color: iconFg.withValues(alpha: 0.5),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// Detail page to show full conversation
class ChatDetailPage extends StatefulWidget {
  final Map<String, dynamic> chat;

  const ChatDetailPage({super.key, required this.chat});

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  List<Map<String, dynamic>>? _messages;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final encryptedPayload = widget.chat['encrypted_payload'] as String;
      final decrypted = await EncryptionService.decrypt(encryptedPayload);
      final payload = jsonDecode(decrypted) as Map<String, dynamic>;
      final messages = payload['messages'] as List?;

      if (messages != null) {
        setState(() {
          _messages = messages
              .map((m) => Map<String, dynamic>.from(m as Map))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _messages = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to decrypt chat: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconFg = theme.iconTheme.color ?? Colors.white;
    final createdAt = DateTime.parse(widget.chat['created_at'] as String);
    final isStarred = widget.chat['is_starred'] as bool? ?? false;

    // Get chat title from first message
    String chatTitle = 'Chat';
    if (_messages != null && _messages!.isNotEmpty) {
      final firstMsg = _messages!.first['text'] as String? ?? '';
      chatTitle = firstMsg.trim().isEmpty ? 'Chat' : firstMsg;
      if (chatTitle.length > 50) {
        chatTitle = '${chatTitle.substring(0, 50)}...';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              chatTitle,
              style: const TextStyle(fontSize: 18),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Created: ${createdAt.toLocal().toString().split('.')[0]}',
              style: TextStyle(
                fontSize: 12,
                color: iconFg.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        actions: [
          if (isStarred)
            Icon(Icons.star, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                )
              : _messages!.isEmpty
                  ? Center(
                      child: Text(
                        'No messages in this chat',
                        style: TextStyle(
                          color: iconFg.withValues(alpha: 0.6),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages!.length,
                      itemBuilder: (context, index) {
                        final message = _messages![index];
                        final sender = message['sender'] as String? ?? 'user';
                        final text = message['text'] as String? ?? '';
                        final reasoning = message['reasoning'] as String? ?? '';
                        final isUser = sender == 'user';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Avatar
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: isUser
                                    ? theme.colorScheme.primary.withValues(alpha: 0.2)
                                    : theme.colorScheme.secondary.withValues(alpha: 0.2),
                                child: Icon(
                                  isUser ? Icons.person : Icons.smart_toy,
                                  size: 20,
                                  color: isUser
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.secondary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Message content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isUser ? 'You' : 'AI Assistant',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: iconFg,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: theme.scaffoldBackgroundColor
                                            .lighten(0.05),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: iconFg.withValues(alpha: 0.2),
                                        ),
                                      ),
                                      child: SelectableText(
                                        text,
                                        style: TextStyle(
                                          color: iconFg,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    if (reasoning.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Colors.blue.withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.lightbulb_outline,
                                                  size: 16,
                                                  color: Colors.blue.shade300,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Reasoning',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                    color: Colors.blue.shade300,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            SelectableText(
                                              reasoning,
                                              style: TextStyle(
                                                color: Colors.blue.shade200,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}

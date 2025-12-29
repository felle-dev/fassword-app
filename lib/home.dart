import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:fassword/services.dart';
import 'package:fassword/models.dart';
import 'package:fassword/password_detail.dart';
import 'package:fassword/password_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SecureStorageService _storage = SecureStorageService();
  List<PasswordEntry> _passwords = [];
  List<PasswordEntry> _filteredPasswords = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPasswords();
    _searchController.addListener(_filterPasswords);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPasswords() async {
    setState(() => _isLoading = true);
    final passwords = await _storage.getPasswords();
    setState(() {
      _passwords = passwords;
      _filteredPasswords = passwords;
      _isLoading = false;
    });
  }

  void _filterPasswords() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPasswords = _passwords
          .where(
            (p) =>
                p.website.toLowerCase().contains(query) ||
                p.username.toLowerCase().contains(query),
          )
          .toList();
    });
  }

  Future<void> _addOrEditPassword([PasswordEntry? entry]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditPasswordScreen(entry: entry)),
    );

    if (result != null) {
      if (entry == null) {
        _passwords.add(result);
      } else {
        final index = _passwords.indexWhere((p) => p.id == entry.id);
        if (index != -1) _passwords[index] = result;
      }
      await _storage.savePasswords(_passwords);
      _loadPasswords();
    }
  }

  Future<void> _deletePassword(PasswordEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded),
        title: const Text('Delete Password'),
        content: Text(
          'Are you sure you want to delete the password for ${entry.website}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _passwords.removeWhere((p) => p.id == entry.id);
      await _storage.savePasswords(_passwords);
      _loadPasswords();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Password deleted')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Fassword'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'Fassword',
                applicationVersion: '1.0.0',
                applicationIcon: Icon(
                  Icons.lock_rounded,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
                children: [const Text('A secure and simple password manager.')],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search passwords',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPasswords.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 80,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _searchController.text.isEmpty
                                ? 'No passwords saved'
                                : 'No results found',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (_searchController.text.isEmpty) ...[
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () => _addOrEditPassword(),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Password'),
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _filteredPasswords.length,
                    itemBuilder: (ctx, i) {
                      final entry = _filteredPasswords[i];
                      final initial = entry.website.isNotEmpty
                          ? entry.website[0].toUpperCase()
                          : '?';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            color: theme.colorScheme.surface,
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _showPasswordDetails(entry),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: theme.colorScheme.primary,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        initial,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.website,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          entry.username,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton(
                                    icon: const Icon(Icons.more_vert),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    itemBuilder: (ctx) => [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.edit_outlined,
                                              size: 20,
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                            const SizedBox(width: 12),
                                            const Text('Edit'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete_outline,
                                              size: 20,
                                              color: theme.colorScheme.error,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: theme.colorScheme.error,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _addOrEditPassword(entry);
                                      } else if (value == 'delete') {
                                        _deletePassword(entry);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 100), // Space for FAB
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEditPassword(),
        icon: const Icon(Icons.add),
        label: const Text('Add Password'),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _showPasswordDetails(PasswordEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => PasswordDetailsSheet(
        entry: entry,
        onEdit: () {
          Navigator.pop(ctx);
          _addOrEditPassword(entry);
        },
        onDelete: () {
          Navigator.pop(ctx);
          _deletePassword(entry);
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/auth_session.dart';

// ── Model ──────────────────────────────────────────────────────────────────────

class UserModel {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final int roleId;
  final String? phone;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.roleId,
    this.phone,
  });

  String get fullName => '$firstName $lastName'.trim();
  String get roleName =>
      roleId == 3 ? 'Admin' : roleId == 2 ? 'Owner' : 'Renter';
  bool get isAdmin => roleId == 3;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>? ?? {};
    final roles = json['roles'] as List<dynamic>? ?? [];
    final roleId =
        roles.isNotEmpty ? (roles[0]['id'] as int? ?? 1) : 1;
    return UserModel(
      id: json['id'] as int,
      firstName: profile['first_name']?.toString() ??
          json['name']?.toString() ??
          'User',
      lastName: profile['last_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      roleId: roleId,
      phone: profile['phone']?.toString() ?? json['phone']?.toString(),
    );
  }
}

// ── Screen ─────────────────────────────────────────────────────────────────────

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<UserModel> _users = [];
  List<UserModel> _filtered = [];
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchCtrl.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService.getUsers(AuthSession.instance.token);
      if (res['status'] == 200) {
        final raw = res['body'];
        final list = (raw is List ? raw : (raw['data'] ?? raw['users'] ?? [])) as List<dynamic>;
        final users = list
            .map((j) => UserModel.fromJson(j as Map<String, dynamic>))
            .toList();
        setState(() {
          _users = users;
          _filtered = users;
          _loading = false;
        });
      } else {
        setState(() {
          _error = res['body']?['message']?.toString() ?? 'Failed to load users';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
        _loading = false;
      });
    }
  }

  void _filterUsers() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _users
          .where((u) =>
              u.fullName.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q) ||
              u.roleName.toLowerCase().contains(q))
          .toList();
    });
  }

  Future<void> _deleteUser(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete User'),
        content: Text(
            'Delete ${user.fullName}? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final res = await ApiService.deleteUser(
          AuthSession.instance.token, user.id);
      if (res['status'] == 200 || res['status'] == 204) {
        setState(() {
          _users.removeWhere((u) => u.id == user.id);
          _filtered.removeWhere((u) => u.id == user.id);
        });
        _showSnack('User deleted');
      } else {
        _showSnack(
            res['body']?['message']?.toString() ?? 'Delete failed',
            error: true);
      }
    } catch (e) {
      _showSnack('Error: $e', error: true);
    }
  }

  Future<void> _toggleAdmin(UserModel user) async {
    try {
      final res = user.isAdmin
          ? await ApiService.demoteFromAdmin(
              AuthSession.instance.token, user.id)
          : await ApiService.promoteToAdmin(
              AuthSession.instance.token, user.id);
      if (res['status'] == 200) {
        _loadUsers();
        _showSnack(user.isAdmin
            ? '${user.firstName} is no longer admin'
            : '${user.firstName} is now admin');
      } else {
        _showSnack(
            res['body']?['message']?.toString() ?? 'Role change failed',
            error: true);
      }
    } catch (e) {
      _showSnack('Error: $e', error: true);
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red : null,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _openForm({UserModel? user}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserFormSheet(
        user: user,
        onSaved: (data) async {
          try {
            if (user == null) {
              final res = await ApiService.createUser(
                  AuthSession.instance.token, data);
              if (res['status'] == 201 || res['status'] == 200) {
                _loadUsers();
                _showSnack('User created');
              } else {
                _showSnack(
                    res['body']?['message']?.toString() ?? 'Create failed',
                    error: true);
              }
            } else {
              final res = await ApiService.updateUser(
                  AuthSession.instance.token, user.id, data);
              if (res['status'] == 200) {
                _loadUsers();
                _showSnack('User updated');
              } else {
                _showSnack(
                    res['body']?['message']?.toString() ?? 'Update failed',
                    error: true);
              }
            }
          } catch (e) {
            _showSnack('Error: $e', error: true);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminCount = _users.where((u) => u.isAdmin).length;
    final ownerCount = _users.where((u) => u.roleId == 2).length;
    final renterCount = _users.where((u) => u.roleId == 1).length;

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        title: const Text('Manage Users',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () => _openForm(),
            tooltip: 'Add User',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_outlined,
                          size: 52, color: AppTheme.textGrey),
                      const SizedBox(height: 12),
                      Text(_error!,
                          style:
                              const TextStyle(color: AppTheme.textGrey),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadUsers,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadUsers,
                  child: Column(
                    children: [
                      // Stats bar
                      Container(
                        color: AppTheme.primaryBlue,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Row(
                          children: [
                            _statPill('👑', '$adminCount', 'Admins'),
                            const SizedBox(width: 8),
                            _statPill('🏠', '$ownerCount', 'Owners'),
                            const SizedBox(width: 8),
                            _statPill('🎓', '$renterCount', 'Renters'),
                            const Spacer(),
                            Text(
                              '${_users.length} total',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      // Search
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            hintText: 'Search by name, email or role...',
                            hintStyle: const TextStyle(
                                fontSize: 13, color: AppTheme.textGrey),
                            prefixIcon: const Icon(Icons.search,
                                color: AppTheme.textGrey, size: 20),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                          ),
                        ),
                      ),
                      // List
                      Expanded(
                        child: _filtered.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('👤',
                                        style: TextStyle(fontSize: 48)),
                                    const SizedBox(height: 12),
                                    Text(
                                      _searchCtrl.text.isEmpty
                                          ? 'No users yet'
                                          : 'No results for "${_searchCtrl.text}"',
                                      style: const TextStyle(
                                          color: AppTheme.textGrey),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 10, 16, 24),
                                itemCount: _filtered.length,
                                itemBuilder: (ctx, i) => _UserCard(
                                  user: _filtered[i],
                                  onEdit: () =>
                                      _openForm(user: _filtered[i]),
                                  onDelete: () =>
                                      _deleteUser(_filtered[i]),
                                  onToggleAdmin: () =>
                                      _toggleAdmin(_filtered[i]),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _statPill(String emoji, String count, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text('$count $label',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── User Card ──────────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleAdmin;

  const _UserCard({
    required this.user,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final roleColor = user.isAdmin
        ? const Color(0xFF8E24AA)
        : user.roleId == 2
            ? AppTheme.primaryBlue
            : const Color(0xFF2E7D32);
    final roleEmoji =
        user.isAdmin ? '👑' : user.roleId == 2 ? '🏠' : '🎓';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: roleColor.withValues(alpha: 0.12),
            ),
            child: Center(
                child:
                    Text(roleEmoji, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName.isEmpty ? '(no name)' : user.fullName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textGrey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    user.roleName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: roleColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _iconBtn(Icons.edit_outlined, AppTheme.primaryBlue,
                  'Edit', onEdit),
              _iconBtn(
                user.isAdmin ? Icons.star_rounded : Icons.star_outline_rounded,
                user.isAdmin
                    ? const Color(0xFF8E24AA)
                    : AppTheme.textGrey,
                user.isAdmin ? 'Remove Admin' : 'Make Admin',
                onToggleAdmin,
              ),
              _iconBtn(Icons.delete_outline_rounded, Colors.red,
                  'Delete', onDelete),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(
      IconData icon, Color color, String tooltip, VoidCallback onTap) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        icon: Icon(icon, size: 20, color: color),
        onPressed: onTap,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
      ),
    );
  }
}

// ── Add / Edit Form Sheet ─────────────────────────────────────────────────────

class _UserFormSheet extends StatefulWidget {
  final UserModel? user;
  final Future<void> Function(Map<String, dynamic>) onSaved;

  const _UserFormSheet({this.user, required this.onSaved});

  @override
  State<_UserFormSheet> createState() => _UserFormSheetState();
}

class _UserFormSheetState extends State<_UserFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstCtrl;
  late final TextEditingController _lastCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passCtrl;
  late final TextEditingController _phoneCtrl;
  int _roleId = 1;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _firstCtrl = TextEditingController(text: u?.firstName ?? '');
    _lastCtrl = TextEditingController(text: u?.lastName ?? '');
    _emailCtrl = TextEditingController(text: u?.email ?? '');
    _passCtrl = TextEditingController();
    _phoneCtrl = TextEditingController(text: u?.phone ?? '');
    _roleId = u?.roleId ?? 1;
  }

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = <String, dynamic>{
      'first_name': _firstCtrl.text.trim(),
      'last_name': _lastCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'role_id': _roleId,
      if (widget.user == null || _passCtrl.text.isNotEmpty)
        'password': _passCtrl.text,
    };
    await widget.onSaved(data);
    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.user != null;
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.lightGrey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  isEdit ? 'Edit User' : 'Add New User',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark),
                ),
                const SizedBox(height: 18),
                Row(children: [
                  Expanded(
                      child: _field('First Name', _firstCtrl,
                          required: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _field('Last Name', _lastCtrl)),
                ]),
                const SizedBox(height: 14),
                _field('Email', _emailCtrl,
                    required: true,
                    keyboard: TextInputType.emailAddress),
                const SizedBox(height: 14),
                _field(
                  isEdit
                      ? 'New Password (blank = keep current)'
                      : 'Password',
                  _passCtrl,
                  required: !isEdit,
                  obscure: true,
                ),
                const SizedBox(height: 14),
                _field('Phone', _phoneCtrl,
                    keyboard: TextInputType.phone),
                const SizedBox(height: 16),
                const Text('Role',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark)),
                const SizedBox(height: 10),
                Row(children: [
                  _roleChip(1, 'Renter', '🎓'),
                  const SizedBox(width: 8),
                  _roleChip(2, 'Owner', '🏠'),
                  const SizedBox(width: 8),
                  _roleChip(3, 'Admin', '👑'),
                ]),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(isEdit ? 'Save Changes' : 'Create User'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    bool required = false,
    bool obscure = false,
    TextInputType? keyboard,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppTheme.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      validator: required
          ? (v) =>
              (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
    );
  }

  Widget _roleChip(int id, String label, String emoji) {
    final selected = _roleId == id;
    return GestureDetector(
      onTap: () => setState(() => _roleId = id),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryBlue : AppTheme.inputBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.primaryBlue : AppTheme.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppTheme.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../data/mock_data.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../employee/employee_main.dart';
import '../manager/manager_main.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ShiftSyncScope.of(context);
    final user = controller.currentUser;

    if (controller.needsProfileSetup) {
      return const InviteCompletionScreen();
    }

    if (user == null) {
      return const AuthScreen();
    }

    if (!controller.hasActiveTeam) {
      return const NoActiveTeamScreen();
    }

    if (!controller.isProfileVerified) {
      return const UsernameUnlockScreen();
    }

    return user.role == UserRole.manager
        ? const ManagerMain()
        : const EmployeeMain();
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isRegisterMode = false;
  UserRole _selectedRole = UserRole.manager;
  final _registerFormKey = GlobalKey<FormState>();
  final _loginFormKey = GlobalKey<FormState>();

  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();
  final _businessName = TextEditingController();
  final _registerName = TextEditingController();
  final _registerEmail = TextEditingController();
  final _registerPassword = TextEditingController();
  final _emailLinkEmail = TextEditingController();
  final _usernameController = TextEditingController();

  String _selectedStateCode = 'IL';
  String? _errorText;

  void _switchMode(bool registerMode) {
    setState(() {
      _isRegisterMode = registerMode;
      _errorText = null;
      _usernameController.clear();
    });
  }

  @override
  void dispose() {
    _loginEmail.dispose();
    _loginPassword.dispose();
    _businessName.dispose();
    _registerName.dispose();
    _registerEmail.dispose();
    _registerPassword.dispose();
    _emailLinkEmail.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ShiftSyncScope.of(context);
    final emailLinkInviteId = controller.pendingInviteId;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF17142B), Color(0xFF231F46), Color(0xFF0F4C5C)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: [
                    SizedBox(
                      width: 360,
                      child: _MarketingPanel(
                        inviteEmail: controller.authenticatedEmail,
                        inviteTeamName:
                            controller.hasPendingEmailLinkSignIn ? 'your team invite' : null,
                      ),
                    ),
                    SizedBox(
                      width: 660,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _ModeChip(
                                  label: 'Workplace Sign In',
                                  selected: !_isRegisterMode,
                                  onTap: () => _switchMode(false),
                                ),
                                const SizedBox(width: 8),
                                _ModeChip(
                                  label: 'Create Account',
                                  selected: _isRegisterMode,
                                  onTap: () => _switchMode(true),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              controller.hasPendingEmailLinkSignIn
                                  ? 'Finish your email invite sign in'
                                  : _isRegisterMode
                                  ? 'Create business or employee account'
                                  : 'Select workplace and enter username',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              controller.hasPendingEmailLinkSignIn
                                  ? 'Enter the invited email address to complete the secure Firebase email-link sign in, then finish your employee profile.'
                                  : _isRegisterMode
                                  ? 'Businesses create the workplace first. Employees should only create an account through an invite email.'
                                  : 'Employees and managers choose their workplace, select their profile from a dropdown, and confirm their username.',
                              style: const TextStyle(
                                  color: AppColors.textSecondary, height: 1.45),
                            ),
                            if (_errorText != null) ...[
                              const SizedBox(height: 18),
                              _ErrorBanner(message: _errorText!),
                            ],
                            const SizedBox(height: 20),
                            if (controller.hasPendingEmailLinkSignIn)
                              _buildEmailLinkSignInForm(
                                context,
                                controller,
                                emailLinkInviteId,
                              )
                            else if (_isRegisterMode)
                              _buildRegisterForm(context, controller)
                            else
                              _buildWorkplaceUsernameForm(
                                context,
                                controller,
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
        ),
      ),
    );
  }

  Widget _buildWorkplaceUsernameForm(
    BuildContext context,
    controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Text(
            'Sign in with your Firebase email and password first. After that, ShiftSync will ask you to confirm your username before opening the workplace.',
            style: TextStyle(color: Colors.white, height: 1.45),
          ),
        ),
        const SizedBox(height: 18),
        _buildEmailPasswordForm(context, controller),
      ],
    );
  }

  Widget _buildEmailPasswordForm(BuildContext context, controller) {
    return Form(
      key: _loginFormKey,
      child: Column(
        children: [
          TextFormField(
            controller: _loginEmail,
            decoration: _inputDecoration('Email'),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'Enter your email.'
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _loginPassword,
            obscureText: true,
            decoration: _inputDecoration('Password'),
            validator: (value) => (value == null || value.isEmpty)
                ? 'Enter your password.'
                : null,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: controller.isBusy
                  ? null
                  : () async {
                      if (!_loginFormKey.currentState!.validate()) {
                        return;
                      }
                      final error = await controller.login(
                        email: _loginEmail.text,
                        password: _loginPassword.text,
                      );
                      if (!mounted) {
                        return;
                      }
                      setState(() => _errorText = error);
                    },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('Continue to username step'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailLinkSignInForm(
    BuildContext context,
    controller,
    String? inviteId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            inviteId == null
                ? 'Invite link detected. Enter the same email address that received the invitation.'
                : 'Invite link detected for team invite $inviteId. Enter the same email address that received the invitation.',
            style: const TextStyle(color: Colors.white, height: 1.4),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _emailLinkEmail,
          keyboardType: TextInputType.emailAddress,
          decoration: _inputDecoration('Invited email address'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: controller.isBusy ||
                    _emailLinkEmail.text.trim().isEmpty
                ? null
                : () async {
                    final error = await controller.completeEmailLinkSignIn(
                      email: _emailLinkEmail.text,
                    );
                    if (!mounted) {
                      return;
                    }
                    setState(() => _errorText = error);
                  },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Complete email link sign in'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm(
      BuildContext context, controller) {
    final isBusinessAccount = _selectedRole == UserRole.manager;

    return Form(
      key: _registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<UserRole>(
            initialValue: _selectedRole,
            dropdownColor: AppColors.surfaceVariant,
            decoration: _inputDecoration('Account type'),
            items: const [
              DropdownMenuItem(
                  value: UserRole.manager, child: Text('Business account')),
              DropdownMenuItem(
                  value: UserRole.employee, child: Text('Employee account')),
            ],
            onChanged: (value) =>
                setState(() => _selectedRole = value ?? UserRole.manager),
          ),
          const SizedBox(height: 14),
          if (!isBusinessAccount)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Employees should not use this form. They join by clicking the invite email link, signing in with that email, and finishing their profile in the app.',
                style: TextStyle(color: Colors.white, height: 1.4),
              ),
            ),
          if (isBusinessAccount) ...[
            const SizedBox(height: 14),
            TextFormField(
              controller: _businessName,
              decoration: _inputDecoration('Business name'),
              validator: (value) {
                if (_selectedRole != UserRole.manager) {
                  return null;
                }
                return value == null || value.trim().isEmpty
                    ? 'Enter your business name.'
                    : null;
              },
            ),
          ],
          const SizedBox(height: 14),
          TextFormField(
            controller: _registerName,
            decoration: _inputDecoration(
                isBusinessAccount ? 'Owner full name' : 'Employee full name'),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'Enter the account name.'
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _registerEmail,
            onChanged: (_) => setState(() {}),
            decoration: _inputDecoration('Email'),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'Enter an email.'
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _registerPassword,
            obscureText: true,
            decoration: _inputDecoration('Password'),
            validator: (value) {
              if (value == null || value.length < 6) {
                return 'Use at least 6 characters.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _usernameController,
            onChanged: (_) => setState(() {}),
            decoration: _inputDecoration('Username'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter a username.'
                : null,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _selectedStateCode,
            dropdownColor: AppColors.surfaceVariant,
            decoration: _inputDecoration('Home state for withholding'),
            items: usStates
                .map(
                  (state) => DropdownMenuItem<String>(
                    value: state.code,
                    child: Text('${state.name} (${state.code})'),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(
                () => _selectedStateCode = value ?? _selectedStateCode),
          ),
          const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
              onPressed: controller.isBusy
                  ? null
                  : () async {
                if (!_registerFormKey.currentState!.validate()) {
                  return;
                }

                final error = await controller.register(
                  fullName: _registerName.text,
                  email: _registerEmail.text,
                  password: _registerPassword.text,
                  username: _usernameController.text,
                  stateCode: _selectedStateCode,
                  requestedRole: _selectedRole,
                  businessName: _businessName.text,
                );
                if (!mounted) {
                  return;
                }
                setState(() => _errorText = error);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(isBusinessAccount
                    ? 'Create business account'
                    : 'Create employee account'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.surfaceVariant.withValues(alpha: 0.7),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
    );
  }
}

class UsernameUnlockScreen extends StatefulWidget {
  const UsernameUnlockScreen({super.key});

  @override
  State<UsernameUnlockScreen> createState() => _UsernameUnlockScreenState();
}

class InviteCompletionScreen extends StatefulWidget {
  const InviteCompletionScreen({super.key});

  @override
  State<InviteCompletionScreen> createState() => _InviteCompletionScreenState();
}

class NoActiveTeamScreen extends StatelessWidget {
  const NoActiveTeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ShiftSyncScope.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Container(
          width: 460,
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.group_off_outlined,
                  color: Colors.white, size: 40),
              const SizedBox(height: 16),
              const Text(
                'No Active Team',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This account is not currently attached to a business team. If you were removed, ask the business owner to send a new invite.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                controller.authenticatedEmail ?? '',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: controller.logout,
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InviteCompletionScreenState extends State<InviteCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  String _selectedStateCode = 'IL';
  String? _errorText;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ShiftSyncScope.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Container(
          width: 460,
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Finish Joining Your Team',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Signed in as ${controller.authenticatedEmail ?? 'your invited email'}. Set up your employee profile to join the business team.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 16),
                  _ErrorBanner(message: _errorText!),
                ],
                const SizedBox(height: 18),
                TextFormField(
                  controller: _fullNameController,
                  decoration: _inputDecorationForSheet('Full name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter your full name.'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _usernameController,
                  decoration: _inputDecorationForSheet('Username'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a username.'
                      : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _selectedStateCode,
                  dropdownColor: AppColors.surfaceVariant,
                  decoration:
                      _inputDecorationForSheet('Home state for withholding'),
                  items: usStates
                      .map(
                        (state) => DropdownMenuItem<String>(
                          value: state.code,
                          child: Text('${state.name} (${state.code})'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(
                    () => _selectedStateCode = value ?? _selectedStateCode,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: controller.isBusy
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) {
                              return;
                            }
                            final error =
                                await controller.completeInvitedRegistration(
                              fullName: _fullNameController.text,
                              username: _usernameController.text,
                              stateCode: _selectedStateCode,
                            );
                            if (!mounted) {
                              return;
                            }
                            setState(() => _errorText = error);
                          },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text('Join team'),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: controller.logout,
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecorationForSheet(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
    );
  }
}

class _UsernameUnlockScreenState extends State<UsernameUnlockScreen> {
  final _usernameController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ShiftSyncScope.of(context);
    final user = controller.currentUser!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Container(
          width: 420,
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.primary.withValues(alpha: 0.16),
                child: Text(user.initials,
                    style: const TextStyle(color: Colors.white, fontSize: 24)),
              ),
              const SizedBox(height: 16),
              Text(
                'Confirm @${user.username}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'You stay clocked in until you press clock out. If you sign out while clocked in, sign back in with your username to clock out later.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _usernameController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Enter username',
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                ),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 8),
                Text(_errorText!,
                    style: const TextStyle(color: AppColors.error)),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _usernameController.text.trim().isEmpty
                      ? null
                      : () {
                          final success = controller
                              .verifyUsername(_usernameController.text);
                          if (!success) {
                            setState(() => _errorText =
                                'Username does not match. Try again.');
                          }
                        },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Unlock workplace'),
                  ),
                ),
              ),
              TextButton(
                onPressed: controller.logout,
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _MarketingPanel extends StatelessWidget {
  final String? inviteEmail;
  final String? inviteTeamName;

  const _MarketingPanel({
    this.inviteEmail,
    this.inviteTeamName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Free email-link onboarding',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'ShiftSync',
            style: TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.bold,
              height: 0.95,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Businesses create the workplace, invite employees by email link, assign roles and hourly rate, and users return by selecting the workplace and confirming their username.',
            style: TextStyle(
                color: AppColors.textSecondary, height: 1.6, fontSize: 15),
          ),
          if (inviteEmail != null) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                'Pending invite detected for $inviteEmail${inviteTeamName == null ? '' : ' from $inviteTeamName'}. Create the employee account with that email to join the workplace.',
                style: const TextStyle(color: Colors.white, height: 1.4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Text(message, style: const TextStyle(color: Colors.white)),
    );
  }
}

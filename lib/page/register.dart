import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:startbuddy/service/auth/auth_servvice.dart';
import 'package:startbuddy/service/db/db_service.dart';
import 'package:startbuddy/theme.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    ageController.dispose();
    nameController.dispose();
    super.dispose();
  }

  var isobscure = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      height: 300,
                      width: 300,

                      child: Image.asset("assets/logo.png"),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Welcome,',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign up to continue building with StartBuddy.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 36),
                  TextField(
                    controller: nameController,
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      hintText: 'Name',
                      prefixIcon: Icon(
                        Icons.person_outline_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      hintText: 'Email address',
                      prefixIcon: Icon(
                        Icons.mail_outline_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: isobscure,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      prefixIcon: Icon(
                        Icons.lock_outline_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isobscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            if(isobscure == false) {
                              isobscure =true;
                            }
                            else {
                              isobscure = false;
                            }

                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  TextField(
                    controller: ageController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      hintText: 'Age',
                      prefixIcon: Icon(
                        Icons.person_outline_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Forgot password?',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        final response = await AuthService()
                            .signUpWithEmailPassword(
                              emailController.text,
                              passwordController.text,
                              context: context,
                            );
                        if (!context.mounted || response == null) return;

                       await DbService().createUser(
                          name: nameController.text,
                          age: int.parse(ageController.text),
                          email: emailController.text.trim(),
                        );

                        context.go('/');
                      },
                      style: ElevatedButton.styleFrom(
                        disabledBackgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary,
                        disabledForegroundColor: Colors.white,
                      ),
                      child: const Text('Create account'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'or',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.g_mobiledata_rounded, size: 30),
                      label: const Text('Continue with Google'),
                      style: OutlinedButton.styleFrom(
                        disabledForegroundColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : AppTheme.textPrimaryLight,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () {
                          context.go('/login');
                        },
                        child: Text(
                          'Sign in',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

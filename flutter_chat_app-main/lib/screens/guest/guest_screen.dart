import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_app/cubits/cubits.dart';
import 'package:flutter_chat_app/screens/screens.dart';
import 'package:flutter_login/flutter_login.dart';

class GuestScreen extends StatelessWidget {
  const GuestScreen({super.key});

  static const routeName = "guest";

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GuestCubit>();

    return FlutterLogin(
      scrollable: true,
      hideForgotPasswordButton: true,
      theme: LoginTheme(
        titleStyle: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        pageColorDark: Colors.purpleAccent,
        pageColorLight: Colors.blue.shade300,
      ),
      onLogin: cubit.signIn,
      onSignup: cubit.signUp,
      userValidator: (value) {
        if (value == null || !value.contains('@')) {
          return 'Please enter a valid email address';
        }
        return null;
      },
      passwordValidator: (value) {
        if (value == null || value.length < 5) {
          return "Please must be at least 5 chars";
        }
        return null;
      },
      onSubmitAnimationCompleted: () {
        Navigator.of(context).pushReplacementNamed(ChatListScreen.routeName);
      },
      onRecoverPassword: (_) async => null,
    );
  }
}

import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/await_approval_screen.dart';
import 'screens/home_screen.dart';
import 'screens/verify_email_screen.dart';


class Routes {
static const splash = '/';
static const signIn = '/sign-in';
static const signUp = '/sign-up';
static const awaitApproval = '/await-approval';
static const verifyEmail = '/verify-email';
static const home = '/home';
}


class AppRouter {
static Route<dynamic> onGenerateRoute(RouteSettings settings) {
switch (settings.name) {
case Routes.splash:
return MaterialPageRoute(builder: (_) => const SplashScreen());
case Routes.signIn:
return MaterialPageRoute(builder: (_) => const SignInScreen());
case Routes.signUp:
return MaterialPageRoute(builder: (_) => const SignUpScreen());
case Routes.awaitApproval:
return MaterialPageRoute(builder: (_) => const AwaitApprovalScreen());
case Routes.verifyEmail:
return MaterialPageRoute(builder: (_) => const VerifyEmailScreen());
case Routes.home:
return MaterialPageRoute(builder: (_) => const HomeScreen());
default:
return MaterialPageRoute(builder: (_) => const SplashScreen());
}
}
}
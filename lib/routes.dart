import 'package:flutter/material.dart';
import 'package:lifeassistant/authentication.dart/sign_in_screen.dart';
import 'package:lifeassistant/authentication.dart/sign_up_screen.dart';
import 'package:lifeassistant/home.dart';
import 'package:lifeassistant/lifeassistantscreens/addtaskscreen.dart';
import 'package:lifeassistant/mainscreen.dart';
import 'package:lifeassistant/onboardingscreens.dart/onboarding.dart';

class AppRoutes {
  static const String onboard = '/onboard';
  static const String login = '/login';
  static const String addproductscreen = '/addproduct';
  static const String listproductscreen = '/listproduct';
  static const String bottombarscreen = '/btmsbar';
  static const String home = '/mainscreen';
  static const String mainnav = '/mainnav';
  static const String addtask = '/addtask';
  static const String notification = '/notification';
  static const String history = '/history';
  static const String campaingn = '/mainscreenforcampaign';
  static const String goodness = '/mainscreenforgoodness';
  static const String signUp = '/signup';
  static const String profile = '/profile';
  static const String editprofile = '/editprofile';
  static const String thanksroute = '/thanksroute';
  static const String thanksrouteforitem = '/thanksrouteforitem';
  static const String testroute = '/testroute';
  // Add more routes as needed

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      onboard: (context) => const OnboardingScreen(),
      login: (context) => const SignInPage(),
      mainnav: (context) => MainScreen(indexvalue: 0),
      home: (context) => const HomeScreen(),
      signUp: (context) => const SignUpScreen(),
      addtask: (context) => const AddTaskScreen(),
      // bottombarscreen: (context) => const BottomBarList(),
      // addproductscreen: (context) => const AddProductScreen(),
      // listproductscreen: (context) => const ProductListingScreen(),
      // history: (context) => const OrderHistoryScreen(),
      // notification: (context) => const NotificationsScreen(),
      // history: (context) => const HistoryScreen(),
      // campaingn: (context) => const MainScreen(indexvalue: 1),
      // goodness: (context) => const MainScreen(indexvalue: 2),
      // profile: (context) => const ProfileScreen(),
      // editprofile: (context) => const EditProfileScreen(),
      // testroute: (context) => const HomePage(),
      // thanksroute: (context) => const ThankYouScreen(flag: 0),
      // thanksrouteforitem: (context) => const ThankYouScreen(flag: 1),
      // Add more routes here
    };
  }
}
